import 'package:flutter/widgets.dart';
import 'package:osn_identity/osn_identity.dart';
import 'package:osn_protocol/osn_protocol.dart';

/// 一条已签名并已在本机验签的 Request。
class SignedRequest {
  const SignedRequest({
    required this.request,
    required this.envelope,
    required this.verified,
  });

  final Request request;
  final Envelope envelope;
  final bool verified;
}

/// 应用级内存会话。
///
/// 身份与需求在页面之间共享，但**只在内存中**：重启应用即丢失。
/// 这样可以先验证交互与协议，而不把持久化问题混进来。
class AppSession extends ChangeNotifier {
  PeerIdentity? _identity;
  Future<PeerIdentity>? _identityFuture;
  bool _loadingIdentity = false;
  String? _identityError;
  final List<SignedRequest> _requests = <SignedRequest>[];

  PeerIdentity? get identity => _identity;
  bool get loadingIdentity => _loadingIdentity;
  String? get identityError => _identityError;
  List<SignedRequest> get requests =>
      List<SignedRequest>.unmodifiable(_requests);

  /// 确保本机身份已生成；并发调用会复用同一个 Future。
  Future<PeerIdentity> ensureIdentity() {
    final identity = _identity;
    if (identity != null) {
      return Future<PeerIdentity>.value(identity);
    }
    return _identityFuture ??= _generateIdentity();
  }

  Future<PeerIdentity> _generateIdentity() async {
    _loadingIdentity = true;
    _identityError = null;
    notifyListeners();
    try {
      final identity = await PeerIdentity.generate();
      _identity = identity;
      return identity;
    } on Object catch (error) {
      _identityError = '生成身份失败：$error';
      _identityFuture = null;
      rethrow;
    } finally {
      _loadingIdentity = false;
      notifyListeners();
    }
  }

  /// 重新生成身份，并清空用旧身份发布的本机需求。
  Future<void> regenerateIdentity() async {
    _identity = null;
    _identityFuture = null;
    _requests.clear();
    notifyListeners();
    await ensureIdentity();
  }

  /// 发布一条签名 Request。
  ///
  /// 会先做模型校验，再签名并立即独立验签；验签失败不会进入列表。
  Future<SignedRequest> publish({
    required String title,
    required RequestCategory category,
    required int priceMinor,
    String description = '',
    String? originLabel,
    String? destinationLabel,
  }) async {
    final identity = await ensureIdentity();
    final now = DateTime.now().toUtc();
    final createdAt = formatUtcTimestamp(now);
    final expiresAt = formatUtcTimestamp(now.add(const Duration(hours: 2)));
    final start = formatUtcTimestamp(now.add(const Duration(minutes: 30)));
    final end = formatUtcTimestamp(now.add(const Duration(minutes: 90)));

    final request = Request(
      requestId: Request.newId(),
      creatorId: identity.identityId,
      category: category,
      title: title,
      description: description,
      origin: _place(originLabel),
      destination: _place(destinationLabel),
      timeWindow: TimeWindow(start: start, end: end),
      price: Price(amountMinor: priceMinor, currency: 'CNY'),
      createdAt: createdAt,
      expiresAt: expiresAt,
      nonce: Request.newNonce(),
    );

    final validated = Request.fromJson(request.toJson());
    final envelope = await identity.signEnvelope(
      type: MessageType.requestCreated,
      sentAt: createdAt,
      payload: validated.toJson(),
    );
    final verified = await verifyEnvelopeSignature(envelope);
    if (!verified) {
      throw StateError('新发布的 Request 验签失败，未加入列表');
    }

    final item = SignedRequest(
      request: validated,
      envelope: envelope,
      verified: verified,
    );
    _requests.insert(0, item);
    notifyListeners();
    return item;
  }

  /// 没有内容时的示例数据，避免首屏完全空白。
  Future<SignedRequest> publishDemo() => publish(
    title: '从图书馆带一本书',
    category: RequestCategory.delivery,
    priceMinor: 5000,
    description: '本机示例需求；不会广播。',
    originLabel: '图书馆',
    destinationLabel: '东门',
  );

  Place? _place(String? label) {
    final trimmed = label?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    return Place(label: trimmed);
  }
}

/// 把 [AppSession] 暴露给页面。
class AppScope extends InheritedNotifier<AppSession> {
  const AppScope({super.key, required AppSession session, required super.child})
    : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 未挂载');
    return scope!.notifier!;
  }
}
