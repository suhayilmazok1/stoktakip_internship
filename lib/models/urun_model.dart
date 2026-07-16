/// Ürün katalog modeli.
/// API'den dönen ürün artık sadece katalog bilgisi tutar.
/// Fiziksel birim bilgileri (seri no, lokasyon, garanti) cihaz tablosundadır.
class UrunModel {
  final int id;
  final String ad;
  final String? marka;
  final String? kategori;
  final String? renk;
  final String? aciklama;
  final int stokadedi; // müsait cihaz sayısı (cihaz tablosundan hesaplanır)

  const UrunModel({
    required this.id,
    required this.ad,
    this.marka,
    this.kategori,
    this.renk,
    this.aciklama,
    required this.stokadedi,
  });

  factory UrunModel.fromJson(Map<String, dynamic> json) {
    return UrunModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      ad: json['ad'] as String,
      marka: json['marka'] as String?,
      kategori: json['kategori'] as String?,
      renk: json['renk'] as String?,
      aciklama: json['aciklama'] as String?,
      stokadedi: json['stokadedi'] is int
          ? json['stokadedi'] as int
          : int.tryParse(json['stokadedi'].toString()) ?? 0,
    );
  }

  UrunModel copyWith({
    int? id,
    String? ad,
    String? marka,
    String? kategori,
    String? renk,
    String? aciklama,
    int? stokadedi,
  }) {
    return UrunModel(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      marka: marka ?? this.marka,
      kategori: kategori ?? this.kategori,
      renk: renk ?? this.renk,
      aciklama: aciklama ?? this.aciklama,
      stokadedi: stokadedi ?? this.stokadedi,
    );
  }
}
