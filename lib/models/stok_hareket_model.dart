/// Stok hareket kayıt modeli.
class StokHareketModel {
  final int id;
  final int cihazid;
  final String? serino;
  final int? kullaniciid;
  final int? arizaid;
  final int hareket; // 1=giriş, 2=çıkış
  final int hareketdurumu; // 1=beklemede, 2=tamamlandı, 3=iptal
  final String? aciklama;
  final String? kgt;

  const StokHareketModel({
    required this.id,
    required this.cihazid,
    this.serino,
    this.kullaniciid,
    this.arizaid,
    required this.hareket,
    required this.hareketdurumu,
    this.aciklama,
    this.kgt,
  });

  factory StokHareketModel.fromJson(Map<String, dynamic> json) {
    return StokHareketModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      cihazid: json['cihazid'] is int
          ? json['cihazid'] as int
          : int.parse(json['cihazid'].toString()),
      serino: json['serino'] as String?,
      kullaniciid: json['kullaniciid'] != null
          ? int.tryParse(json['kullaniciid'].toString())
          : null,
      arizaid: json['arizaid'] != null
          ? int.tryParse(json['arizaid'].toString())
          : null,
      hareket: json['hareket'] is int
          ? json['hareket'] as int
          : int.tryParse(json['hareket'].toString()) ?? 1,
      hareketdurumu: json['hareketdurumu'] is int
          ? json['hareketdurumu'] as int
          : int.tryParse(json['hareketdurumu'].toString()) ?? 2,
      aciklama: json['aciklama'] as String?,
      kgt: json['kgt'] as String?,
    );
  }

  bool get isGiris => hareket == 1;
  String get hareketAdi => isGiris ? 'Giriş' : 'Çıkış';

  String get durumAdi {
    switch (hareketdurumu) {
      case 1:
        return 'Beklemede';
      case 2:
        return 'Tamamlandı';
      case 3:
        return 'İptal';
      default:
        return 'Bilinmiyor';
    }
  }
}
