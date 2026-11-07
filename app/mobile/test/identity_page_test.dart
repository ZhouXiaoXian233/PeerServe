import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/ui/identity_page.dart';

void main() {
  Future<void> pumpIdentityPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: IdentityPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('生成内存身份并显示签名有效', (tester) async {
    await pumpIdentityPage(tester);

    expect(find.byKey(IdentityPage.statusChipKey), findsOneWidget);
    expect(find.text('签名有效'), findsOneWidget);
    expect(find.textContaining('did:key:'), findsWidgets);
    expect(find.textContaining('Ed25519 公钥'), findsOneWidget);
  });

  testWidgets('篡改 payload 后验签失败', (tester) async {
    await pumpIdentityPage(tester);

    await tester.ensureVisible(find.byKey(IdentityPage.tamperButtonKey));
    await tester.tap(find.byKey(IdentityPage.tamperButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(IdentityPage.tamperedStatusKey), findsOneWidget);
    expect(find.text('篡改后验签失败（符合预期）'), findsOneWidget);
  });
}
