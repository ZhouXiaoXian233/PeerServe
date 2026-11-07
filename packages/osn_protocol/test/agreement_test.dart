import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Matcher throwsProtocol(ProtocolErrorCode code) => throwsA(
  isA<ProtocolException>().having((error) => error.code, 'code', code),
);

const String _requesterId =
    'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw';
const String _providerId =
    'did:key:z6MkhaXgBZDvotDkL5257faiztiGiC2QtKLGpbnnEGta2doK';

Map<String, Object?> _validJson({
  Object? schemaVersion = 1,
  Object? agreementId = '00000000-0000-4000-8000-000000000003',
  Object? requestId = '00000000-0000-4000-8000-000000000001',
  Object? offerId = '00000000-0000-4000-8000-000000000002',
  Object? requesterId = _requesterId,
  Object? providerId = _providerId,
  Object? serviceTerms = '从图书馆带一本书到东门。',
  Object? agreedPrice = 4500,
  Object? currency = 'CNY',
  Object? startConditions = '响应方到达图书馆后开始。',
  Object? completionConditions = '双方确认书籍交付。',
  Object? cancellationTerms = '任一方可提前说明并取消。',
  Object? createdAt = '2026-11-07T04:40:00.000Z',
  Object? expiresAt = '2026-11-07T06:00:00.000Z',
}) => <String, Object?>{
  'schema_version': schemaVersion,
  'agreement_id': agreementId,
  'request_id': requestId,
  'offer_id': offerId,
  'requester_id': requesterId,
  'provider_id': providerId,
  'service_terms': serviceTerms,
  'agreed_price': agreedPrice,
  'currency': currency,
  'start_conditions': startConditions,
  'completion_conditions': completionConditions,
  'cancellation_terms': cancellationTerms,
  'created_at': createdAt,
  'expires_at': expiresAt,
};

void main() {
  group('Agreement v1', () {
    test('合法协议可解析并往返', () {
      final agreement = Agreement.fromJson(_validJson());
      expect(agreement.requestId, '00000000-0000-4000-8000-000000000001');
      expect(agreement.offerId, '00000000-0000-4000-8000-000000000002');
      expect(agreement.requesterId, _requesterId);
      expect(agreement.providerId, _providerId);
      expect(agreement.agreedPriceMinor, 4500);
      expect(agreement.currency, 'CNY');

      final roundTrip = Agreement.fromJson(agreement.toJson());
      expect(roundTrip.toJson(), agreement.toJson());
    });

    test('拒绝未知 schema_version', () {
      expect(
        () => Agreement.fromJson(_validJson(schemaVersion: 2)),
        throwsProtocol(ProtocolErrorCode.unsupportedSchemaVersion),
      );
    });

    test('拒绝相同 requester/provider 或非法 did:key', () {
      expect(
        () => Agreement.fromJson(_validJson(providerId: _requesterId)),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Agreement.fromJson(_validJson(providerId: 'did:web:example.com')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('拒绝浮点价格、非法货币与负价格', () {
      expect(
        () => Agreement.fromJson(_validJson(agreedPrice: 45.5)),
        throwsProtocol(ProtocolErrorCode.floatNotAllowed),
      );
      expect(
        () => Agreement.fromJson(_validJson(agreedPrice: -1)),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Agreement.fromJson(_validJson(currency: 'cny')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('拒绝超长条款', () {
      expect(
        () => Agreement.fromJson(
          _validJson(serviceTerms: List<String>.filled(2001, 'x').join()),
        ),
        throwsProtocol(ProtocolErrorCode.stringTooLong),
      );
      expect(
        () => Agreement.fromJson(
          _validJson(
            completionConditions: List<String>.filled(1001, 'x').join(),
          ),
        ),
        throwsProtocol(ProtocolErrorCode.stringTooLong),
      );
    });

    test('拒绝过期时间不晚于创建时间', () {
      expect(
        () => Agreement.fromJson(
          _validJson(expiresAt: '2026-11-07T04:00:00.000Z'),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('newId 生成 UUID v4 形状', () {
      final id = Agreement.newId();
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
      );
    });
  });
}
