import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_manager.dart';
import '../../services/theme_manager.dart';
import '../login/login_screen.dart';
import '../failures/failures_screen.dart';
import '../products/products_screen.dart';
import '../shared/placeholder_screen.dart';
import '../shipments/shipments_screen.dart';
import '../stock_movements/device_movements_screen.dart';
import '../expenses/expenses_screen.dart';
import '../assembly/assembly_screen.dart';

// ─── Dashboard Kart Modeli ──────────────────────────────────────────
class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  /// null ise PlaceholderScreen açılır
  final Widget Function()? screenBuilder;

  const _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.screenBuilder,
  });
}

// ═══════════════════════════════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── Menü öğeleri ──────────────────────────────────────────────────
  List<_DashboardItem> get _items => [
    _DashboardItem(
      title: 'Ürünler',
      subtitle: 'Ürün kataloğu ve stok durumu',
      icon: Icons.inventory_2_rounded,
      gradientColors: const [Color(0xFF4C6FFF), Color(0xFF00D9FF)],
      screenBuilder: () => const ProductsScreen(),
    ),
    _DashboardItem(
      title: 'Arıza Takibi',
      subtitle: 'Ürün arıza ve sorun kaydı',
      icon: Icons.report_problem_rounded,
      gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFFAB40)],
      screenBuilder: () => const FailuresScreen(),
    ),
    _DashboardItem(
      title: 'Harici Masraflar',
      subtitle: 'Dış kaynaklı gider takibi',
      icon: Icons.account_balance_wallet_rounded,
      gradientColors: const [Color(0xFF00E096), Color(0xFF00D9FF)],
      screenBuilder: () => const ExpensesScreen(),
    ),
    _DashboardItem(
      title: 'Sevkiyat',
      subtitle: 'Sevkiyat ve teslimat takibi',
      icon: Icons.local_shipping_rounded,
      gradientColors: const [Color(0xFFA855F7), Color(0xFF6366F1)],
      screenBuilder: () => const ShipmentsScreen(),
    ),
    _DashboardItem(
      title: 'Cihaz Hareketleri',
      subtitle: 'Cihazın tüm hareketleri',
      icon: Icons.history_edu_rounded,
      gradientColors: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
      screenBuilder: () => const DeviceMovementsScreen(),
    ),
    _DashboardItem(
      title: 'Montaj / Tamir',
      subtitle: 'Bileşen ekleme ve sökme işlemleri',
      icon: Icons.handyman_rounded,
      gradientColors: const [Color(0xFFF97316), Color(0xFFFBBF24)],
      screenBuilder: () => const AssemblyScreen(),
    ),

  ];

  // ─── Navigasyon ───────────────────────────────────────────────────
  void _navigateTo(BuildContext context, _DashboardItem item) {
    final screen = item.screenBuilder != null
        ? item.screenBuilder!()
        : PlaceholderScreen(
            title: item.title,
            subtitle: '${item.subtitle}\nBu modül yakında eklenecek.',
            icon: item.icon,
            gradientColors: item.gradientColors,
          );

    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => screen));
  }

  // ─── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = AuthManager.instance.currentUser!;
    final items = _items;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: Stack(
          children: [
            // Kart grid (altta kalacak ve scroll olacak)
            GridView.builder(
              // Üst boşluk hesaplaması: SafeArea + appbar + title (yaklaşık 170)
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 190, 24, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildCard(context, items[index]),
            ),

            // Header (Tek parça, gradient maskeli bulanıklık ile yumuşak geçiş)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  // 1. Arka plan bulanıklığı ve gradient maskesi (Yumuşak geçiş için)
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.85, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.65),
                                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Metinler ve İçerik (Maskesiz, net)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24), // Geçiş alanına boşluk bırakmak için alt padding
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Appbar Kısmı
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                            child: _buildHeader(context, user),
                          ),
                        ),

                        // 2. Metin Kısmı
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting('${user.adsoyad} (${user.id})'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stok Takip Paneli',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary(context),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'İşlem yapmak için bir modül seçin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textHint(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Zaman bazlı karşılama ────────────────────────────────────────
  String _greeting(String adsoyad) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın, $adsoyad';
    if (hour < 18) return 'İyi günler, $adsoyad';
    return 'İyi akşamlar, $adsoyad';
  }

  // ─── Header ───────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, user) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              user.adsoyad.isNotEmpty ? user.adsoyad[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.adsoyad} (id: ${user.id})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.yetki.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColorLight(context),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Gece/Gündüz Modu
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeManager.instance.themeModeNotifier,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.inputFillColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.inputBorderColor(context)),
              ),
              child: IconButton(
                onPressed: () => ThemeManager.instance.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : AppTheme.textSecondary(context),
                  size: 22,
                ),
                tooltip: isDark ? 'Aydınlık Mod' : 'Karanlık Mod',
              ),
            );
          },
        ),
        // Çıkış
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inputFillColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.inputBorderColor(context)),
          ),
          child: IconButton(
            onPressed: () => _handleLogout(context),
            icon: Icon(
              Icons.logout_rounded,
              color: AppTheme.textSecondary(context),
              size: 22,
            ),
            tooltip: 'Çıkış Yap',
          ),
        ),
      ],
    );
  }

  // ─── Dashboard Kartı ──────────────────────────────────────────────
  Widget _buildCard(BuildContext context, _DashboardItem item) {
    final isImplemented = item.screenBuilder != null;

    return GestureDetector(
      onTap: () => _navigateTo(context, item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE9ECEF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İkon kutusu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.gradientColors[0].withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.gradientColors[0], size: 24),
              ),

                    const Spacer(),

                    // Başlık
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Alt başlık
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint(context),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // "Yakında" badge (henüz implemente edilmemişler için)
                    if (!isImplemented) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.textHint(
                            context,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'YAKINDA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textHint(context),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
  }

  // ─── Çıkış ────────────────────────────────────────────────────────
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Çıkış Yap',
          style: TextStyle(color: AppTheme.textPrimary(context)),
        ),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AuthManager.instance.logout();
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: AppTheme.accentPink),
            ),
          ),
        ],
      ),
    );
  }
}
