# 信约阁 · PeerServe

[![CI](https://github.com/ZhouXiaoXian233/PeerServe/actions/workflows/ci.yml/badge.svg)](https://github.com/ZhouXiaoXian233/PeerServe/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> 一个开源、无中心业务服务器、以手机为节点的 P2P 需求公告板：直接发布需求、发现需求、联系服务提供者，并记录**参与者自己签名**的协议、事件与评价。

**当前状态：Phase 0.1（工程骨架）——只能跑通 Flutter 应用外壳与测试，尚无身份、协议与网络功能。**

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

## 4. 目录结构（Phase 0.1 现状）

```text
PeerServe/
├── app/mobile/            # Flutter 应用（Android 优先）——当前唯一的可运行代码
│   ├── lib/               # main.dart, app.dart, ui/
│   ├── test/              # widget / smoke 测试
│   └── android/           # Android 宿主工程
├── docs/                  # 设计文档与 ADR（本仓库的"宪法"）
├── .github/workflows/     # CI：analyze + format + test
└── README.md / LICENSE / AGENTS.md / ...
```

> `packages/osn_protocol`、`packages/osn_identity` 等纯 Dart 包**尚未创建**。按本仓库的规则，不为"目录看起来完整"而建空壳：每个包在它的第一个垂直切片开始时才创建（见 [docs/DECISIONS.md](docs/DECISIONS.md) ADR-011）。

## 5. 环境要求

- Flutter **stable**（Dart 3.13+），开发文档按 Flutter 3.47.8 记录
- 目标平台：Android（Phase 0.1 不需要 Android SDK 就能跑 `flutter test`）
- Windows / macOS / Linux 均可开发

完整安装步骤（含国内镜像、Android SDK、真机调试）见 [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)。

检查环境：

```bash
flutter --version
flutter doctor -v
```

## 6. 本地构建与测试

```bash
cd app/mobile

flutter pub get          # 拉取依赖
flutter analyze          # 静态分析（CI 会跑）
dart format --output=none --set-exit-if-changed lib test   # 格式检查
flutter test             # 单元/Widget 测试（CI 会跑）

flutter run              # 连接真机或模拟器运行
flutter build apk --debug   # 需要 Android SDK
```

> 真机验收（两台设备交换签名消息）属于 Phase 2，需要 Android SDK 与两台真机，见 [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)。

## 7. 当前进度

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| Phase 0.1 | Flutter 骨架、目录约定、CI、文档基线 | ✅ 本次 |
| Phase 0.2 | 协议规范化（JCS）+ Ed25519 签名/验签（含测试向量） | ⬜ 下一步 |
| Phase 0.3 | SQLite 持久化与重启恢复验证 | ⬜ |
| Phase 1 | 纯本地业务核心：Request/Offer/Agreement/Event/Review | ⬜ |
| Phase 2 | 两节点直连（Transport + 配对） | ⬜ |
| Phase 3+ | 公告板体验、发现与缓存、安全加固 | ⬜ |

已实现：应用外壳（欢迎页 → 首页）、主题、基础测试与 CI 流水线。

未实现：身份、签名、任何协议模型、数据库、网络传输、P2P 发现。**当前版本不能用于任何真实交易。**

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
