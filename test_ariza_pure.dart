import 'dart:convert';
import 'dart:io';

void main() async {
  var url = Uri.parse('https://ktprezervasyon.yordam.tr/webservis/stoktakip.php');
  var client = HttpClient();
  
  try {
    var request = await client.postUrl(url);
    request.headers.contentType = ContentType("application", "x-www-form-urlencoded", charset: "utf-8");
    
    var body = "dIstekTuru=arizaListele&kullaniciadi=admin&sifre=admin123&arizadurumu=1";
    request.write(body);
    
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    print(responseBody);
  } finally {
    client.close();
  }
}
