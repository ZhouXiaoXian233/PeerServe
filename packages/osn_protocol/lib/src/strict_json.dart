import 'dart:convert';

import 'errors.dart';
import 'json_value.dart';
import 'limits.dart';

/// 严格解析一条协议 JSON 文本。
///
/// 在 `jsonDecode` 之外补齐协议层要求：
/// - UTF-8 大小上限（默认 64 KiB）；
/// - 拒绝重复键（`jsonDecode` 默认后者覆盖前者）；
/// - 拒绝浮点数与超范围整数；
/// - 拒绝孤立代理项、循环结构与过深嵌套。
Object? parseStrictJson(
  String source, {
  int maxBytes = maxProtocolMessageBytes,
}) {
  final byteLength = utf8.encode(source).length;
  if (byteLength > maxBytes) {
    throw ProtocolException(
      ProtocolErrorCode.messageTooLarge,
      '消息 $byteLength 字节，超过上限 $maxBytes 字节',
    );
  }

  _DuplicateKeyScanner(source).scan();

  Object? value;
  try {
    value = jsonDecode(source);
  } on FormatException catch (error) {
    throw ProtocolException(
      ProtocolErrorCode.invalidJson,
      'JSON 解析失败：${error.message}',
    );
  }
  validateJsonValue(value);
  return value;
}

/// 只做结构扫描：检测重复键，并在 `jsonDecode` 之前限制嵌套深度。
///
/// 不负责完整语法校验；语法错误仍由 `jsonDecode` 报告。
class _DuplicateKeyScanner {
  _DuplicateKeyScanner(this.source);

  final String source;
  int _index = 0;

  void scan() {
    _skipWhitespace();
    _scanValue(0);
    _skipWhitespace();
    if (_index != source.length) {
      _fail('JSON 结束后存在多余内容');
    }
  }

  void _scanValue(int depth) {
    if (depth > maxJsonDepth) {
      throw const ProtocolException(
        ProtocolErrorCode.depthExceeded,
        'JSON 嵌套超过 $maxJsonDepth 层',
      );
    }
    _skipWhitespace();
    if (_index >= source.length) {
      _fail('期望一个 JSON 值，但已到结尾');
    }
    final codeUnit = source.codeUnitAt(_index);
    if (codeUnit == 0x7B) {
      _scanObject(depth + 1);
    } else if (codeUnit == 0x5B) {
      _scanArray(depth + 1);
    } else if (codeUnit == 0x22) {
      _scanString();
    } else {
      _scanLiteral();
    }
  }

  void _scanObject(int depth) {
    _index++; // {
    _skipWhitespace();
    if (_index < source.length && source.codeUnitAt(_index) == 0x7D) {
      _index++;
      return;
    }

    final seen = <String>{};
    while (true) {
      _skipWhitespace();
      if (_index >= source.length || source.codeUnitAt(_index) != 0x22) {
        _fail('对象键必须是字符串');
      }
      final start = _index;
      _scanString();
      final rawKey = source.substring(start, _index);
      String key;
      try {
        key = jsonDecode(rawKey) as String;
      } on FormatException {
        _fail('对象键不是合法 JSON 字符串');
      }
      if (!seen.add(key)) {
        throw ProtocolException(
          ProtocolErrorCode.duplicateKey,
          '对象包含重复键 "$key"',
          field: key,
        );
      }

      _skipWhitespace();
      if (_index >= source.length || source.codeUnitAt(_index) != 0x3A) {
        _fail('对象键后缺少冒号');
      }
      _index++;
      _scanValue(depth);
      _skipWhitespace();
      if (_index >= source.length) {
        _fail('对象未闭合');
      }
      final separator = source.codeUnitAt(_index);
      if (separator == 0x2C) {
        _index++;
        continue;
      }
      if (separator == 0x7D) {
        _index++;
        return;
      }
      _fail('对象成员之间缺少逗号或右花括号');
    }
  }

  void _scanArray(int depth) {
    _index++; // [
    _skipWhitespace();
    if (_index < source.length && source.codeUnitAt(_index) == 0x5D) {
      _index++;
      return;
    }

    while (true) {
      _scanValue(depth);
      _skipWhitespace();
      if (_index >= source.length) {
        _fail('数组未闭合');
      }
      final separator = source.codeUnitAt(_index);
      if (separator == 0x2C) {
        _index++;
        continue;
      }
      if (separator == 0x5D) {
        _index++;
        return;
      }
      _fail('数组元素之间缺少逗号或右方括号');
    }
  }

  void _scanString() {
    if (_index >= source.length || source.codeUnitAt(_index) != 0x22) {
      _fail('期望字符串起始引号');
    }
    _index++;
    while (_index < source.length) {
      final codeUnit = source.codeUnitAt(_index);
      if (codeUnit == 0x22) {
        _index++;
        return;
      }
      if (codeUnit == 0x5C) {
        _index++;
        if (_index >= source.length) {
          break;
        }
        if (source.codeUnitAt(_index) == 0x75) {
          _index += 5;
        } else {
          _index++;
        }
        continue;
      }
      _index++;
    }
    _fail('字符串未闭合');
  }

  void _scanLiteral() {
    final start = _index;
    while (_index < source.length && !_isDelimiter(source.codeUnitAt(_index))) {
      _index++;
    }
    if (_index == start) {
      _fail('非法 JSON 值');
    }
  }

  void _skipWhitespace() {
    while (_index < source.length) {
      final codeUnit = source.codeUnitAt(_index);
      if (codeUnit != 0x20 &&
          codeUnit != 0x09 &&
          codeUnit != 0x0A &&
          codeUnit != 0x0D) {
        return;
      }
      _index++;
    }
  }

  bool _isDelimiter(int codeUnit) =>
      codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D ||
      codeUnit == 0x2C ||
      codeUnit == 0x5D ||
      codeUnit == 0x7D;

  Never _fail(String message) {
    throw ProtocolException(ProtocolErrorCode.invalidJson, message);
  }
}
