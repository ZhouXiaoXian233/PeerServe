# 路线图

> 原则：先做一个两台手机可以验证的 P2P 公告板，再逐步扩展。**不要在第一个版本同时开发去中心化网络、信用算法、区块链、支付与地图。**

## Phase 0.1 工程骨架 ✅（2026-11-07）

- [x] Flutter Android 项目（`app/mobile`）
- [x] 应用外壳：欢迎页 → 首页占位、主题
- [x] Widget 冒烟测试
- [x] CI：analyze + format + test
- [x] 文档基线：概览、架构、协议、数据模型、网络、安全、UI、测试计划、ADR、路线图
- [x] 仓库治理：LICENSE(MIT)、AGENTS.md、CONTRIBUTING、CODE_OF_CONDUCT、SECURITY、Issue/PR 模板

**验收**：`flutter analyze` 与 `flutter test` 在干净环境通过。

## Phase 0.2 协议与身份（基础完成）

- [x] 引入 pub workspace 根 `pubspec.yaml`（ADR-011）
- [x] `packages/osn_protocol`：无浮点 JCS、严格 JSON、信封、字段校验
- [x] `packages/osn_identity`：Ed25519 生成/签名/验签、`did:key` 派生
- [x] `protocol/test-vectors/`：JCS、Ed25519（RFC 8032）、信封、篡改用例
- [x] `protocol/schemas/envelope.v1.json`
- [x] 决定 `sender_id`/`sent_at` 纳入签名范围（ADR-013）
- [ ] Offer / Agreement / Event / Review 的业务字段模型与逐字段校验
- [ ] 对象关联、去重、过期与时间偏差策略（依赖存储，Phase 0.3 / 1）

**已完成部分的验收**：RFC 8032 测试向量通过；固定信封向量的签名字节可复算；篡改 payload / `sent_at` / `sender_id` / 签名后验签失败；浮点、重复键、超长消息被拒绝。

## Phase 0.2b Request 模型与本机公告板 ✅（2026-11-07）

- [x] `Request` v1：类别、地点、时间窗、价格、过期时间、nonce、逐字段校验
- [x] Request 装入签名信封，并用 `sender_id` 独立验签（测试覆盖）
- [x] 应用内“需求公告板（内存）”：发布表单、签名状态、折叠的技术详情
- [x] 首页精简为“发布需求 / 查看需求 / 本机身份 / 个人中心”
- [x] 个人中心：昵称、内置头像、简介、常用起终点（仅本机内存）
- [x] 启动示例需求（明确标记，不冒充真实用户）
- [x] 开发者详情 / 技术详情只在 debug 构建显示
- [x] 功能清单移到开发记录 [`FEATURES.md`](FEATURES.md)，不在应用内展示
- [x] web 宿主仅用于本地预览（不是 MVP 发布目标）
- [ ] Offer / Agreement / Event / Review 模型
- [ ] SQLite 持久化

**验收**：`Request.fromJson` 拒绝浮点金额、超长字段、倒置时间窗、越界坐标与非法 nonce；签名后的 Request 可独立验签。

## Phase 0.3 存储

- [ ] SQLite（`drift` + `sqlite3`）表与迁移
- [ ] 重启后数据仍在（集成测试）
- [ ] 导出 / 导入（逐条验签）

## Phase 1 纯本地业务核心

- [ ] Request / Offer / Agreement / Event / Review 生命周期
- [ ] 状态投影 `projectAgreementState`
- [ ] 身份备份（加密导出）
- [ ] `InMemoryTransport` 跑通两节点逻辑
- [ ] 单元测试 U1–U15 全绿

**验收**：不联网，测试可完整模拟创建任务、接受 Offer、签署协议、追加事件、评价。

## Phase 2 两节点直连

- [ ] `Transport` 实现（首选 libp2p，ADR-008）
- [ ] 二维码配对
- [ ] 重连、去重、超时、限速
- [ ] 网络诊断页

**验收**：两台设备不经过项目方服务器交换并验证 Request/Offer/Agreement。

## Phase 3 公告板体验

- [ ] 列表、详情、发布、响应、选择 Offer、签署、时间线、评价、屏蔽
- [ ] 明确的"事实 / 单方声明 / 评价"展示

**验收**：两个用户完成一次从发布到双方确认的演示。

## Phase 4 发现与缓存

- [ ] 摘要广播、TTL、跳数、去重
- [ ] 可选缓存节点、撤回与过期
- [ ] 网络分区测试

**验收**：第三个节点在明确记录的网络条件下能发现被转发的公告。

## Phase 5 安全加固与公开发布

- [ ] 恶意输入与洪泛测试
- [ ] 隐私审查、依赖许可证审计
- [ ] Android 测试构建与安装说明

## Phase 6 可选

- [ ] 外部地图链接、外部支付跳转、多语言、更好的离线缓存
- [ ] 其他客户端实现
- [ ] 最小化公共存证研究（需单独 ADR）
