import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:osn_protocol/osn_protocol.dart';

import '../app_session.dart';

/// 本机需求列表。数据来自 [AppSession]，只在内存中。
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key, this.openComposer = false});

  static const publishButtonKey = Key('requests.publish');
  static const emptyPublishButtonKey = Key('requests.emptyPublish');
  static const emptyStateKey = Key('requests.empty');
  static const titleFieldKey = Key('requests.title');
  static const submitButtonKey = Key('requests.submit');

  final bool openComposer;

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  bool _didOpenComposer = false;

  @override
  void initState() {
    super.initState();
    if (widget.openComposer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didOpenComposer) {
          return;
        }
        _didOpenComposer = true;
        _openComposer();
      });
    }
  }

  Future<void> _openComposer() {
    final session = AppScope.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PublishSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('本机需求')),
      floatingActionButton: FloatingActionButton.extended(
        key: RequestsPage.publishButtonKey,
        onPressed: _openComposer,
        icon: const Icon(Icons.add),
        label: const Text('发布需求'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, child) {
            if (session.requests.isEmpty) {
              return Center(
                key: RequestsPage.emptyStateKey,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text('还没有需求', style: textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        '发布一条本机需求，签名后立即验证。',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: RequestsPage.emptyPublishButtonKey,
                        onPressed: _openComposer,
                        child: const Text('发布第一条需求'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    _listSummary(session.requests),
                    style: textTheme.bodySmall,
                  ),
                ),
                for (final item in session.requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(item: item),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});

  final SignedRequest item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final request = item.request;
    final canonical = canonicalize(item.envelope.signingPayload());

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  child: Text(
                    item.authorAvatar,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Text(item.authorLabel, style: textTheme.labelMedium),
                if (item.isSample) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('示例'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.tertiaryContainer,
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(request.title, style: textTheme.titleMedium),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_categoryLabel(request.category)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: scheme.secondaryContainer,
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_formatAmount(request.price), style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '${request.origin?.label ?? '未指定起点'} → '
              '${request.destination?.label ?? '未指定终点'}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '有效至 ${_shortTime(request.expiresAt)} UTC',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  item.verified ? Icons.verified_outlined : Icons.error_outline,
                  size: 16,
                  color: item.verified ? scheme.primary : scheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  item.verified ? '签名已在本机验证' : '验签失败',
                  style: textTheme.labelSmall?.copyWith(
                    color: item.verified ? scheme.primary : scheme.error,
                  ),
                ),
              ],
            ),
            if (kDebugMode)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: Text('技术详情', style: textTheme.labelLarge),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      'request_id: ${request.requestId}\n'
                      'signature: ${item.envelope.signature}',
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      canonical,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PublishSheet extends StatefulWidget {
  const _PublishSheet({required this.session});

  final AppSession session;

  @override
  State<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<_PublishSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController(text: '50');
  final _description = TextEditingController();
  late final TextEditingController _origin;
  late final TextEditingController _destination;
  RequestCategory _category = RequestCategory.delivery;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.session.profile;
    _origin = TextEditingController(text: profile.defaultOrigin);
    _destination = TextEditingController(text: profile.defaultDestination);
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _origin.dispose();
    _destination.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final priceMinor = _parsePrice(_price.text);
    if (priceMinor == null) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.session.publish(
        title: _title.text.trim(),
        category: _category,
        priceMinor: priceMinor,
        description: _description.text.trim(),
        originLabel: _origin.text,
        destinationLabel: _destination.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error is ProtocolException
              ? '发布失败（${error.code.wire}）：${error.message}'
              : '发布失败：$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('发布需求', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('签名后立即在本机验证；不会联网。', style: textTheme.bodySmall),
              const SizedBox(height: 16),
              TextFormField(
                key: RequestsPage.titleFieldKey,
                controller: _title,
                maxLength: 120,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '需求标题',
                  hintText: '例如：从图书馆带一本书',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请填写标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RequestCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: '类别'),
                items: [
                  for (final category in RequestCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(_categoryLabel(category)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '预算（CNY）',
                  helperText: '只接受最多两位小数；协议层存整数分',
                ),
                validator: (value) {
                  if (_parsePrice(value ?? '') == null) {
                    return '请输入合法金额，例如 50 或 50.00';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _origin,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: '起点（可选）',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _destination,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: '终点（可选）',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                maxLength: 2000,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '补充说明（可选）',
                  counterText: '',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: RequestsPage.submitButtonKey,
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('签名发布'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int? _parsePrice(String input) {
  final match = RegExp(r'^(\d{1,15})(?:\.(\d{1,2}))?$')
      .firstMatch(input.trim());
  if (match == null) {
    return null;
  }
  final major = int.parse(match.group(1)!);
  final cents = (match.group(2) ?? '').padRight(2, '0');
  final amount = major * 100 + int.parse(cents);
  if (amount > maxSafeInteger) {
    return null;
  }
  return amount;
}

String _categoryLabel(RequestCategory category) => switch (category) {
  RequestCategory.ride => '出行',
  RequestCategory.delivery => '带物',
  RequestCategory.food => '餐饮',
  RequestCategory.errand => '跑腿',
  RequestCategory.other => '其他',
};

String _listSummary(List<SignedRequest> items) {
  final samples = items.where((item) => item.isSample).length;
  if (samples == 0) {
    return '${items.length} 条 · 只保存在这台设备的内存中';
  }
  return '${items.length} 条 · 含 $samples 条示例数据，仅用于演示';
}

String _formatAmount(Price price) {
  final major = price.amountMinor ~/ 100;
  final cents = (price.amountMinor % 100).toString().padLeft(2, '0');
  return '${price.currency} $major.$cents';
}

String _shortTime(String timestamp) => timestamp.substring(11, 16);
