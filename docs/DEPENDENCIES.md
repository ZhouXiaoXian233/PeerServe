# 依赖与许可证

> 规则：每个新增依赖必须在此登记版本、许可证、维护状态与已知限制（AGENTS.md 规则 13）。

## 1. 当前依赖（Phase 0.1）

**应用** `app/mobile`：

| 依赖 | 版本 | 许可证 | 用途 | 维护状态 | 已知限制 |
| --- | --- | --- | --- | --- | --- |
| `flutter` (SDK) | 3.47.8 stable | BSD-3-Clause | UI 框架 | 官方 | 无 |
| `flutter_test` (SDK) | 同 SDK | BSD-3-Clause | Widget 测试 | 官方 | 无 |
| `flutter_lints` | 见 `pubspec.yaml` | BSD-3-Clause | 静态分析规则 | 官方 | 规则集偏保守，必要时局部 `ignore` |

当前**没有**运行时第三方依赖：应用外壳只使用 Flutter SDK 自带能力。

## 2. 计划引入（按 Phase）

| 依赖 | 计划版本 | 许可证 | 用途 | 风险 |
| --- | --- | --- | --- | --- |
| `cryptography` | 2.9.x | MIT | Ed25519 / AES-GCM / HKDF / Argon2id | 上次发布 2025-11，需关注维护；必须跑 RFC 8032 向量 |
| `json_canonicalizer` 或自持实现 | 1.1.x / 内部 | Unlicense / MIT | RFC 8785 JCS | 库很新、热度低；先跑上游语料，不合格则 fork 或自持约 150 行实现 |
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
