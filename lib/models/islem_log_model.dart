/// İşlem Log kayıt modeli.
import 'dart:convert';

class IslemLogModel {
  final int id;
  final String tablo;
  final int kayitid;
  final String islem;
  final int kullaniciid;
  final String? adsoyad;
  final Map<String, dynamic>? detay;
  final String? kgt;

  const IslemLogModel({
    required this.id,
    required this.tablo,
    required this.kayitid,
    required this.islem,
    required this.kullaniciid,
    this.adsoyad,
    this.detay,
    this.kgt,
  });

  factory IslemLogModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedDetay;
    if (json['detay'] != null) {
      if (json['detay'] is String) {
        try {
          parsedDetay = jsonDecode(json['detay'] as String) as Map<String, dynamic>;
        } catch (_) {}
      } else if (json['detay'] is Map) {
        parsedDetay = Map<String, dynamic>.from(json['detay'] as Map);
      }
    }

    return IslemLogModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      tablo: json['tablo'] as String,
      kayitid: json['kayitid'] is int ? json['kayitid'] as int : int.parse(json['kayitid'].toString()),
      islem: json['islem'] as String,
      kullaniciid: json['kullaniciid'] is int ? json['kullaniciid'] as int : int.parse(json['kullaniciid'].toString()),
      adsoyad: json['adsoyad'] as String?,
      detay: parsedDetay,
      kgt: json['kgt'] as String?,
    );
  }
}
