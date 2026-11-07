import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Matcher throwsProtocol(ProtocolErrorCode code) => throwsA(
  isA<ProtocolException>().having((error) => error.code, 'code', code),
);

const String _creatorId =
    'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw';

Map<String, Object?> _validJson({
  Object? schemaVersion = 1,
  Object? requestId = '00000000-0000-4000-8000-000000000001',
  Object? creatorId = _creatorId,
  Object? category = 'delivery',
  Object? title = '从图书馆带一本书',
  Object? description = '轻装，约 500 克。',
  Object? origin = const <String, Object?>{
    'label': '图书馆',
    'lat_e7': 312304000,
    'lon_e7': 1214737000,
    'precision_m': 100,
  },
  Object? destination = const <String, Object?>{
    'label': '东门',
    'lat_e7': 312310000,
    'lon_e7': 1214740000,
    'precision_m': 100,
  },
  Object? timeWindow = const <String, Object?>{
    'start': '2026-11-07T05:00:00.000Z',
    'end': '2026-11-07T06:00:00.000Z',
  },
  Object? price = const <String, Object?>{
    'amount_minor': 5000,
    'currency': 'CNY',
    'payment_method': 'external_agreement',
  },
  Object? createdAt = '2026-11-07T04:30:00.000Z',
  Object? expiresAt = '2026-11-07T05:30:00.000Z',
  Object? nonce = 'AAECAwQFBgcICQoLDA0ODw',
}) => <String, Object?>{
  'schema_version': schemaVersion,
  'request_id': requestId,
  'creator_id': creatorId,
  'category': category,
  'title': title,
  'description': description,
  'origin': origin,
  'destination': destination,
  'time_window': timeWindow,
  'price': price,
  'created_at': createdAt,
  'expires_at': expiresAt,
  'nonce': nonce,
};

void main() {
  group('Request v1', () {
    test('合法需求可解析并往返', () {
      final request = Request.fromJson(_validJson());
      expect(request.requestId, '00000000-0000-4000-8000-000000000001');
      expect(request.creatorId, _creatorId);
      expect(request.category, RequestCategory.delivery);
      expect(request.title, '从图书馆带一本书');
      expect(request.origin?.latE7, 312304000);
      expect(request.price.amountMinor, 5000);
      expect(request.price.paymentMethod, PaymentMethod.externalAgreement);

      final roundTrip = Request.fromJson(request.toJson());
      expect(roundTrip.toJson(), request.toJson());
    });

    test('地点可以只给 label，不带坐标', () {
      final request = Request.fromJson(
        _validJson(
          origin: const <String, Object?>{'label': '图书馆附近'},
          destination: const <String, Object?>{'label': '东门附近'},
        ),
      );
      expect(request.origin?.label, '图书馆附近');
      expect(request.origin?.latE7, isNull);
    });

    test('拒绝未知 schema_version', () {
      expect(
        () => Request.fromJson(_validJson(schemaVersion: 2)),
        throwsProtocol(ProtocolErrorCode.unsupportedSchemaVersion),
      );
    });

    test('拒绝未知 category / payment_method', () {
      expect(
        () => Request.fromJson(_validJson(category: 'teleport')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Request.fromJson(
          _validJson(
            price: const <String, Object?>{
              'amount_minor': 5000,
              'currency': 'CNY',
              'payment_method': 'cash',
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('拒绝浮点金额与非安全整数', () {
      expect(
        () => Request.fromJson(
          _validJson(
            price: const <String, Object?>{
              'amount_minor': 50.5,
              'currency': 'CNY',
              'payment_method': 'external_agreement',
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.floatNotAllowed),
      );
      expect(
        () => Request.fromJson(
          _validJson(
            price: const <String, Object?>{
              'amount_minor': maxSafeInteger + 1,
              'currency': 'CNY',
              'payment_method': 'external_agreement',
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.integerOutOfRange),
      );
    });

    test('拒绝超长标题与描述', () {
      expect(
        () => Request.fromJson(
          _validJson(title: List<String>.filled(121, 'x').join()),
        ),
        throwsProtocol(ProtocolErrorCode.stringTooLong),
      );
      expect(
        () => Request.fromJson(
          _validJson(description: List<String>.filled(2001, 'x').join()),
        ),
        throwsProtocol(ProtocolErrorCode.stringTooLong),
      );
    });

    test('拒绝倒置的时间窗与过期时间', () {
      expect(
        () => Request.fromJson(
          _validJson(
            timeWindow: const <String, Object?>{
              'start': '2026-11-07T06:00:00.000Z',
              'end': '2026-11-07T05:00:00.000Z',
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () =>
            Request.fromJson(_validJson(expiresAt: '2026-11-07T04:00:00.000Z')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('拒绝不完整或越界的坐标', () {
      expect(
        () => Request.fromJson(
          _validJson(
            origin: const <String, Object?>{
              'label': '图书馆',
              'lat_e7': 312304000,
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Request.fromJson(
          _validJson(
            origin: const <String, Object?>{
              'label': '图书馆',
              'lat_e7': 910000000,
              'lon_e7': 1214737000,
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Request.fromJson(
          _validJson(
            origin: const <String, Object?>{'label': '图书馆', 'precision_m': 100},
          ),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('拒绝非法货币、nonce 与 request_id', () {
      expect(
        () => Request.fromJson(
          _validJson(
            price: const <String, Object?>{
              'amount_minor': 5000,
              'currency': 'cny',
              'payment_method': 'external_agreement',
            },
          ),
        ),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Request.fromJson(_validJson(nonce: 'AAAA')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
      expect(
        () => Request.fromJson(_validJson(requestId: 'bad id!')),
        throwsProtocol(ProtocolErrorCode.invalidField),
      );
    });

    test('newId 与 newNonce 生成固定形状', () {
      final first = Request.newId();
      final second = Request.newId();
      expect(first, isNot(second));
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(first),
        isTrue,
      );
      final nonce = Request.newNonce();
      expect(nonce.length, 22);
      expect(decodeBase64UrlNoPad(nonce, field: 'nonce').length, 16);
    });
  });
}
