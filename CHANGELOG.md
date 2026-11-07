# 变更日志

本项目的重要变更都记录在此文件。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划中

- Phase 0.2c：Offer / Agreement / Event / Review 业务对象模型与字段校验
- Phase 0.3：SQLite 持久化与重启恢复验证

## [0.2.1] - 2026-11-07

### 新增

- `osn_protocol` 的 `Request` v1：类别、地点、时间窗、价格、过期时间、nonce 与逐字段校验；拒绝浮点金额、超长字段、倒置时间窗、越界坐标与非法 nonce。
- 应用内“需求公告板（内存）”：本机生成身份、签名 Request、立即独立验签，并显示字段、签名状态与规范化 JSON。
- 应用内“功能清单”页：按“已完成 / 部分完成 / 计划中”展示真实进度。
- web 宿主（`app/mobile/web/`）仅用于本地预览，不属于 MVP 发布目标。
- Request 与信封的集成测试：Request 装入签名信封后可独立验签。

### 变更

- 应用版本提升到 `0.2.1+3`。
- 首页增加“身份与签名演示 / 需求公告板 / 功能清单”三个真实入口。
- 测试计划、路线图、协议规范、架构、数据模型、UI 流程与依赖文档同步更新。

### 说明

- 身份与需求都只在内存中，重启即丢失；没有数据库、网络、P2P。
- 当前版本仍**不能用于任何真实交易**。

## [0.2.0] - 2026-11-07

### 新增

- 根 `pubspec.yaml` 启用 Dart pub workspace，成员为 `app/mobile`、`packages/osn_protocol`、`packages/osn_identity`。
- `osn_protocol`：协议允许值域内的 RFC 8785 JCS 规范化、严格 JSON 解析（重复键/浮点/大小/深度/孤立代理项）、信封模型与校验、签名字节生成。
- `osn_identity`：纯 Dart Ed25519（`cryptography` 2.9.0）、种子派生、签名/验签、`did:key`（Ed25519 multicodec + base58btc）编解码、按 `sender_id` 独立验签。
- `protocol/schemas/envelope.v1.json` 与 `protocol/test-vectors/`：JCS 用例、RFC 8032 TEST 1–3、固定信封向量。
- 应用首页 → “本地身份（内存）”演示页：生成身份、显示 did:key/公钥、查看规范化 JSON、篡改标题后观察验签失败。
- Widget 测试覆盖导航、签名有效状态与篡改失败状态。

### 变更

- 信封签名范围确定为 `{schema_version, type, sender_id, sent_at, payload}`（ADR-013）。
- 签名编码固定为无填充 base64url（64 字节 → 86 字符）。
- 协议层禁浮点：JCS 只实现无浮点子集；`1.0`/`-0.0`/`1e30` 等输入直接拒绝。
- 应用版本提升到 `0.2.0+2`；CI 改为 workspace 下 format + analyze + 双包测试 + Flutter 测试。

### 说明

- 身份只存在内存，重启即丢失；没有数据库、网络、P2P 与真实业务对象模型。
- 当前版本仍**不能用于任何真实交易**。

## [0.1.0] - 2026-11-07

### 新增

- Flutter 应用骨架（`app/mobile`）：应用外壳、主题、欢迎页 → 首页占位流程。
- Widget 冒烟测试与 `flutter test` 基线。
- GitHub Actions CI：`flutter analyze`、格式检查、`flutter test`。
- 项目文档基线：README、架构、协议、数据模型、网络安全、测试计划、ADR（001–011）、路线图。
- 仓库治理文件：MIT LICENSE、AGENTS.md、CONTRIBUTING.md、CODE_OF_CONDUCT.md、SECURITY.md、Issue 模板。

### 说明

- 本版本**不含**身份、签名、数据库、网络与任何业务逻辑；不可用于真实交易。
- 尚未推送远端、尚未配置 release 流程。

[Unreleased]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ZhouXiaoXian233/PeerServe/releases/tag/v0.1.0
