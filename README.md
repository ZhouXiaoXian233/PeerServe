# 信约阁 · PeerServe

[![CI](https://github.com/ZhouXiaoXian233/PeerServe/actions/workflows/ci.yml/badge.svg)](https://github.com/ZhouXiaoXian233/PeerServe/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> 一个开源、无中心业务服务器、以手机为节点的 P2P 需求公告板：直接发布需求、发现需求、联系服务提供者，并记录**参与者自己签名**的协议、事件与评价。

**当前状态：Phase 0.2d（协议、身份、Request/Offer/Agreement 模型）——可生成内存身份、编辑个人资料、发布并验签本机需求、对需求签名响应；协议双签模型已实现，协议 UI 与数据库/网络尚未实现。**

---

## 1. 它解决什么问题

网约车、顺路带物、跑腿代购这类"附近的小协作"，今天几乎都要经过平台：平台掌握入口、匹配、数据和规则，抽佣与规则的透明度由平台单方面决定。

PeerServe 想提供一个**开放工具**而不是一个新平台：

- 需求公告由发布者自己签名、自己保管；
- 匹配与协商发生在两个人之间，不经过项目方服务器；
- 谁签署了什么、谁声明了什么，是**可验证的事实**；
- 服务好坏的评价是**参与者的意见**，不是系统判决。

## 2. 它是什么 / 不是什么

| 是 | 不是 |
| --- | --- |
| 一个开放协议 + 参考客户端（Android 优先） | 一个中心化平台或 SaaS |
| 用户自己持有密钥与本地完整记录 | 一个托管资金的支付系统 |
| 追加式、可验证的签名事件记录 | 一条区块链，也不发行任何代币 |
| 区分"事实记录"与"主观评价"的展示层 | 一个自动仲裁、自动封禁的信用系统 |
| 一个实验性原型 | 已在安全/法律上评估过的商用出行或配送平台 |

**明确不做**：发币、NFT、代币激励、链上共识、中心业务 API、强制全局信用分、AI 自动裁决。

## 3. 架构

```text
┌──────────────────────────────────────────┐
│              Flutter 客户端               │
├──────────────────────────────────────────┤
│ ui            页面与交互                  │
│ tasks / events / reviews                  │
│   Request · Offer · Agreement · Event      │
│ identity      Ed25519 密钥、签名、验签     │
│ protocol      模型、JCS 规范化、schema     │
│ storage       SQLite 本地持久化与导入导出   │
│ network       Transport 抽象与节点连接      │
│ trust_view    事实 / 评价分开呈现           │
└──────────────────────────────────────────┘
        ↕ 直连 P2P 消息（无项目方服务器）
   其他用户自有的手机节点
```

模块之间通过接口通信；UI 不直接写 SQL，也不直接操作套接字。详见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 4. 目录结构（Phase 0.2 现状）

```text
PeerServe/
├── pubspec.yaml           # pub workspace 根（单一 lockfile）
├── app/mobile/            # Flutter 应用（Android 优先；web 仅本地预览）
│   ├── lib/               # main.dart, app.dart, ui/
│   ├── test/              # widget / 导航 / 身份 / 公告板测试
│   └── web/               # 本地预览用 web 宿主（非发布目标）
├── packages/
│   ├── osn_protocol/      # 无浮点 JCS、严格 JSON、信封、Request 模型
│   └── osn_identity/      # Ed25519、did:key、信封签名/验签
├── protocol/
│   ├── schemas/           # envelope.v1.json
│   └── test-vectors/      # JCS、RFC 8032、固定信封向量
├── docs/                  # 设计文档与 ADR（本仓库的"宪法"）
├── tool/                  # 固定向量生成脚本
├── .github/workflows/     # CI：format + analyze + test
└── README.md / LICENSE / AGENTS.md / ...
```

> `osn_storage`、`osn_transport`、`osn_trust_view` 仍**未创建**：按 ADR-011，包只在对应垂直切片开始时才创建，不建空壳。

## 5. 环境要求

- Flutter **stable**（Dart 3.13+），开发文档按 Flutter 3.47.8 记录
- 目标平台：Android（Phase 0/1 不需要 Android SDK 就能跑 `flutter test`）
- Windows / macOS / Linux 均可开发

完整安装步骤（含国内镜像、Android SDK、真机调试）见 [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)。

检查环境：

```bash
flutter --version
flutter doctor -v
```

## 6. 本地构建与测试

工作区根目录：

```bash
dart pub get
dart test packages/osn_protocol
dart test packages/osn_identity
```

应用：

```bash
flutter analyze app/mobile
flutter test app/mobile
flutter run -d android          # 需要 Android SDK 与设备/模拟器
flutter run -d chrome           # 仅本地预览；不是发布目标
flutter build apk --debug       # 需要 Android SDK
```

> `web/` 只是为了在没有 Android 设备时快速看界面，不属于 MVP 验收平台。真机验收（两台设备交换签名消息）属于 Phase 2，需要 Android SDK 与两台真机。

格式检查：

```bash
dart format --output=none --set-exit-if-changed app/mobile/lib app/mobile/test packages tool
```

> 真机验收（两台设备交换签名消息）属于 Phase 2，需要 Android SDK 与两台真机，见 [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)。当前的内存身份演示可在 `flutter test` 或应用首页进入。

## 7. 当前进度

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| Phase 0.1 | Flutter 骨架、目录约定、CI、文档基线 | ✅ |
| Phase 0.2 | 协议规范化（无浮点 JCS）+ Ed25519 + did:key + 信封（含测试向量） | ✅ 基础完成 |
| Phase 0.2b | Request v1 + 本机签名公告板 + 发布表单 + 个人中心 + 类别筛选 | ✅ |
| Phase 0.2c | Offer v1 + 本机签名响应 | ✅ |
| Phase 0.2d | Agreement v1 + 双信封签署规则 | ✅ 本切片 |
| Phase 0.2e | Event / Review 业务模型 | ⬜ 下一步 |
| Phase 0.3 | SQLite 持久化与重启恢复验证 | ⬜ |
| Phase 1 | 纯本地业务核心：发布→响应→签署→事件→评价 | ⬜ |
| Phase 2 | 两节点直连（Transport + 配对） | ⬜ |
| Phase 3+ | 公告板体验、发现与缓存、安全加固 | ⬜ |

已实现：

- `osn_protocol`：无浮点 JCS 子集、严格 JSON（重复键/浮点/大小/深度）、信封模型与校验、Request v1、Offer v1、Agreement v1；
- `osn_identity`：Ed25519 种子派生、签名/验签、`did:key` 编解码、按 `sender_id` 独立验签；
- 固定向量：RFC 8032 TEST 1–3、JCS 用例、固定信封/Request/Offer/Agreement 向量；
- UI：暖纸主题 + 渐变 Hero；首页 → “发布需求 / 最近需求 / 本机身份 / 个人中心”；需求列表支持类别筛选和“响应这条需求”；技术详情只在 debug 构建显示。
- 启动时放入 4 条明确标记“示例”的签名需求，用于在没有其他节点时查看列表形态；它们不是真实用户。

未实现：Offer / Agreement / Event / Review、数据库、网络传输、P2P 发现、真实交易流程。**当前版本不能用于任何真实交易。**

> 开发用功能清单在 [docs/FEATURES.md](docs/FEATURES.md)，不在应用内展示。

## 8. 安全与隐私限制（务必阅读）

- **签名不证明现实**：密钥签名只证明"某把密钥签署了这段数据"，不证明车真的来了、货真的送到。
- **P2P 不等于匿名**：IP 地址、连接时间、广播内容仍可能暴露信息。
- **无中心服务器 ≠ 一定连得上**：节点发现与 NAT 穿透可能需要可替换的中继/信令基础设施，详见 [docs/NETWORK_DESIGN.md](docs/NETWORK_DESIGN.md)。
- **广播出去的数据收不回来**：撤回只是新事件，无法保证所有缓存节点删除副本。
- **评价是意见**：可能被串通刷单，也可能包含诽谤；客户端只做来源与签名校验，不做"定罪"。
- **不托管资金**：应用不处理付款、不担保履约、不代管退款。
- **本原型未做安全与法律评估**：网约车、食品配送、快递与劳务涉及当地许可、保险与人身安全义务，软件不替代这些义务。

安全问题报告流程见 [SECURITY.md](SECURITY.md)。

## 9. 参与贡献

- 先读 [AGENTS.md](AGENTS.md)（面向 AI 与人类贡献者的硬性规则）与 [docs/DECISIONS.md](docs/DECISIONS.md)。
- 一个 PR 只做一个可验证的垂直切片；协议变更必须同时更新 schema、文档、测试向量与版本号。
- 提交前必须真实运行 `flutter analyze` 与 `flutter test`，并在 PR 里贴出结果。
- 交流与行为准则见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)，安全问题见 [SECURITY.md](SECURITY.md)。

## 10. 许可证

代码、协议与文档均以 [MIT](LICENSE) 许可发布，除非文件内另有声明。

第三方依赖的许可证与已知限制记录在 [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md)。
