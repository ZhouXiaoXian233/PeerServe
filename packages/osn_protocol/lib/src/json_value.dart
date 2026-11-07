import 'dart:collection';

import 'errors.dart';

/// 协议层允许的最大 JSON 嵌套深度。
const int maxJsonDepth = 32;

/// IEEE-754 双精度能精确表示的整数上界（2^53 - 1）。
///
/// 超过这个范围的整数在 JCS / ECMAScript 中会丢精度，因此协议层直接拒绝。
const int maxSafeInteger = 9007199254740991;

/// 校验一个已解析的 JSON 值是否满足协议允许的值域。
///
/// 允许：`null`、`bool`、安全的 `int`、合法 Unicode 的 `String`、
/// `List`、以及键全为 `String` 的 `Map`。
/// 拒绝：`double`（协议层禁浮点）、超范围整数、孤立代理项、循环引用。
void validateJsonValue(Object? value, {String path = r'$'}) {
  _validate(value, path, 0, HashSet<Object>.identity());
}

void _validate(
  Object? value,
  String path,
  int depth,
  Set<Object> activeContainers,
) {
  if (depth > maxJsonDepth) {
    throw ProtocolException(
      ProtocolErrorCode.depthExceeded,
      'JSON 嵌套超过 $maxJsonDepth 层',
      field: path,
    );
  }

  if (value == null || value is bool) {
    return;
  }
  if (value is String) {
    _validateUnicodeScalarString(value, path);
    return;
  }
  if (value is int) {
    if (value < -maxSafeInteger || value > maxSafeInteger) {
      throw ProtocolException(
        ProtocolErrorCode.integerOutOfRange,
        '整数超出安全范围 [-$maxSafeInteger, $maxSafeInteger]',
        field: path,
      );
    }
    return;
  }
  if (value is double) {
    throw ProtocolException(
      ProtocolErrorCode.floatNotAllowed,
      '协议层禁止浮点数；金额用最小单位整数，经纬度用 1e-7 整数',
      field: path,
    );
  }
  if (value is List) {
    _enter(value, path, activeContainers);
    for (var index = 0; index < value.length; index++) {
      _validate(value[index], '$path[$index]', depth + 1, activeContainers);
    }
    activeContainers.remove(value);
    return;
  }
  if (value is Map) {
    _enter(value, path, activeContainers);
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ProtocolException(
          ProtocolErrorCode.invalidField,
          'JSON 对象键必须是字符串，实际为 ${key.runtimeType}',
          field: path,
        );
      }
      _validateUnicodeScalarString(key, '$path.<key>');
      _validate(entry.value, '$path.$key', depth + 1, activeContainers);
    }
    activeContainers.remove(value);
    return;
  }

  throw ProtocolException(
    ProtocolErrorCode.invalidPayload,
    '不支持的值类型 ${value.runtimeType}',
    field: path,
  );
}

void _enter(Object container, String path, Set<Object> activeContainers) {
  if (!activeContainers.add(container)) {
    throw ProtocolException(
      ProtocolErrorCode.invalidPayload,
      '检测到循环引用；JSON 不允许循环结构',
      field: path,
    );
  }
}

void _validateUnicodeScalarString(String value, String path) {
  for (var index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
      final next = index + 1 < value.length ? value.codeUnitAt(index + 1) : -1;
      if (next < 0xDC00 || next > 0xDFFF) {
        throw ProtocolException(
          ProtocolErrorCode.invalidUnicode,
          '字符串包含孤立的高代理项 U+${codeUnit.toRadixString(16)}',
          field: path,
        );
      }
      index++;
    } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
      throw ProtocolException(
        ProtocolErrorCode.invalidUnicode,
        '字符串包含孤立的低代理项 U+${codeUnit.toRadixString(16)}',
        field: path,
      );
    }
  }
}
