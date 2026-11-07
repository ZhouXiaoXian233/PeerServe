import 'package:flutter/material.dart';

import 'ui/home_page.dart';
import 'ui/theme.dart';

/// 应用根组件。
///
/// Phase 0.1 只装配主题与首页；身份、协议、存储与网络模块尚不存在，
/// 因此这里**没有** Provider / 依赖注入容器——等第一个真实模块出现时再加入，
/// 避免为了"架构完整"制造空抽象。
class PeerServeApp extends StatelessWidget {
  const PeerServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeerServe · 信约阁',
      debugShowCheckedModeBanner: false,
      theme: PeerServeTheme.light,
      darkTheme: PeerServeTheme.dark,
      home: const HomePage(),
    );
  }
}
