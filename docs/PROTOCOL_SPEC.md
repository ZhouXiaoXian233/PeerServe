# 协议规范（设计目标，Phase 0.2 起实施）

> 状态：**设计基线**。本文件描述将来必须满足的规则；目前尚无任何实现。
> 版本：`schema_version = 1`（未发布）

## 1. 设计目标

1. **自描述**：每条签名对象都能独立验证，接收方不需要中心服务提供上下文。
2. **跨语言可复现**：任何客户端用任何语言都能得到相同签名字节。
3. **可演进**：版本号显式，未知版本安全拒绝而不是猜测。
4. **不承诺现实**：协议只表达"谁声明了什么"，不表达"世界真的如此"。

## 2. 签名域分离

```text
signed_bytes = UTF-8( "PeerServe:v1:" + JCS(payload) )
signature    = Ed25519.sign(private_key, signed_bytes)
```

- 前缀 `PeerServe:v1:` 是**域分离**，防止同一密钥在其他协议（SSH、签名邮件、其他 DApp）中的签名被重放到本协议。
- `JCS(payload)` 为 [RFC 8785](https://www.rfc-editor.org/rfc/rfc8785) 规范化 JSON。
- **签名不在 payload 内**：签名放在信封外层，避免"签名覆盖签名自己"的递归问题。

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
| `signature` | ✅ | 对 `payload` 的签名（不含 `sender_id`/`sent_at`，见下） |

> 待定（Phase 0.2 决策）：`sender_id`/`sent_at` 是否纳入签名范围。倾向**纳入**（构造 `signing_payload = {schema_version, type, sender_id, sent_at, payload}`），以防发送方身份被替换。此处保持显式 TODO，不做未验证的假设。

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

## 9. 版本演进

- 破坏性变更 → 提升 `schema_version` 主版本；
- 增加可选字段 → 同版本内允许，接收方忽略未知字段**但不参与重新签名**；
- 未知 `schema_version` → 拒绝并提示用户升级，**不猜测**；
- 每次变更同步更新：`protocol/schemas/*.json`、测试向量、本文件、`CHANGELOG.md`。

## 10. 测试向量（Phase 0.2 交付）

`protocol/test-vectors/` 至少包含：

- `jcs/`：RFC 8785 附录 B 用例，重点 `-0`、`1e+30`、`333333333.33333329`、lone surrogate、UTF-16 键排序；
- `ed25519/`：RFC 8032 §7.1 向量；
- `envelope/`：固定密钥 + 固定 payload → 固定签名字节；
- `tamper/`：逐字段篡改 → 验签必须失败。
