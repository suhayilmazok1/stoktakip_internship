/// Arıza kayıt modeli.
class ArizaModel {
  final int id;
  final int cihazid;
  final String? serino;
  final String? urunad;
  final int? alankullaniciid;
  final int? teknisyenid;
  final int arizadurumu; // 1=açık, 2=kapalı
  final String? aciklama;
  final String? tamamlanmatarihi;
  final String? kgt;
  final String? ne;
  final String? nerede;
  final String? nezaman;
  final String? sorun;

  const ArizaModel({
    required this.id,
    required this.cihazid,
    this.serino,
    this.urunad,
    this.alankullaniciid,
    this.teknisyenid,
    required this.arizadurumu,
    this.aciklama,
    this.tamamlanmatarihi,
    this.kgt,
    this.ne,
    this.nerede,
    this.nezaman,
    this.sorun,
  });

  factory ArizaModel.fromJson(Map<String, dynamic> json) {
    return ArizaModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      cihazid: json['cihazid'] is int
          ? json['cihazid'] as int
          : int.parse(json['cihazid'].toString()),
      serino: json['serino'] as String?,
      urunad: json['urunad'] as String?,
      alankullaniciid: json['alankullaniciid'] != null
          ? int.tryParse(json['alankullaniciid'].toString())
          : null,
      teknisyenid: json['teknisyenid'] != null
          ? int.tryParse(json['teknisyenid'].toString())
          : null,
      arizadurumu: json['arizadurumu'] is int
          ? json['arizadurumu'] as int
          : int.tryParse(json['arizadurumu'].toString()) ?? 1,
      aciklama: json['aciklama'] as String?,
      tamamlanmatarihi: json['tamamlanmatarihi'] as String?,
      kgt: json['kgt'] as String?,
      ne: json['ne'] as String?,
      nerede: json['nerede'] as String?,
      nezaman: json['nezaman'] as String?,
      sorun: json['sorun'] as String?,
    );
  }

  bool get isAcik => arizadurumu == 1;
  String get durumAdi => isAcik ? 'Açık' : 'Kapalı';

  String get displaySeriNo {
    if (serino != null && serino!.trim().isNotEmpty) {
      return serino!;
    }
    return cihazid.toString();
  }
}
