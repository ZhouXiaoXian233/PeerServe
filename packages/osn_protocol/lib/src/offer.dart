import 'did.dart';
import 'errors.dart';
import 'ids.dart';
import 'json_value.dart';
import 'request.dart';
import 'timestamp.dart';

/// 对某条 Request 的服务响应（Offer）v1。
///
/// 只表达"提供方愿意以什么条件响应"，不表示需求方已接受。
class Offer {
  const Offer({
    required this.offerId,
    required this.requestId,
    required this.providerId,
    this.message = '',
    this.proposedPrice,
    this.proposedTime,
    required this.createdAt,
    required this.expiresAt,
  });

  static const int schemaVersion = 1;

  final String offerId;
  final String requestId;
  final String providerId;
  final String message;
  final Price? proposedPrice;
  final TimeWindow? proposedTime;
  final String createdAt;
  final String expiresAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': schemaVersion,
    'offer_id': offerId,
    'request_id': requestId,
    'provider_id': providerId,
    'message': message,
    if (proposedPrice != null) 'proposed_price': proposedPrice!.toJson(),
    if (proposedTime != null) 'proposed_time': proposedTime!.toJson(),
    'created_at': createdAt,
    'expires_at': expiresAt,
  };

  static Offer fromJson(Object? input) {
    validateJsonValue(input, path: r'$');
    final map = _requireMap(input, r'$');

    final version = _requireInt(map, 'schema_version', r'$.schema_version');
    if (version != schemaVersion) {
      throw ProtocolException(
        ProtocolErrorCode.unsupportedSchemaVersion,
        '不支持的 Offer schema_version=$version',
        field: r'$.schema_version',
      );
    }

    final offerId = _requireString(
      map,
      'offer_id',
      r'$.offer_id',
      maxRunes: 64,
    );
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$').hasMatch(offerId)) {
      throw const ProtocolException(
        ProtocolErrorCode.invalidField,
        'offer_id 只能包含字母、数字、下划线与连字符',
        field: r'$.offer_id',
      );
    }

    final requestId = _requireString(
      map,
      'request_id',
      r'$.request_id',
      maxRunes: 64,
    );
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$').hasMatch(requestId)) {
      throw const ProtocolException(
        ProtocolErrorCode.invalidField,
        'request_id 只能包含字母、数字、下划线与连字符',
        field: r'$.request_id',
      );
    }

    final providerId = _requireString(map, 'provider_id', r'$.provider_id');
    validateDidKeyId(providerId, field: r'$.provider_id');

    final message = _requireString(
      map,
      'message',
      r'$.message',
      minRunes: 0,
      maxRunes: 1000,
    );

    final proposedPrice = map['proposed_price'] == null
        ? null
        : Price.fromJson(map['proposed_price'], path: r'$.proposed_price');
    final proposedTime = map['proposed_time'] == null
        ? null
        : TimeWindow.fromJson(map['proposed_time'], path: r'$.proposed_time');

    final createdAt = _requireString(map, 'created_at', r'$.created_at');
    requireUtcTimestamp(createdAt, field: r'$.created_at');
    final expiresAt = _requireString(map, 'expires_at', r'$.expires_at');
    requireUtcTimestamp(expiresAt, field: r'$.expires_at');
    if (!DateTime.parse(expiresAt).isAfter(DateTime.parse(createdAt))) {
      throw const ProtocolException(
        ProtocolErrorCode.invalidField,
        'expires_at 必须晚于 created_at',
        field: r'$.expires_at',
      );
    }

    return Offer(
      offerId: offerId,
      requestId: requestId,
      providerId: providerId,
      message: message,
      proposedPrice: proposedPrice,
      proposedTime: proposedTime,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  static String newId() => newUuidV4();
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

String _requireString(
  Map<String, Object?> map,
  String key,
  String path, {
  int minRunes = 1,
  int? maxRunes,
}) {
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
  final runes = value.runes.length;
  if (runes < minRunes) {
    throw ProtocolException(
      ProtocolErrorCode.invalidField,
      '$key 不能为空',
      field: path,
    );
  }
  if (maxRunes != null && runes > maxRunes) {
    throw ProtocolException(
      ProtocolErrorCode.stringTooLong,
      '$key 超过 $maxRunes 字符',
      field: path,
    );
  }
  return value;
}

int _requireInt(Map<String, Object?> map, String key, String path) {
  if (!map.containsKey(key)) {
    throw ProtocolException(
      ProtocolErrorCode.missingField,
      '缺少字段 $key',
      field: path,
    );
  }
  final value = map[key];
  if (value is double) {
    throw ProtocolException(
      ProtocolErrorCode.floatNotAllowed,
      '$key 不允许浮点数',
      field: path,
    );
  }
  if (value is! int) {
    throw ProtocolException(
      ProtocolErrorCode.invalidField,
      '$key 必须是整数',
      field: path,
    );
  }
  return value;
}
