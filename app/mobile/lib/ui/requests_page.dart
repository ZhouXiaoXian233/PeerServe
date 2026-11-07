import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:osn_protocol/osn_protocol.dart';

import '../app_session.dart';
import 'agreement_page.dart';

/// 本机需求列表。数据来自 [AppSession]，只在内存中。
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key, this.openComposer = false});

  static const publishButtonKey = Key('requests.publish');
  static const emptyPublishButtonKey = Key('requests.emptyPublish');
  static const emptyStateKey = Key('requests.empty');
  static const titleFieldKey = Key('requests.title');
  static const submitButtonKey = Key('requests.submit');
  static const offerMessageFieldKey = Key('requests.offerMessage');
  static const offerSubmitButtonKey = Key('requests.offerSubmit');

  static Key offerButtonKey(String requestId) =>
      Key('requests.offer.$requestId');
  static Key simulateOfferButtonKey(String requestId) =>
      Key('requests.simulateOffer.$requestId');
  static Key acceptOfferButtonKey(String offerId) =>
      Key('requests.acceptOffer.$offerId');
  static Key viewAgreementButtonKey(String agreementId) =>
      Key('requests.viewAgreement.$agreementId');

  final bool openComposer;

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  bool _didOpenComposer = false;
  RequestCategory? _filter;

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

  Future<void> _openOfferSheet(SignedRequest request) {
    final session = AppScope.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OfferSheet(session: session, request: request),
    );
  }

  Future<void> _simulateOffer(SignedRequest request) async {
    try {
      await AppScope.of(context).simulateOfferForOwnRequest(request);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('模拟响应失败：$error')));
      }
    }
  }

  Future<void> _acceptOffer(SignedRequest request, SignedOffer offer) async {
    try {
      final agreement = await AppScope.of(context).acceptOffer(request, offer);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                AgreementPage(agreementId: agreement.agreement.agreementId),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('生成协议失败：$error')));
      }
    }
  }

  void _viewAgreement(String agreementId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgreementPage(agreementId: agreementId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('需求')),
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

            final filtered = _filter == null
                ? session.requests
                : session.requests
                      .where((item) => item.request.category == _filter)
                      .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('全部'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                      for (final category in RequestCategory.values) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(_categoryLabel(category)),
                          selected: _filter == category,
                          onSelected: (_) => setState(() => _filter = category),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                  child: Text(
                    _listSummary(filtered),
                    style: textTheme.bodySmall,
                  ),
                ),
                if (filtered.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('这个类别还没有需求。', style: textTheme.bodyMedium),
                    ),
                  )
                else
                  for (final item in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RequestCard(
                        item: item,
                        offers: session.offersFor(item.request.requestId),
                        agreements: session.agreementsFor(
                          item.request.requestId,
                        ),
                        isOwn:
                            item.request.creatorId ==
                            session.identity?.identityId,
                        canRespond:
                            item.request.creatorId !=
                            session.identity?.identityId,
                        onRespond: () => _openOfferSheet(item),
                        onSimulateOffer: () => _simulateOffer(item),
                        onAcceptOffer: (offer) => _acceptOffer(item, offer),
                        onViewAgreement: _viewAgreement,
                      ),
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
  const _RequestCard({
    required this.item,
    required this.offers,
    required this.agreements,
    required this.isOwn,
    required this.canRespond,
    required this.onRespond,
    required this.onSimulateOffer,
    required this.onAcceptOffer,
    required this.onViewAgreement,
  });

  final SignedRequest item;
  final List<SignedOffer> offers;
  final List<SignedAgreement> agreements;
  final bool isOwn;
  final bool canRespond;
  final VoidCallback onRespond;
  final VoidCallback onSimulateOffer;
  final ValueChanged<SignedOffer> onAcceptOffer;
  final ValueChanged<String> onViewAgreement;

  SignedAgreement? _agreementFor(String offerId) {
    for (final agreement in agreements) {
      if (agreement.agreement.offerId == offerId) {
        return agreement;
      }
    }
    return null;
  }

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
            if (offers.isNotEmpty) ...[
              const SizedBox(height: 4),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                initiallyExpanded: isOwn,
                title: Text(
                  isOwn ? '收到的响应（${offers.length}）' : '我的响应（${offers.length}）',
                  style: textTheme.labelLarge,
                ),
                children: [
                  for (final offer in offers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _OfferTile(
                        offer: offer,
                        onAccept:
                            isOwn && _agreementFor(offer.offer.offerId) == null
                            ? () => onAcceptOffer(offer)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
            if (isOwn && offers.isEmpty) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: RequestsPage.simulateOfferButtonKey(request.requestId),
                  onPressed: onSimulateOffer,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('模拟一条响应（演示）'),
                ),
              ),
            ],
            if (canRespond && offers.isEmpty) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: RequestsPage.offerButtonKey(request.requestId),
                  onPressed: onRespond,
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('响应这条需求'),
                ),
              ),
            ],
            if (agreements.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final agreement in agreements)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    agreement.mutuallySigned
                        ? Icons.verified_outlined
                        : Icons.pending_outlined,
                    color: agreement.mutuallySigned
                        ? scheme.primary
                        : scheme.outline,
                  ),
                  title: Text(
                    agreement.mutuallySigned ? '协议 · 双方已签署' : '协议 · 等待对方签署',
                    style: textTheme.labelLarge,
                  ),
                  subtitle: Text(
                    _formatAmountValue(
                      agreement.agreement.agreedPriceMinor,
                      agreement.agreement.currency,
                    ),
                  ),
                  trailing: TextButton(
                    key: RequestsPage.viewAgreementButtonKey(
                      agreement.agreement.agreementId,
                    ),
                    onPressed: () =>
                        onViewAgreement(agreement.agreement.agreementId),
                    child: const Text('查看'),
                  ),
                ),
            ],
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

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, this.onAccept});

  final SignedOffer offer;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final price = offer.offer.proposedPrice;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                offer.verified ? Icons.verified_outlined : Icons.error_outline,
                size: 16,
                color: offer.verified ? scheme.primary : scheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                offer.verified ? '响应已签名并验签' : '响应验签失败',
                style: textTheme.labelSmall?.copyWith(
                  color: offer.verified ? scheme.primary : scheme.error,
                ),
              ),
              if (offer.isSample) ...[
                const Spacer(),
                Text(
                  '示例响应',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (offer.offer.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(offer.offer.message, style: textTheme.bodySmall),
          ],
          if (price != null) ...[
            const SizedBox(height: 4),
            Text('报价 ${_formatAmount(price)}', style: textTheme.labelMedium),
          ],
          const SizedBox(height: 4),
          Text(
            '有效至 ${_shortTime(offer.offer.expiresAt)} UTC',
            style: textTheme.bodySmall,
          ),
          if (onAccept != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                key: RequestsPage.acceptOfferButtonKey(offer.offer.offerId),
                onPressed: onAccept,
                child: const Text('接受并生成协议'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.session, required this.request});

  final AppSession session;
  final SignedRequest request;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _message;
  late final TextEditingController _price;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(text: '我可以顺路带过去。');
    _price = TextEditingController(
      text: _formatMinorInput(widget.request.request.price.amountMinor),
    );
  }

  @override
  void dispose() {
    _message.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final priceText = _price.text.trim();
    final priceMinor = priceText.isEmpty ? null : _parsePrice(priceText);
    if (priceText.isNotEmpty && priceMinor == null) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.session.respondToRequest(
        widget.request,
        message: _message.text.trim(),
        priceMinor: priceMinor,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error is ProtocolException
              ? '响应失败（${error.code.wire}）：${error.message}'
              : '响应失败：$error';
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
              Text('响应需求', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.request.request.title, style: textTheme.bodySmall),
              const SizedBox(height: 16),
              TextFormField(
                key: RequestsPage.offerMessageFieldKey,
                controller: _message,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '给发布者的说明',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '你的报价（CNY，可选）',
                  helperText: '留空表示按原预算或线下协商',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return null;
                  }
                  return _parsePrice(text) == null
                      ? '请输入合法金额，例如 45 或 45.00'
                      : null;
                },
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
                  key: RequestsPage.offerSubmitButtonKey,
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('签名响应'),
                ),
              ),
            ],
          ),
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

String _formatAmount(Price price) =>
    _formatAmountValue(price.amountMinor, price.currency);

String _formatAmountValue(int amountMinor, String currency) {
  final major = amountMinor ~/ 100;
  final cents = (amountMinor % 100).toString().padLeft(2, '0');
  return '$currency $major.$cents';
}

String _formatMinorInput(int amountMinor) {
  final major = amountMinor ~/ 100;
  final cents = (amountMinor % 100).toString().padLeft(2, '0');
  return '$major.$cents';
}

String _shortTime(String timestamp) => timestamp.substring(11, 16);
