import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'services/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // LocalStorage'ı başlat
  await LocalStorageManager.instance.init();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // İlk çalıştırmada sistem durum çubuğu ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const StokTakipApp());
}

class StokTakipApp extends StatelessWidget {
  const StokTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        // Tema değiştiğinde durum çubuğu renklerini de dinamik olarak değiştir
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: isDark
                ? AppTheme.scaffoldDark
                : const Color(0xFFF8F9FA),
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: isDark ? AppTheme.scaffoldDark : const Color(0xFFF8F9FA),
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
          child: MaterialApp(
            title: 'Stok Takip',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const LoginScreen(),
          ),
        );
      },
    );
  }
}
