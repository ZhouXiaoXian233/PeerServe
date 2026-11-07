# 数据模型与本地存储

> 状态：**设计草案**。Request v1 已有内存数据模型与校验（`osn_protocol`），但 Phase 0.3 才用 SQLite 落库；当前代码中不存在任何表。

## 1. 原则

1. 保存**原始签名载荷**（`payload_json` + `signature`），不只保存渲染后的文本。
2. 按 ID 去重；重复事件不产生新行。
3. 签名无效的数据不得进入"可信"表；最多保留最小诊断记录。
4. schema 变更走迁移脚本，不在运行时随手改表。
5. 本地库是**部分视图**，不是全网真相。

## 2. 表（草案）

### 2.1 `identities`

| 列 | 类型 | 说明 |
| --- | --- | --- |
| `identity_id` | TEXT PK | 公钥派生标识（`did:key`） |
| `public_key` | TEXT NOT NULL | base64url 或 multibase |
| `display_name` | TEXT | 可变资料，非身份 |
| `created_at` | TEXT NOT NULL | ISO-8601 UTC |
| `is_active` | INTEGER NOT NULL | 0/1，多身份场景 |

> **不存未加密私钥**。私钥存系统安全存储（Keystore 包裹）或加密文件，表中最多存引用。

### 2.2 `requests`

`request_id` PK · `creator_id` · `schema_version` · `category` · `payload_json` · `signature` · `created_at` · `expires_at` · `local_status`（`active/withdrawn/expired`）· `source_peer_id`

### 2.3 `offers`

`offer_id` PK · `request_id` · `provider_id` · `payload_json` · `signature` · `created_at`

### 2.4 `agreements`

`agreement_id` PK · `request_id` · `offer_id` · `payload_json` · `requester_signature` · `provider_signature` · `verification_status`（`pending/mutually_signed/conflicting/invalid`）· `created_at`

### 2.5 `events`

`event_id` PK · `agreement_id`（可空）· `actor_id` · `event_type` · `payload_json` · `signature` · `created_at_device` · `received_at_local` · `verification_status` · `previous_event_hash`（可空）

### 2.6 `reviews`

`review_id` PK · `agreement_id` · `reviewer_id` · `reviewee_id` · `payload_json` · `signature` · `created_at` · `verification_status` · `supersedes_review_id`（可空）

### 2.7 `peers`

`peer_id` PK · `public_key` · `last_seen_at` · `connection_info_json` · `trust_label`（本地标签）· `blocked_locally`（默认 0）

### 2.8 `seen_messages`

`message_id` PK · `first_seen_at` · `expires_at` · `source_peer_id`

> 用于去重与 TTL 清理；不保存消息内容。

## 3. 索引

- `requests(expires_at)`、`requests(category)`：列表与过期过滤。
- `offers(request_id)`：查看某需求的所有响应。
- `events(agreement_id, actor_id, sequence_number)`：事件链重放。
- `reviews(agreement_id)`、`reviews(reviewee_id)`：评价展示。
- `seen_messages(expires_at)`：定期清理。

## 4. 状态投影

`Agreement` 的展示状态由事件推导，**不落库为权威字段**：

```text
agreements.verification_status = pending
  + 双方签名齐全且有效        → mutually_signed
  + service.started           → in_progress
  + completion.claimed        → completion_claimed（单方）
  + completion.confirmed(双方) → mutually_confirmed
  + service.cancelled         → cancelled
  + dispute.statement_added   → disputed（附注，不判定对错）
```

派生规则集中在一个纯函数里（`projectAgreementState(events)`），便于测试与复用。

## 5. 导入 / 导出

- 导出格式：JSON Lines，每行一个信封（含签名），外加 `manifest.json`（版本、导出时间、身份 ID、条目数）。
- 导入必须**逐条重新验签**；失败的条目进入 `rejected/` 报告，不静默丢弃。
- 导出内容不含私钥；身份备份是独立的加密文件（ADR-010）。
- 导入幂等：重复条目按 ID 覆盖/跳过，不产生重复事件。

## 6. 迁移

- 每个迁移有编号与说明（`migrations/0001_init.sql`），只前进不回滚。
- 迁移前自动备份数据库文件到应用私有目录，并保留最近 N 份。
- 迁移失败时不得进入半迁移状态（事务包裹）。
