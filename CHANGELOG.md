# 变更日志

本项目的重要变更都记录在此文件。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划中

- Phase 0.2c：Offer / Agreement / Event / Review 业务对象模型与字段校验
- Phase 0.3：SQLite 持久化与重启恢复验证

## [0.2.5] - 2026-11-07

### 新增

- `osn_protocol` 的 `Offer` v1：`offer_id`、`request_id`、`provider_id`、说明、可选报价/时间、有效期。
- `offer.v1.json` Schema 与固定 Offer 向量。
- 需求卡片增加“响应这条需求”：填写说明/报价，签名后立即验签，并显示“我的响应”。
- 示例需求也可以响应；响应只保存在本机，不会真的送达发布者。

### 变更

- 应用版本提升到 `0.2.5+7`。
- 协议规范、路线图、测试计划、功能清单与 UI 流程同步更新。

### 说明

- Offer 只表示响应方的声明，不代表需求方接受。
- 仍为内存演示：重启后响应也会丢失。

## [0.2.4] - 2026-11-07

### 变更

- 重做视觉主题：暖纸背景、深绿主色、陶土强调、圆角卡片、更宽松的排版与按钮/输入框样式。
- 首页改为渐变 Hero + “最近需求”预览 + 本机身份入口，减少纯文字说明。
- 个人中心改为渐变资料头 + 表单，头像与昵称更醒目。
- 需求列表增加“全部 / 出行 / 带物 / 餐饮 / 跑腿 / 其他”类别筛选。
- 应用版本提升到 `0.2.4+6`。

### 说明

- 开发者详情 / 技术详情仍只在 `kDebugMode` 显示。
- 功能清单仍在 [`docs/FEATURES.md`](docs/FEATURES.md)，不在应用内。

## [0.2.3] - 2026-11-07

### 新增

- 个人中心：昵称、内置头像、简介、常用起终点；资料只保存在本机内存。
- 首页右上角头像入口 + 问候语；个人资料会影响发布表单的默认起终点。
- 启动时放入 4 条明确标记“示例”的签名需求，便于在没有其他节点时查看列表形态。
- 发布表单增加内联错误提示，避免错误 SnackBar 被底部弹层遮住。
- 开发者详情/技术详情只在 `kDebugMode` 显示，release 构建不出现。

### 变更

- 需求列表显示发布者头像、昵称与“示例”标记。
- 应用版本提升到 `0.2.3+5`。

### 说明

- 示例身份与示例需求均为运行时生成，仅用于演示，不代表真实用户。
- 头像首版使用内置表情；图片上传需要本地存储与权限，后续再加。
- 仍为内存演示：重启后身份、资料、需求都会丢失。

## [0.2.2] - 2026-11-07

### 变更

- 功能清单移出应用，改为开发记录 [`docs/FEATURES.md`](docs/FEATURES.md)；页面不再展示路线图式内容。
- 本机身份与需求改为共享 `AppSession`，页面之间不再各自生成身份。
- 首页精简为“发布需求 / 查看本机需求 / 本机身份”三个入口，移除开发路线、设计边界长卡片。
- 需求页增加真实发布表单（标题、类别、预算、起终点、说明），技术详情折叠隐藏。
- 身份页只显示状态与身份标识；公钥、签名、规范化 JSON 与篡改测试收进“开发者详情”。
- 应用版本提升到 `0.2.2+4`。

### 说明

- 仍为内存演示：重启后身份与需求都会丢失。

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

[Unreleased]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.5...HEAD
[0.2.5]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ZhouXiaoXian233/PeerServe/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ZhouXiaoXian233/PeerServe/releases/tag/v0.1.0
