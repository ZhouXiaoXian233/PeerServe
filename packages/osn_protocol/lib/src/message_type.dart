/// 协议 v1 已知的消息/事件类型。
enum MessageType {
  requestCreated('request.created'),
  requestUpdated('request.updated'),
  requestWithdrawn('request.withdrawn'),
  offerCreated('offer.created'),
  offerWithdrawn('offer.withdrawn'),
  agreementProposed('agreement.proposed'),
  agreementSigned('agreement.signed'),
  serviceStarted('service.started'),
  completionClaimed('completion.claimed'),
  completionConfirmed('completion.confirmed'),
  serviceCancelled('service.cancelled'),
  disputeStatementAdded('dispute.statement_added'),
  reviewCreated('review.created');

  const MessageType(this.wire);

  /// 出现在 JSON 中的稳定字符串。
  final String wire;

  /// 解析线上类型字符串；未知类型返回 `null`。
  static MessageType? tryParse(String wire) {
    for (final type in values) {
      if (type.wire == wire) {
        return type;
      }
    }
    return null;
  }
}
