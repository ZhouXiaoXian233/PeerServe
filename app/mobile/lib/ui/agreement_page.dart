import 'package:flutter/material.dart';

import '../app_session.dart';

/// 协议详情：条款、双方签署状态与模拟对方签署入口。
class AgreementPage extends StatefulWidget {
  const AgreementPage({super.key, required this.agreementId});

  static const statusChipKey = Key('agreement.status');
  static const providerSignButtonKey = Key('agreement.providerSign');

  final String agreementId;

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool _signing = false;
  String? _error;

  Future<void> _simulateProviderSign() async {
    final session = AppScope.of(context);
    final agreement = _find(session);
    if (agreement == null || _signing) {
      return;
    }
    setState(() {
      _signing = true;
      _error = null;
    });
    try {
      await session.simulateProviderAccept(agreement);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _signing = false;
          _error = '签署失败：$error';
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _signing = false);
    }
  }

  SignedAgreement? _find(AppSession session) {
    for (final agreement in session.agreements) {
      if (agreement.agreement.agreementId == widget.agreementId) {
        return agreement;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('协议')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, child) {
            final agreement = _find(session);
            if (agreement == null) {
              return const Center(child: Text('协议不存在或已被清除'));
            }
            return _AgreementBody(
              agreement: agreement,
              signing: _signing,
              error: _error,
              onProviderSign: _simulateProviderSign,
            );
          },
        ),
      ),
    );
  }
}

class _AgreementBody extends StatelessWidget {
  const _AgreementBody({
    required this.agreement,
    required this.signing,
    required this.error,
    required this.onProviderSign,
  });

  final SignedAgreement agreement;
  final bool signing;
  final String? error;
  final VoidCallback onProviderSign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = agreement.agreement;
    final signed = agreement.mutuallySigned;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      key: AgreementPage.statusChipKey,
                      label: Text(signed ? '双方已签署' : '等待对方签署'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: signed
                          ? scheme.primaryContainer
                          : scheme.secondaryContainer,
                      side: BorderSide.none,
                    ),
                    const Spacer(),
                    Text(
                      _formatAmount(value.agreedPriceMinor, value.currency),
                      style: textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(value.serviceTerms, style: textTheme.bodyLarge),
                const SizedBox(height: 16),
                _PartyRow(
                  label: '需求方',
                  did: value.requesterId,
                  verified: agreement.requesterVerified,
                ),
                const SizedBox(height: 8),
                _PartyRow(
                  label: '响应方',
                  did: value.providerId,
                  verified: agreement.providerVerified,
                ),
                const SizedBox(height: 8),
                Text(
                  '创建于 ${value.createdAt} · 有效至 ${value.expiresAt}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('约定条件', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                _Condition(label: '开始', value: value.startConditions),
                _Condition(label: '完成', value: value.completionConditions),
                _Condition(label: '取消', value: value.cancellationTerms),
              ],
            ),
          ),
        ),
        if (!signed) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('等待签署', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    agreement.canSimulateProvider
                        ? '这是本机演示：可让模拟响应方对同一份协议签名。'
                        : '需要对方在自己的设备上签名后才能标记为双方已签署。',
                    style: textTheme.bodySmall,
                  ),
                  if (agreement.canSimulateProvider) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: AgreementPage.providerSignButtonKey,
                        onPressed: signing ? null : onProviderSign,
                        child: signing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('模拟对方签署（演示）'),
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: textTheme.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('协议只证明双方密钥签署了这份条款，不证明现实一定履约。', style: textTheme.bodySmall),
      ],
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.label,
    required this.did,
    required this.verified,
  });

  final String label;
  final String did;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          verified ? Icons.verified_outlined : Icons.pending_outlined,
          size: 16,
          color: verified ? scheme.primary : scheme.outline,
        ),
        const SizedBox(width: 6),
        Text('$label：', style: textTheme.labelMedium),
        Expanded(
          child: Text(
            _shortDid(did),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        Text(verified ? '已签署' : '未签署', style: textTheme.labelSmall),
      ],
    );
  }
}

class _Condition extends StatelessWidget {
  const _Condition({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 40, child: Text(label, style: textTheme.labelMedium)),
          Expanded(child: Text(value, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}

String _shortDid(String did) {
  if (did.length <= 28) {
    return did;
  }
  return '${did.substring(0, 18)}…${did.substring(did.length - 8)}';
}

String _formatAmount(int amountMinor, String currency) {
  final major = amountMinor ~/ 100;
  final cents = (amountMinor % 100).toString().padLeft(2, '0');
  return '$currency $major.$cents';
}
