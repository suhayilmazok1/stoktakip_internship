/// Montaj kayıt modeli.
/// Bir bileşen cihazın bir ana cihaza monte edilmesi.
class MontajModel {
  final int id;
  final int anacihazid;
  final String? anaserino;
  final String? anaurunad;
  final int bilesencihazid;
  final String? bilesenserino;
  final String? bilesenurunad;
  final String? aciklama;
  final String? sokulmetarihi;
  final String? kgt;

  const MontajModel({
    required this.id,
    required this.anacihazid,
    this.anaserino,
    this.anaurunad,
    required this.bilesencihazid,
    this.bilesenserino,
    this.bilesenurunad,
    this.aciklama,
    this.sokulmetarihi,
    this.kgt,
  });

  factory MontajModel.fromJson(Map<String, dynamic> json) {
    return MontajModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      anacihazid: json['anacihazid'] is int
          ? json['anacihazid'] as int
          : int.parse(json['anacihazid'].toString()),
      anaserino: json['anaserino'] as String?,
      anaurunad: json['anaurunad'] as String?,
      bilesencihazid: json['bilesencihazid'] is int
          ? json['bilesencihazid'] as int
          : int.parse(json['bilesencihazid'].toString()),
      bilesenserino: json['bilesenserino'] as String?,
      bilesenurunad: json['bilesenurunad'] as String?,
      aciklama: json['aciklama'] as String?,
      sokulmetarihi: json['sokulmetarihi'] as String?,
      kgt: json['kgt'] as String?,
    );
  }

  /// Hâlâ takılı mı?
  bool get isAktif => sokulmetarihi == null;

  String get displayAnaSeriNo {
    if (anaserino != null && anaserino!.trim().isNotEmpty) {
      return anaserino!;
    }
    return anacihazid.toString();
  }

  String get displayBilesenSeriNo {
    if (bilesenserino != null && bilesenserino!.trim().isNotEmpty) {
      return bilesenserino!;
    }
    return bilesencihazid.toString();
  }
}
