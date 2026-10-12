import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/appcolors.dart';
import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';
import '../widgets/meeting_access_option.dart';
import '../widgets/meeting_form_field.dart';
import '../widgets/meeting_timing_option.dart';

class CreateMeetingPage extends StatelessWidget {
  const CreateMeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<MeetingBloc>();
      return const _CreateMeetingView();
    } catch (_) {
      // Fallback if accessed in isolation without parent MeetingBloc
      return const _CreateMeetingView();
    }
  }
}

class _CreateMeetingView extends StatefulWidget {
  const _CreateMeetingView();

  @override
  State<_CreateMeetingView> createState() => _CreateMeetingViewState();
}

class _CreateMeetingViewState extends State<_CreateMeetingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _categories = ['Project', 'Friends', 'Community', 'Team', 'Other'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} at ${_formatTime(dt)}';
  }

  Future<void> _selectDate(BuildContext context, MeetingState state) async {
    final now = DateTime.now();
    final current = state.scheduledStartTime ?? now.add(const Duration(hours: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(now) ? now : current,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.navigationBackground,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.navigationBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final existing = state.scheduledStartTime ?? current;
      final updated = DateTime(
        picked.year,
        picked.month,
        picked.day,
        existing.hour,
        existing.minute,
      );
      context.read<MeetingBloc>().add(MeetingScheduleChanged(updated));
    }
  }

  Future<void> _selectTime(BuildContext context, MeetingState state) async {
    final now = DateTime.now();
    final current = state.scheduledStartTime ?? now.add(const Duration(hours: 1));
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.navigationBackground,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.navigationBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final existing = state.scheduledStartTime ?? current;
      final updated = DateTime(
        existing.year,
        existing.month,
        existing.day,
        picked.hour,
        picked.minute,
      );
      context.read<MeetingBloc>().add(MeetingScheduleChanged(updated));
    }
  }

  void _submit(BuildContext context, MeetingState state) {
    FocusScope.of(context).unfocus();
    context.read<MeetingBloc>().add(MeetingSubmitted(
      name: _nameController.text,
      description: _descriptionController.text,
      category: state.category,
      accessType: state.accessType,
      meetingType: state.meetingType,
      scheduledStartTime: state.scheduledStartTime,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My meetings',
          style: TextStyle(
            color: AppColors.inactiveText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<MeetingBloc, MeetingState>(
          listener: (context, state) {
            if (state.status == MeetingStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.maybePop(context, true);
            } else if (state.status == MeetingStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.navigationBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.navigationBorder),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Create a meeting space',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                MeetingFormField(
                                  label: 'Meeting name',
                                  hint: 'e.g. Kerala Community',
                                  controller: _nameController,
                                ),
                                const SizedBox(height: 20),
                                MeetingFormField(
                                  label: 'Description',
                                  hint: 'What brings this group together?',
                                  controller: _descriptionController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Category',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                DropdownButtonFormField<String>(
                                  initialValue: state.category.isEmpty ? null : state.category,
                                  hint: const Text(
                                    'Choose a category',
                                    style: TextStyle(color: AppColors.hintText, fontSize: 13),
                                  ),
                                  dropdownColor: AppColors.navigationBackground,
                                  iconEnabledColor: AppColors.inactiveText,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.navigationBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.primary),
                                    ),
                                  ),
                                  items: _categories.map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      context.read<MeetingBloc>().add(MeetingCategoryChanged(value));
                                    }
                                  },
                                ),

                                const SizedBox(height: 22),
                                const Text(
                                  'When do you want to start?',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                MeetingTimingOption(
                                  title: 'Start an Instant Meeting',
                                  subtitle: 'Create and start the meeting right now',
                                  icon: Icons.bolt_outlined,
                                  value: 'instant',
                                  groupValue: state.meetingType,
                                  onChanged: (value) {
                                    context.read<MeetingBloc>().add(MeetingTypeChanged(value));
                                  },
                                ),
                                const SizedBox(height: 10),
                                MeetingTimingOption(
                                  title: 'Create a Meeting for Later',
                                  subtitle: 'Pick a date and time to schedule for later',
                                  icon: Icons.calendar_today_outlined,
                                  value: 'scheduled',
                                  groupValue: state.meetingType,
                                  onChanged: (value) {
                                    context.read<MeetingBloc>().add(MeetingTypeChanged(value));
                                    if (state.scheduledStartTime == null) {
                                      final defaultTime = DateTime.now().add(const Duration(hours: 1));
                                      context.read<MeetingBloc>().add(MeetingScheduleChanged(defaultTime));
                                    }
                                  },
                                ),

                                if (state.isScheduled) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.navigationBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Schedule details',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _SchedulePickerButton(
                                                icon: Icons.calendar_month_outlined,
                                                label: state.scheduledStartTime != null
                                                    ? _formatDate(state.scheduledStartTime!)
                                                    : 'Select Date',
                                                onTap: () => _selectDate(context, state),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _SchedulePickerButton(
                                                icon: Icons.schedule_outlined,
                                                label: state.scheduledStartTime != null
                                                    ? _formatTime(state.scheduledStartTime!)
                                                    : 'Select Time',
                                                onTap: () => _selectTime(context, state),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (state.scheduledStartTime != null) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            'Meeting starts on ${_formatDateTime(state.scheduledStartTime!)}',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 22),
                                const Text(
                                  'Who can access this space?',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                MeetingAccessOption(
                                  title: 'Invite only',
                                  value: 'invite_only',
                                  groupValue: state.accessType,
                                  onChanged: (value) => context.read<MeetingBloc>().add(MeetingAccessChanged(value)),
                                ),
                                const SizedBox(height: 10),
                                MeetingAccessOption(
                                  title: 'Anyone with the link',
                                  value: 'anyone_with_link',
                                  groupValue: state.accessType,
                                  onChanged: (value) => context.read<MeetingBloc>().add(MeetingAccessChanged(value)),
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: AppColors.navigationBorder, height: 1),
                                const SizedBox(height: 16),
                                if (state.status == MeetingStatus.failure && state.message.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      state.message,
                                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: state.status == MeetingStatus.submitting
                                          ? null
                                          : () => Navigator.maybePop(context),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: state.status == MeetingStatus.submitting
                                          ? null
                                          : () => _submit(context, state),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors.primaryDisabled,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      child: state.status == MeetingStatus.submitting
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                            )
                                          : Text(
                                              state.isScheduled ? 'Schedule meeting' : 'Create meeting',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _MeetingBottomNavigation(
                  onHome: () => Navigator.maybePop(context),
                  onMeetings: () {},
                  onNotifications: () {},
                  onProfile: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SchedulePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SchedulePickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.navigationBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.navigationBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingBottomNavigation extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onMeetings;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _MeetingBottomNavigation({
    required this.onHome,
    required this.onMeetings,
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navigationBackground,
        border: Border.all(color: AppColors.navigationBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _NavItem(label: 'Home', selected: false, onTap: onHome),
          _NavItem(label: 'Meetings', selected: true, onTap: onMeetings),
          _NavItem(label: 'Notifications', selected: false, onTap: onNotifications),
          _NavItem(label: 'Profile', selected: false, onTap: onProfile),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.selectedText : AppColors.inactiveText,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
