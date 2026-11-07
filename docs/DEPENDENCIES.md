# 依赖与许可证

> 规则：每个新增依赖必须在此登记版本、许可证、维护状态与已知限制（AGENTS.md 规则 13）。

## 1. 当前依赖（Phase 0.2b）

**应用** `app/mobile`：

| 依赖 | 版本 | 许可证 | 用途 | 维护状态 | 已知限制 |
| --- | --- | --- | --- | --- | --- |
| `flutter` (SDK) | 3.47.8 stable | BSD-3-Clause | UI 框架 | 官方 | 无 |
| `flutter_test` (SDK) | 同 SDK | BSD-3-Clause | Widget 测试 | 官方 | 无 |
| `flutter_lints` | 6.0.0 | BSD-3-Clause | 静态分析规则 | 官方 | 规则集偏保守，必要时局部 `ignore` |
| `osn_identity` | workspace | MIT（本仓库） | 身份与信封签名 | 本仓库 | 仅内存身份，无持久化 |
| `osn_protocol` | workspace | MIT（本仓库） | 协议模型与校验 | 本仓库 | 业务对象模型尚未实现 |

**纯 Dart 包**：

| 依赖 | 版本 | 许可证 | 用途 | 维护状态 | 已知限制 |
| --- | --- | --- | --- | --- | --- |
| `cryptography` | 2.9.0 | Apache-2.0 | 纯 Dart Ed25519（`DartEd25519`） | 最近发布 2025-11；单人/小团队维护 | 未使用平台原生加速；必须持续跑 RFC 8032 向量 |
| `test` | 1.31.1 | BSD-3-Clause | 纯 Dart 测试 | Dart 官方 | 无 |
| `lints` | 6.0.0 | BSD-3-Clause | 纯 Dart 分析规则 | Dart 官方 | 无 |

`json_canonicalizer` 1.1.0（Unlicense）曾作为 JCS 候选评估，但其数字路径依赖 Dart `double.toString()`，与协议"禁浮点"的安全目标不一致；本仓库改为自持约 150 行的**无浮点 JCS 子集**，并用固定向量与拒绝测试覆盖。该决定已记录在 ADR-009。

当前没有数据库、网络、平台通道或任何中心业务服务依赖。

## 2. 计划引入（按 Phase）

| 依赖 | 计划版本 | 许可证 | 用途 | 风险 |
| --- | --- | --- | --- | --- |
| `drift` + `sqlite3` | 2.35.x / 3.8.x | MIT | SQLite 与迁移 | `sqlite3_flutter_libs` 已 EOL，改用 `sqlite3` 3.x 自带原生库 |
| `dart_libp2p` | 4.9.1（锁版本） | MIT | Noise + Yamux + TCP/UDX + mDNS | 单人维护、生态年轻；必须适配器隔离 + 契约测试 |
| `flutter_secure_storage` | 11.x | BSD-3 | Keystore 包裹密钥 | 只存包裹密钥，不存明文私钥 |
| `flutter_riverpod` / `go_router` | 3.x / 18.x | MIT | 状态管理与路由 | 首版不用代码生成 |

## 3. 明确不引入

| 不引入 | 原因 |
| --- | --- |
| 区块链节点 / 钱包 / IPFS 守护进程 | 首版不引入链与存证（ADR-007） |
| 任何中心业务后端（Node/Postgres/Redis/Docker） | 项目无服务器（ADR-001、ADR-005） |
| Melos / Nx / Turborepo | Dart pub workspaces 足够 |
| GPL / AGPL / Coopyleft 代码 | 分发许可冲突；仅作阅读参考 |
| 支付 SDK | MVP 不处理资金 |

## 4. 许可证合规

- 本项目代码、协议与文档：**MIT**。
- 依赖必须为 MIT / BSD / Apache-2.0 / Unlicense 等宽松许可。
- 引入新依赖前在 PR 中说明：许可证、为何必要时不自己实现、替代方案。
- 发布前用 `dart pub deps` 与（Phase 5）许可证扫描脚本复核。
