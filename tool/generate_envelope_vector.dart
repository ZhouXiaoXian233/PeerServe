import 'dart:convert';
import 'dart:io';

import 'package:osn_identity/osn_identity.dart';
import 'package:osn_protocol/osn_protocol.dart';

Future<void> main() async {
  const seedHex =
      '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60';
  final identity = await PeerIdentity.fromSeed(_hexToBytes(seedHex));
  final envelope = await identity.signEnvelope(
    type: MessageType.requestCreated,
    sentAt: '2026-11-07T04:30:00.000Z',
    payload: const <String, Object?>{
      'request_id': '00000000-0000-4000-8000-000000000001',
      'category': 'delivery',
      'title': '从图书馆带一本书',
      'price': <String, Object?>{'amount_minor': 5000, 'currency': 'CNY'},
      'origin': <String, Object?>{
        'label': '图书馆',
        'lat_e7': 312304000,
        'lon_e7': 1214737000,
        'precision_m': 100,
      },
      'nonce': 'AAECAwQFBgcICQoLDA0ODw',
    },
  );

  final vector = <String, Object?>{
    'warning': '公开的 RFC 8032 测试种子，只用于向量复算，不是任何真实身份，也不得用于实际用途。',
    'seed_hex': seedHex,
    'sender_id': identity.identityId,
    'schema_version': protocolSchemaVersion,
    'type': envelope.type.wire,
    'sent_at': envelope.sentAt,
    'payload': envelope.payload,
    'canonical_signing_payload': canonicalize(envelope.signingPayload()),
    'signed_bytes_utf8': utf8.decode(envelope.signingBytes()),
    'signature_base64url': envelope.signature,
  };

  final output = File('protocol/test-vectors/envelope/request_created.json')
    ..createSync(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(vector)}\n',
  );
}

List<int> _hexToBytes(String hex) => <int>[
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
];
