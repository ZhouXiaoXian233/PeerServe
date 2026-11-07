import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/app.dart';

void main() {
  testWidgets('应用可以启动并渲染首页骨架', (tester) async {
    await tester.pumpWidget(const PeerServeApp());
    await tester.pumpAndSettle();

    expect(find.text('信约阁'), findsOneWidget);
    expect(find.text('PeerServe'), findsOneWidget);
  });

  testWidgets('首页明确标注当前处于 Phase 0.1', (tester) async {
    await tester.pumpWidget(const PeerServeApp());
    await tester.pumpAndSettle();

    expect(find.text('Phase 0.1'), findsOneWidget);
    expect(find.text('工程骨架'), findsOneWidget);
  });
}
