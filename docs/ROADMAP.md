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

## Phase 0.2 协议与身份（下一步）

- [ ] 引入 pub workspace 根 `pubspec.yaml`（ADR-011）
- [ ] `packages/osn_protocol`：模型、JCS 规范化、字段校验、禁浮点
- [ ] `packages/osn_identity`：Ed25519 生成/签名/验签、`did:key` 派生
- [ ] `protocol/test-vectors/`：JCS(RFC 8785)、Ed25519(RFC 8032)、信封、篡改用例
- [ ] 决定 `sender_id`/`sent_at` 是否纳入签名范围

**验收**：固定向量签名在 Dart 与（脚本生成的）参考实现下字节一致；篡改任一字段验签失败。

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
