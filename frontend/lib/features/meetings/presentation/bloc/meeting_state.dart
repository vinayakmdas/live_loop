import 'package:equatable/equatable.dart';

enum MeetingStatus { initial, submitting, success, failure }

class MeetingState extends Equatable {
  final String category;
  final String accessType;
  final MeetingStatus status;
  final String message;

  const MeetingState({
    this.category = '',
    this.accessType = 'invite_only',
    this.status = MeetingStatus.initial,
    this.message = '',
  });

  MeetingState copyWith({
    String? category,
    String? accessType,
    MeetingStatus? status,
    String? message,
  }) {
    return MeetingState(
      category: category ?? this.category,
      accessType: accessType ?? this.accessType,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [category, accessType, status, message];
}
