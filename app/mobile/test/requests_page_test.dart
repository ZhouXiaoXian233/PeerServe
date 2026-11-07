import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/app_session.dart';
import 'package:peerserve/ui/requests_page.dart';

void main() {
  testWidgets('启动后显示明确标记的示例需求', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final session = AppSession();
    addTearDown(session.dispose);
    await session.bootstrap();

    await tester.pumpWidget(
      AppScope(
        session: session,
        child: const MaterialApp(home: RequestsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(session.requests.where((item) => item.isSample).length, 4);
    expect(find.text('帮忙取一份快递'), findsOneWidget);
    expect(find.text('示例'), findsWidgets);
    expect(find.textContaining('含 4 条示例数据'), findsOneWidget);
  });

  testWidgets('有示例数据时仍可发布本机需求', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final session = AppSession();
    addTearDown(session.dispose);
    await session.bootstrap();

    await tester.pumpWidget(
      AppScope(
        session: session,
        child: const MaterialApp(home: RequestsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(RequestsPage.publishButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(RequestsPage.titleFieldKey), '我的新需求');
    await tester.tap(find.byKey(RequestsPage.submitButtonKey));
    await tester.pumpAndSettle();

    expect(session.requests.first.request.title, '我的新需求');
    expect(session.requests.first.isSample, isFalse);
    expect(find.text('我的新需求'), findsOneWidget);
  });
}
