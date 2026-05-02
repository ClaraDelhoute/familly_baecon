import 'package:flutter/material.dart';

class AlertObservedExpectedBubbles extends StatelessWidget {
  final String observedLabel;
  final String expectedLabel;
  final Color accentColor;

  const AlertObservedExpectedBubbles({
    super.key,
    required this.observedLabel,
    required this.expectedLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Bubble(
          label: 'Observé',
          value: observedLabel,
          textColor: accentColor,
          bgColor: accentColor.withValues(alpha: 0.12),
          borderColor: accentColor.withValues(alpha: 0.35),
          icon: Icons.visibility_rounded,
        ),
        const SizedBox(height: 8),
        _Bubble(
          label: 'Attendu',
          value: expectedLabel,
          textColor: Colors.black87,
          bgColor: Colors.black.withValues(alpha: 0.06),
          borderColor: Colors.black.withValues(alpha: 0.14),
          icon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;

  const _Bubble({
    required this.label,
    required this.value,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
