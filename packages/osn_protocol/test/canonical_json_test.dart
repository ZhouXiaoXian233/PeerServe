import 'dart:convert';
import 'dart:io';

import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Matcher throwsProtocol(ProtocolErrorCode code) => throwsA(
  isA<ProtocolException>().having((error) => error.code, 'code', code),
);

Directory repoRoot() {
  var directory = Directory.current;
  while (true) {
    if (Directory('${directory.path}/protocol/test-vectors').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('找不到仓库根目录（protocol/test-vectors）');
    }
    directory = parent;
  }
}

void main() {
  group('canonicalize（协议子集 JCS）', () {
    test('与跨语言向量一致', () async {
      final file = File(
        '${repoRoot().path}/protocol/test-vectors/jcs/cases.json',
      );
      final document =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final cases = document['cases'] as List<dynamic>;

      for (final item in cases) {
        final vector = item as Map<String, dynamic>;
        expect(
          canonicalize(vector['input']),
          vector['canonical'],
          reason: vector['name'] as String,
        );
      }
    });

    test('对象插入顺序不影响结果', () {
      final first = canonicalize(<String, Object?>{'b': 2, 'a': 1});
      final second = canonicalize(<String, Object?>{'a': 1, 'b': 2});
      expect(first, second);
    });

    test('canonicalizeUtf8 返回 UTF-8 字节', () {
      expect(
        canonicalizeUtf8(<String, Object?>{'é': 1}),
        utf8.encode('{"é":1}'),
      );
    });

    test('拒绝所有浮点数（含 -0、1e30、RFC 边界值）', () {
      for (final value in <double>[-0.0, 1.0, 1e30, 333333333.33333329]) {
        expect(
          () => canonicalize(<String, Object?>{'value': value}),
          throwsProtocol(ProtocolErrorCode.floatNotAllowed),
          reason: '$value',
        );
      }
    });

    test('拒绝超出 IEEE-754 安全范围的整数', () {
      expect(
        () => canonicalize(<String, Object?>{'value': maxSafeInteger + 1}),
        throwsProtocol(ProtocolErrorCode.integerOutOfRange),
      );
      expect(
        () => canonicalize(<String, Object?>{'value': -maxSafeInteger - 1}),
        throwsProtocol(ProtocolErrorCode.integerOutOfRange),
      );
    });

    test('拒绝孤立代理项', () {
      final loneHigh = String.fromCharCode(0xD800);
      final loneLow = String.fromCharCode(0xDC00);
      expect(
        () => canonicalize(<String, Object?>{'value': loneHigh}),
        throwsProtocol(ProtocolErrorCode.invalidUnicode),
      );
      expect(
        () => canonicalize(<String, Object?>{'value': loneLow}),
        throwsProtocol(ProtocolErrorCode.invalidUnicode),
      );
    });

    test('拒绝循环引用', () {
      final value = <String, Object?>{};
      value['self'] = value;
      expect(
        () => canonicalize(value),
        throwsProtocol(ProtocolErrorCode.invalidPayload),
      );
    });

    test('拒绝非字符串对象键', () {
      expect(
        () => canonicalize(<Object?, Object?>{1: 'x'}),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });
  });
}
