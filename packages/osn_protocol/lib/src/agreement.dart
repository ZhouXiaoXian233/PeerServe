import 'did.dart';
import 'errors.dart';
import 'ids.dart';
import 'json_value.dart';
import 'timestamp.dart';

/// 双方协议（Agreement）v1 的条款部分。
///
/// 双签不在 payload 内重复存放：需求方与响应方各自对一个**完全相同**的
/// Agreement payload 生成一个签名信封（`agreement.proposed` / `agreement.signed`）。
/// 两个信封都存在且验签通过，视图才标记为 `mutually_signed`。
/// 这样避免"签名覆盖签名"的递归，也复用统一信封校验。详见 ADR-014。
class Agreement {
  const Agreement({
    required this.agreementId,
    required this.requestId,
    required this.offerId,
    required this.requesterId,
    required this.providerId,
    required this.serviceTerms,
    required this.agreedPriceMinor,
    required this.currency,
    required this.startConditions,
    required this.completionConditions,
    required this.cancellationTerms,
    required this.createdAt,
    required this.expiresAt,
  });

  static const int schemaVersion = 1;

  final String agreementId;
  final String requestId;
  final String offerId;
  final String requesterId;
  final String providerId;
  final String serviceTerms;
  final int agreedPriceMinor;
  final String currency;
  final String startConditions;
  final String completionConditions;
  final String cancellationTerms;
  final String createdAt;
  final String expiresAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': schemaVersion,
    'agreement_id': agreementId,
    'request_id': requestId,
    'offer_id': offerId,
    'requester_id': requesterId,
    'provider_id': providerId,
    'service_terms': serviceTerms,
    'agreed_price': agreedPriceMinor,
    'currency': currency,
    'start_conditions': startConditions,
    'completion_conditions': completionConditions,
    'cancellation_terms': cancellationTerms,
    'created_at': createdAt,
    'expires_at': expiresAt,
  };

  static Agreement fromJson(Object? input) {
    validateJsonValue(input, path: r'$');
    final map = _requireMap(input, r'$');

    final version = _requireInt(map, 'schema_version', r'$.schema_version');
    if (version != schemaVersion) {
      throw ProtocolException(
        ProtocolErrorCode.unsupportedSchemaVersion,
        '不支持的 Agreement schema_version=$version',
        field: r'$.schema_version',
      );
    }

    final agreementId = _requireId(map, 'agreement_id', r'$.agreement_id');
    final requestId = _requireId(map, 'request_id', r'$.request_id');
    final offerId = _requireId(map, 'offer_id', r'$.offer_id');

    final requesterId = _requireString(map, 'requester_id', r'$.requester_id');
    validateDidKeyId(requesterId, field: r'$.requester_id');
    final providerId = _requireString(map, 'provider_id', r'$.provider_id');
    validateDidKeyId(providerId, field: r'$.provider_id');
    if (requesterId == providerId) {
      throw const ProtocolException(
        ProtocolErrorCode.invalidField,
        'requester_id 与 provider_id 不能相同',
        field: r'$.provider_id',
      );
    }

    final serviceTerms = _requireString(
      map,
      'service_terms',
      r'$.service_terms',
      maxRunes: 2000,
    );
    final agreedPrice = _requireInt(map, 'agreed_price', r'$.agreed_price');
    if (agreedPrice < 0) {
      throw const ProtocolException(
        ProtocolErrorCode.invalidField,
        'agreed_price 不能为负数',
        field: r'$.agreed_price',
      );
    }
    final currency = _requireString(
      map,
      'currency',
      r'$.currency',
      maxRunes: 3,
    );
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw const ProtocolException(
        ProtocolErrorCode.invalidField,
        'currency 必须是 3 位大写字母（例如 CNY）',
        field: r'$.currency',
      );
    }

    final startConditions = _requireString(
      map,
      'start_conditions',
      r'$.start_conditions',
      maxRunes: 1000,
    );
    final completionConditions = _requireString(
      map,
      'completion_conditions',
      r'$.completion_conditions',
      maxRunes: 1000,
    );
    final cancellationTerms = _requireString(
      map,
      'cancellation_terms',
      r'$.cancellation_terms',
      maxRunes: 1000,
    );

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

    return Agreement(
      agreementId: agreementId,
      requestId: requestId,
      offerId: offerId,
      requesterId: requesterId,
      providerId: providerId,
      serviceTerms: serviceTerms,
      agreedPriceMinor: agreedPrice,
      currency: currency,
      startConditions: startConditions,
      completionConditions: completionConditions,
      cancellationTerms: cancellationTerms,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  static String newId() => newUuidV4();
}

String _requireId(Map<String, Object?> map, String key, String path) {
  final value = _requireString(map, key, path, maxRunes: 64);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$').hasMatch(value)) {
    throw ProtocolException(
      ProtocolErrorCode.invalidField,
      '$key 只能包含字母、数字、下划线与连字符',
      field: path,
    );
  }
  return value;
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
