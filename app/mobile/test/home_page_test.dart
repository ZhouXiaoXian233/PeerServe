import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/app_session.dart';
import 'package:peerserve/ui/home_page.dart';
import 'package:peerserve/ui/identity_page.dart';
import 'package:peerserve/ui/requests_page.dart';

Future<AppSession> pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final session = AppSession();
  addTearDown(session.dispose);
  await session.ensureIdentity();

  await tester.pumpWidget(
    AppScope(
      session: session,
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

void main() {
  testWidgets('首页只保留主操作与身份入口', (tester) async {
    await pumpHome(tester);

    expect(find.byKey(HomePage.publishButtonKey), findsOneWidget);
    expect(find.byKey(HomePage.browseButtonKey), findsOneWidget);
    expect(find.byKey(HomePage.identityTileKey), findsOneWidget);
    expect(find.text('功能清单'), findsNothing);
    expect(find.text('开发路线'), findsNothing);
    expect(find.textContaining('内存演示'), findsOneWidget);
  });

  testWidgets('发布需求：填表、签名、回到列表并显示验签状态', (tester) async {
    final session = await pumpHome(tester);

    await tester.tap(find.byKey(HomePage.publishButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RequestsPage.titleFieldKey), findsOneWidget);
    await tester.enterText(find.byKey(RequestsPage.titleFieldKey), '从图书馆带一本书');
    await tester.tap(find.byKey(RequestsPage.submitButtonKey));
    await tester.pumpAndSettle();

    expect(session.requests.length, 1);
    expect(session.requests.single.request.title, '从图书馆带一本书');
    expect(find.text('从图书馆带一本书'), findsOneWidget);
    expect(find.text('签名已在本机验证'), findsOneWidget);
  });

  testWidgets('身份页默认隐藏技术细节，开发者详情可运行篡改测试', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomePage.identityTileKey));
    await tester.pumpAndSettle();

    expect(find.text('本机身份'), findsOneWidget);
    expect(find.byKey(IdentityPage.statusChipKey), findsOneWidget);
    expect(find.text('Ed25519 公钥（hex）'), findsNothing);

    await tester.tap(find.text('开发者详情'));
    await tester.pumpAndSettle();

    expect(find.text('Ed25519 公钥（hex）'), findsOneWidget);
    await tester.ensureVisible(find.byKey(IdentityPage.tamperButtonKey));
    await tester.tap(find.byKey(IdentityPage.tamperButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('篡改后验签失败（符合预期）'), findsOneWidget);
  });

  testWidgets('查看本机需求：空状态提示清晰', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomePage.browseButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RequestsPage.emptyStateKey), findsOneWidget);
    expect(find.text('还没有需求'), findsOneWidget);
    expect(find.text('发布第一条需求'), findsOneWidget);
  });
}
