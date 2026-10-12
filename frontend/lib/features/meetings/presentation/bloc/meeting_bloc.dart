import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/meeting_entity.dart';
import '../../domain/usecases/create_meeting.dart';
import 'meeting_event.dart';
import 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final CreateMeeting createMeeting;

  MeetingBloc({required this.createMeeting}) : super(const MeetingState()) {
    on<MeetingCategoryChanged>((event, emit) {
      emit(state.copyWith(category: event.category, status: MeetingStatus.initial, message: ''));
    });

    on<MeetingAccessChanged>((event, emit) {
      emit(state.copyWith(accessType: event.accessType, status: MeetingStatus.initial, message: ''));
    });

    on<MeetingMessageCleared>((event, emit) {
      emit(state.copyWith(status: MeetingStatus.initial, message: ''));
    });

    on<MeetingSubmitted>((event, emit) async {
      if (event.name.trim().isEmpty) {
        emit(state.copyWith(status: MeetingStatus.failure, message: 'Please enter a meeting name.'));
        return;
      }
      if (event.category.isEmpty) {
        emit(state.copyWith(status: MeetingStatus.failure, message: 'Please choose a category.',));
        return;
      }

      emit(state.copyWith(status: MeetingStatus.submitting, message: ''));
      try {
        await createMeeting(MeetingEntity(
          name: event.name.trim(),
          description: event.description.trim(),
          category: event.category,
          accessType: event.accessType,
        ));
        emit(state.copyWith(status: MeetingStatus.success, message: 'Meeting space created successfully.'));
      } catch (_) {
        emit(state.copyWith(status: MeetingStatus.failure, message: 'Could not create the meeting. Please try again.'));
      }
    });
  }
}
