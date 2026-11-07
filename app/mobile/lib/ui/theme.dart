import 'package:flutter/material.dart';

/// 应用主题。
///
/// 设计取向：信息层级优先——"事实 / 单方声明 / 主观评价"必须能在视觉上区分，
/// 而不是靠颜色堆砌。Phase 0.1 只定义基础配色与排版。
abstract final class PeerServeTheme {
  /// 主色：低饱和的青绿，避免被误读为"完成/通过"的成功色。
  static const seedColor = Color(0xFF2F6F62);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
