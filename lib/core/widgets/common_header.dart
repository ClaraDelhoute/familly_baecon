import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? actionWidget;

  const CommonHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentBlue, AppTheme.accentCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (actionWidget != null) actionWidget!,
          ],
        ),
      ),
    );
  }
}
