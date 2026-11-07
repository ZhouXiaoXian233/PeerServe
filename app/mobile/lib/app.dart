import 'package:flutter/material.dart';

import 'ui/home_page.dart';
import 'ui/theme.dart';

/// 应用根组件。
///
/// Phase 0.2 装配主题、首页与内存身份演示页。
/// 身份目前没有持久化，也没有依赖注入容器；等存储层出现时再加入。
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
