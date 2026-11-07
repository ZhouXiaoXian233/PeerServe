import 'dart:math';
import 'dart:typed_data';

import 'base64url.dart';
import 'did.dart';
import 'errors.dart';
import 'json_value.dart';
import 'timestamp.dart';

/// 需求类别（协议 v1）。
enum RequestCategory {
  ride('ride'),
  delivery('delivery'),
  food('food'),
  errand('errand'),
  other('other');

  const RequestCategory(this.wire);

  final String wire;

  static RequestCategory? tryParse(String value) {
    for (final category in values) {
      if (category.wire == value) {
        return category;
      }
    }
    return null;
  }
}

/// 价格支付方式。协议只表达"协商信息"，不表示托管或担保。
enum PaymentMethod {
  externalAgreement('external_agreement');

  const PaymentMethod(this.wire);

  final String wire;

  static PaymentMethod? tryParse(String value) {
    for (final method in values) {
      if (method.wire == value) {
        return method;
      }
    }
    return null;
  }
}

/// 一个地点。坐标可选；只给 `label` 表示模糊区域。
class Place {
  const Place({required this.label, this.latE7, this.lonE7, this.precisionM});

  final String label;

  /// 纬度 × 1e7 的整数。
  final int? latE7;

  /// 经度 × 1e7 的整数。
  final int? lonE7;

  /// 精度半径（米）。
  final int? precisionM;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    if (latE7 != null) 'lat_e7': latE7,
    if (lonE7 != null) 'lon_e7': lonE7,
    if (precisionM != null) 'precision_m': precisionM,
  };

  static Place fromJson(Object? input, {required String path}) {
    final map = _requireMap(input, path);
    final label = _requireString(map, 'label', '$path.label', maxRunes: 120);
    final lat = _optionalInt(map, 'lat_e7', '$path.lat_e7');
    final lon = _optionalInt(map, 'lon_e7', '$path.lon_e7');
    final precision = _optionalInt(map, 'precision_m', '$path.precision_m');

    if ((lat == null) != (lon == null)) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        'lat_e7 与 lon_e7 必须同时存在或同时省略',
        field: path,
      );
    }
    if (lat != null && (lat < -900000000 || lat > 900000000)) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        'lat_e7 必须在 [-900000000, 900000000] 内',
        field: '$path.lat_e7',
      );
    }
    if (lon != null && (lon < -1800000000 || lon > 1800000000)) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        'lon_e7 必须在 [-1800000000, 1800000000] 内',
        field: '$path.lon_e7',
      );
    }
    if (precision != null && (precision <= 0 || precision > 100000)) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        'precision_m 必须在 (0, 100000] 内',
        field: '$path.precision_m',
      );
    }
    if (lat == null && precision != null) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        '没有坐标时不应携带 precision_m',
        field: '$path.precision_m',
      );
    }

    return Place(label: label, latE7: lat, lonE7: lon, precisionM: precision);
  }
}

/// 需求的时间窗。
class TimeWindow {
  const TimeWindow({required this.start, required this.end});

  final String start;
  final String end;

  Map<String, Object?> toJson() => <String, Object?>{
    'start': start,
    'end': end,
  };

  static TimeWindow fromJson(Object? input, {required String path}) {
    final map = _requireMap(input, path);
    final start = _requireString(map, 'start', '$path.start');
    final end = _requireString(map, 'end', '$path.end');
    requireUtcTimestamp(start, field: '$path.start');
    requireUtcTimestamp(end, field: '$path.end');
    if (!DateTime.parse(end).isAfter(DateTime.parse(start))) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        '时间窗 end 必须晚于 start',
        field: path,
      );
    }
    return TimeWindow(start: start, end: end);
  }
}

/// 需求预算。`amountMinor` 是最小货币单位的整数。
class Price {
  const Price({
    required this.amountMinor,
    required this.currency,
    this.paymentMethod = PaymentMethod.externalAgreement,
  });

  final int amountMinor;
  final String currency;
  final PaymentMethod paymentMethod;

  Map<String, Object?> toJson() => <String, Object?>{
    'amount_minor': amountMinor,
    'currency': currency,
    'payment_method': paymentMethod.wire,
  };

  static Price fromJson(Object? input, {required String path}) {
    final map = _requireMap(input, path);
    final amount = _requireInt(map, 'amount_minor', '$path.amount_minor');
    if (amount < 0) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        'amount_minor 不能为负数',
        field: '$path.amount_minor',
      );
    }
    final currency = _requireString(
      map,
      'currency',
      '$path.currency',
      maxRunes: 3,
    );
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        'currency 必须是 3 位大写字母（例如 CNY）',
        field: '$path.currency',
      );
    }
    final methodWire = _requireString(
      map,
      'payment_method',
      '$path.payment_method',
    );
    final method = PaymentMethod.tryParse(methodWire);
    if (method == null) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        '未知 payment_method "$methodWire"',
        field: '$path.payment_method',
      );
    }
    return Price(
      amountMinor: amount,
      currency: currency,
      paymentMethod: method,
    );
  }
}

/// 需求公告（Request）v1。
///
/// 该类只负责数据和校验，不签名、不联网、不落库。
/// 签名由 `osn_identity` 对包含该对象 JSON 的信封完成。
class Request {
  const Request({
    required this.requestId,
    required this.creatorId,
    required this.category,
    required this.title,
    this.description = '',
    this.origin,
    this.destination,
    required this.timeWindow,
    required this.price,
    required this.createdAt,
    required this.expiresAt,
    required this.nonce,
  });

  static const int schemaVersion = 1;

  final String requestId;
  final String creatorId;
  final RequestCategory category;
  final String title;
  final String description;
  final Place? origin;
  final Place? destination;
  final TimeWindow timeWindow;
  final Price price;
  final String createdAt;
  final String expiresAt;

  /// 16 字节随机数，无填充 base64url。
  final String nonce;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': schemaVersion,
    'request_id': requestId,
    'creator_id': creatorId,
    'category': category.wire,
    'title': title,
    'description': description,
    if (origin != null) 'origin': origin!.toJson(),
    if (destination != null) 'destination': destination!.toJson(),
    'time_window': timeWindow.toJson(),
    'price': price.toJson(),
    'created_at': createdAt,
    'expires_at': expiresAt,
    'nonce': nonce,
  };

  static Request fromJson(Object? input) {
    validateJsonValue(input, path: r'$');
    final map = _requireMap(input, r'$');

    final version = _requireInt(map, 'schema_version', r'$.schema_version');
    if (version != schemaVersion) {
      throw ProtocolException(
        ProtocolErrorCode.unsupportedSchemaVersion,
        '不支持的 Request schema_version=$version',
        field: r'$.schema_version',
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

    final creatorId = _requireString(map, 'creator_id', r'$.creator_id');
    validateDidKeyId(creatorId, field: r'$.creator_id');

    final categoryWire = _requireString(map, 'category', r'$.category');
    final category = RequestCategory.tryParse(categoryWire);
    if (category == null) {
      throw ProtocolException(
        ProtocolErrorCode.invalidField,
        '未知 category "$categoryWire"',
        field: r'$.category',
      );
    }

    final title = _requireString(map, 'title', r'$.title', maxRunes: 120);
    final description =
        _optionalString(map, 'description', r'$.description', maxRunes: 2000) ??
        '';

    final origin = map['origin'] == null
        ? null
        : Place.fromJson(map['origin'], path: r'$.origin');
    final destination = map['destination'] == null
        ? null
        : Place.fromJson(map['destination'], path: r'$.destination');

    final timeWindowRaw = map['time_window'];
    if (timeWindowRaw == null) {
      throw const ProtocolException(
        ProtocolErrorCode.missingField,
        'Request 缺少 time_window',
        field: r'$.time_window',
      );
    }
    final timeWindow = TimeWindow.fromJson(
      timeWindowRaw,
      path: r'$.time_window',
    );

    final priceRaw = map['price'];
    if (priceRaw == null) {
      throw const ProtocolException(
        ProtocolErrorCode.missingField,
        'Request 缺少 price',
        field: r'$.price',
      );
    }
    final price = Price.fromJson(priceRaw, path: r'$.price');

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

    final nonce = _requireString(map, 'nonce', r'$.nonce');
    final nonceBytes = _decodeNonce(nonce);

    return Request(
      requestId: requestId,
      creatorId: creatorId,
      category: category,
      title: title,
      description: description,
      origin: origin,
      destination: destination,
      timeWindow: timeWindow,
      price: price,
      createdAt: createdAt,
      expiresAt: expiresAt,
      nonce: encodeBase64UrlNoPad(nonceBytes),
    );
  }

  /// 生成一个随机的 UUID v4 风格 request_id。
  static String newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  /// 生成 16 字节 nonce（无填充 base64url）。
  static String newNonce() => encodeBase64UrlNoPad(_randomBytes(16));
}

Uint8List _decodeNonce(String nonce) {
  final Uint8List bytes;
  try {
    bytes = decodeBase64UrlNoPad(nonce, field: r'$.nonce');
  } on ProtocolException {
    throw const ProtocolException(
      ProtocolErrorCode.invalidField,
      'nonce 必须是 16 字节的无填充 base64url',
      field: r'$.nonce',
    );
  }
  if (bytes.length != 16) {
    throw const ProtocolException(
      ProtocolErrorCode.invalidField,
      'nonce 必须是 16 字节',
      field: r'$.nonce',
    );
  }
  return bytes;
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

String? _optionalString(
  Map<String, Object?> map,
  String key,
  String path, {
  int? maxRunes,
}) {
  if (!map.containsKey(key) || map[key] == null) {
    return null;
  }
  return _requireString(map, key, path, minRunes: 0, maxRunes: maxRunes);
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
  if (value < -maxSafeInteger || value > maxSafeInteger) {
    throw ProtocolException(
      ProtocolErrorCode.integerOutOfRange,
      '$key 超出安全整数范围',
      field: path,
    );
  }
  return value;
}

int? _optionalInt(Map<String, Object?> map, String key, String path) {
  if (!map.containsKey(key) || map[key] == null) {
    return null;
  }
  return _requireInt(map, key, path);
}

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}
