import 'package:flutter/material.dart';

import '../app_session.dart';
import 'identity_page.dart';
import 'profile_page.dart';
import 'requests_page.dart';

/// 首页：只保留主操作、需求入口与个人中心。
///
/// 技术细节（公钥、规范化 JSON、签名）放在 debug 构建的“开发者详情”里，
/// 首页不展示路线图、功能清单或长篇边界说明。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const publishButtonKey = Key('home.publish');
  static const browseButtonKey = Key('home.browse');
  static const identityTileKey = Key('home.identity');
  static const profileButtonKey = Key('home.profile');

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final textTheme = Theme.of(context).textTheme;

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
                  radius: 16,
                  child: Text(
                    session.profile.avatar,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
          const Padding(
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
        child: ListenableBuilder(
          listenable: session,
          builder: (context, child) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const SizedBox(height: 12),
                Text(
                  '你好，${session.profile.nickname}',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '附近的小协作，\n自己约定，自己留证。',
                  style: textTheme.headlineMedium?.copyWith(
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '用本机身份发布需求，签名并保存可验证的记录。'
                  '没有中心服务器，也没有平台替你裁决。',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  key: publishButtonKey,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RequestsPage(openComposer: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('发布需求'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: browseButtonKey,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RequestsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_outlined),
                  label: Text(
                    session.requests.isEmpty
                        ? '查看需求'
                        : '查看需求（${session.requests.length}）',
                  ),
                ),
                const SizedBox(height: 28),
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
                const SizedBox(height: 24),
                const _LimitNotice(),
              ],
            );
          },
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
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
