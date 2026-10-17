/// Utility class for formatting dates, times, and countdowns across Live Loop.
class DateTimeFormatter {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  /// Formats the remaining countdown until [scheduledTime].
  ///
  /// Examples:
  /// - "Starts in 30 minutes"
  /// - "Starts in 2 hours"
  /// - "Starts tomorrow"
  /// - "Starts in 3 days"
  /// - "Starts now"
  static String formatCountdown(DateTime? scheduledTime, {DateTime? now}) {
    if (scheduledTime == null) return 'Starts now';

    final current = now ?? DateTime.now();
    final localScheduled = scheduledTime.toLocal();
    final localNow = current.toLocal();
    final difference = localScheduled.difference(localNow);

    if (difference.isNegative || difference.inSeconds <= 0) {
      return 'Starts now';
    }

    final scheduledDay =
        DateTime(localScheduled.year, localScheduled.month, localScheduled.day);
    final currentDay =
        DateTime(localNow.year, localNow.month, localNow.day);
    final calendarDayDiff = scheduledDay.difference(currentDay).inDays;

    if (calendarDayDiff == 0) {
      // Same calendar day
      if (difference.inMinutes < 1) {
        return 'Starts in 1 minute';
      } else if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        return 'Starts in $mins ${mins == 1 ? 'minute' : 'minutes'}';
      } else {
        final hours = difference.inHours;
        return 'Starts in $hours ${hours == 1 ? 'hour' : 'hours'}';
      }
    } else if (calendarDayDiff == 1) {
      // Tomorrow
      if (difference.inHours <= 3) {
        final hours = difference.inHours;
        if (hours == 0) {
          final mins = difference.inMinutes;
          return 'Starts in $mins ${mins == 1 ? 'minute' : 'minutes'}';
        }
        return 'Starts in $hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return 'Starts tomorrow';
    } else {
      // 2 or more days in future
      final days = calendarDayDiff;
      return 'Starts in $days ${days == 1 ? 'day' : 'days'}';
    }
  }

  /// Formats the scheduled date (e.g. "Tomorrow", "Today", "Oct 18, 2026").
  /// Returns an empty string if [scheduledTime] is null.
  static String formatScheduledDate(DateTime? scheduledTime, {DateTime? now}) {
    if (scheduledTime == null) return '';

    final localScheduled = scheduledTime.toLocal();
    final localNow = (now ?? DateTime.now()).toLocal();

    final scheduledDay =
        DateTime(localScheduled.year, localScheduled.month, localScheduled.day);
    final currentDay =
        DateTime(localNow.year, localNow.month, localNow.day);
    final diff = scheduledDay.difference(currentDay).inDays;

    if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Tomorrow';
    }

    final monthName = _months[localScheduled.month - 1];
    return '$monthName ${localScheduled.day}, ${localScheduled.year}';
  }

  /// Formats the scheduled start time in 12-hour format (e.g. "2:30 PM", "10:00 AM").
  /// Returns an empty string if [scheduledTime] is null.
  static String formatScheduledTime(DateTime? scheduledTime) {
    if (scheduledTime == null) return '';

    final local = scheduledTime.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Formats full scheduled date and time (e.g. "Tomorrow at 2:30 PM").
  static String formatDateTime(DateTime? scheduledTime, {DateTime? now}) {
    if (scheduledTime == null) return '';
    final date = formatScheduledDate(scheduledTime, now: now);
    final time = formatScheduledTime(scheduledTime);
    if (date.isEmpty) return time;
    if (time.isEmpty) return date;
    return '$date at $time';
  }
}
