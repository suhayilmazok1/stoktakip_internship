import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Arka plan dairesi için renk
    final circleColor = isDark 
        ? AppTheme.primaryColor(context).withValues(alpha: 0.1)
        : AppTheme.primaryColor(context).withValues(alpha: 0.05);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon Kutusu
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Başlık
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Alt Başlık
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
                height: 1.5,
              ),
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 32),
              // Opsiyonel Aksiyon Butonu
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
