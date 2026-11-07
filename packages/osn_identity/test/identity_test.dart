import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:osn_identity/osn_identity.dart';
import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Uint8List hexToBytes(String hex) {
  if (hex.length.isOdd) {
    throw ArgumentError('hex 长度必须是偶数');
  }
  return Uint8List.fromList(<int>[
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ]);
}

String bytesToHex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

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
  group('Ed25519（RFC 8032 向量）', () {
    test('种子派生、签名与验签与向量一致', () async {
      final file = File(
        '${repoRoot().path}/protocol/test-vectors/ed25519/rfc8032.json',
      );
      final document =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final vectors = document['vectors'] as List<dynamic>;

      for (final item in vectors) {
        final vector = item as Map<String, dynamic>;
        final name = vector['name'] as String;
        final seed = hexToBytes(vector['seed'] as String);
        final expectedPublicKey = hexToBytes(vector['public_key'] as String);
        final message = hexToBytes(vector['message'] as String);
        final expectedSignature = hexToBytes(vector['signature'] as String);

        final identity = await PeerIdentity.fromSeed(seed);
        expect(identity.publicKey, expectedPublicKey, reason: name);
        expect(
          identity.identityId,
          didKeyFromPublicKey(expectedPublicKey),
          reason: name,
        );

        final signature = await identity.sign(message);
        expect(bytesToHex(signature), vector['signature'], reason: name);
        expect(
          bytesToHex(signature),
          bytesToHex(expectedSignature),
          reason: name,
        );
        expect(await identity.verify(message, signature), isTrue, reason: name);
      }
    });

    test('篡改消息后验签失败', () async {
      final identity = await PeerIdentity.fromSeed(
        hexToBytes(
          '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
        ),
      );
      final signature = await identity.sign(<int>[1, 2, 3]);
      expect(await identity.verify(<int>[1, 2, 4], signature), isFalse);
    });
  });

  group('信封签名/验签', () {
    late PeerIdentity identity;

    setUp(() async {
      identity = await PeerIdentity.fromSeed(
        hexToBytes(
          '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
        ),
      );
    });

    Future<Envelope> signedEnvelope() => identity.signEnvelope(
      type: MessageType.requestCreated,
      sentAt: '2026-11-07T04:30:00.000Z',
      payload: const <String, Object?>{
        'request_id': '00000000-0000-4000-8000-000000000001',
        'title': '从图书馆带一本书',
        'price': <String, Object?>{'amount_minor': 5000, 'currency': 'CNY'},
      },
    );

    test('签名信封可通过独立验签，JSON 往返后仍有效', () async {
      final envelope = await signedEnvelope();
      expect(await verifyEnvelopeSignature(envelope), isTrue);

      final parsed = Envelope.parse(jsonEncode(envelope.toJson()));
      expect(await verifyEnvelopeSignature(parsed), isTrue);
      expect(parsed.senderId, identity.identityId);
    });

    test('篡改 payload、sent_at 或 sender_id 后验签失败', () async {
      final envelope = await signedEnvelope();
      final json = envelope.toJson();

      final changedPayload = Envelope.fromJson(<String, Object?>{
        ...json,
        'payload': const <String, Object?>{
          'request_id': '00000000-0000-4000-8000-000000000001',
          'title': '改成别的标题',
        },
      });
      expect(await verifyEnvelopeSignature(changedPayload), isFalse);

      final changedTime = Envelope.fromJson(<String, Object?>{
        ...json,
        'sent_at': '2026-11-07T04:31:00.000Z',
      });
      expect(await verifyEnvelopeSignature(changedTime), isFalse);

      final other = await PeerIdentity.generate();
      final changedSender = Envelope.fromJson(<String, Object?>{
        ...json,
        'sender_id': other.identityId,
      });
      expect(await verifyEnvelopeSignature(changedSender), isFalse);
    });

    test('篡改签名字节后验签失败', () async {
      final envelope = await signedEnvelope();
      final signature = decodeBase64UrlNoPad(
        envelope.signature,
        field: 'signature',
      );
      signature[0] ^= 0x01;
      final changed = envelope.withSignature(encodeBase64UrlNoPad(signature));
      expect(await verifyEnvelopeSignature(changed), isFalse);
    });

    test('非法 payload 不使验签接口抛异常，只返回 false', () async {
      final envelope = Envelope(
        type: MessageType.requestCreated,
        payload: const <String, Object?>{'price': 1.5},
        senderId: identity.identityId,
        sentAt: '2026-11-07T04:30:00.000Z',
        signature: encodeBase64UrlNoPad(Uint8List(64)),
      );
      expect(await verifyEnvelopeSignature(envelope), isFalse);
    });

    test('相同种子得到相同身份', () async {
      final seed = hexToBytes(
        '4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb',
      );
      final first = await PeerIdentity.fromSeed(seed);
      final second = await PeerIdentity.fromSeed(seed);
      expect(first.identityId, second.identityId);
      expect(first.publicKey, second.publicKey);
    });

    test('固定信封向量可复算', () async {
      final file = File(
        '${repoRoot().path}/protocol/test-vectors/envelope/request_created.json',
      );
      final vector =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final identity = await PeerIdentity.fromSeed(
        hexToBytes(vector['seed_hex'] as String),
      );

      expect(identity.identityId, vector['sender_id']);

      final envelope = await identity.signEnvelope(
        type: MessageType.tryParse(vector['type'] as String)!,
        sentAt: vector['sent_at'] as String,
        payload: Map<String, Object?>.from(vector['payload'] as Map),
      );
      expect(envelope.signature, vector['signature_base64url']);
      expect(
        canonicalize(envelope.signingPayload()),
        vector['canonical_signing_payload'],
      );
      expect(utf8.decode(envelope.signingBytes()), vector['signed_bytes_utf8']);
      expect(await verifyEnvelopeSignature(envelope), isTrue);
    });

    test('Request 可装入签名信封并验签', () async {
      final request = Request(
        requestId: Request.newId(),
        creatorId: identity.identityId,
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
        nonce: Request.newNonce(),
      );
      final validated = Request.fromJson(request.toJson());
      final envelope = await identity.signEnvelope(
        type: MessageType.requestCreated,
        sentAt: '2026-11-07T04:30:00.000Z',
        payload: validated.toJson(),
      );

      expect(await verifyEnvelopeSignature(envelope), isTrue);
      final decoded = Request.fromJson(envelope.payload);
      expect(decoded.title, '从图书馆带一本书');
      expect(decoded.creatorId, identity.identityId);
      expect(decoded.price.amountMinor, 5000);
    });

    test('Offer 可装入签名信封并验签', () async {
      final offer = Offer(
        offerId: Offer.newId(),
        requestId: '00000000-0000-4000-8000-000000000001',
        providerId: identity.identityId,
        message: '我可以顺路带过去。',
        proposedPrice: const Price(amountMinor: 4500, currency: 'CNY'),
        createdAt: '2026-11-07T04:35:00.000Z',
        expiresAt: '2026-11-07T06:00:00.000Z',
      );
      final validated = Offer.fromJson(offer.toJson());
      final envelope = await identity.signEnvelope(
        type: MessageType.offerCreated,
        sentAt: '2026-11-07T04:35:00.000Z',
        payload: validated.toJson(),
      );

      expect(await verifyEnvelopeSignature(envelope), isTrue);
      final decoded = Offer.fromJson(envelope.payload);
      expect(decoded.requestId, '00000000-0000-4000-8000-000000000001');
      expect(decoded.providerId, identity.identityId);
      expect(decoded.proposedPrice?.amountMinor, 4500);
    });

    test('Agreement 由双方对同一 payload 各自签名', () async {
      final provider = await PeerIdentity.fromSeed(
        hexToBytes(
          '4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb',
        ),
      );
      final agreement = Agreement(
        agreementId: Agreement.newId(),
        requestId: '00000000-0000-4000-8000-000000000001',
        offerId: '00000000-0000-4000-8000-000000000002',
        requesterId: identity.identityId,
        providerId: provider.identityId,
        serviceTerms: '从图书馆带一本书到东门。',
        agreedPriceMinor: 4500,
        currency: 'CNY',
        startConditions: '响应方到达图书馆后开始。',
        completionConditions: '双方确认书籍交付。',
        cancellationTerms: '任一方可提前说明并取消。',
        createdAt: '2026-11-07T04:40:00.000Z',
        expiresAt: '2026-11-07T06:00:00.000Z',
      );
      final validated = Agreement.fromJson(agreement.toJson());

      final requesterEnvelope = await identity.signEnvelope(
        type: MessageType.agreementProposed,
        sentAt: '2026-11-07T04:40:00.000Z',
        payload: validated.toJson(),
      );
      final providerEnvelope = await provider.signEnvelope(
        type: MessageType.agreementSigned,
        sentAt: '2026-11-07T04:41:00.000Z',
        payload: validated.toJson(),
      );

      expect(await verifyEnvelopeSignature(requesterEnvelope), isTrue);
      expect(await verifyEnvelopeSignature(providerEnvelope), isTrue);
      expect(
        canonicalize(requesterEnvelope.payload),
        canonicalize(providerEnvelope.payload),
      );
      expect(
        Agreement.fromJson(providerEnvelope.payload).agreementId,
        agreement.agreementId,
      );
    });
  });
}
