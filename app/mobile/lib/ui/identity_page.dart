import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:osn_identity/osn_identity.dart';
import 'package:osn_protocol/osn_protocol.dart';

import '../app_session.dart';

/// 本机身份页。
///
/// 主视图只显示身份状态与必要操作；公钥、签名、规范化 JSON 与篡改测试
/// 都收进“开发者详情”，避免把技术细节塞给普通用户。
class IdentityPage extends StatefulWidget {
  const IdentityPage({super.key});

  static const statusChipKey = Key('identity.status');
  static const tamperButtonKey = Key('identity.tamper');
  static const tamperedStatusKey = Key('identity.tamperedStatus');

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  Envelope? _demoEnvelope;
  Envelope? _tamperedEnvelope;
  bool? _tamperedVerified;
  bool _demoRunning = false;

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新生成身份？'),
        content: const Text('这会清空本机需求，并丢弃当前身份的私钥。此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('重新生成'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await AppScope.of(context).regenerateIdentity();
    if (!mounted) {
      return;
    }
    setState(() {
      _demoEnvelope = null;
      _tamperedEnvelope = null;
      _tamperedVerified = null;
    });
  }

  Future<void> _runTamperDemo() async {
    final identity = AppScope.of(context).identity;
    if (identity == null || _demoRunning) {
      return;
    }
    setState(() => _demoRunning = true);
    final now = formatUtcTimestamp(DateTime.now().toUtc());
    final envelope = await identity.signEnvelope(
      type: MessageType.requestCreated,
      sentAt: now,
      payload: <String, Object?>{
        'title': '签名演示',
        'price': <String, Object?>{'amount_minor': 5000, 'currency': 'CNY'},
      },
    );
    final changedPayload = Map<String, Object?>.from(envelope.payload)
      ..['title'] = '被篡改的标题';
    final tampered = Envelope(
      type: envelope.type,
      payload: changedPayload,
      senderId: envelope.senderId,
      sentAt: envelope.sentAt,
      signature: envelope.signature,
    );
    final tamperedVerified = await verifyEnvelopeSignature(tampered);
    if (!mounted) {
      return;
    }
    setState(() {
      _demoEnvelope = envelope;
      _tamperedEnvelope = tampered;
      _tamperedVerified = tamperedVerified;
      _demoRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('本机身份')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, child) {
            final identity = session.identity;
            final textTheme = Theme.of(context).textTheme;

            if (identity == null) {
              return Center(
                child: session.identityError == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(session.identityError!),
                      ),
              );
            }

            final publicKeyHex = identity.publicKey
                .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
                .join();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              key: IdentityPage.statusChipKey,
                              label: const Text('身份已就绪'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              side: BorderSide.none,
                            ),
                            const Spacer(),
                            const Text('仅内存', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('身份标识', style: textTheme.labelMedium),
                        const SizedBox(height: 4),
                        SelectableText(
                          identity.identityId,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '私钥只保存在本机内存，不显示、不导出、不写日志。'
                          '关闭应用或重新生成后无法恢复。',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _regenerate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新生成身份'),
                ),
                const SizedBox(height: 24),
                if (kDebugMode)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('开发者详情'),
                    subtitle: const Text('公钥、签名与篡改验签测试'),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ed25519 公钥（hex）',
                                style: textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                publicKeyHex,
                                style: textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.tonalIcon(
                                key: IdentityPage.tamperButtonKey,
                                onPressed: _demoRunning ? null : _runTamperDemo,
                                icon: const Icon(Icons.science_outlined),
                                label: const Text('运行篡改验签测试'),
                              ),
                              if (_tamperedEnvelope != null) ...[
                                const SizedBox(height: 12),
                                Chip(
                                  key: IdentityPage.tamperedStatusKey,
                                  label: Text(
                                    _tamperedVerified == true
                                        ? '篡改后仍然通过（异常）'
                                        : '篡改后验签失败（符合预期）',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: _tamperedVerified == true
                                      ? Theme.of(context)
                                            .colorScheme
                                            .errorContainer
                                      : Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                  side: BorderSide.none,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '签名：${_demoEnvelope!.signature}',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SelectableText(
                                    canonicalize(
                                      _demoEnvelope!.signingPayload(),
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
