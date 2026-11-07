import 'dart:convert';
import 'dart:typed_data';

import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Matcher throwsProtocol(ProtocolErrorCode code) => throwsA(
  isA<ProtocolException>().having((error) => error.code, 'code', code),
);

const String _senderId =
    'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw';

final String _signature = encodeBase64UrlNoPad(Uint8List(64));

Map<String, Object?> _validJson({
  Object? schemaVersion = 1,
  Object? type = 'request.created',
  Object? payload = const <String, Object?>{
    'request_id': '00000000-0000-4000-8000-000000000001',
    'title': '从图书馆带一本书',
  },
  Object? senderId = _senderId,
  Object? sentAt = '2026-11-07T04:30:00.000Z',
  Object? signature,
}) => <String, Object?>{
  'schema_version': schemaVersion,
  'type': type,
  'payload': payload,
  'sender_id': senderId,
  'sent_at': sentAt,
  'signature': signature ?? _signature,
};

void main() {
  group('Envelope', () {
    test('解析合法信封', () {
      final envelope = Envelope.fromJson(_validJson());
      expect(envelope.schemaVersion, protocolSchemaVersion);
      expect(envelope.type, MessageType.requestCreated);
      expect(envelope.senderId, _senderId);
      expect(envelope.sentAt, '2026-11-07T04:30:00.000Z');
      expect(envelope.signature, _signature);
      expect(envelope.payload['title'], '从图书馆带一本书');
    });

    test('签名载荷包含 sender_id 与 sent_at', () {
      final payload = <String, Object?>{'a': 1, 'b': 2};
      final first = Envelope.fromJson(_validJson(payload: payload));
      final second = Envelope.fromJson(
        _validJson(payload: <String, Object?>{'b': 2, 'a': 1}),
      );

      expect(first.signingBytes(), second.signingBytes());
      expect(
        first.signingPayload().keys,
        containsAll(<String>['sender_id', 'sent_at']),
      );
      expect(
        utf8.decode(first.signingBytes()),
        startsWith(signatureDomainPrefix),
      );
    });

    test('拒绝未知 schema_version', () {
      expect(
        () => Envelope.fromJson(_validJson(schemaVersion: 2)),
        throwsProtocol(ProtocolErrorCode.unsupportedSchemaVersion),
      );
    });

    test('拒绝未知消息类型', () {
      expect(
        () => Envelope.fromJson(_validJson(type: 'request.unknown')),
        throwsProtocol(ProtocolErrorCode.unknownMessageType),
      );
    });

    test('拒绝缺失字段与未知字段', () {
      final missing = _validJson()..remove('payload');
      expect(
        () => Envelope.fromJson(missing),
        throwsProtocol(ProtocolErrorCode.missingField),
      );
      final unknown = _validJson()..['extra'] = true;
      expect(
        () => Envelope.fromJson(unknown),
        throwsProtocol(ProtocolErrorCode.unknownField),
      );
    });

    test('拒绝浮点 payload', () {
      expect(
        () => Envelope.fromJson(
          _validJson(payload: <String, Object?>{'price': 12.5}),
        ),
        throwsProtocol(ProtocolErrorCode.floatNotAllowed),
      );
    });

    test('拒绝非法时间戳', () {
      for (final value in <String>[
        '2026-11-07T04:30:00Z',
        '2026-11-07T12:30:00.000+08:00',
        '2026-13-07T04:30:00.000Z',
      ]) {
        expect(
          () => Envelope.fromJson(_validJson(sentAt: value)),
          throwsProtocol(ProtocolErrorCode.invalidTimestamp),
          reason: value,
        );
      }
    });

    test('拒绝填充或错误长度的签名', () {
      expect(
        () => Envelope.fromJson(_validJson(signature: '$_signature=')),
        throwsProtocol(ProtocolErrorCode.invalidSignatureEncoding),
      );
      expect(
        () => Envelope.fromJson(_validJson(signature: 'AAAA')),
        throwsProtocol(ProtocolErrorCode.invalidSignatureEncoding),
      );
    });

    test('拒绝重复键的 JSON 文本', () {
      final source = jsonEncode(_validJson());
      final duplicated = source.replaceFirst(
        '"schema_version":1',
        '"schema_version":1,"schema_version":2',
      );
      expect(
        () => Envelope.parse(duplicated),
        throwsProtocol(ProtocolErrorCode.duplicateKey),
      );
    });

    test('拒绝超过 64 KiB 的信封', () {
      final payload = <String, Object?>{
        'text': List<String>.filled(maxProtocolMessageBytes + 1, 'x').join(),
      };
      expect(
        () => Envelope.fromJson(_validJson(payload: payload)),
        throwsProtocol(ProtocolErrorCode.messageTooLarge),
      );
    });

    test('withSignature 校验编码并保留其他字段', () {
      final envelope = Envelope.fromJson(_validJson());
      final replacement = encodeBase64UrlNoPad(
        Uint8List.fromList(List<int>.generate(64, (index) => index)),
      );
      final changed = envelope.withSignature(replacement);
      expect(changed.signature, replacement);
      expect(changed.payload, envelope.payload);
      expect(
        () => envelope.withSignature('bad'),
        throwsProtocol(ProtocolErrorCode.invalidSignatureEncoding),
      );
    });
  });
}
