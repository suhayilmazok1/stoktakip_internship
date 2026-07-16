import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse("http://195.175.249.231:8080/stok_takip/api/api.php?action=urunListele"));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  final Map<String, dynamic> data = json.decode(responseBody);
  final List<dynamic> urunler = data['data'];
  
  for (var u in urunler) {
    if (u['ad'].toString().toLowerCase().contains('kiosk')) {
      print('--- URUN ---');
      print('id: ${u['id']}');
      print('ad: ${u['ad']}');
      print('marka: ${u['marka']}');
      print('kategori: ${u['kategori']}');
      print('aciklama: ${u['aciklama']}');
    }
  }
}
