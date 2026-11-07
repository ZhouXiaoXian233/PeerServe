# 网络设计

> 状态：**设计草案**。Phase 0.2–0.3 仅定义接口与 `InMemoryTransport`；真实传输在 Phase 2。

## 1. 必须先分清的五件事

| 能力 | 问题 | 本项目态度 |
| --- | --- | --- |
| 传输 | 两个已知节点怎么连 | 抽象接口，先内存实现 |
| 发现 | 怎么知道别的节点存在 | Phase 4 才做；MVP 用二维码手动配对 |
| 广播/转发 | 摘要怎么传播 | 只转发已验签摘要，带 TTL/跳数/去重 |
| 持久化 | 离线时谁保存 | 每台设备保存自己的副本；缓存节点可选 |
| 可用性 | 发布者离线还能被发现吗 | **不承诺**；UI 必须显示数据新鲜度 |

"直连成功"不等于其余四项已解决。

## 2. 接口

```dart
abstract interface class Transport {
  Future<void> connect(PeerAddress peer);
  Stream<PeerMessage> get incomingMessages;
  Future<void> send(PeerAddress peer, PeerMessage message);
  Future<void> disconnect(PeerAddress peer);
}
```

约定：

- `Transport` 只保证"字节送达"，不解释业务语义，不裁定交易结果。
- 上层拿到消息后必须走 [PROTOCOL_SPEC.md](PROTOCOL_SPEC.md) §8 的校验顺序。
- `InMemoryTransport` 用于测试与本地演示，必须支持：丢包、延迟、重连、重复投递、乱序注入。

## 3. 分阶段

### 阶段 A（Phase 1）：本地 + 模拟传输
- 无网络；两节点逻辑用 `InMemoryTransport` 跑通。
- 验收：发布→响应→签署→事件→评价全流程可在单进程测试中完成。

### 阶段 B（Phase 2）：已知节点直连
- 二维码交换连接信息（multiaddr），建立加密通道。
- 验收：两台设备不经过项目方服务器，互发并验证 Request/Offer/Agreement。
- 明确标注为**技术验证**，不是最终体验。

### 阶段 C（Phase 4）：自动发现与转发
- 评估 mDNS / DHT / GossipSub / relay。
- 必须先回答：是否需要 bootstrap、信令、STUN/TURN；Android 后台限制；NAT 失败行为；运营成本与单点依赖。

## 4. 基础设施依赖（必须文档化）

| 组件 | 是否必需 | 可否替换/自托管 | 备注 |
| --- | --- | --- | --- |
| mDNS（局域网发现） | 否 | 无外部依赖 | 仅同网段；受省电策略影响 |
| libp2p relay / bootstrap | 视方案 | 是 | 公共节点有可用性与隐私争议 |
| STUN/TURN | 仅 WebRTC 方案 | 是 | TURN 有带宽成本 |
| 二维码配对 | Phase 2 是 | 无外部依赖 | 首次体验成本高 |

**禁止**在 README 或 UI 中宣称"零基础设施"或"完全去中心化"。发现层若依赖固定 bootstrap 节点，就存在可用性依赖。

## 5. 消息与流量控制

- 单条消息上限 64 KiB；超出直接丢弃并记录（不解析）。
- 每条消息带 `message_id`、`expires_at`、`ttl_hops`（默认 3）。
- 节点维护 `seen_messages` 集合，重复即丢弃。
- 广播速率限制：每节点每分钟 N 条（默认 60），可配置。
- 只转发**签名验证通过**的公告摘要；过期公告停止转发。
- 精确坐标默认不广播。

## 6. 离线与不一致

- 离线节点收不到消息；UI 显示"最后同步时间"与"数据可能过期"。
- 不同设备可能看到不同状态：接收新事件后重新投影，不覆盖冲突记录。
- 撤回是**新事件**；缓存节点收到后停止转发，但无法保证远端删除。
- MVP 不承诺"发布者离线后新用户仍能找到任务"。

## 7. 网络诊断页（UI）

显示：当前传输方式、连接节点数、最近成功连接时间、已缓存公告数、已丢弃消息数与原因分布、当前 relay/bootstrap 配置（可替换）。

**不显示**：私钥、完整连接凭据、对方精确位置。

## 8. 未决问题

- `sender_id`/`sent_at` 是否纳入签名范围（见 PROTOCOL_SPEC §4 TODO）；
- libp2p 与 Ed25519 身份密钥能否共用（PeerId 派生）；
- Android 前台服务与省电白名单策略；
- 多设备同一身份（ADR-010 复审时讨论）。
