import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/meeting_entity.dart';
import '../../domain/entities/meeting_join_result.dart';
import '../../domain/usecases/create_meeting.dart';
import '../../domain/usecases/get_meetings.dart';
import '../../domain/usecases/join_meeting.dart';
import '../../domain/usecases/search_meetings.dart';
import 'meeting_event.dart';
import 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final CreateMeeting createMeeting;
  final GetMeetings getMeetings;
  final JoinMeeting? joinMeeting;
  final SearchMeetings? searchMeetings;

  MeetingBloc({
    required this.createMeeting,
    required this.getMeetings,
    this.joinMeeting,
    this.searchMeetings,
  }) : super(const MeetingState()) {
    on<LoadMeetingsEvent>(_onLoadMeetings);
    on<MeetingCategoryChanged>(_onCategoryChanged);
    on<MeetingAccessChanged>(_onAccessChanged);
    on<MeetingPasswordChanged>(_onPasswordChanged);
    on<MeetingTypeChanged>(_onTypeChanged);
    on<MeetingScheduleChanged>(_onScheduleChanged);
    on<MeetingMessageCleared>(_onMessageCleared);
    on<MeetingSubmitted>(_onMeetingSubmitted);
    on<JoinMeetingRequested>(_onJoinMeeting);
    on<SearchPrivateMeetingsEvent>(_onSearchPrivateMeetings);
  }

  Future<void> _onLoadMeetings(
    LoadMeetingsEvent event,
    Emitter<MeetingState> emit,
  ) async {
    emit(MeetingLoading(
      meetings: state.meetings,
      category: state.category,
      accessType: state.accessType,
      meetingType: state.meetingType,
      scheduledStartTime: state.scheduledStartTime,
      status: state.status,
      message: '',
    ));

    try {
      final meetings = await getMeetings();
      emit(MeetingLoaded(
        meetings: meetings,
        category: state.category,
        accessType: state.accessType,
        meetingType: state.meetingType,
        scheduledStartTime: state.scheduledStartTime,
        status: MeetingStatus.initial,
        message: '',
      ));
    } catch (e) {
      emit(MeetingError(
        error: e.toString(),
        meetings: state.meetings,
        category: state.category,
        accessType: state.accessType,
        meetingType: state.meetingType,
        scheduledStartTime: state.scheduledStartTime,
        message: e.toString(),
      ));
    }
  }

  void _onCategoryChanged(
    MeetingCategoryChanged event,
    Emitter<MeetingState> emit,
  ) {
    emit(state.copyWith(
      category: event.category,
      status: MeetingStatus.initial,
      message: '',
    ));
  }

  void _onAccessChanged(
    MeetingAccessChanged event,
    Emitter<MeetingState> emit,
  ) {
    emit(state.copyWith(
      accessType: event.accessType,
      status: MeetingStatus.initial,
      message: '',
    ));
  }

  void _onPasswordChanged(
    MeetingPasswordChanged event,
    Emitter<MeetingState> emit,
  ) {
    emit(state.copyWith(
      password: event.password,
      status: MeetingStatus.initial,
      message: '',
    ));
  }

  void _onTypeChanged(
    MeetingTypeChanged event,
    Emitter<MeetingState> emit,
  ) {
    emit(state.copyWith(
      meetingType: event.meetingType,
      status: MeetingStatus.initial,
      message: '',
    ));
  }

  void _onScheduleChanged(
    MeetingScheduleChanged event,
    Emitter<MeetingState> emit,
  ) {
    emit(state.copyWith(
      scheduledStartTime: event.scheduledStartTime,
      status: MeetingStatus.initial,
      message: '',
    ));
  }

  void _onMessageCleared(
    MeetingMessageCleared event,
    Emitter<MeetingState> emit,
  ) {
    emit(state.copyWith(status: MeetingStatus.initial, message: ''));
  }

  Future<void> _onMeetingSubmitted(
    MeetingSubmitted event,
    Emitter<MeetingState> emit,
  ) async {
    if (event.name.trim().isEmpty) {
      emit(state.copyWith(
        status: MeetingStatus.failure,
        message: 'Please enter a meeting name.',
      ));
      return;
    }
    if (event.category.isEmpty) {
      emit(state.copyWith(
        status: MeetingStatus.failure,
        message: 'Please choose a category.',
      ));
      return;
    }

    final effectivePassword = (event.password ?? state.password).trim();
    if (event.accessType == 'private' && effectivePassword.isEmpty) {
      emit(state.copyWith(
        status: MeetingStatus.failure,
        message: 'Please enter a password for your private room.',
      ));
      return;
    }

    emit(state.copyWith(
      status: MeetingStatus.submitting,
      message: '',
    ));

    try {
      final isScheduled = event.scheduledStartTime != null;
      final newMeeting = await createMeeting(MeetingEntity(
        name: event.name.trim(),
        description: event.description.trim(),
        category: event.category.toLowerCase(),
        accessType: event.accessType,
        password: effectivePassword.isNotEmpty ? effectivePassword : null,
        meetingType: isScheduled ? 'scheduled' : 'instant',
        scheduledStartTime: event.scheduledStartTime,
      ));

      // Public rooms are visible to everyone in the meeting list.
      // Private rooms do NOT appear in the public meeting list.
      final updatedMeetings = event.accessType == 'public'
          ? [newMeeting, ...state.meetings]
          : state.meetings;

      emit(state.copyWith(
        meetings: updatedMeetings,
        category: '',
        password: '',
        accessType: 'public',
        meetingType: 'instant',
        clearScheduledStartTime: true,
        status: MeetingStatus.success,
        message: isScheduled
            ? 'Meeting scheduled successfully.'
            : 'Meeting created successfully (starts instantly).',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MeetingStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onSearchPrivateMeetings(
    SearchPrivateMeetingsEvent event,
    Emitter<MeetingState> emit,
  ) async {
    emit(state.copyWith(
      isSearchingPrivate: true,
      searchPrivateQuery: event.query,
      message: '',
    ));

    try {
      final results = searchMeetings != null
          ? await searchMeetings!(query: event.query, type: 'private')
          : <MeetingEntity>[];
      emit(state.copyWith(
        isSearchingPrivate: false,
        privateSearchResults: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSearchingPrivate: false,
        privateSearchResults: [],
        message: e.toString(),
      ));
    }
  }

  Future<void> _onJoinMeeting(
    JoinMeetingRequested event,
    Emitter<MeetingState> emit,
  ) async {
    if (joinMeeting == null) return;
    emit(state.copyWith(isJoining: true, message: ''));

    try {
      final result = await joinMeeting!(
        meetingId: event.meetingId,
        meetingLink: event.meetingLink,
        roomName: event.roomName,
        passcode: event.passcode,
      );

      final updatedMeetings = state.meetings.map((m) {
        if (m.id == result.meeting.id) {
          return result.meeting;
        }
        return m;
      }).toList();

      emit(MeetingJoined(
        joinResult: result,
        meetings: updatedMeetings,
        category: state.category,
        accessType: state.accessType,
        meetingType: state.meetingType,
        scheduledStartTime: state.scheduledStartTime,
      ));
    } catch (e) {
      emit(state.copyWith(
        isJoining: false,
        status: MeetingStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<MeetingJoinResult?> joinMeetingDirect({
    String? meetingId,
    String? meetingLink,
    String? roomName,
    String? passcode,
  }) async {
    if (joinMeeting == null) return null;
    return joinMeeting!(
      meetingId: meetingId,
      meetingLink: meetingLink,
      roomName: roomName,
      passcode: passcode,
    );
  }

  Future<List<MeetingEntity>> searchPrivateMeetingsDirect(String query) async {
    if (searchMeetings == null) return [];
    return searchMeetings!(query: query, type: 'private');
  }
}
