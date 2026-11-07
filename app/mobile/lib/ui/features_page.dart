import 'package:flutter/material.dart';

/// 应用内功能清单。
///
/// 这是"当前代码能做什么"的可见版本，不是产品承诺。
/// 权威细节仍以 `docs/ROADMAP.md`、`docs/TEST_PLAN.md` 与测试为准。
class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  static const title = '功能清单';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PeerServe 当前进度', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${_done.length} 项已完成 · ${_partial.length} 项部分完成 · '
                      '${_planned.length} 项计划中。'
                      '“部分完成”表示已有可运行切片，但还缺持久化、网络或完整业务流。',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '当前仍不能用于真实交易：签名只证明某把密钥签署了内容，'
                        '不证明现实履约。',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _FeatureGroup(
              title: '已完成',
              state: _FeatureState.done,
              items: _done,
            ),
            const SizedBox(height: 16),
            const _FeatureGroup(
              title: '部分完成',
              state: _FeatureState.partial,
              items: _partial,
            ),
            const SizedBox(height: 16),
            const _FeatureGroup(
              title: '计划中',
              state: _FeatureState.planned,
              items: _planned,
            ),
          ],
        ),
      ),
    );
  }
}

enum _FeatureState { done, partial, planned }

class _Feature {
  const _Feature({
    required this.title,
    required this.detail,
    required this.phase,
  });

  final String title;
  final String detail;
  final String phase;
}

const List<_Feature> _done = <_Feature>[
  _Feature(
    title: 'pub workspace 与单一 lockfile',
    detail: 'app/mobile + packages/osn_protocol + packages/osn_identity 统一解析。',
    phase: 'Phase 0.2',
  ),
  _Feature(
    title: '无浮点 JCS 子集',
    detail: '键排序、字符串转义、安全整数；浮点一律拒绝。',
    phase: 'Phase 0.2',
  ),
  _Feature(
    title: '严格 JSON 解析',
    detail: '拒绝重复键、浮点、超长、超深嵌套与孤立代理项。',
    phase: 'Phase 0.2',
  ),
  _Feature(
    title: '签名信封',
    detail: '域分离前缀 + 覆盖 sender_id / sent_at / payload 的签名字节。',
    phase: 'Phase 0.2',
  ),
  _Feature(
    title: 'Ed25519 与 did:key',
    detail: '纯 Dart 签名/验签、base58btc 身份标识、独立公钥解析。',
    phase: 'Phase 0.2',
  ),
  _Feature(
    title: '协议测试向量',
    detail: 'RFC 8032 TEST 1–3、JCS 用例、固定信封签名可复算。',
    phase: 'Phase 0.2',
  ),
  _Feature(
    title: 'Request v1 数据模型',
    detail: '类别、地点、时间窗、价格、过期时间与 nonce 的逐字段校验。',
    phase: 'Phase 0.2b',
  ),
  _Feature(
    title: '内存身份演示',
    detail: '生成临时身份、显示 did:key、篡改 payload 后验签失败。',
    phase: 'Phase 0.2',
  ),
  _Feature(
    title: '内存需求公告板',
    detail: '本机签名发布 Request 并立即验签；无网络、无持久化。',
    phase: 'Phase 0.2b',
  ),
];

const List<_Feature> _partial = <_Feature>[
  _Feature(
    title: '身份持久化与加密备份',
    detail: '当前身份只在内存；关闭页面即丢失，尚无 Keystore/加密导出。',
    phase: 'Phase 0.3 / 1',
  ),
  _Feature(
    title: '公告板 UI',
    detail: '已有签名列表与发布示例，但还没有分类筛选、搜索与详情编辑。',
    phase: 'Phase 3',
  ),
];

const List<_Feature> _planned = <_Feature>[
  _Feature(
    title: 'Offer / Agreement / Event / Review',
    detail: '响应、双方签署、事件链、完成确认与评价尚未实现。',
    phase: 'Phase 1',
  ),
  _Feature(
    title: 'SQLite 本地存储',
    detail: '重启后数据仍在；导入/导出逐条重新验签。',
    phase: 'Phase 0.3',
  ),
  _Feature(
    title: 'P2P 传输与二维码配对',
    detail: '两节点直连、重连、去重、限速与网络诊断。',
    phase: 'Phase 2',
  ),
  _Feature(title: '发现与缓存', detail: '摘要广播、TTL、跳数、可选缓存节点与撤回。', phase: 'Phase 4'),
  _Feature(
    title: '身份与数据导出',
    detail: '加密身份备份、JSON Lines 导出与导入拒绝报告。',
    phase: 'Phase 1',
  ),
  _Feature(
    title: '本地屏蔽与反垃圾',
    detail: '本地频率限制、大小限制、过期时间与节点屏蔽。',
    phase: 'Phase 2 / 3',
  ),
  _Feature(
    title: '可替换基础设施',
    detail: 'relay/bootstrap/STUN 可配置、可替换、可关闭。',
    phase: 'Phase 2',
  ),
];

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({
    required this.title,
    required this.state,
    required this.items,
  });

  final String title;
  final _FeatureState state;
  final List<_Feature> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (icon, color, label) = switch (state) {
      _FeatureState.done => (Icons.check_circle_outline, scheme.primary, '已完成'),
      _FeatureState.partial => (Icons.pending_outlined, scheme.tertiary, '部分'),
      _FeatureState.planned => (
        Icons.radio_button_unchecked,
        scheme.onSurfaceVariant,
        '计划',
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(title, style: textTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '$label · ${items.length}',
                    style: textTheme.labelSmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            for (final item in items)
              ListTile(
                dense: true,
                leading: Icon(icon, size: 18, color: color),
                title: Text(item.title, style: textTheme.bodyMedium),
                subtitle: Text(item.detail),
                trailing: Text(item.phase, style: textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}
