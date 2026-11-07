# 架构

> 状态：Phase 0.1 · 本文件描述**目标架构**与**当前实现**的差距。

## 1. 分层

```text
┌───────────────────────────────────────────────────────┐
│ ui           页面、路由、主题                          │
├───────────────────────────────────────────────────────┤
│ tasks / events / reviews   业务用例（Request→Offer→Agreement→Event→Review）│
│ trust_view   事实统计与评价展示（不计算强制总分）        │
├───────────────────────────────────────────────────────┤
│ identity     Ed25519 密钥、签名、验签、身份标识派生     │
│ protocol     模型、JCS 规范化、schema 校验、测试向量    │
│ storage      SQLite、迁移、导入导出                     │
│ network      Transport 抽象、连接、去重、限流           │
└───────────────────────────────────────────────────────┘
```

依赖方向**单向向下**：

- `ui` → `tasks/events/reviews` → `identity/protocol/storage`；
- `network` 只依赖 `protocol`（信封）与 `identity`（验签），不依赖 `ui`；
- `trust_view` 只读 `storage` 的投影，不写库、不判定对错。

**禁止**：UI 直接拼 SQL；UI 直接操作 socket；`storage` 依赖 Flutter；`protocol` 依赖 Flutter 或 `dart:io`。

## 2. 模块职责

| 模块 | 职责 | 不做 |
| --- | --- | --- |
| `protocol` | 数据模型、`schema_version`、JCS 规范化、字段校验、测试向量 | 不签名、不落库、不联网 |
| `identity` | 生成密钥、派生 `identity_id`、签名/验签、备份加解密 | 不决定业务规则 |
| `storage` | SQLite 表、迁移、事务、查询投影、导入导出 | 不解释业务语义 |
| `network` | `Transport` 实现、连接管理、消息收发、去重、限流、TTL | 不裁定交易结果 |
| `tasks` | Request/Offer/Agreement 生命周期与状态投影 | 不直接访问网络套接字 |
| `events` | 追加式事件、`previous_event_hash` 链、冲突标记 | 不覆盖已签名内容 |
| `reviews` | 评价创建与合法性校验（参与者、唯一性） | 不聚合"信用分" |
| `trust_view` | 事实统计、来源与签名状态、评价分布 | 不给出好坏结论 |
| `ui` | 页面与交互 | 不持有业务真相 |

## 3. 关键设计约束

1. **状态是投影，不是字段**。`Agreement` 的"已开始/已完成"由签名事件推导，任何中心字段都不是权威。
2. **签名覆盖规范化后的完整字段**，且带域分离前缀（见 [PROTOCOL_SPEC.md](PROTOCOL_SPEC.md)）。
3. **接收即校验**：schema → 长度 → 签名 → 对象关联（例如 Offer 必须指向已存在的 Request）。
4. **冲突并存**：矛盾事件都保留，视图标记 `conflicting`，不静默删除。
5. **可替换基础设施**：网络层通过接口注入，relay/bootstrap 可在配置中替换或关闭（见 [NETWORK_DESIGN.md](NETWORK_DESIGN.md)）。
6. **UI 必须能表达不确定性**：数据来源、最后同步时间、签名状态、单方声明 vs 双方确认。

## 4. 目录（当前 / 目标）

```text
PeerServe/
├── app/mobile/                 # ✅ 现在：Flutter 应用
│   ├── lib/
│   │   ├── main.dart           # 入口
│   │   ├── app.dart            # MaterialApp + 路由
│   │   └── ui/                 # 页面与主题
│   ├── test/                   # widget / smoke 测试
│   └── android/                # Android 宿主工程
├── packages/                   # ⬜ 第二个垂直切片时才创建（ADR-011）
│   ├── osn_protocol/           # Phase 0.2
│   ├── osn_identity/           # Phase 0.2
│   ├── osn_storage/            # Phase 0.3
│   ├── osn_transport/          # Phase 2
│   └── osn_trust_view/         # Phase 3
├── protocol/
│   ├── schemas/                # ⬜ Phase 0.2 起：JSON Schema
│   └── test-vectors/           # ⬜ Phase 0.2 起：跨语言签名向量
├── docs/
├── .github/
└── scripts/
```

> 为什么现在只有 `app/mobile`：见 ADR-011。**不为目录完整性创建空壳包**——空包会让"看起来实现了"变成一种误导。

## 5. 一次典型流程（目标态）

```text
A 发布 Request
  │  protocol.validate → identity.sign → storage.insert → network.broadcast(summary)
  ▼
B 收到摘要
  │  network.ingest → protocol.validate → identity.verify → storage.cache
  ▼
B 提交 Offer（签名）
  ▼
A 接受 → 生成 Agreement → 双方各自签名 → 合并为 mutually_signed 视图
  ▼
事件：service.started → completion.claimed → completion.confirmed
  ▼
双方各自写 Review（必须引用有效 Agreement）
```

## 6. 数据流与信任边界

| 数据 | 谁产生 | 信任程度 |
| --- | --- | --- |
| 签名的事件/协议 | 参与者设备 | 只能证明"该密钥签署了该内容" |
| 缓存公告摘要 | 任意转发节点 | 需保留原始发布者签名；缓存者不背书内容 |
| `received_at_local` | 本机 | 只证明本机在某时收到 |
| 设备时间戳 | 对端设备 | 仅作声明，可能不准 |
| 评价 | 交易参与者 | 主观意见，可能串通或恶意 |
| 事实统计 | 本机按本地数据计算 | 受限于本机见过的数据 |

## 7. 测试策略（架构层）

- `protocol` / `identity` / `storage`：纯 Dart 单元测试，秒级反馈，不依赖 Flutter。
- `network`：`InMemoryTransport` 模拟两节点，覆盖重连、重复、超时、乱序。
- `ui`：widget 测试覆盖"事实 / 单方声明 / 评价"的展示差异。
- 跨语言：`protocol/test-vectors/` 保证任何客户端实现得到相同签名字节。

详见 [TEST_PLAN.md](TEST_PLAN.md)。
