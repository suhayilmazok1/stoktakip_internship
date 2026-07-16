import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/urun_model.dart';
import '../models/cihaz_model.dart';
import '../models/ariza_model.dart';
import '../models/sevkiyat_model.dart';
import '../models/masraf_model.dart';
import '../models/haricalim_model.dart';
import '../models/seyahat_model.dart';
import '../models/montaj_model.dart';
import '../models/stok_hareket_model.dart';
import '../models/islem_log_model.dart';
import 'auth_manager.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ─── Ortak POST metodu ───────────────────────────────────────────
  Future<Map<String, dynamic>> _post({
    required String dIstekTuru,
    String? kullaniciadi,
    String? sifre,
    Map<String, String>? extraParams,
  }) async {
    final user = kullaniciadi ?? AuthManager.instance.kullaniciadi;
    final pass = sifre ?? AuthManager.instance.sifre;

    if (user == null || pass == null) {
      throw const ApiException('Oturum bilgileri bulunamadı.');
    }

    final body = <String, String>{
      'dIstekTuru': dIstekTuru,
      'kullaniciadi': user,
      'sifre': pass,
      ...?extraParams,
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl),
        body: body,
      );

      if (response.statusCode != 200) {
        throw ApiException('Sunucu hatası: ${response.body}');
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return decoded;
    } on FormatException {
      throw const ApiException('Sunucudan geçersiz yanıt alındı.');
    } on http.ClientException {
      throw const ApiException(
        'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
      );
    }
  }

  /// Ortak liste çekme yardımcısı
  Future<List<T>> _fetchList<T>({
    required String dIstekTuru,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, String>? extraParams,
    String? errorMessage,
  }) async {
    final result = await _post(
      dIstekTuru: dIstekTuru,
      extraParams: extraParams,
    );

    if (result['success'] == true) {
      final data = result['data'];

      if (data == null || data is bool) {
        return [];
      }

      if (data is List) {
        return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }

      // If it's a map (e.g. empty object {} from PHP)
      if (data is Map && data.isEmpty) {
        return [];
      }

      return [];
    }

    throw ApiException(
      result['message'] as String? ?? errorMessage ?? 'Veri alınamadı.',
    );
  }

  /// Ortak ekleme/güncelleme/silme yardımcısı
  Future<Map<String, dynamic>> _mutate({
    required String dIstekTuru,
    required Map<String, String> params,
    String? errorMessage,
  }) async {
    final result = await _post(dIstekTuru: dIstekTuru, extraParams: params);

    if (result['success'] != true) {
      throw ApiException(
        result['message'] as String? ?? errorMessage ?? 'İşlem başarısız.',
      );
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════
  // GİRİŞ YAP
  // ═══════════════════════════════════════════════════════════════════

  Future<UserModel> girisYap({
    required String kullaniciadi,
    required String sifre,
  }) async {
    final result = await _post(
      dIstekTuru: ApiConstants.girisYap,
      kullaniciadi: kullaniciadi,
      sifre: sifre,
    );

    if (result['success'] == true && result['data'] != null) {
      return UserModel.fromJson(result['data'] as Map<String, dynamic>);
    }

    throw ApiException(result['message'] as String? ?? 'Giriş başarısız.');
  }

  Future<List<UserModel>> kullaniciListele() async {
    return _fetchList(
      dIstekTuru: ApiConstants.kullaniciListele,
      fromJson: UserModel.fromJson,
      errorMessage: 'Kullanıcılar alınamadı.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ÜRÜN (KATALOG)
  // ═══════════════════════════════════════════════════════════════════

  Future<List<UrunModel>> urunListele({String? kategori, String? arama}) async {
    final extra = <String, String>{};
    if (kategori != null && kategori.isNotEmpty) extra['kategori'] = kategori;
    if (arama != null && arama.isNotEmpty) extra['arama'] = arama;

    return _fetchList(
      dIstekTuru: ApiConstants.urunListele,
      fromJson: UrunModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Ürün listesi alınamadı.',
    );
  }

  Future<void> urunEkle({
    required String ad,
    String? marka,
    String? kategori,
    String? renk,
    String? aciklama,
  }) async {
    final extra = <String, String>{'ad': ad};
    if (marka != null && marka.isNotEmpty) extra['marka'] = marka;
    if (kategori != null && kategori.isNotEmpty) extra['kategori'] = kategori;
    if (renk != null && renk.isNotEmpty) extra['renk'] = renk;
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;

    await _mutate(
      dIstekTuru: ApiConstants.urunEkle,
      params: extra,
      errorMessage: 'Ürün eklenemedi.',
    );
  }

  Future<void> urunGuncelle({
    required int id,
    String? ad,
    String? marka,
    String? kategori,
    String? renk,
    String? aciklama,
  }) async {
    final extra = <String, String>{'id': id.toString()};
    if (ad != null) extra['ad'] = ad;
    if (marka != null) extra['marka'] = marka;
    if (kategori != null) extra['kategori'] = kategori;
    if (renk != null) extra['renk'] = renk;
    if (aciklama != null) extra['aciklama'] = aciklama;

    await _mutate(
      dIstekTuru: ApiConstants.urunGuncelle,
      params: extra,
      errorMessage: 'Ürün güncellenemedi.',
    );
  }

  Future<void> urunSil({required int id}) async {
    await _mutate(
      dIstekTuru: ApiConstants.urunSil,
      params: {'id': id.toString()},
      errorMessage: 'Ürün silinemedi.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CİHAZ (FİZİKSEL BİRİM)
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> cihazEkle({
    required int urunid,
    String? serino,
    int? miktar,
    String? lokasyon,
    String? alimtarihi,
    String? ureticigarantibitis,
    String? bizimgarantibitis,
    String? ureticibarkod,
    String? bizimbarkod,
  }) async {
    final extra = <String, String>{'urunid': urunid.toString()};
    if (serino != null && serino.isNotEmpty) extra['serino'] = serino;
    if (miktar != null && miktar > 0) extra['miktar'] = miktar.toString();
    if (lokasyon != null && lokasyon.isNotEmpty) extra['lokasyon'] = lokasyon;
    if (alimtarihi != null && alimtarihi.isNotEmpty)
      extra['alimtarihi'] = alimtarihi;
    if (ureticigarantibitis != null && ureticigarantibitis.isNotEmpty) {
      extra['ureticigarantibitis'] = ureticigarantibitis;
    }
    if (bizimgarantibitis != null && bizimgarantibitis.isNotEmpty) {
      extra['bizimgarantibitis'] = bizimgarantibitis;
    }
    if (ureticibarkod != null && ureticibarkod.isNotEmpty) {
      extra['ureticibarkod'] = ureticibarkod;
    }
    if (bizimbarkod != null && bizimbarkod.isNotEmpty) {
      extra['bizimbarkod'] = bizimbarkod;
    }

    return _mutate(
      dIstekTuru: ApiConstants.cihazEkle,
      params: extra,
      errorMessage: 'Cihaz eklenemedi.',
    );
  }

  Future<List<CihazModel>> cihazListele({int? urunid}) async {
    final extra = <String, String>{};
    if (urunid != null) extra['urunid'] = urunid.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.cihazListele,
      fromJson: CihazModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Cihaz listesi alınamadı.',
    );
  }

  Future<void> cihazGuncelle({
    required int id,
    String? serino,
    String? lokasyon,
    String? alimtarihi,
    int? cihazdurumu,
    String? ureticigarantibitis,
    String? bizimgarantibitis,
    String? ureticibarkod,
    String? bizimbarkod,
  }) async {
    final extra = <String, String>{'id': id.toString()};
    if (serino != null) extra['serino'] = serino;
    if (lokasyon != null) extra['lokasyon'] = lokasyon;
    if (alimtarihi != null) extra['alimtarihi'] = alimtarihi;
    if (cihazdurumu != null) extra['cihazdurumu'] = cihazdurumu.toString();
    if (ureticigarantibitis != null)
      extra['ureticigarantibitis'] = ureticigarantibitis;
    if (bizimgarantibitis != null)
      extra['bizimgarantibitis'] = bizimgarantibitis;
    if (ureticibarkod != null) extra['ureticibarkod'] = ureticibarkod;
    if (bizimbarkod != null) extra['bizimbarkod'] = bizimbarkod;

    await _mutate(
      dIstekTuru: ApiConstants.cihazGuncelle,
      params: extra,
      errorMessage: 'Cihaz güncellenemedi.',
    );
  }

  Future<void> cihazSil({required int id}) async {
    await _mutate(
      dIstekTuru: ApiConstants.cihazSil,
      params: {'id': id.toString()},
      errorMessage: 'Cihaz silinemedi.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ARIZA
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> arizaAc({
    required int cihazid,
    int? teknisyenid,
    String? aciklama,
    String? ne,
    String? nerede,
    String? nezaman,
    String? sorun,
  }) async {
    final extra = <String, String>{'cihazid': cihazid.toString()};
    if (teknisyenid != null) extra['teknisyenid'] = teknisyenid.toString();
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;
    if (ne != null && ne.isNotEmpty) extra['ne'] = ne;
    if (nerede != null && nerede.isNotEmpty) extra['nerede'] = nerede;
    if (nezaman != null && nezaman.isNotEmpty) extra['nezaman'] = nezaman;
    if (sorun != null && sorun.isNotEmpty) extra['sorun'] = sorun;

    return _mutate(
      dIstekTuru: ApiConstants.arizaAc,
      params: extra,
      errorMessage: 'Arıza kaydı açılamadı.',
    );
  }

  Future<void> arizaKapat({required int id, int? yenicihazdurumu}) async {
    final extra = <String, String>{'id': id.toString()};
    if (yenicihazdurumu != null)
      extra['yenicihazdurumu'] = yenicihazdurumu.toString();

    await _mutate(
      dIstekTuru: ApiConstants.arizaKapat,
      params: extra,
      errorMessage: 'Arıza kapatılamadı.',
    );
  }

  Future<List<ArizaModel>> arizaListele({
    int? cihazid,
    int? arizadurumu,
  }) async {
    final extra = <String, String>{};
    if (cihazid != null) extra['cihazid'] = cihazid.toString();
    if (arizadurumu != null) extra['arizadurumu'] = arizadurumu.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.arizaListele,
      fromJson: ArizaModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Arıza listesi alınamadı.',
    );
  }

  Future<void> arizaGuncelle({
    required int id,
    int? cihazid,
    int? teknisyenid,
    String? aciklama,
    int? arizadurumu,
    String? ne,
    String? nerede,
    String? nezaman,
    String? sorun,
  }) async {
    final extra = <String, String>{'id': id.toString()};
    if (cihazid != null) extra['cihazid'] = cihazid.toString();
    if (teknisyenid != null) extra['teknisyenid'] = teknisyenid.toString();
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;
    if (arizadurumu != null) extra['arizadurumu'] = arizadurumu.toString();
    if (ne != null && ne.isNotEmpty) extra['ne'] = ne;
    if (nerede != null && nerede.isNotEmpty) extra['nerede'] = nerede;
    if (nezaman != null && nezaman.isNotEmpty) extra['nezaman'] = nezaman;
    if (sorun != null && sorun.isNotEmpty) extra['sorun'] = sorun;

    await _mutate(
      dIstekTuru: ApiConstants.arizaGuncelle,
      params: extra,
      errorMessage: 'Arıza kaydı güncellenemedi.',
    );
  }

  Future<void> arizaSil(int id) async {
    await _mutate(
      dIstekTuru: ApiConstants.arizaSil,
      params: {'id': id.toString()},
      errorMessage: 'Arıza silinemedi.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEVKİYAT
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> sevkiyatEkle({
    int? cihazid,
    int? arizaid,
    String? takipno,
    String? kargofirmasi,
    double? ucret,
    int? yon,
    String? aciklama,
  }) async {
    final extra = <String, String>{};
    if (cihazid != null) extra['cihazid'] = cihazid.toString();
    if (arizaid != null) extra['arizaid'] = arizaid.toString();
    if (takipno != null && takipno.isNotEmpty) extra['takipno'] = takipno;
    if (kargofirmasi != null && kargofirmasi.isNotEmpty)
      extra['kargofirmasi'] = kargofirmasi;
    if (ucret != null) extra['ucret'] = ucret.toString();
    if (yon != null) extra['yon'] = yon.toString();
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;

    return _mutate(
      dIstekTuru: ApiConstants.sevkiyatEkle,
      params: extra,
      errorMessage: 'Sevkiyat kaydı oluşturulamadı.',
    );
  }

  Future<void> sevkiyatDurumGuncelle({
    required int id,
    required int sevkiyatdurumu,
    String? takipno,
  }) async {
    final extra = <String, String>{
      'id': id.toString(),
      'sevkiyatdurumu': sevkiyatdurumu.toString(),
    };
    if (takipno != null && takipno.isNotEmpty) extra['takipno'] = takipno;

    await _mutate(
      dIstekTuru: ApiConstants.sevkiyatDurumGuncelle,
      params: extra,
      errorMessage: 'Sevkiyat durumu güncellenemedi.',
    );
  }

  Future<void> sevkiyatGuncelle({
    required int id,
    int? cihazid,
    int? arizaid,
    String? takipno,
    String? kargofirmasi,
    double? ucret,
    int? sevkiyatdurumu,
    int? yon,
  }) async {
    final extra = <String, String>{'id': id.toString()};
    if (cihazid != null) extra['cihazid'] = cihazid.toString();
    if (arizaid != null) extra['arizaid'] = arizaid.toString();
    if (takipno != null && takipno.isNotEmpty) extra['takipno'] = takipno;
    if (kargofirmasi != null && kargofirmasi.isNotEmpty)
      extra['kargofirmasi'] = kargofirmasi;
    if (ucret != null) extra['ucret'] = ucret.toString();
    if (sevkiyatdurumu != null)
      extra['sevkiyatdurumu'] = sevkiyatdurumu.toString();
    if (yon != null) extra['yon'] = yon.toString();

    await _mutate(
      dIstekTuru: ApiConstants.sevkiyatGuncelle,
      params: extra,
      errorMessage: 'Sevkiyat kaydı güncellenemedi.',
    );
  }

  Future<void> sevkiyatSil(int id) async {
    await _mutate(
      dIstekTuru: ApiConstants.sevkiyatSil,
      params: {'id': id.toString()},
      errorMessage: 'Sevkiyat silinemedi.',
    );
  }

  Future<List<SevkiyatModel>> sevkiyatListele({
    int? sevkiyatdurumu,
    String? takipno,
    int? cihazid,
  }) async {
    final extra = <String, String>{};
    if (sevkiyatdurumu != null)
      extra['sevkiyatdurumu'] = sevkiyatdurumu.toString();
    if (takipno != null && takipno.isNotEmpty) extra['takipno'] = takipno;
    if (cihazid != null) extra['cihazid'] = cihazid.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.sevkiyatListele,
      fromJson: SevkiyatModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Sevkiyat listesi alınamadı.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MASRAF
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> masrafEkle({
    int? arizaid,
    String? ad,
    int? miktar,
    double? birimfiyat,
    double? tutar,
  }) async {
    final extra = <String, String>{};
    if (arizaid != null) extra['arizaid'] = arizaid.toString();
    if (ad != null && ad.isNotEmpty) extra['ad'] = ad;
    if (miktar != null) extra['miktar'] = miktar.toString();
    if (birimfiyat != null) extra['birimfiyat'] = birimfiyat.toString();
    if (tutar != null) extra['tutar'] = tutar.toString();

    return _mutate(
      dIstekTuru: ApiConstants.masrafEkle,
      params: extra,
      errorMessage: 'Masraf kaydı eklenemedi.',
    );
  }

  Future<List<MasrafModel>> masrafListele({int? arizaid}) async {
    final extra = <String, String>{};
    if (arizaid != null) extra['arizaid'] = arizaid.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.masrafListele,
      fromJson: MasrafModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Masraf listesi alınamadı.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MONTAJ
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> montajYap({
    required int anacihazid,
    required int bilesencihazid,
    String? aciklama,
  }) async {
    final extra = <String, String>{
      'anacihazid': anacihazid.toString(),
      'bilesencihazid': bilesencihazid.toString(),
    };
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;

    return _mutate(
      dIstekTuru: ApiConstants.montajYap,
      params: extra,
      errorMessage: 'Montaj yapılamadı.',
    );
  }

  Future<void> montajSok({
    required int bilesencihazid,
    int? yenicihazdurumu,
  }) async {
    final extra = <String, String>{'bilesencihazid': bilesencihazid.toString()};
    if (yenicihazdurumu != null)
      extra['yenicihazdurumu'] = yenicihazdurumu.toString();

    await _mutate(
      dIstekTuru: ApiConstants.montajSok,
      params: extra,
      errorMessage: 'Bileşen sökme işlemi başarısız.',
    );
  }

  Future<List<MontajModel>> montajListele({
    int? anacihazid,
    int? bilesencihazid,
    bool gecmisdahil = false,
  }) async {
    final extra = <String, String>{};
    if (anacihazid != null) extra['anacihazid'] = anacihazid.toString();
    if (bilesencihazid != null)
      extra['bilesencihazid'] = bilesencihazid.toString();
    if (gecmisdahil) extra['gecmisdahil'] = '1';

    return _fetchList(
      dIstekTuru: ApiConstants.montajListele,
      fromJson: MontajModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Montaj listesi alınamadı.',
    );
  }

  Future<void> montajGuncelle({
    required int id,
    String? aciklama,
  }) async {
    final extra = <String, String>{'id': id.toString()};
    if (aciklama != null) extra['aciklama'] = aciklama;

    await _mutate(
      dIstekTuru: ApiConstants.montajGuncelle,
      params: extra,
      errorMessage: 'Montaj güncellenemedi.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STOK HAREKET
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> stokHareketEkle({
    required int cihazid,
    required int hareket,
    int? arizaid,
    String? aciklama,
    int? hareketdurumu,
  }) async {
    final extra = <String, String>{
      'cihazid': cihazid.toString(),
      'hareket': hareket.toString(),
    };
    if (arizaid != null) extra['arizaid'] = arizaid.toString();
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;
    if (hareketdurumu != null)
      extra['hareketdurumu'] = hareketdurumu.toString();

    return _mutate(
      dIstekTuru: ApiConstants.stokHareketEkle,
      params: extra,
      errorMessage: 'Stok hareketi kaydedilemedi.',
    );
  }

  Future<List<StokHareketModel>> stokHareketListele({
    int? cihazid,
    int? hareket,
    int? arizaid,
  }) async {
    final extra = <String, String>{};
    if (cihazid != null) extra['cihazid'] = cihazid.toString();
    if (hareket != null) extra['hareket'] = hareket.toString();
    if (arizaid != null) extra['arizaid'] = arizaid.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.stokHareketListele,
      fromJson: StokHareketModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Stok hareket listesi alınamadı.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HARİCİ ALIM
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> haricalimEkle({
    int? kullaniciid,
    String? urunadi,
    double? tutar,
    String? faturano,
    String? alimtarihi,
    String? aciklama,
  }) async {
    final extra = <String, String>{};
    if (kullaniciid != null) extra['kullaniciid'] = kullaniciid.toString();
    if (urunadi != null && urunadi.isNotEmpty) extra['urunadi'] = urunadi;
    if (tutar != null) extra['tutar'] = tutar.toString();
    if (faturano != null && faturano.isNotEmpty) extra['faturano'] = faturano;
    if (alimtarihi != null && alimtarihi.isNotEmpty)
      extra['alimtarihi'] = alimtarihi;
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;

    return _mutate(
      dIstekTuru: ApiConstants.haricalimEkle,
      params: extra,
      errorMessage: 'Harici alım eklenemedi.',
    );
  }

  Future<List<HariciAlimModel>> haricalimListele({int? kullaniciid}) async {
    final extra = <String, String>{};
    if (kullaniciid != null) extra['kullaniciid'] = kullaniciid.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.haricalimListele,
      fromJson: HariciAlimModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Harici alım listesi alınamadı.',
    );
  }

  Future<Map<String, dynamic>> haricalimGuncelle({
    required int id,
    int? kullaniciid,
    String? urunadi,
    double? tutar,
    String? faturano,
    String? alimtarihi,
    String? aciklama,
  }) async {
    final extra = <String, String>{'id': id.toString()};
    if (kullaniciid != null) extra['kullaniciid'] = kullaniciid.toString();
    if (urunadi != null && urunadi.isNotEmpty) extra['urunadi'] = urunadi;
    if (tutar != null) extra['tutar'] = tutar.toString();
    if (faturano != null) extra['faturano'] = faturano;
    if (alimtarihi != null) extra['alimtarihi'] = alimtarihi;
    if (aciklama != null) extra['aciklama'] = aciklama;

    return _mutate(
      dIstekTuru: ApiConstants.haricalimGuncelle,
      params: extra,
      errorMessage: 'Harici alım güncellenemedi.',
    );
  }

  Future<Map<String, dynamic>> haricalimSil(int id) async {
    return _mutate(
      dIstekTuru: ApiConstants.haricalimSil,
      params: {'id': id.toString()},
      errorMessage: 'Harici alım silinemedi.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEYAHAT
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> seyahatEkle({
    int? arizaid,
    String? seyahatdetayi,
    String? tarih,
    String? aciklama,
    String? kullanicilar, // virgülle ayrılmış list
    double? tutar,
  }) async {
    final extra = <String, String>{};
    if (arizaid != null) extra['arizaid'] = arizaid.toString();
    if (seyahatdetayi != null && seyahatdetayi.isNotEmpty) {
      extra['seyahatdetayi'] = seyahatdetayi;
    }
    if (tarih != null && tarih.isNotEmpty) extra['tarih'] = tarih;
    if (aciklama != null && aciklama.isNotEmpty) extra['aciklama'] = aciklama;
    if (kullanicilar != null && kullanicilar.isNotEmpty) {
      extra['kullanicilar'] = kullanicilar;
    }
    if (tutar != null) extra['tutar'] = tutar.toString();

    return _mutate(
      dIstekTuru: ApiConstants.seyahatEkle,
      params: extra,
      errorMessage: 'Seyahat eklenemedi.',
    );
  }

  Future<List<SeyahatModel>> seyahatListele({int? arizaid}) async {
    final extra = <String, String>{};
    if (arizaid != null) extra['arizaid'] = arizaid.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.seyahatListele,
      fromJson: SeyahatModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'Seyahat listesi alınamadı.',
    );
  }

  Future<Map<String, dynamic>> seyahatGuncelle({
    required int id,
    int? arizaid,
    String? seyahatdetayi,
    String? tarih,
    String? aciklama,
    String? kullanicilar,
    double? tutar,
  }) async {
    final extra = <String, String>{'id': id.toString()};
    if (arizaid != null) extra['arizaid'] = arizaid.toString();
    if (seyahatdetayi != null) extra['seyahatdetayi'] = seyahatdetayi;
    if (tarih != null) extra['tarih'] = tarih;
    if (aciklama != null) extra['aciklama'] = aciklama;
    if (kullanicilar != null) extra['kullanicilar'] = kullanicilar;
    if (tutar != null) extra['tutar'] = tutar.toString();

    return _mutate(
      dIstekTuru: ApiConstants.seyahatGuncelle,
      params: extra,
      errorMessage: 'Seyahat güncellenemedi.',
    );
  }

  Future<Map<String, dynamic>> seyahatSil(int id) async {
    return _mutate(
      dIstekTuru: ApiConstants.seyahatSil,
      params: {'id': id.toString()},
      errorMessage: 'Seyahat silinemedi.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // İŞLEM LOG
  // ═══════════════════════════════════════════════════════════════════

  Future<List<IslemLogModel>> islemLogListele({
    String? tablo,
    int? kayitid,
  }) async {
    final extra = <String, String>{};
    if (tablo != null) extra['tablo'] = tablo;
    if (kayitid != null) extra['kayitid'] = kayitid.toString();

    return _fetchList(
      dIstekTuru: ApiConstants.islemLogListele,
      fromJson: IslemLogModel.fromJson,
      extraParams: extra.isNotEmpty ? extra : null,
      errorMessage: 'İşlem logları alınamadı.',
    );
  }
}
