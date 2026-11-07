import 'dart:convert';
import 'dart:io';

import 'package:osn_protocol/osn_protocol.dart';

Future<void> main() async {
  final offer = Offer(
    offerId: '00000000-0000-4000-8000-000000000002',
    requestId: '00000000-0000-4000-8000-000000000001',
    providerId: 'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw',
    message: '我可以顺路带过去。',
    proposedPrice: const Price(amountMinor: 4500, currency: 'CNY'),
    proposedTime: const TimeWindow(
      start: '2026-11-07T05:10:00.000Z',
      end: '2026-11-07T05:40:00.000Z',
    ),
    createdAt: '2026-11-07T04:35:00.000Z',
    expiresAt: '2026-11-07T06:00:00.000Z',
  );

  final vector = <String, Object?>{
    'warning': '固定测试向量，不是真实响应。',
    'offer': offer.toJson(),
    'canonical_json': canonicalize(offer.toJson()),
  };

  final output = File('protocol/test-vectors/offer/offer_v1.json')
    ..createSync(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(vector)}\n',
  );
}
