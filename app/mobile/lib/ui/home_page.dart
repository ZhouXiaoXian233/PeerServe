import 'package:flutter/material.dart';

import '../app_session.dart';
import 'identity_page.dart';
import 'profile_page.dart';
import 'requests_page.dart';

/// 首页：主操作、最近需求与本机身份。
///
/// 技术细节只在 debug 构建的“开发者详情”里；首页不展示路线图或长篇说明。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const publishButtonKey = Key('home.publish');
  static const browseButtonKey = Key('home.browse');
  static const identityTileKey = Key('home.identity');
  static const profileButtonKey = Key('home.profile');

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('信约阁'),
        actions: [
          ListenableBuilder(
            listenable: session,
            builder: (context, child) {
              return IconButton(
                key: profileButtonKey,
                tooltip: '个人中心',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfilePage(),
                    ),
                  );
                },
                icon: CircleAvatar(
                  radius: 18,
                  child: Text(
                    session.profile.avatar,
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, child) {
            final textTheme = Theme.of(context).textTheme;
            final recent = session.requests.take(2).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                _HeroCard(
                  nickname: session.profile.nickname,
                  requestCount: session.requests.length,
                  onPublish: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RequestsPage(openComposer: true),
                      ),
                    );
                  },
                  onBrowse: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RequestsPage(),
                      ),
                    );
                  },
                ),
                if (session.bootstrapError != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        session.bootstrapError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                Row(
                  children: [
                    Text('最近需求', style: textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      key: browseButtonKey,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RequestsPage(),
                          ),
                        );
                      },
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '还没有需求。发布第一条，或者稍后查看示例。',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  for (final item in recent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HomeRequestTile(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RequestsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                const SizedBox(height: 18),
                _IdentityTile(
                  session: session,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const IdentityPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const _LimitNotice(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.nickname,
    required this.requestCount,
    required this.onPublish,
    required this.onBrowse,
  });

  final String nickname;
  final int requestCount;
  final VoidCallback onPublish;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            const Color(0xFF2F7A63),
            const Color(0xFF3F8A70),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '你好，$nickname',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今天，帮个忙？',
            style: textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimary,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '发布一条附近的小需求，签名后各自留证。'
            '没有中心服务器，也没有平台替你裁决。',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: HomePage.publishButtonKey,
              onPressed: onPublish,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.onPrimary,
                foregroundColor: scheme.primary,
              ),
              icon: const Icon(Icons.add),
              label: const Text('发布需求'),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onBrowse,
              style: TextButton.styleFrom(foregroundColor: scheme.onPrimary),
              icon: const Icon(Icons.explore_outlined),
              label: Text(requestCount == 0 ? '浏览需求' : '浏览 $requestCount 条需求'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeRequestTile extends StatelessWidget {
  const _HomeRequestTile({required this.item, required this.onTap});

  final SignedRequest item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final request = item.request;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.secondaryContainer,
                child: Text(
                  item.authorAvatar,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium,
                          ),
                        ),
                        if (item.isSample)
                          Text(
                            '示例',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.origin?.label ?? '未指定'} → '
                      '${request.destination?.label ?? '未指定'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(request.price.amountMinor),
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityTile extends StatelessWidget {
  const _IdentityTile({required this.session, required this.onTap});

  final AppSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final identity = session.identity;

    if (identity == null) {
      return Card(
        child: ListTile(
          leading: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text(session.identityError ?? '正在生成本机身份…'),
        ),
      );
    }

    return Card(
      child: ListTile(
        key: HomePage.identityTileKey,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(Icons.key_outlined, color: scheme.onSecondaryContainer),
        ),
        title: const Text('本机身份'),
        subtitle: Text(
          identity.identityId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _LimitNotice extends StatelessWidget {
  const _LimitNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '当前为内存演示：重启后身份与需求会丢失，不能用于真实交易。',
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAmount(int amountMinor) {
  final major = amountMinor ~/ 100;
  final cents = (amountMinor % 100).toString().padLeft(2, '0');
  return 'CNY $major.$cents';
}
