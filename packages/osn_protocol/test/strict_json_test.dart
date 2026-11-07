import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Matcher throwsProtocol(ProtocolErrorCode code) => throwsA(
  isA<ProtocolException>().having((error) => error.code, 'code', code),
);

void main() {
  group('parseStrictJson', () {
    test('接受合法 JSON 与代理对', () {
      expect(
        parseStrictJson('{"name":"信约阁","emoji":"😀","n":1,"ok":true}'),
        <String, Object?>{'name': '信约阁', 'emoji': '😀', 'n': 1, 'ok': true},
      );
    });

    test('拒绝重复键（包括 \\u 转义后相同的键）', () {
      expect(
        () => parseStrictJson('{"a":1,"a":2}'),
        throwsProtocol(ProtocolErrorCode.duplicateKey),
      );
      expect(
        () => parseStrictJson(r'{"a":1,"\u0061":2}'),
        throwsProtocol(ProtocolErrorCode.duplicateKey),
      );
      expect(
        () => parseStrictJson('{"outer":{"x":1,"x":2}}'),
        throwsProtocol(ProtocolErrorCode.duplicateKey),
      );
    });

    test('不把不同对象里的同名键误判为重复', () {
      final value = parseStrictJson('{"a":{"x":1},"b":{"x":2}}');
      expect(value, isA<Map<String, Object?>>());
    });

    test('拒绝浮点数与指数形式', () {
      expect(
        () => parseStrictJson('{"a":1.5}'),
        throwsProtocol(ProtocolErrorCode.floatNotAllowed),
      );
      expect(
        () => parseStrictJson('{"a":1e3}'),
        throwsProtocol(ProtocolErrorCode.floatNotAllowed),
      );
    });

    test('拒绝 NaN / Infinity / 非法 JSON', () {
      expect(
        () => parseStrictJson('{"a":NaN}'),
        throwsProtocol(ProtocolErrorCode.invalidJson),
      );
      expect(
        () => parseStrictJson('{"a":Infinity}'),
        throwsProtocol(ProtocolErrorCode.invalidJson),
      );
      expect(
        () => parseStrictJson('{"a":1,}'),
        throwsProtocol(ProtocolErrorCode.invalidJson),
      );
      expect(
        () => parseStrictJson('{"a":1} trailing'),
        throwsProtocol(ProtocolErrorCode.invalidJson),
      );
    });

    test('拒绝孤立代理项', () {
      expect(
        () => parseStrictJson(r'{"a":"\ud800"}'),
        throwsProtocol(ProtocolErrorCode.invalidUnicode),
      );
    });

    test('拒绝超过 64 KiB 的消息', () {
      final source =
          '{"a":"${List<String>.filled(maxProtocolMessageBytes + 1, 'x').join()}"}';
      expect(
        () => parseStrictJson(source),
        throwsProtocol(ProtocolErrorCode.messageTooLarge),
      );
    });

    test('拒绝超过最大深度的嵌套', () {
      final source =
          '${List<String>.filled(maxJsonDepth + 1, '[').join()}0'
          '${List<String>.filled(maxJsonDepth + 1, ']').join()}';
      expect(
        () => parseStrictJson(source),
        throwsProtocol(ProtocolErrorCode.depthExceeded),
      );
    });
  });
}
