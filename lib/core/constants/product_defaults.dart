/// Varsayılan kategori ve ürün tanımları.
/// Kullanıcı bunlardan seçebilir veya kendi değerini yazabilir.
class ProductDefaults {
  ProductDefaults._();

  /// Kategori → varsayılan ürün adları haritası.
  /// Değeri boş liste olan kategorilerin alt ürün önerisi yoktur.
  static const Map<String, List<String>> categoryProducts = {
    'Rezervasyon Kiosk\'u': [],
    'Katalog Tarama Cihazı': [],
    'Güvenlik Kapısı': [],
    'Büyük Ekranlı Kiosk': [],
    'HF Cihazı': [],
    'UHF Cihazı': [],
    'UHF El Terminali (Sayım Cihazı)': [],
    'HF El Terminali (Sayım Cihazı)': [],
    'Rezervasyon Kiosk\'u Ekranları': [],
    'Eski Tip Turnike Üstü Ekranı': [],
    'Sirkülasyon Cihazları': [],
    'Robotlar': [],
    'Sterilizasyon Cihazı': [],
    'Eski Tip Turnike Küçük Ekranlar': [],
    'Barkod Okuyucu Siyah Kablo': [],
  };

  /// Tüm varsayılan kategori adları.
  static List<String> get categories => categoryProducts.keys.toList();

  /// Verilen kategoriye ait varsayılan ürün adlarını döner.
  static List<String> productsForCategory(String kategori) {
    // Büyük/küçük harf duyarsız eşleşme
    for (final entry in categoryProducts.entries) {
      if (entry.key.toLowerCase() == kategori.toLowerCase()) {
        return entry.value;
      }
    }
    return [];
  }

  /// Arama metnine göre filtrelenmiş kategorileri döner.
  static List<String> filterCategories(String query) {
    if (query.isEmpty) return categories;
    final q = query.toLowerCase();
    return categories.where((c) => c.toLowerCase().contains(q)).toList();
  }
}
