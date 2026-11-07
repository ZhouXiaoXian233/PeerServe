import 'package:flutter/widgets.dart';
import 'package:osn_identity/osn_identity.dart';
import 'package:osn_protocol/osn_protocol.dart';

/// 本机用户资料。只在内存中，不进入身份标识，也不参与签名。
class UserProfile {
  const UserProfile({
    this.nickname = '本机用户',
    this.avatar = '🙂',
    this.bio = '',
    this.defaultOrigin = '',
    this.defaultDestination = '',
  });

  final String nickname;
  final String avatar;
  final String bio;
  final String defaultOrigin;
  final String defaultDestination;

  UserProfile copyWith({
    String? nickname,
    String? avatar,
    String? bio,
    String? defaultOrigin,
    String? defaultDestination,
  }) => UserProfile(
    nickname: nickname ?? this.nickname,
    avatar: avatar ?? this.avatar,
    bio: bio ?? this.bio,
    defaultOrigin: defaultOrigin ?? this.defaultOrigin,
    defaultDestination: defaultDestination ?? this.defaultDestination,
  );
}

/// 一条已签名并已在本机验签的 Request。
class SignedRequest {
  const SignedRequest({
    required this.request,
    required this.envelope,
    required this.verified,
    required this.authorLabel,
    required this.authorAvatar,
    this.isSample = false,
  });

  final Request request;
  final Envelope envelope;
  final bool verified;
  final String authorLabel;
  final String authorAvatar;

  /// 示例数据：用于在没有其他节点时展示列表形态，明确标记，不冒充真实用户。
  final bool isSample;
}

/// 一条已签名并已在本机验签的 Offer。
class SignedOffer {
  const SignedOffer({
    required this.offer,
    required this.envelope,
    required this.verified,
  });

  final Offer offer;
  final Envelope envelope;
  final bool verified;
}

/// 应用级内存会话。
///
/// 身份、资料与需求在页面之间共享，但**只在内存中**：重启应用即丢失。
class AppSession extends ChangeNotifier {
  PeerIdentity? _identity;
  Future<PeerIdentity>? _identityFuture;
  bool _loadingIdentity = false;
  String? _identityError;
  UserProfile _profile = const UserProfile();
  final List<SignedRequest> _requests = <SignedRequest>[];
  final List<SignedOffer> _offers = <SignedOffer>[];
  bool _seeded = false;
  Future<void>? _bootstrapFuture;

  PeerIdentity? get identity => _identity;
  bool get loadingIdentity => _loadingIdentity;
  String? get identityError => _identityError;
  UserProfile get profile => _profile;
  List<SignedRequest> get requests =>
      List<SignedRequest>.unmodifiable(_requests);
  List<SignedOffer> get offers => List<SignedOffer>.unmodifiable(_offers);

  List<SignedOffer> offersFor(String requestId) =>
      List<SignedOffer>.unmodifiable(
        _offers.where((item) => item.offer.requestId == requestId),
      );

  bool hasResponded(String requestId) =>
      _offers.any((item) => item.offer.requestId == requestId);

  /// 应用启动：生成身份，并放入几条明确标记的示例需求。
  Future<void> bootstrap() => _bootstrapFuture ??= _bootstrapInternal();

  Future<void> _bootstrapInternal() async {
    await ensureIdentity();
    await _seedSamples();
  }

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

  /// 重新生成身份，清空本机需求并重新放入示例数据。
  Future<void> regenerateIdentity() async {
    _identity = null;
    _identityFuture = null;
    _requests.clear();
    _offers.clear();
    _seeded = false;
    _bootstrapFuture = null;
    notifyListeners();
    await ensureIdentity();
    await _seedSamples();
  }

  void updateProfile(UserProfile next) {
    _profile = next;
    notifyListeners();
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
    final item = await _createSignedRequest(
      identity: identity,
      title: title,
      category: category,
      priceMinor: priceMinor,
      description: description,
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      authorLabel: _profile.nickname,
      authorAvatar: _profile.avatar,
    );
    _requests.insert(0, item);
    notifyListeners();
    return item;
  }

  /// 响应一条本机可见的 Request，签名并立即验签。
  ///
  /// 示例数据也可以响应，但只会保存在本机，不会真的送达发布者。
  Future<SignedOffer> respondToRequest(
    SignedRequest request, {
    String message = '',
    int? priceMinor,
  }) async {
    final identity = await ensureIdentity();
    if (request.request.creatorId == identity.identityId) {
      throw StateError('不能响应自己发布的需求');
    }
    if (!_requests.any(
      (item) => item.request.requestId == request.request.requestId,
    )) {
      throw StateError('需求不在本机列表中');
    }

    final now = DateTime.now().toUtc();
    final requestExpires = DateTime.parse(request.request.expiresAt);
    if (!requestExpires.isAfter(now)) {
      throw StateError('需求已过期');
    }
    final createdAt = formatUtcTimestamp(now);
    final twoHoursLater = now.add(const Duration(hours: 2));
    final expiresAt = formatUtcTimestamp(
      twoHoursLater.isBefore(requestExpires) ? twoHoursLater : requestExpires,
    );

    final offer = Offer(
      offerId: Offer.newId(),
      requestId: request.request.requestId,
      providerId: identity.identityId,
      message: message,
      proposedPrice: priceMinor == null
          ? null
          : Price(amountMinor: priceMinor, currency: 'CNY'),
      proposedTime: request.request.timeWindow,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
    final validated = Offer.fromJson(offer.toJson());
    final envelope = await identity.signEnvelope(
      type: MessageType.offerCreated,
      sentAt: createdAt,
      payload: validated.toJson(),
    );
    final verified = await verifyEnvelopeSignature(envelope);
    if (!verified) {
      throw StateError('新 Offer 验签失败');
    }

    final signed = SignedOffer(
      offer: validated,
      envelope: envelope,
      verified: verified,
    );
    _offers.add(signed);
    notifyListeners();
    return signed;
  }

  Future<SignedRequest> _createSignedRequest({
    required PeerIdentity identity,
    required String title,
    required RequestCategory category,
    required int priceMinor,
    required String authorLabel,
    required String authorAvatar,
    String description = '',
    String? originLabel,
    String? destinationLabel,
    DateTime? now,
    bool isSample = false,
  }) async {
    final base = now ?? DateTime.now().toUtc();
    final createdAt = formatUtcTimestamp(base);
    final expiresAt = formatUtcTimestamp(base.add(const Duration(hours: 2)));
    final start = formatUtcTimestamp(base.add(const Duration(minutes: 30)));
    final end = formatUtcTimestamp(base.add(const Duration(minutes: 90)));

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
      throw StateError('新发布的 Request 验签失败');
    }
    return SignedRequest(
      request: validated,
      envelope: envelope,
      verified: verified,
      authorLabel: authorLabel,
      authorAvatar: authorAvatar,
      isSample: isSample,
    );
  }

  Future<void> _seedSamples() async {
    if (_seeded) {
      return;
    }
    _seeded = true;
    final now = DateTime.now().toUtc();
    final samples =
        <
          ({
            String name,
            String avatar,
            String title,
            String origin,
            String destination,
            RequestCategory category,
            int price,
            int minutesAgo,
          })
        >[
          (
            name: '小林',
            avatar: '🚲',
            title: '帮忙取一份快递',
            origin: '菜鸟驿站',
            destination: '3 号楼',
            category: RequestCategory.delivery,
            price: 800,
            minutesAgo: 6,
          ),
          (
            name: '阿岚',
            avatar: '🍜',
            title: '拼单带一份午餐',
            origin: '南门食堂',
            destination: '图书馆',
            category: RequestCategory.food,
            price: 2500,
            minutesAgo: 14,
          ),
          (
            name: '老周',
            avatar: '🧰',
            title: '借一把螺丝刀，十分钟就还',
            origin: '工具间',
            destination: '2 号楼',
            category: RequestCategory.errand,
            price: 0,
            minutesAgo: 22,
          ),
          (
            name: '小夏',
            avatar: '🚗',
            title: '顺路去地铁站',
            origin: '东门',
            destination: '地铁站',
            category: RequestCategory.ride,
            price: 1500,
            minutesAgo: 31,
          ),
        ];

    for (final sample in samples) {
      final identity = await PeerIdentity.generate();
      final item = await _createSignedRequest(
        identity: identity,
        title: sample.title,
        category: sample.category,
        priceMinor: sample.price,
        description: '示例数据，用于展示需求列表；不是真实用户发布。',
        originLabel: sample.origin,
        destinationLabel: sample.destination,
        authorLabel: sample.name,
        authorAvatar: sample.avatar,
        now: now.subtract(Duration(minutes: sample.minutesAgo)),
        isSample: true,
      );
      _requests.add(item);
    }
    notifyListeners();
  }

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
