import 'errors.dart';

final RegExp _utcMillisPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{3})Z$',
);

/// 校验并返回 UTC ISO-8601 毫秒时间戳字符串。
///
/// 协议统一使用 `YYYY-MM-DDTHH:mm:ss.sssZ`，避免本地时区与精度歧义。
String requireUtcTimestamp(Object? value, {required String field}) {
  if (value is! String) {
    throw ProtocolException(
      ProtocolErrorCode.invalidTimestamp,
      '时间戳必须是字符串',
      field: field,
    );
  }
  final match = _utcMillisPattern.firstMatch(value);
  if (match == null) {
    throw ProtocolException(
      ProtocolErrorCode.invalidTimestamp,
      '时间戳必须形如 2026-11-07T04:30:00.000Z',
      field: field,
    );
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  final millisecond = int.parse(match.group(7)!);

  if (month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31 ||
      hour > 23 ||
      minute > 59 ||
      second > 59) {
    throw ProtocolException(
      ProtocolErrorCode.invalidTimestamp,
      '时间戳字段超出合法范围',
      field: field,
    );
  }

  // DateTime.utc 会把 2026-13-07 之类的输入归一化；回读组件才能拒绝它。
  final parsed = DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
    millisecond,
  );
  if (parsed.year != year ||
      parsed.month != month ||
      parsed.day != day ||
      parsed.hour != hour ||
      parsed.minute != minute ||
      parsed.second != second ||
      parsed.millisecond != millisecond) {
    throw ProtocolException(
      ProtocolErrorCode.invalidTimestamp,
      '时间戳不是真实存在的 UTC 日期',
      field: field,
    );
  }
  return value;
}

/// 把 `DateTime` 格式化为协议规定的 UTC 毫秒时间戳。
String formatUtcTimestamp(DateTime value) {
  final iso = value.toUtc().toIso8601String();
  // Dart 的 toIso8601String 在微秒非零时会输出 6 位小数；协议固定 3 位。
  return '${iso.substring(0, 23)}Z';
}

/// 当前时刻的协议时间戳。
String nowUtcTimestamp() => formatUtcTimestamp(DateTime.now().toUtc());
