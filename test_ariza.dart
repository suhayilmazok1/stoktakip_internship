import 'package:stok_takip_ai/services/api_service.dart';

void main() async {
  try {
    final list = await ApiService.instance.arizaListele(arizadurumu: 1);
    print(list.length);
  } catch (e) {
    print(e);
  }
}
