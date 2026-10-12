import 'package:flutter/material.dart';
import '../../../../core/appcolors.dart';

class MeetingCard extends StatelessWidget {
  final String meetingName;
  final String description;
  final String category;
  final String accessType;
  final String meetingType;
  final DateTime? scheduledStartTime;
  final VoidCallback? onTap;

  const MeetingCard({
    super.key,
    required this.meetingName,
    required this.description,
    required this.category,
    required this.accessType,
    this.meetingType = 'instant',
    this.scheduledStartTime,
    this.onTap,
  });

  String _formatCategory(String text) {
    if (text.isEmpty) return 'General';
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatAccessType(String text) {
    if (text == 'anyone_with_link') return 'Link access';
    if (text == 'invite_only') return 'Invite only';
    return text;
  }

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
                  _BadgeChip(
                    icon: accessType == 'anyone_with_link'
                        ? Icons.link
                        : Icons.lock_outline,
                    label: _formatAccessType(accessType),
                    backgroundColor: AppColors.background,
                    textColor: AppColors.textPrimary,
                  ),
                  if (isScheduled)
                    _BadgeChip(
                      icon: Icons.calendar_today_outlined,
                      label: scheduleLabel,
                      backgroundColor: AppColors.background,
                      textColor: AppColors.warning,
                    )
                  else
                    const _BadgeChip(
                      icon: Icons.bolt_outlined,
                      label: 'Instant Meeting',
                      backgroundColor: AppColors.background,
                      textColor: AppColors.inactiveText,
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
