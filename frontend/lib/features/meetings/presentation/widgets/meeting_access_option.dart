import 'package:flutter/material.dart';
import '../../../../core/appcolors.dart';

class MeetingAccessOption extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const MeetingAccessOption({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedBackground.withValues(alpha: 0.55) : Colors.transparent,
          border: Border.all(color: selected ? AppColors.primary : AppColors.navigationBorder),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 19,
              color: selected ? AppColors.primary : AppColors.grey,
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
