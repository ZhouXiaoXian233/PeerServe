import 'dart:convert';
import 'dart:typed_data';

import 'json_value.dart';

/// RFC 8785（JCS）规范化，限协议允许的值域。
///
/// 与通用 JCS 实现的区别只有一个：**浮点数直接拒绝**。
/// 这是 ADR-009 的决定，用来规避 ECMAScript 数字格式化在不同语言间的差异。
/// 对协议允许的 `int` / `string` / `bool` / `null` / `array` / `object`，
/// 输出与 RFC 8785 一致。
String canonicalize(Object? value) {
  validateJsonValue(value);
  final output = StringBuffer();
  _writeValue(output, value);
  return output.toString();
}

/// 规范化并编码为 UTF-8 字节，供签名使用。
Uint8List canonicalizeUtf8(Object? value) =>
    Uint8List.fromList(utf8.encode(canonicalize(value)));

void _writeValue(StringBuffer output, Object? value) {
  if (value == null) {
    output.write('null');
  } else if (value is bool) {
    output.write(value ? 'true' : 'false');
  } else if (value is int) {
    output.write(value);
  } else if (value is String) {
    _writeString(output, value);
  } else if (value is List) {
    output.write('[');
    for (var index = 0; index < value.length; index++) {
      if (index > 0) {
        output.write(',');
      }
      _writeValue(output, value[index]);
    }
    output.write(']');
  } else if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    output.write('{');
    for (var index = 0; index < keys.length; index++) {
      if (index > 0) {
        output.write(',');
      }
      _writeString(output, keys[index]);
      output.write(':');
      _writeValue(output, value[keys[index]]);
    }
    output.write('}');
  } else {
    // validateJsonValue 已经拦截所有其他类型；这里只是防御性兜底。
    throw StateError('canonicalize 收到未校验的类型 ${value.runtimeType}');
  }
}

const Map<int, String> _shortEscapes = <int, String>{
  0x08: r'\b',
  0x09: r'\t',
  0x0A: r'\n',
  0x0C: r'\f',
  0x0D: r'\r',
  0x22: r'\"',
  0x5C: r'\\',
};

void _writeString(StringBuffer output, String value) {
  output.write('"');
  for (var index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    final shortEscape = _shortEscapes[codeUnit];
    if (shortEscape != null) {
      output.write(shortEscape);
    } else if (codeUnit < 0x20) {
      output
        ..write(r'\u')
        ..write(codeUnit.toRadixString(16).padLeft(4, '0'));
    } else {
      // 非 ASCII 字符按 UTF-8 原样输出；JCS 不做 \u 转义。
      output.writeCharCode(codeUnit);
    }
  }
  output.write('"');
}
