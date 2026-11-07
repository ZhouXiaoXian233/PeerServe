import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/app_session.dart';
import 'package:peerserve/ui/identity_page.dart';

Future<AppSession> pumpIdentity(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final session = AppSession();
  addTearDown(session.dispose);
  await session.ensureIdentity();

  await tester.pumpWidget(
    AppScope(
      session: session,
      child: const MaterialApp(home: IdentityPage()),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

void main() {
  testWidgets('身份页显示状态，技术细节默认隐藏', (tester) async {
    await pumpIdentity(tester);

    expect(find.byKey(IdentityPage.statusChipKey), findsOneWidget);
    expect(find.text('身份已就绪'), findsOneWidget);
    expect(find.textContaining('did:key:'), findsOneWidget);
    expect(find.text('Ed25519 公钥（hex）'), findsNothing);
  });

  testWidgets('开发者详情中的篡改验签测试失败', (tester) async {
    await pumpIdentity(tester);

    await tester.tap(find.text('开发者详情'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(IdentityPage.tamperButtonKey));
    await tester.tap(find.byKey(IdentityPage.tamperButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(IdentityPage.tamperedStatusKey), findsOneWidget);
    expect(find.text('篡改后验签失败（符合预期）'), findsOneWidget);
  });
}
