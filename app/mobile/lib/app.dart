import 'dart:async';

import 'package:flutter/material.dart';

import 'app_session.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';

/// 应用根组件。
///
/// 本机身份与需求由一个 [AppSession] 持有，页面通过 [AppScope] 共享。
/// 会话只在内存中；持久化属于 Phase 0.3。
class PeerServeApp extends StatefulWidget {
  const PeerServeApp({super.key});

  @override
  State<PeerServeApp> createState() => _PeerServeAppState();
}

class _PeerServeAppState extends State<PeerServeApp> {
  late final AppSession _session;

  @override
  void initState() {
    super.initState();
    _session = AppSession();
    unawaited(_session.bootstrap());
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: _session,
      child: MaterialApp(
        title: 'PeerServe · 信约阁',
        debugShowCheckedModeBanner: false,
        theme: PeerServeTheme.light,
        darkTheme: PeerServeTheme.dark,
        home: const HomePage(),
      ),
    );
  }
}
