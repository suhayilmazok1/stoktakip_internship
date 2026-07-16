import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Henüz implemente edilmemiş modüller için ortak "Yakında" ekranı.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Gövde ──
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // İkon
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                gradientColors[0].withValues(alpha: 0.2),
                                gradientColors[1].withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: gradientColors[0].withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(icon, size: 44, color: gradientColors[0]),
                        ),
                        const SizedBox(height: 28),

                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: gradientColors,
                          ).createShader(bounds),
                          child: const Text(
                            'Yakında',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Geri dön butonu
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Ana Sayfaya Dön'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary(context),
                            side: BorderSide(
                              color: AppTheme.inputBorderColor(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
