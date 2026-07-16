import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://ktprezervasyon.yordam.tr/webservis/stoktakip.php?dIstekTuru=islemLogListele&kullaniciadi=admin&sifre=123456');
  final response = await http.get(url);
  print(response.body);
}
