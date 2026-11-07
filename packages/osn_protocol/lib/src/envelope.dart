import 'dart:convert';
import 'dart:typed_data';

import 'base64url.dart';
import 'canonical_json.dart';
import 'did.dart';
import 'errors.dart';
import 'json_value.dart';
import 'limits.dart';
import 'message_type.dart';
import 'strict_json.dart';
import 'timestamp.dart';

/// 协议信封：外层签名容器。
///
/// 签名覆盖 `schema_version`、`type`、`sender_id`、`sent_at` 与 `payload`，
/// 但**不覆盖** `signature` 自身。这样发送方身份与时间戳也被签名保护，
/// 接收方不能在不破坏签名的情况下替换它们。
class Envelope {
  const Envelope({
    this.schemaVersion = protocolSchemaVersion,
    required this.type,
    required this.payload,
    required this.senderId,
    required this.sentAt,
    required this.signature,
  });

  final int schemaVersion;
  final MessageType type;
  final Map<String, Object?> payload;
  final String senderId;
  final String sentAt;

  /// 无填充 base64url 的 64 字节 Ed25519 签名。
  final String signature;

  /// 被签名的对象（不含 signature 自身）。
  Map<String, Object?> signingPayload() => <String, Object?>{
    'schema_version': schemaVersion,
    'type': type.wire,
    'sender_id': senderId,
    'sent_at': sentAt,
    'payload': payload,
  };

  /// 实际送入 Ed25519 的字节：域分离前缀 + JCS。
  Uint8List signingBytes() {
    final canonical = canonicalize(signingPayload());
    return Uint8List.fromList(utf8.encode('$signatureDomainPrefix$canonical'));
  }

  /// 线上 JSON 表示。
  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': schemaVersion,
    'type': type.wire,
    'payload': payload,
    'sender_id': senderId,
    'sent_at': sentAt,
    'signature': signature,
  };

  /// 替换签名，保留其余字段。
  Envelope withSignature(String newSignature) {
    _validateSignatureEncoding(newSignature, field: r'$.signature');
    return Envelope(
      schemaVersion: schemaVersion,
      type: type,
      payload: payload,
      senderId: senderId,
      sentAt: sentAt,
      signature: newSignature,
    );
  }

  /// 校验并解析一个已解码的 JSON 值。
  ///
  /// 只做结构与编码校验；密码学验签由 `osn_identity` 完成。
  static Envelope fromJson(Object? input) {
    final map = _requireMap(input, r'$');
    const allowedKeys = <String>{
      'schema_version',
      'type',
      'payload',
      'sender_id',
      'sent_at',
      'signature',
    };
    for (final key in map.keys) {
      if (!allowedKeys.contains(key)) {
        throw ProtocolException(
          ProtocolErrorCode.unknownField,
          '信封包含未知字段 "$key"',
          field: r'$.$key',
        );
      }
    }

    final rawVersion = map['schema_version'];
    if (rawVersion == null) {
      throw const ProtocolException(
        ProtocolErrorCode.missingField,
        '信封缺少 schema_version',
        field: r'$.schema_version',
      );
    }
    if (rawVersion is! int) {
      throw const ProtocolException(
        ProtocolErrorCode.invalidField,
        'schema_version 必须是整数',
        field: r'$.schema_version',
      );
    }
    if (rawVersion != protocolSchemaVersion) {
      throw ProtocolException(
        ProtocolErrorCode.unsupportedSchemaVersion,
        '不支持的 schema_version=$rawVersion；当前仅支持 $protocolSchemaVersion',
        field: r'$.schema_version',
      );
    }

    final rawType = _requireString(map, 'type', r'$.type');
    final type = MessageType.tryParse(rawType);
    if (type == null) {
      throw ProtocolException(
        ProtocolErrorCode.unknownMessageType,
        '未知消息类型 "$rawType"',
        field: r'$.type',
      );
    }

    final rawPayload = map['payload'];
    if (rawPayload == null) {
      throw const ProtocolException(
        ProtocolErrorCode.missingField,
        '信封缺少 payload',
        field: r'$.payload',
      );
    }
    final payloadMap = _requireMap(rawPayload, r'$.payload');
    validateJsonValue(payloadMap, path: r'$.payload');

    final senderId = _requireString(map, 'sender_id', r'$.sender_id');
    validateDidKeyId(senderId, field: r'$.sender_id');

    final sentAt = _requireString(map, 'sent_at', r'$.sent_at');
    requireUtcTimestamp(sentAt, field: r'$.sent_at');

    final signature = _requireString(map, 'signature', r'$.signature');
    _validateSignatureEncoding(signature, field: r'$.signature');

    final envelope = Envelope(
      type: type,
      payload: Map<String, Object?>.from(payloadMap),
      senderId: senderId,
      sentAt: sentAt,
      signature: signature,
    );

    final encoded = utf8.encode(jsonEncode(envelope.toJson())).length;
    if (encoded > maxProtocolMessageBytes) {
      throw ProtocolException(
        ProtocolErrorCode.messageTooLarge,
        '信封 $encoded 字节，超过上限 $maxProtocolMessageBytes 字节',
      );
    }
    return envelope;
  }

  /// 从 JSON 文本严格解析信封。
  static Envelope parse(String source) => fromJson(parseStrictJson(source));
}

Map<String, Object?> _requireMap(Object? value, String path) {
  if (value is! Map) {
    throw ProtocolException(
      ProtocolErrorCode.invalidField,
      '期望 JSON 对象，实际为 ${value.runtimeType}',
      field: path,
    );
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        'JSON 对象键必须是字符串',
        field: path,
      );
    }
    result[key] = entry.value;
  }
  return result;
}

String _requireString(Map<String, Object?> map, String key, String path) {
  if (!map.containsKey(key)) {
    throw ProtocolException(
      ProtocolErrorCode.missingField,
      '缺少字段 $key',
      field: path,
    );
  }
  final value = map[key];
  if (value is! String) {
    throw ProtocolException(
      ProtocolErrorCode.invalidField,
      '$key 必须是字符串',
      field: path,
    );
  }
  return value;
}

final RegExp _signaturePattern = RegExp(r'^[A-Za-z0-9_-]{86}$');

void _validateSignatureEncoding(String value, {required String field}) {
  if (!_signaturePattern.hasMatch(value)) {
    throw ProtocolException(
      ProtocolErrorCode.invalidSignatureEncoding,
      'Ed25519 签名必须是 86 字符的无填充 base64url',
      field: field,
    );
  }
  final bytes = decodeBase64UrlNoPad(value, field: field);
  if (bytes.length != 64) {
    throw ProtocolException(
      ProtocolErrorCode.invalidSignatureEncoding,
      'Ed25519 签名必须是 64 字节，实际 ${bytes.length} 字节',
      field: field,
    );
  }
}
