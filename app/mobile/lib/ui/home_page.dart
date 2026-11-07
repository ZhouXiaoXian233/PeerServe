import 'package:flutter/material.dart';

/// 首页占位。
///
/// Phase 0.1 的职责只有两件：
/// 1. 让人一眼看出这是**什么项目**、现在到哪一步；
/// 2. 明确标出"哪些能力还不存在"，避免把设计文档当成已实现功能。
///
/// 所有禁用按钮都是有意的：不做假的成功路径。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const createIdentityButtonKey = Key('home.createIdentityButton');

  static const phaseLabel = 'Phase 0.1';
  static const titleText = '信约阁';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(titleText),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'PeerServe',
                style: TextStyle(fontSize: 12, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _IntroCard(textTheme: textTheme),
            const SizedBox(height: 16),
            _PlannedFeaturesCard(textTheme: textTheme),
            const SizedBox(height: 16),
            _BoundariesCard(textTheme: textTheme),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'v0.1.0 · MIT License · 无中心业务服务器',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 当前阶段与"这是骨架"的说明。
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: const Text(HomePage.phaseLabel),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: scheme.secondaryContainer,
                  side: BorderSide.none,
                ),
                const SizedBox(width: 8),
                Text('工程骨架', style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '一个无中心业务服务器的 P2P 需求公告板：'
              '用你自己的密钥发布需求、签署协议，并各自保存可验证的记录。',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '当前版本只有界面外壳：身份、签名、协议、数据库与 P2P 网络都尚未实现。'
                '它不能用于任何真实交易。',
                style: textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            const FilledButton(
              key: HomePage.createIdentityButtonKey,
              onPressed: null,
              child: Text('创建身份（Phase 1 起可用）'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 按阶段列出"将会出现"的能力，避免用户误以为只是自己没找到入口。
class _PlannedFeaturesCard extends StatelessWidget {
  const _PlannedFeaturesCard({required this.textTheme});

  final TextTheme textTheme;

  static const _items = <({IconData icon, String label, String phase})>[
    (icon: Icons.key_outlined, label: '创建本地身份与密钥备份', phase: 'Phase 1'),
    (icon: Icons.campaign_outlined, label: '发布需求公告（Request）', phase: 'Phase 1'),
    (icon: Icons.handshake_outlined, label: '响应与双方签署协议', phase: 'Phase 1'),
    (icon: Icons.timeline_outlined, label: '追加式事件与完成确认', phase: 'Phase 1'),
    (icon: Icons.devices_other_outlined, label: '两台设备直连', phase: 'Phase 2'),
    (icon: Icons.travel_explore_outlined, label: '附近公告发现与缓存', phase: 'Phase 4'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('开发路线', style: textTheme.titleSmall),
            ),
            for (final item in _items)
              ListTile(
                dense: true,
                leading: Icon(item.icon, size: 20),
                title: Text(item.label),
                trailing: Text(
                  item.phase,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 不可越过的设计边界——写在首页，因为它们是产品承诺而不是免责声明。
class _BoundariesCard extends StatelessWidget {
  const _BoundariesCard({required this.textTheme});

  final TextTheme textTheme;

  static const _items = <String>[
    '不托管资金、不担保履约：支付由双方约定的外部方式完成。',
    '评价是参与者的主观意见，不是系统裁定的事实。',
    '签名只证明"某把密钥签署了什么"，不证明现实一定发生。',
    '有争议陈述不代表对方有过错；系统不会自动处罚任何人。',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('设计边界', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final line in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· '),
                    Expanded(child: Text(line, style: textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
