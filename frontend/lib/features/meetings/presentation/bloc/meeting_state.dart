import 'package:equatable/equatable.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/entities/meeting_join_result.dart';

enum MeetingStatus { initial, submitting, success, failure }

class MeetingState extends Equatable {
  final List<MeetingEntity> meetings;
  final String category;
  final String accessType;
  final String password;
  final String meetingType; // 'instant' or 'scheduled'
  final DateTime? scheduledStartTime;
  final MeetingStatus status;
  final String message;
  final MeetingJoinResult? joinResult;
  final bool isJoining;
  final List<MeetingEntity> privateSearchResults;
  final bool isSearchingPrivate;
  final String searchPrivateQuery;

  const MeetingState({
    this.meetings = const [],
    this.category = '',
    this.accessType = 'public',
    this.password = '',
    this.meetingType = 'instant',
    this.scheduledStartTime,
    this.status = MeetingStatus.initial,
    this.message = '',
    this.joinResult,
    this.isJoining = false,
    this.privateSearchResults = const [],
    this.isSearchingPrivate = false,
    this.searchPrivateQuery = '',
  });

  bool get isInstant => meetingType == 'instant';
  bool get isScheduled => meetingType == 'scheduled';

  MeetingState copyWith({
    List<MeetingEntity>? meetings,
    String? category,
    String? accessType,
    String? password,
    String? meetingType,
    DateTime? scheduledStartTime,
    bool clearScheduledStartTime = false,
    MeetingStatus? status,
    String? message,
    MeetingJoinResult? joinResult,
    bool? isJoining,
    List<MeetingEntity>? privateSearchResults,
    bool? isSearchingPrivate,
    String? searchPrivateQuery,
  }) {
    return MeetingState(
      meetings: meetings ?? this.meetings,
      category: category ?? this.category,
      accessType: accessType ?? this.accessType,
      password: password ?? this.password,
      meetingType: meetingType ?? this.meetingType,
      scheduledStartTime: clearScheduledStartTime
          ? null
          : (scheduledStartTime ?? this.scheduledStartTime),
      status: status ?? this.status,
      message: message ?? this.message,
      joinResult: joinResult ?? this.joinResult,
      isJoining: isJoining ?? this.isJoining,
      privateSearchResults: privateSearchResults ?? this.privateSearchResults,
      isSearchingPrivate: isSearchingPrivate ?? this.isSearchingPrivate,
      searchPrivateQuery: searchPrivateQuery ?? this.searchPrivateQuery,
    );
  }

  @override
  List<Object?> get props => [
        meetings,
        category,
        accessType,
        password,
        meetingType,
        scheduledStartTime,
        status,
        message,
        joinResult,
        isJoining,
        privateSearchResults,
        isSearchingPrivate,
        searchPrivateQuery,
      ];
}

class MeetingLoading extends MeetingState {
  const MeetingLoading({
    super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.initial,
    super.message,
  });
}

class MeetingLoaded extends MeetingState {
  const MeetingLoaded({
    required super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.initial,
    super.message,
  });
}

class MeetingError extends MeetingState {
  final String error;

  const MeetingError({
    required this.error,
    super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.failure,
    super.message,
  });

  @override
  List<Object?> get props => [error, ...super.props];
}

class MeetingJoined extends MeetingState {
  const MeetingJoined({
    required MeetingJoinResult joinResult,
    super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.success,
    super.message,
  }) : super(joinResult: joinResult, isJoining: false);
}

