/// Sevkiyat kayıt modeli.
class SevkiyatModel {
  final int id;
  final int? arizaid;
  final int? cihazid;
  final String? serino;
  final String? takipno;
  final String? kargofirmasi;
  final double? ucret;
  final int
  sevkiyatdurumu; // 1=hazırlanıyor, 2=gönderildi, 3=teslim edildi, 4=iade
  final int? kullaniciid;
  final int yon; // 1=Giden, 2=Gelen
  final String? aciklama;
  final String? kgt;
  final String? kg;
  final String? kdt;
  final String? kd;
  final int? durum;

  const SevkiyatModel({
    required this.id,
    this.arizaid,
    this.cihazid,
    this.serino,
    this.takipno,
    this.kargofirmasi,
    this.ucret,
    required this.sevkiyatdurumu,
    this.kullaniciid,
    this.yon = 1,
    this.aciklama,
    this.kgt,
    this.kg,
    this.kdt,
    this.kd,
    this.durum,
  });

  factory SevkiyatModel.fromJson(Map<String, dynamic> json) {
    return SevkiyatModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      arizaid: json['arizaid'] != null
          ? int.tryParse(json['arizaid'].toString())
          : null,
      cihazid: json['cihazid'] != null
          ? int.tryParse(json['cihazid'].toString())
          : null,
      serino: json['serino'] as String?,
      takipno: json['takipno'] as String?,
      kargofirmasi: json['kargofirmasi'] as String?,
      ucret: json['ucret'] != null
          ? double.tryParse(json['ucret'].toString())
          : null,
      sevkiyatdurumu: json['sevkiyatdurumu'] is int
          ? json['sevkiyatdurumu'] as int
          : int.tryParse(json['sevkiyatdurumu'].toString()) ?? 1,
      kullaniciid: json['kullaniciid'] != null
          ? int.tryParse(json['kullaniciid'].toString())
          : null,
      yon: json['yon'] is int
          ? json['yon'] as int
          : int.tryParse(json['yon'].toString()) ?? 1,
      aciklama: json['aciklama'] as String?,
      kgt: json['kgt'] as String?,
      kg: json['kg'] as String?,
      kdt: json['kdt'] as String?,
      kd: json['kd'] as String?,
      durum: json['durum'] is int
          ? json['durum'] as int
          : (json['durum'] != null ? int.tryParse(json['durum'].toString()) : null),
    );
  }

  String get durumAdi {
    switch (sevkiyatdurumu) {
      case 1:
        return 'Hazırlanıyor';
      case 2:
        return 'Gönderildi';
      case 3:
        return 'Teslim Edildi';
      case 4:
        return 'İade';
      default:
        return 'Bilinmiyor';
    }
  }

  String get displaySeriNo {
    if (serino != null && serino!.trim().isNotEmpty) {
      return serino!;
    }
    return cihazid?.toString() ?? '-';
  }
}
