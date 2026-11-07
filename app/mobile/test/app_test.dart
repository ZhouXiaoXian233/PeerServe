import 'package:flutter_test/flutter_test.dart';
import 'package:peerserve/app.dart';

void main() {
  testWidgets('应用可以启动并显示清晰的主操作', (tester) async {
    await tester.pumpWidget(const PeerServeApp());
    await tester.pumpAndSettle();

    expect(find.text('信约阁'), findsOneWidget);
    expect(find.text('今天，帮个忙？'), findsOneWidget);
    expect(find.text('发布需求'), findsOneWidget);
    expect(find.textContaining('浏览'), findsOneWidget);
  });
}
