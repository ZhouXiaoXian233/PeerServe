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
    this.sampleProviderIdentity,
  });

  final Offer offer;
  final Envelope envelope;
  final bool verified;

  /// 仅用于本机协议演示的模拟响应方私钥；真实 Offer 为 null。
  final PeerIdentity? sampleProviderIdentity;

  bool get isSample => sampleProviderIdentity != null;
}

/// 一份协议及其签名信封。
///
/// 双签按 ADR-014 使用两个独立信封；`providerEnvelope` 为空表示等待对方签署。
class SignedAgreement {
  const SignedAgreement({
    required this.agreement,
    required this.requesterEnvelope,
    required this.requesterVerified,
    this.providerEnvelope,
    this.providerVerified = false,
    this.sampleProviderIdentity,
  });

  final Agreement agreement;
  final Envelope requesterEnvelope;
  final bool requesterVerified;
  final Envelope? providerEnvelope;
  final bool providerVerified;
  final PeerIdentity? sampleProviderIdentity;

  bool get mutuallySigned =>
      providerEnvelope != null && requesterVerified && providerVerified;

  bool get canSimulateProvider =>
      providerEnvelope == null && sampleProviderIdentity != null;

  SignedAgreement withProviderEnvelope(Envelope envelope, bool verified) =>
      SignedAgreement(
        agreement: agreement,
        requesterEnvelope: requesterEnvelope,
        requesterVerified: requesterVerified,
        providerEnvelope: envelope,
        providerVerified: verified,
        sampleProviderIdentity: sampleProviderIdentity,
      );
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
  final List<SignedAgreement> _agreements = <SignedAgreement>[];
  bool _seeded = false;
  Future<void>? _bootstrapFuture;

  PeerIdentity? get identity => _identity;
  bool get loadingIdentity => _loadingIdentity;
  String? get identityError => _identityError;
  UserProfile get profile => _profile;
  List<SignedRequest> get requests =>
      List<SignedRequest>.unmodifiable(_requests);
  List<SignedOffer> get offers => List<SignedOffer>.unmodifiable(_offers);
  List<SignedAgreement> get agreements =>
      List<SignedAgreement>.unmodifiable(_agreements);

  List<SignedOffer> offersFor(String requestId) =>
      List<SignedOffer>.unmodifiable(
        _offers.where((item) => item.offer.requestId == requestId),
      );

  List<SignedAgreement> agreementsFor(String requestId) =>
      List<SignedAgreement>.unmodifiable(
        _agreements.where((item) => item.agreement.requestId == requestId),
      );

  SignedAgreement? agreementForOffer(String offerId) {
    for (final agreement in _agreements) {
      if (agreement.agreement.offerId == offerId) {
        return agreement;
      }
    }
    return null;
  }

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
    _agreements.clear();
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

  /// 为自己发布的需求生成一条**模拟响应**，用于走通协议流程。
  ///
  /// 响应方是运行时生成的示例身份，明确标记为示例，不代表真实用户。
  Future<SignedOffer> simulateOfferForOwnRequest(SignedRequest request) async {
    final identity = await ensureIdentity();
    if (request.request.creatorId != identity.identityId) {
      throw StateError('只能为自己的需求模拟响应');
    }
    if (_offers.any(
      (item) => item.offer.requestId == request.request.requestId,
    )) {
      throw StateError('这条需求已经有一条响应');
    }

    final provider = await PeerIdentity.generate();
    final now = DateTime.now().toUtc();
    final requestExpires = DateTime.parse(request.request.expiresAt);
    final createdAt = formatUtcTimestamp(now);
    final twoHoursLater = now.add(const Duration(hours: 2));
    final expiresAt = formatUtcTimestamp(
      twoHoursLater.isBefore(requestExpires) ? twoHoursLater : requestExpires,
    );

    final offer = Offer(
      offerId: Offer.newId(),
      requestId: request.request.requestId,
      providerId: provider.identityId,
      message: '示例响应：我可以帮忙。',
      proposedPrice: request.request.price,
      proposedTime: request.request.timeWindow,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
    final validated = Offer.fromJson(offer.toJson());
    final envelope = await provider.signEnvelope(
      type: MessageType.offerCreated,
      sentAt: createdAt,
      payload: validated.toJson(),
    );
    final verified = await verifyEnvelopeSignature(envelope);
    if (!verified) {
      throw StateError('模拟 Offer 验签失败');
    }

    final signed = SignedOffer(
      offer: validated,
      envelope: envelope,
      verified: verified,
      sampleProviderIdentity: provider,
    );
    _offers.add(signed);
    notifyListeners();
    return signed;
  }

  /// 需求方接受一条 Offer，生成待对方签署的 Agreement。
  Future<SignedAgreement> acceptOffer(
    SignedRequest request,
    SignedOffer offer,
  ) async {
    final identity = await ensureIdentity();
    if (request.request.creatorId != identity.identityId) {
      throw StateError('只有需求方可以接受响应');
    }
    if (!_offers.any((item) => item.offer.offerId == offer.offer.offerId)) {
      throw StateError('响应不在本机列表中');
    }
    if (!offer.verified) {
      throw StateError('响应验签失败');
    }
    final existing = agreementForOffer(offer.offer.offerId);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now().toUtc();
    final requestExpires = DateTime.parse(request.request.expiresAt);
    if (!requestExpires.isAfter(now)) {
      throw StateError('需求已过期');
    }
    final createdAt = formatUtcTimestamp(now);
    final agreedPrice =
        offer.offer.proposedPrice?.amountMinor ??
        request.request.price.amountMinor;
    final currency =
        offer.offer.proposedPrice?.currency ?? request.request.price.currency;

    final agreement = Agreement(
      agreementId: Agreement.newId(),
      requestId: request.request.requestId,
      offerId: offer.offer.offerId,
      requesterId: identity.identityId,
      providerId: offer.offer.providerId,
      serviceTerms: request.request.description.isNotEmpty
          ? request.request.description
          : request.request.title,
      agreedPriceMinor: agreedPrice,
      currency: currency,
      startConditions: '响应方按约定开始服务',
      completionConditions: '双方确认完成',
      cancellationTerms: '任一方可提前说明并取消',
      createdAt: createdAt,
      expiresAt: formatUtcTimestamp(requestExpires),
    );
    final validated = Agreement.fromJson(agreement.toJson());
    final envelope = await identity.signEnvelope(
      type: MessageType.agreementProposed,
      sentAt: createdAt,
      payload: validated.toJson(),
    );
    final verified = await verifyEnvelopeSignature(envelope);
    if (!verified) {
      throw StateError('Agreement 需求方签名验证失败');
    }

    final signed = SignedAgreement(
      agreement: validated,
      requesterEnvelope: envelope,
      requesterVerified: verified,
      sampleProviderIdentity: offer.sampleProviderIdentity,
    );
    _agreements.add(signed);
    notifyListeners();
    return signed;
  }

  /// 仅用于本机演示：让模拟响应方对同一 Agreement payload 签名。
  Future<SignedAgreement> simulateProviderAccept(
    SignedAgreement agreement,
  ) async {
    final index = _agreements.indexWhere(
      (item) => item.agreement.agreementId == agreement.agreement.agreementId,
    );
    if (index < 0) {
      throw StateError('协议不在本机列表中');
    }
    final current = _agreements[index];
    final provider = current.sampleProviderIdentity;
    if (provider == null || !current.canSimulateProvider) {
      throw StateError('这份协议没有可用的模拟对方身份');
    }
    if (provider.identityId != current.agreement.providerId) {
      throw StateError('模拟身份与协议 provider_id 不一致');
    }

    final sentAt = formatUtcTimestamp(DateTime.now().toUtc());
    final envelope = await provider.signEnvelope(
      type: MessageType.agreementSigned,
      sentAt: sentAt,
      payload: current.agreement.toJson(),
    );
    if (canonicalize(envelope.payload) !=
        canonicalize(current.requesterEnvelope.payload)) {
      throw StateError('双方签署的 Agreement payload 不一致');
    }
    final verified = await verifyEnvelopeSignature(envelope);
    if (!verified) {
      throw StateError('Agreement 响应方签名验证失败');
    }

    final updated = current.withProviderEnvelope(envelope, verified);
    _agreements[index] = updated;
    notifyListeners();
    return updated;
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
