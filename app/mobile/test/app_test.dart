import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/app.dart';

void main() {
  testWidgets('应用可以启动并渲染首页', (tester) async {
    await tester.pumpWidget(const PeerServeApp());
    await tester.pumpAndSettle();

    expect(find.text('信约阁'), findsOneWidget);
    expect(find.text('PeerServe'), findsOneWidget);
  });

  testWidgets('首页明确标注当前处于 Phase 0.2', (tester) async {
    await tester.pumpWidget(const PeerServeApp());
    await tester.pumpAndSettle();

    expect(find.text('Phase 0.2'), findsWidgets);
    expect(find.text('协议 · 身份 · 公告板'), findsOneWidget);
  });
}
