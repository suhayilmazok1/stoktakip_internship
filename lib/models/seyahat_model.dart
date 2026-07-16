class SeyahatKisiModel {
  final int kullaniciid;
  final String adsoyad;

  const SeyahatKisiModel({required this.kullaniciid, required this.adsoyad});

  factory SeyahatKisiModel.fromJson(Map<String, dynamic> json) {
    return SeyahatKisiModel(
      kullaniciid: json['kullaniciid'] is int
          ? json['kullaniciid'] as int
          : int.parse(json['kullaniciid'].toString()),
      adsoyad: json['adsoyad'] as String? ?? '',
    );
  }
}

class SeyahatModel {
  final int id;
  final int? arizaid;
  final String? seyahatdetayi;
  final String? tarih;
  final String? aciklama;
  final double? tutar;
  final List<SeyahatKisiModel> kisiler;

  const SeyahatModel({
    required this.id,
    this.arizaid,
    this.seyahatdetayi,
    this.tarih,
    this.aciklama,
    this.tutar,
    this.kisiler = const [],
  });

  factory SeyahatModel.fromJson(Map<String, dynamic> json) {
    List<SeyahatKisiModel> kisilerList = [];
    if (json['kisiler'] != null && json['kisiler'] is List) {
      kisilerList = (json['kisiler'] as List)
          .map((kisiJson) => SeyahatKisiModel.fromJson(kisiJson))
          .toList();
    }

    return SeyahatModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      arizaid: json['arizaid'] != null
          ? int.tryParse(json['arizaid'].toString())
          : null,
      seyahatdetayi: json['seyahatdetayi'] as String?,
      tarih: json['tarih'] as String?,
      aciklama: json['aciklama'] as String?,
      tutar: json['tutar'] != null ? double.tryParse(json['tutar'].toString()) : null,
      kisiler: kisilerList,
    );
  }
}
