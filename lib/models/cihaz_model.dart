/// Fiziksel birim (cihaz) modeli.
/// Her cihaz bir ürüne bağlıdır (urunid).
class CihazModel {
  final int id;
  final int urunid;
  final String? serino;
  final String? alimtarihi;
  final String? lokasyon;
  final int
      cihazdurumu; // 1=müsait, 2=tamirde, 3=satıldı, 4=hurda, 5=kayıp, 6=montede
  final String? ureticigarantibitis;
  final String? bizimgarantibitis;
  final String? ureticibarkod;
  final String? bizimbarkod;

  const CihazModel({
    required this.id,
    required this.urunid,
    this.serino,
    this.alimtarihi,
    this.lokasyon,
    required this.cihazdurumu,
    this.ureticigarantibitis,
    this.bizimgarantibitis,
    this.ureticibarkod,
    this.bizimbarkod,
  });

  factory CihazModel.fromJson(Map<String, dynamic> json) {
    return CihazModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      urunid: json['urunid'] is int
          ? json['urunid'] as int
          : int.parse(json['urunid'].toString()),
      serino: json['serino'] as String?,
      alimtarihi: json['alimtarihi'] as String?,
      lokasyon: json['lokasyon'] as String?,
      cihazdurumu: json['cihazdurumu'] is int
          ? json['cihazdurumu'] as int
          : int.tryParse(json['cihazdurumu'].toString()) ?? 1,
      ureticigarantibitis: json['ureticigarantibitis'] as String?,
      bizimgarantibitis: json['bizimgarantibitis'] as String?,
      ureticibarkod: json['ureticibarkod'] as String?,
      bizimbarkod: json['bizimbarkod'] as String?,
    );
  }

  /// Cihaz durumu açıklaması
  String get durumAdi {
    switch (cihazdurumu) {
      case 1:
        return 'Müsait';
      case 2:
        return 'Tamirde';
      case 3:
        return 'Satıldı';
      case 4:
        return 'Hurda';
      case 5:
        return 'Kayıp';
      case 6:
        return 'Montede Kullanıldı';
      default:
        return 'Bilinmiyor';
    }
  }

  bool get isMusait => cihazdurumu == 1;

  bool get hasSeriNo => serino != null && serino!.trim().isNotEmpty;

  /// Seri no varsa kendi değerini, yoksa ID'yi döner
  String get displaySeriNo {
    if (hasSeriNo) {
      return serino!;
    }
    return id.toString();
  }

  /// UI'da göstermek için tam metin: Seri No varsa "Seri No: XXX", yoksa "ID: YYY"
  String get displayIdentifier {
    if (hasSeriNo) {
      return 'Seri No: $serino';
    }
    return 'ID: $id';
  }
}
