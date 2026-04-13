import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? actionWidget;
  final bool compact;

  const CommonHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionWidget,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        compact ? 42 : 60,
        20,
        compact ? 14 : 24,
      ),
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
                    style: TextStyle(
                      fontSize: compact ? 21 : 24,
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
                          fontSize: compact ? 13 : 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ?actionWidget,
          ],
        ),
      ),
    );
  }
}
