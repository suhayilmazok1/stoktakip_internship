class UserModel {
  final int id;
  final String adsoyad;
  final String kullanici;
  final String yetki;

  const UserModel({
    required this.id,
    required this.adsoyad,
    required this.kullanici,
    required this.yetki,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      adsoyad: json['adsoyad'] as String,
      kullanici: json['kullanici'] as String,
      yetki: json['yetki'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adsoyad': adsoyad,
      'kullanici': kullanici,
      'yetki': yetki,
    };
  }
}
