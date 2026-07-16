class HariciAlimModel {
  final int id;
  final int? kullaniciid;
  final String? adsoyad;
  final String? urunadi;
  final double? tutar;
  final String? faturano;
  final String? alimtarihi;
  final String? aciklama;

  const HariciAlimModel({
    required this.id,
    this.kullaniciid,
    this.adsoyad,
    this.urunadi,
    this.tutar,
    this.faturano,
    this.alimtarihi,
    this.aciklama,
  });

  factory HariciAlimModel.fromJson(Map<String, dynamic> json) {
    return HariciAlimModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      kullaniciid: json['kullaniciid'] != null
          ? int.tryParse(json['kullaniciid'].toString())
          : null,
      adsoyad: json['adsoyad'] as String?,
      urunadi: json['urunadi'] as String?,
      tutar: json['tutar'] != null
          ? double.tryParse(json['tutar'].toString())
          : null,
      faturano: json['faturano'] as String?,
      alimtarihi: json['alimtarihi'] as String?,
      aciklama: json['aciklama'] as String?,
    );
  }
}
