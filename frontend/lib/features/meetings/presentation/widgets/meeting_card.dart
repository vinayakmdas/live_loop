import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/appcolors.dart';

class MeetingCard extends StatelessWidget {
  final String meetingName;
  final String description;
  final String category;
  final String accessType;
  final String? joinCode;
  final String meetingType;
  final DateTime? scheduledStartTime;
  final VoidCallback? onTap;

  const MeetingCard({
    super.key,
    required this.meetingName,
    required this.description,
    required this.category,
    required this.accessType,
    this.joinCode,
    this.meetingType = 'instant',
    this.scheduledStartTime,
    this.onTap,
  });

  String _formatCategory(String text) {
    if (text.isEmpty) return 'General';
    return text[0].toUpperCase() + text.substring(1);
  }

  bool get _isPrivate => accessType.toLowerCase() == 'private';

  bool get _isScheduledMeeting =>
      meetingType.toLowerCase() == 'scheduled' ||
      meetingType.toLowerCase() == 'later';

  String _formatScheduleBadge(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final localDt = dt.toLocal();
    final hour = localDt.hour == 0
        ? 12
        : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final period = localDt.hour >= 12 ? 'PM' : 'AM';
    return '${months[localDt.month - 1]} ${localDt.day}, ${localDt.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isScheduled = _isScheduledMeeting;
    final hasValidTime = isScheduled && scheduledStartTime != null;
    final scheduleLabel = hasValidTime
        ? _formatScheduleBadge(scheduledStartTime!)
        : (isScheduled ? 'Scheduled for Later' : 'Instant Meeting');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.navigationBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.navigationBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isScheduled
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isScheduled
                          ? Icons.calendar_month_outlined
                          : Icons.bolt_outlined,
                      color: isScheduled ? AppColors.warning : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meetingName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: AppColors.inactiveText,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.inactiveText,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _BadgeChip(
                    icon: Icons.folder_outlined,
                    label: _formatCategory(category),
                    backgroundColor: AppColors.background,
                    textColor: AppColors.primary,
                  ),
                  if (_isPrivate)
                    _BadgeChip(
                      icon: Icons.lock_outline,
                      label: 'Private',
                      backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                      textColor: AppColors.warning,
                    )
                  else
                    _BadgeChip(
                      icon: Icons.public,
                      label: 'Public',
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      textColor: AppColors.primary,
                    ),
                  if (_isPrivate && joinCode != null && joinCode!.isNotEmpty)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: joinCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppColors.white, size: 16),
                                const SizedBox(width: 8),
                                Text('Meeting code $joinCode copied to clipboard!'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.key_outlined, size: 12, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              'Code: $joinCode',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.copy_rounded, size: 11, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  if (isScheduled) ...[
                    if (hasValidTime && DateTime.now().isBefore(scheduledStartTime!.toLocal()))
                      _BadgeChip(
                        icon: Icons.access_time_rounded,
                        label: 'Starts: $scheduleLabel',
                        backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                        textColor: AppColors.warning,
                      )
                    else
                      _BadgeChip(
                        icon: Icons.fiber_manual_record,
                        label: hasValidTime ? 'Live Now · Scheduled ($scheduleLabel)' : 'Live Now',
                        backgroundColor: AppColors.success.withValues(alpha: 0.12),
                        textColor: AppColors.success,
                      ),
                  ] else
                    const _BadgeChip(
                      icon: Icons.bolt_outlined,
                      label: 'Live Now',
                      backgroundColor: AppColors.background,
                      textColor: AppColors.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.navigationBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
