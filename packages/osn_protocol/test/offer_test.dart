import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Matcher throwsProtocol(ProtocolErrorCode code) => throwsA(
  isA<ProtocolException>().having((error) => error.code, 'code', code),
);

const String _providerId =
    'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw';

Map<String, Object?> _validJson({
  Object? schemaVersion = 1,
  Object? offerId = '00000000-0000-4000-8000-000000000002',
  Object? requestId = '00000000-0000-4000-8000-000000000001',
  Object? providerId = _providerId,
  Object? message = '我可以顺路带过去。',
  Object? proposedPrice = const <String, Object?>{
    'amount_minor': 4500,
    'currency': 'CNY',
    'payment_method': 'external_agreement',
  },
  Object? proposedTime = const <String, Object?>{
    'start': '2026-11-07T05:10:00.000Z',
    'end': '2026-11-07T05:40:00.000Z',
  },
  Object? createdAt = '2026-11-07T04:35:00.000Z',
  Object? expiresAt = '2026-11-07T06:00:00.000Z',
}) => <String, Object?>{
  'schema_version': schemaVersion,
  'offer_id': offerId,
  'request_id': requestId,
  'provider_id': providerId,
  'message': message,
  'proposed_price': proposedPrice,
  'proposed_time': proposedTime,
  'created_at': createdAt,
  'expires_at': expiresAt,
};

void main() {
  group('Offer v1', () {
    test('合法响应可解析并往返', () {
      final offer = Offer.fromJson(_validJson());
      expect(offer.requestId, '00000000-0000-4000-8000-000000000001');
      expect(offer.providerId, _providerId);
      expect(offer.message, '我可以顺路带过去。');
      expect(offer.proposedPrice?.amountMinor, 4500);
      expect(offer.proposedTime?.start, '2026-11-07T05:10:00.000Z');

      final roundTrip = Offer.fromJson(offer.toJson());
      expect(roundTrip.toJson(), offer.toJson());
    });

    test('proposed_price / proposed_time 可省略', () {
      final json = _validJson()
        ..remove('proposed_price')
        ..remove('proposed_time');
      final offer = Offer.fromJson(json);
      expect(offer.proposedPrice, isNull);
      expect(offer.proposedTime, isNull);
    });

    test('拒绝未知 schema_version', () {
      expect(
        () => Offer.fromJson(_validJson(schemaVersion: 2)),
        throwsProtocol(ProtocolErrorCode.unsupportedSchemaVersion),
      );
    });

    test('拒绝非法 provider_id / request_id / offer_id', () {
      expect(
        () => Offer.fromJson(_validJson(providerId: 'did:web:example.com')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Offer.fromJson(_validJson(requestId: 'bad id!')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Offer.fromJson(_validJson(offerId: 'bad id!')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('拒绝超长消息', () {
      expect(
        () => Offer.fromJson(
          _validJson(message: List<String>.filled(1001, 'x').join()),
        ),
        throwsProtocol(ProtocolErrorCode.stringTooLong),
      );
    });

    test('拒绝浮点报价与倒置时间', () {
      expect(
        () => Offer.fromJson(
          _validJson(
            proposedPrice: const <String, Object?>{
              'amount_minor': 45.5,
              'currency': 'CNY',
              'payment_method': 'external_agreement',
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.floatNotAllowed),
      );
      expect(
        () => Offer.fromJson(
          _validJson(
            proposedTime: const <String, Object?>{
              'start': '2026-11-07T06:00:00.000Z',
              'end': '2026-11-07T05:00:00.000Z',
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('拒绝 expires_at 不晚于 created_at', () {
      expect(
        () => Offer.fromJson(_validJson(expiresAt: '2026-11-07T04:00:00.000Z')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('newId 生成 UUID v4 形状', () {
      final id = Offer.newId();
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
      );
    });
  });
}
