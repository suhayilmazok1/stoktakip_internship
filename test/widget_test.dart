import 'package:flutter_test/flutter_test.dart';

import 'package:stok_takip/main.dart';

void main() {
  testWidgets('App should render LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const StokTakipApp());

    // Login ekranında "Giriş Yap" yazısı bulunmalı
    expect(find.text('Giriş Yap'), findsWidgets);
  });
}
