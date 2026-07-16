import '../models/user_model.dart';
import 'api_service.dart';
import 'local_storage_manager.dart';

/// Auth durumunu (kullanıcı bilgisi + credential) merkezi olarak yöneten singleton.
class AuthManager {
  AuthManager._();
  static final AuthManager instance = AuthManager._();

  UserModel? _currentUser;
  String? _kullaniciadi;
  String? _sifre;

  // ── Getter'lar ──
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get kullaniciadi => _kullaniciadi;
  String? get sifre => _sifre;

  /// Giriş yap – başarılıysa kullanıcı bilgisini ve credential'ları saklar.
  Future<UserModel> login({
    required String kullaniciadi,
    required String sifre,
  }) async {
    final user = await ApiService.instance.girisYap(
      kullaniciadi: kullaniciadi,
      sifre: sifre,
    );
    _currentUser = user;
    _kullaniciadi = kullaniciadi;
    _sifre = sifre;

    // Otomatik giriş için yerel hafızaya kaydet
    await LocalStorageManager.instance.setString('kullaniciadi', kullaniciadi);
    await LocalStorageManager.instance.setString('sifre', _sifre!);

    return user;
  }

  /// Çıkış yap – tüm oturum verisini temizler.
  void logout() {
    _currentUser = null;
    _kullaniciadi = null;
    _sifre = null;

    // Otomatik giriş bilgilerini temizle
    LocalStorageManager.instance.remove('kullaniciadi');
    LocalStorageManager.instance.remove('sifre');
  }
}
