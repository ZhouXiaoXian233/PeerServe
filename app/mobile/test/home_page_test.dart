import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/ui/home_page.dart';
import 'package:peerserve/ui/identity_page.dart';
import 'package:peerserve/ui/requests_page.dart';

void main() {
  /// 首页整体是一张可滚动的长列表；测试里把视口调高，
  /// 让"设计边界"这类靠后的内容也被构建出来，否则 ListView 的懒加载会漏掉断言。
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('身份入口可打开真实的内存签名演示', (tester) async {
    await pumpHome(tester);

    final button = tester.widget<FilledButton>(
      find.byKey(HomePage.createIdentityButtonKey),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('身份与签名演示'), findsOneWidget);

    await tester.tap(find.byKey(HomePage.createIdentityButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('本地身份（内存）'), findsOneWidget);
    expect(find.byKey(IdentityPage.statusChipKey), findsOneWidget);
  });

  testWidgets('需求公告板入口可发布并验签本机需求', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomePage.requestsButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('需求公告板（内存）'), findsOneWidget);
    expect(find.text('签名有效'), findsWidgets);

    await tester.ensureVisible(find.byKey(RequestsPage.publishButtonKey));
    await tester.tap(find.byKey(RequestsPage.publishButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('签名有效'), findsWidgets);
  });

  testWidgets('功能清单列出已完成与计划中', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomePage.featuresButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('功能清单'), findsOneWidget);
    expect(find.textContaining('项已完成'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('Request v1 数据模型'), findsOneWidget);
  });

  testWidgets('首页必须声明当前能力的限制说明', (tester) async {
    await pumpHome(tester);

    expect(find.textContaining('不能用于任何真实交易'), findsOneWidget);
  });

  testWidgets('设计边界：不托管资金、评价是意见、争议不等于过错', (tester) async {
    await pumpHome(tester);

    expect(find.textContaining('不托管资金'), findsOneWidget);
    expect(find.textContaining('主观意见'), findsOneWidget);
    expect(find.textContaining('不代表对方有过错'), findsOneWidget);
  });

  testWidgets('开发路线列出后续阶段，说明功能不是"找不到入口"', (tester) async {
    await pumpHome(tester);

    expect(find.text('开发路线'), findsOneWidget);
    expect(find.text('Phase 1'), findsWidgets);
    expect(find.text('Phase 2'), findsOneWidget);
  });
}
