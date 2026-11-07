# 协议规范（Phase 0.2b）

> 状态：**信封、JCS 子集、Ed25519 与 Request v1 已实现**；Offer / Agreement / Event / Review 的业务对象模型尚未实现。
> 版本：`schema_version = 1`（未发布）

## 1. 设计目标

1. **自描述**：每条签名对象都能独立验证，接收方不需要中心服务提供上下文。
2. **跨语言可复现**：任何客户端用任何语言都能得到相同签名字节。
3. **可演进**：版本号显式，未知版本安全拒绝而不是猜测。
4. **不承诺现实**：协议只表达"谁声明了什么"，不表达"世界真的如此"。

## 2. 签名域分离

```text
signed_payload = {
  "schema_version": 1,
  "type": "...",
  "sender_id": "did:key:...",
  "sent_at": "2026-11-07T04:30:00.000Z",
  "payload": { }
}
signed_bytes = UTF-8( "PeerServe:v1:" + JCS(signed_payload) )
signature    = Ed25519.sign(private_key, signed_bytes)
```

- 前缀 `PeerServe:v1:` 是**域分离**，防止同一密钥在其他协议（SSH、签名邮件、其他 DApp）中的签名被重放到本协议。
- `JCS(signed_payload)` 为 [RFC 8785](https://www.rfc-editor.org/rfc/rfc8785) 规范化 JSON；本协议只使用其无浮点子集。
- **签名不在 signed_payload 内**：签名放在信封外层，避免"签名覆盖签名自己"的递归问题。
- `sender_id` 与 `sent_at` **纳入签名范围**（ADR-013）：接收方不能在不破坏签名的情况下替换发送方身份或声明时间。

验证方必须**重新计算** `signed_bytes` 后验签，绝不比对序列化字符串。

## 3. 无浮点约束

payload 中允许的类型：`string` / `bool` / `null` / `integer` / `array` / `object`。
**禁止** `float`。任何含浮点数的 payload 一律拒绝（`schema` 错误）。

替代表示：

| 值 | 表示 | 示例 |
| --- | --- | --- |
| 金额 | 最小货币单位的整数 | `5000` 表示 50.00 CNY |
| 经纬度 | 1e-7 度的整数 | `312304000` 表示 31.2304° |
| 时间 | UTC ISO-8601 字符串（毫秒精度） | `2026-11-07T04:30:00.000Z` |
| 比例/精度 | 整数百分比或整数米 | `precision_m: 100` |

理由：ECMAScript 数字格式化（JCS 依赖）与 Dart 的 `double.toString()` 在边界值上不一致，是跨语言签名失败最常见的来源。

实现上，`osn_protocol` 的 JCS 只接受协议允许的类型；`1.0`、`-0.0`、`1e30`、`333333333.33333329` 等输入一律以 `float_not_allowed` 拒绝。RFC 8785 中的浮点用例因此是**拒绝向量**，不是规范化向量；字符串转义、UTF-16 键排序与安全整数仍按 RFC 8785 输出。

## 4. 信封

```json
{
  "schema_version": 1,
  "type": "request.created",
  "payload": { },
  "sender_id": "did:key:z6Mk...",
  "sent_at": "2026-11-07T04:30:00.000Z",
  "signature": "base64url(ed25519_sig)"
}
```

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `schema_version` | ✅ | 整数，当前 `1`；未知版本必须拒绝并提示升级 |
| `type` | ✅ | 事件类型或消息类型（见 §6） |
| `payload` | ✅ | 被签名的业务对象；**不含** `signature` |
| `sender_id` | ✅ | 发送方身份标识，必须与签名密钥一致 |
| `sent_at` | ✅ | 发送方设备时间（仅声明） |
| `signature` | ✅ | 对 `signed_payload` 的签名（不含 `signature` 自身） |

签名编码固定为**无填充 base64url**（64 字节 → 86 字符）。`sent_at` 固定为 UTC 毫秒精度 `YYYY-MM-DDTHH:mm:ss.sssZ`；不接受本地时区偏移。

> Phase 0.2 已决定：`sender_id`/`sent_at` 纳入签名范围（`signed_payload`），见 ADR-013。早期草案中"只签 payload"的方案已废弃。

## 5. 身份标识

- 密钥算法：**Ed25519**（RFC 8032）。
- 身份标识：优先 `did:key`（`ed25519-pub` multicodec + base58btc），自描述、无注册中心。
- 退化方案（若依赖过重）：`osn1` + base32(SHA-256(pubkey))；两种都必须有固定测试向量。
- **禁止**把昵称、手机号、实名信息混入身份标识；昵称是可替换资料。

## 6. 对象与事件类型

- `request.created` / `request.updated` / `request.withdrawn`
- `offer.created` / `offer.withdrawn`
- `agreement.proposed` / `agreement.signed`
- `service.started`
- `completion.claimed`（单方声明）
- `completion.confirmed`（参与方确认）
- `service.cancelled`
- `dispute.statement_added`（**不等于**对方有过错）
- `review.created`

## 7. 对象字段（v1 草案）

### 7.1 Request

> Phase 0.2b 已实现：`packages/osn_protocol/lib/src/request.dart`。`origin` / `destination` 可省略；只给 `label` 表示模糊位置。

```json
{
  "schema_version": 1,
  "request_id": "uuid-v4-or-random-128bit",
  "creator_id": "did:key:z6Mk...",
  "category": "ride | delivery | food | errand | other",
  "title": "≤ 120 字符",
  "description": "≤ 2000 字符",
  "origin":      { "label": "≤ 120 字符", "lat_e7": 312304000, "lon_e7": 1214737000, "precision_m": 100 },
  "destination": { "label": "≤ 120 字符", "lat_e7": 312304000, "lon_e7": 1214737000, "precision_m": 100 },
  "time_window": { "start": "ISO-8601 UTC", "end": "ISO-8601 UTC" },
  "price": { "amount_minor": 5000, "currency": "CNY", "payment_method": "external_agreement" },
  "created_at": "ISO-8601 UTC",
  "expires_at": "ISO-8601 UTC",
  "nonce": "16 bytes base64url"
}
```

- 位置可只给 `label`（模糊区域），精确坐标应在双方建立联系后另行交换。
- `price.payment_method` 仅表示协商信息，不代表托管或担保。

### 7.2 Offer

`offer_id`、`request_id`、`provider_id`、`message`(≤1000)、`proposed_price`(可选)、`proposed_time`(可选)、`created_at`、`expires_at`。

### 7.3 Agreement

`agreement_id`、`request_id`、`offer_id`、`requester_id`、`provider_id`、`service_terms`、`agreed_price`、`currency`、`start_conditions`、`completion_conditions`、`cancellation_terms`、`created_at`、`expires_at`，外加两个独立签名 `requester_signature` / `provider_signature`。

- 只有两个签名都验证通过，视图才标记 `mutually_signed`。
- 任何条款变更 → 生成新版本 + 重新签名，**不覆盖**已签署内容。

### 7.4 Event

`event_id`、`agreement_id`(可空)、`event_type`、`actor_id`、`created_at_device`、`sequence_number`、`payload`、`previous_event_hash`(可空)、`signature`。

- `previous_event_hash` 按 `(agreement_id, actor_id)` 维度串成链，值为上一条已签名事件的 SHA-256。
- 冲突事件两条都保留，视图标记 `conflicting`。

### 7.5 Review

`review_id`、`agreement_id`、`reviewer_id`、`reviewee_id`、`rating`(1–5，可选)、`tags`(受控词表)、`comment`(≤1000)、`created_at`、`supersedes_review_id`(可选)。

约束：

- `reviewer_id` 必须是该 Agreement 的参与者；`reviewee_id` 必须是对方。
- 同一 `(agreement_id, reviewer_id)` 只有一条有效评价；修改发布新版本并引用旧 `review_id`。

## 8. 校验顺序（接收方必须遵守）

1. 消息大小上限（默认 64 KiB）；
2. JSON 解析（严格、拒绝重复键、拒绝浮点）；
3. `schema_version` 已知；
4. 字段存在性、类型、长度、数值范围；
5. 签名验证（域分离 + JCS + Ed25519）；
6. 对象关联（Offer→Request 存在；Review→Agreement 存在且作者是参与者）；
7. 时间与过期（`expires_at`、`sent_at` 偏差容忍）；
8. 去重（`message_id` / `event_id`）；
9. 通过后才写入"可信视图"；否则仅保留最小诊断记录。

Phase 0.2 的 `osn_protocol` 已实现第 1–4 步（信封层与 Request 字段校验）与第 5 步所需的签名字节生成；`osn_identity` 实现第 5 步的验签。第 6–8 步依赖 Offer/Agreement 与存储，属于 Phase 0.2c / Phase 1 / Phase 0.3。

## 9. 版本演进

- 破坏性变更 → 提升 `schema_version` 主版本；
- 增加可选字段 → 同版本内允许，接收方忽略未知字段**但不参与重新签名**；
- v1 实现的信封层**拒绝未知顶层字段**（避免出现"未签名却被展示"的字段）；`payload` 内部的未知字段会被保留并参与签名；
- 未知 `schema_version` → 拒绝并提示用户升级，**不猜测**；
- 每次变更同步更新：`protocol/schemas/*.json`、测试向量、本文件、`CHANGELOG.md`。

## 10. 测试向量（Phase 0.2 已交付）

`protocol/test-vectors/` 当前包含：

- `jcs/cases.json`：键排序（含 UTF-16 顺序）、字符串转义、非 ASCII 原样输出、安全整数、嵌套；
- `ed25519/rfc8032.json`：RFC 8032 §7.1 的 TEST 1–3（种子、公钥、消息、签名）；
- `envelope/request_created.json`：固定种子 + 固定 payload + 固定 `sent_at` → 固定 did:key、规范化 JSON、签名字节与签名；
- `request/request_v1.json`：固定 Request v1 → 固定规范化 JSON；
- 测试内的篡改用例：逐项修改 payload / `sent_at` / `sender_id` / 签名字节 → 验签必须失败。

浮点输入（`-0.0`、`1e30`、`333333333.33333329`）与孤立代理项作为**拒绝用例**放在单元测试中，因为协议层禁止这些值。

## 11. 实现边界（避免把设计当事实）

已实现：

- `packages/osn_protocol`：无浮点 JCS 子集、严格 JSON 解析、信封模型与校验、签名字节生成；
- `packages/osn_protocol` 的 `Request` v1：类别、地点、时间窗、价格、过期时间、nonce 的逐字段校验；
- `packages/osn_identity`：Ed25519 种子派生、签名/验签、did:key 编解码、信封独立验签；
- `protocol/schemas/envelope.v1.json`：信封 JSON Schema（浮点禁令由实现层补充）；
- `protocol/schemas/request.v1.json`：Request v1 JSON Schema（依赖关系与 nonce 长度由实现层补充）。

尚未实现：

- Offer / Agreement / Event / Review 的业务字段模型与逐字段校验；
- 对象关联、去重、过期与时间偏差策略；
- 存储、网络与完整业务 UI 流程。
