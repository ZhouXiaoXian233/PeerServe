import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('requireProtocolInt', () {
    test('接受安全整数', () {
      expect(requireProtocolInt(0, field: 'x'), 0);
      expect(requireProtocolInt(1, field: 'x'), 1);
      expect(requireProtocolInt(maxSafeInteger, field: 'x'), maxSafeInteger);
    });

    test('整数值的 double 在 web 兼容路径按整数处理', () {
      // dart2js 下 1 可能同时满足 is int 与 is double；这里锁定兼容行为。
      expect(requireProtocolInt(1.0, field: 'x'), 1);
      expect(requireProtocolInt(-0.0, field: 'x'), 0);
    });

    test('拒绝非整数与超范围值', () {
      expect(
        () => requireProtocolInt(1.5, field: 'x'),
        throwsA(
          isA<ProtocolException>().having(
            (error) => error.code,
            'code',
            ProtocolErrorCode.floatNotAllowed,
          ),
        ),
      );
      expect(
        () => requireProtocolInt(maxSafeInteger + 1, field: 'x'),
        throwsA(
          isA<ProtocolException>().having(
            (error) => error.code,
            'code',
            ProtocolErrorCode.integerOutOfRange,
          ),
        ),
      );
    });
  });
}
