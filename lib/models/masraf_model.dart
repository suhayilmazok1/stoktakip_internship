/// Masraf kayıt modeli.
class MasrafModel {
  final int id;
  final int? arizaid;
  final String? ad;
  final int? miktar;
  final double? birimfiyat;
  final double? tutar;
  final int? kullaniciid;
  final String? kgt;

  const MasrafModel({
    required this.id,
    this.arizaid,
    this.ad,
    this.miktar,
    this.birimfiyat,
    this.tutar,
    this.kullaniciid,
    this.kgt,
  });

  factory MasrafModel.fromJson(Map<String, dynamic> json) {
    return MasrafModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      arizaid: json['arizaid'] is int ? json['arizaid'] as int : null,
      ad: json['ad'] as String?,
      miktar: json['miktar'] is int ? json['miktar'] as int : null,
      birimfiyat: json['birimfiyat'] != null
          ? double.tryParse(json['birimfiyat'].toString())
          : null,
      tutar: json['tutar'] != null
          ? double.tryParse(json['tutar'].toString())
          : null,
      kullaniciid: json['kullaniciid'] is int
          ? json['kullaniciid'] as int
          : null,
      kgt: json['kgt'] as String?,
    );
  }
}
