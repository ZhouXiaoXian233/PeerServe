import 'dart:convert';
import 'dart:io';

import 'package:osn_protocol/osn_protocol.dart';

Future<void> main() async {
  const creatorId = 'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw';
  final request = Request(
    requestId: '00000000-0000-4000-8000-000000000001',
    creatorId: creatorId,
    category: RequestCategory.delivery,
    title: '从图书馆带一本书',
    description: '轻装，约 500 克。',
    origin: const Place(label: '图书馆'),
    destination: const Place(label: '东门'),
    timeWindow: const TimeWindow(
      start: '2026-11-07T05:00:00.000Z',
      end: '2026-11-07T06:00:00.000Z',
    ),
    price: const Price(amountMinor: 5000, currency: 'CNY'),
    createdAt: '2026-11-07T04:30:00.000Z',
    expiresAt: '2026-11-07T05:30:00.000Z',
    nonce: 'AAECAwQFBgcICQoLDA0ODw',
  );

  final vector = <String, Object?>{
    'warning': '固定测试向量，不是真实需求。',
    'request': request.toJson(),
    'canonical_json': canonicalize(request.toJson()),
  };

  final output = File('protocol/test-vectors/request/request_v1.json')
    ..createSync(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(vector)}\n',
  );
}
