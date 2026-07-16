import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? '';

  // ── Kimlik Doğrulama ──
  static const String girisYap = 'girisYap';

  // ── Ürün (Katalog) ──
  static const String urunListele = 'urunListele';
  static const String urunEkle = 'urunEkle';
  static const String urunGuncelle = 'urunGuncelle';
  static const String urunSil = 'urunSil';

  // ── Cihaz (Fiziksel Birim) ──
  static const String cihazEkle = 'cihazEkle';
  static const String cihazListele = 'cihazListele';
  static const String cihazGuncelle = 'cihazGuncelle';
  static const String cihazSil = 'cihazSil';

  // ── Arıza ──
  static const String arizaAc = 'arizaAc';
  static const String arizaKapat = 'arizaKapat';
  static const String arizaListele = 'arizaListele';
  static const String arizaGuncelle = 'arizaGuncelle';
  static const String arizaSil = 'arizaSil';

  // ── Sevkiyat ──
  static const String sevkiyatEkle = 'sevkiyatEkle';
  static const String sevkiyatGuncelle = 'sevkiyatGuncelle';
  static const String sevkiyatDurumGuncelle = 'sevkiyatDurumGuncelle';
  static const String sevkiyatSil = 'sevkiyatSil';
  static const String sevkiyatListele = 'sevkiyatListele';

  // ── Masraf ──
  static const String masrafEkle = 'masrafEkle';
  static const String masrafListele = 'masrafListele';

  // ── Montaj ──
  static const String montajYap = 'montajYap';
  static const String montajSok = 'montajSok';
  static const String montajListele = 'montajListele';
  static const String montajGuncelle = 'montajGuncelle';

  // ── Stok Hareket ──
  static const String stokHareketEkle = 'stokHareketEkle';
  static const String stokHareketListele = 'stokHareketListele';

  // ── Harici Alım ──
  static const String haricalimEkle = 'haricalimEkle';
  static const String haricalimListele = 'haricalimListele';
  static const String haricalimGuncelle = 'haricalimGuncelle';
  static const String haricalimSil = 'haricalimSil';

  // ── Seyahat ──
  static const String seyahatEkle = 'seyahatEkle';
  static const String seyahatListele = 'seyahatListele';
  static const String seyahatGuncelle = 'seyahatGuncelle';
  static const String seyahatSil = 'seyahatSil';

  // ── İşlem Log ──
  static const String islemLogListele = 'islemlogListele';

  // ── Kullanıcı ──
  static const String kullaniciListele = 'kullaniciListele';
}
