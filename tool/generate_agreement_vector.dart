import 'dart:convert';
import 'dart:io';

import 'package:osn_protocol/osn_protocol.dart';

Future<void> main() async {
  final agreement = Agreement(
    agreementId: '00000000-0000-4000-8000-000000000003',
    requestId: '00000000-0000-4000-8000-000000000001',
    offerId: '00000000-0000-4000-8000-000000000002',
    requesterId: 'did:key:z6MktwupdmLXVVqTzCw4i46r4uGyosGXRnR3XjN4Zq7oMMsw',
    providerId: 'did:key:z6MkhaXgBZDvotDkL5257faiztiGiC2QtKLGpbnnEGta2doK',
    serviceTerms: '从图书馆带一本书到东门。',
    agreedPriceMinor: 4500,
    currency: 'CNY',
    startConditions: '响应方到达图书馆后开始。',
    completionConditions: '双方确认书籍交付。',
    cancellationTerms: '任一方可提前说明并取消。',
    createdAt: '2026-11-07T04:40:00.000Z',
    expiresAt: '2026-11-07T06:00:00.000Z',
  );

  final vector = <String, Object?>{
    'warning': '固定测试向量，不是真实协议。',
    'agreement': agreement.toJson(),
    'canonical_json': canonicalize(agreement.toJson()),
  };

  final output = File('protocol/test-vectors/agreement/agreement_v1.json')
    ..createSync(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(vector)}\n',
  );
}
