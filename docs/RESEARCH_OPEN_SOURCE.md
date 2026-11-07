# 开源借鉴与技术选型调研（Phase 0 前置）

> 调研日期：2026-10-25  
> 状态：提案。维护者确认后，把结论拆成 ADR 写入 `docs/DECISIONS.md`。  
> 约束：无中心业务服务器、不发币、不自研密码学、Android 优先、AI 辅助开发可维护。  
> 数据来源：GitHub 仓库页/API、pub.dev API、Flutter 官方文档（版本与热度为调研当日快照）。

## 0. 结论摘要

1. **客户端**：Flutter 3.47.8 stable / Dart 3.13.7，先做 Android。本机只需补装 Flutter SDK 与 Android SDK。
2. **业务核心**：纯 Dart 包（协议、身份、存储、信任视图）+ 一个 Flutter app；用 Dart pub workspaces 管理，不引入 Melos。
3. **密码学**：Ed25519 用 `cryptography`，签名前用 RFC 8785 JCS 规范化；协议层**禁止浮点数**（金额用最小单位整数，经纬度用 1e-7 整数），绕开 JCS 最大的跨语言坑。
4. **网络**：先定义 `Transport` 接口 + `InMemoryTransport`；Phase 2 首选 `dart_libp2p`（Noise + Yamux + TCP/UDX + mDNS，MIT），用二维码交换 multiaddr 完成手动配对。`nearby`（mDNS+BLE）作为离线/无网备选，`iroh` 只在 NAT 穿透成为硬需求时再评估。
5. **不引入**：区块链、代币、托管支付、全局信用分、Rust 工具链、任何中心业务后端。P2P 发现所需的中继/bootstrap 必须作为“可替换基础设施”写进文档，不能宣称“零基础设施”。

## 1. 可借鉴的开源项目（产品与协议层）

| 项目 | 类型 / 许可 | 活跃度 | 值得借鉴 | 不要照搬 |
|---|---|---|---|---|
| [Briar](https://github.com/briar/briar) | Android P2P 通讯，Tor / Wi-Fi / 蓝牙；GPL-3.0 | 活跃，官方仓库在 code.briarproject.org | 公告板/论坛式签名帖子、二维码验证联系人、无账号身份、离线队列与 TTL | Tor 依赖、Bramble 协议栈、GPL 代码（只读参考） |
| [Berty](https://github.com/berty/berty) | 离线优先 P2P 通讯；Apache-2.0 或 MIT | 活跃（2026-10） | BLE + mDNS 的移动端传输分层、应用生命周期处理、网络诊断信息、无手机号身份 | Go/React Native 栈、IPFS/OrbitDB 的复杂度 |
| [Nostr](https://github.com/nostr-protocol/nostr) / [dart-nostr](https://github.com/ethicnology/dart-nostr) | 签名事件 + relay；开源 | dart-nostr 活跃（2026-08） | 事件信封、过期时间（NIP-40）、删除请求（NIP-09）、多 relay 冗余与去重 | 全局公开时间线、把 kind 体系当业务模型、把公共 relay 当唯一发现层 |
| [SSB](https://github.com/ssbc/ssb-server) / [Manyverse](https://github.com/staltz/manyverse) | 追加式签名 feed；开源 | Manyverse 2024 后基本停更 | 每条 feed 用 `previous` 哈希串联、部分复制、离线优先 | secret-handshake / muxrpc 整套栈 |
| [OpenBazaar](https://github.com/OpenBazaar/openbazaar-go) | 去中心化市场（已归档）；MIT | 2021 起停更 | Ricardian contract 的“人读 + 机读”双层结构、订单状态机、争议证据导出 | 加密托管、IPFS、已停维护的代码 |
| [Particl](https://github.com/particl/particl-desktop) | P2P 市场 + 隐私币；GPL-2.0 | 活跃（2026-01） | 无账号下单流程、两方托管的状态与 UX（本项目只记录、不托管） | 区块链、PART、SMSG 存储网络 |
| [CoopCycle](https://github.com/coopcycle/coopcycle-web) | 合作社配送平台；Coopyleft（非 OSI 开源） | 活跃（2026-10） | 取送点、时间窗、价格、路线等配送领域字段；骑手端 UX；外部地图链接 | 代码（许可限制商用）、中心化后端 |
| [qaul.net](https://github.com/qaul/qaul.net) | 无互联网 mesh 通讯，Rust；AGPL-3.0 | 活跃（2026-10） | mesh 场景的能力分级、降级提示、“无网络也能用”的信息架构 | Rust 重栈、AGPL 代码 |
| [iroh](https://github.com/n0-computer/iroh) | 按公钥拨号的 QUIC + 打洞 + relay；MIT/Apache-2.0 | 活跃（2026-10） | 以公钥为地址、直连失败回退 relay 的显式策略、relay 可自托管 | MVP 阶段引入 Rust 工具链 |
| [JCS 参考实现](https://github.com/cyberphone/json-canonicalization) | RFC 8785 + 跨语言测试向量；Apache-2.0 | 维护中 | 官方 test vectors、数字/Unicode/代理对边界用例 | Java/Go 实现代码 |

**取舍原则**：借鉴“信息架构、状态机、交互与协议字段”，不借鉴“重共识、重代币、重托管、重基础设施”的实现。

## 2. 可复用的 Dart / Flutter 组件

| 组件 | 版本（2026-10） | 许可 / 热度 | 用途 | 风险与备注 |
|---|---|---|---|---|
| `dart_libp2p` | 4.9.1 | MIT；8 likes，约 2.5k 次/月 | Noise 加密、Yamux 多路复用、TCP/UDX、mDNS、打洞与 relay | 单人维护、2025-07 才起步；必须锁版本 + 契约测试 + 可替换适配器 |
| `dart_libp2p_kad_dht` / `_pubsub` | 1.6.0 / 3.1.0 | MIT；低热度 | Phase 4 的 DHT 与 GossipSub | 只评估，不进 MVP |
| `nearby` | 0.2.0 | BSD-3；1 like，很新 | mDNS + BLE + TCP 会话，自动发现，PIN/PSK 认证 | 2026-10 才发布；Android 12+ 蓝牙权限、BLE 广播受系统限制 |
| `iroh_flutter` | 1.2.0 | MIT/Apache-2.0；1 like | QUIC、打洞、relay，按公钥拨号 | 构建时自动装 Rust（cargokit），依赖公共 relay；不是 MVP 选项 |
| `flutter_webrtc` | 1.6.2 | MIT；4.5k stars | WebRTC DataChannel | 需要信令交换；跨 NAT 需 STUN/TURN（可能产生费用） |
| `drift` + `sqlite3` | 2.35.3 / 3.8.0 | MIT；高热度 | 类型安全 SQLite、迁移、响应式查询 | `sqlite3_flutter_libs` 已 EOL（0.6.0+eol），用 `sqlite3` 3.x 自带原生库 |
| `cryptography` | 2.9.0 | MIT；315 likes，约 11 万次/月 | Ed25519、X25519、AES-GCM、HKDF、Argon2id | 上次发布 2025-11，需关注维护；用 RFC 8032 向量自测 |
| `cryptography_flutter` | 2.3.4 | MIT | 平台原生加速 | Android Keystore 对 Ed25519 的原生支持因版本/厂商而异，不能作为设计前提；按“Keystore 包裹密钥 + 软件 Ed25519”处理 |
| `flutter_secure_storage` | 11.2.0 | BSD-3；高热度 | Keystore/Keychain 保护的密钥材料 | 只存“包裹密钥”，不要存明文私钥到日志 |
| `json_canonicalizer` | 1.1.0 | Unlicense；0 likes | RFC 8785 JCS（含官方语料、UTF-16 排序、`-0`、`1e+30`） | 很新；必须跑上游 test vectors 后再信任，必要时 fork |
| `mobile_scanner` + `qr_flutter` | 7.4.2 / 4.1.0 | BSD-3 / BSD-3 | 二维码配对 | 相机权限；二维码内容要限长、校验 |
| `flutter_riverpod` / `go_router` | 3.4.3 / 18.1.1 | MIT | 状态管理与路由 | 首版不用代码生成，降低构建复杂度 |
| `mdns_dart` | 2.2.2 | MIT | 独立 mDNS | 若不用 libp2p 内置 mDNS 才需要 |

## 3. Phase 2 传输方案对比

| 方案 | 无项目方服务器 | 跨公网 | 发现 | 加密 | 应用层工作量 | 结论 |
|---|---|---|---|---|---|---|
| **dart_libp2p** | 是（relay/DHT 为可替换基础设施） | 打洞 + relay 可用 | mDNS + 手动 multiaddr | Noise（与身份公钥绑定） | 中 | **首选**，同一栈可延伸到 Phase 4 |
| `nearby` | 是 | 否（局域网/BLE） | 自动 mDNS + BLE | 会话加密 + PIN/PSK | 低 | 离线演示与 BLE 备选 |
| `iroh_flutter` | 是（公共 relay 可自建） | 是，打洞成功率高 | 按公钥 + DNS | QUIC/TLS 1.3 | 低（但构建重） | NAT 穿透成为硬需求时再上 |
| WebRTC | 是（信令自定） | 需 STUN/TURN | 手动/二维码信令 | DTLS-SRTP | 高（SDP 交换 UX） | 不作为首版 |
| Nostr relay | 是（relay 第三方） | 是 | relay 订阅 | 事件签名，传输层 TLS | 低 | Phase 4 广播备选，不是“直连” |
| 裸 TCP + 自签 TLS | 是 | 需端口/公网 IP | 手动 | TLS（自签需 pin） | 中 | 不推荐，重复造轮子 |

**建议**：`Transport` 接口保持不变；Phase 2 只实现 `Libp2pTransport`（TCP + Noise + mDNS + 二维码 multiaddr），把“离线 BLE”留成第二个适配器。NAT 穿透与 DHT 明确标注为“未实现/实验性”，不在 MVP 承诺。

## 4. 建议的工程结构

```text
peerserve/
├── pubspec.yaml                 # Dart pub workspace 根
├── app/mobile/                  # Flutter UI 与平台集成
├── packages/
│   ├── osn_protocol/            # 模型、JCS、schema 校验、测试向量
│   ├── osn_identity/            # Ed25519、did:key 派生、备份加密
│   ├── osn_storage/             # drift/sqlite3、迁移、导入导出
│   ├── osn_transport/           # Transport 接口、InMemory、libp2p 适配器
│   └── osn_trust_view/          # 事实/评价投影，不计算总分
├── protocol/
│   ├── schemas/                 # JSON Schema
│   └── test-vectors/            # JCS、签名、事件链
├── docs/
└── scripts/
```

- 纯 Dart 包不依赖 Flutter，`dart test` 秒级反馈；UI 只依赖接口。
- 先建 `protocol`、`identity`、`storage`、`app` 与 `transport` 的接口；**不要**为目录完整创建空壳。
- Phase 0 可先做单包 `app/mobile`，验证通过后再拆包；拆包成本低于长期耦合成本。

## 5. 协议层的具体建议（需写入 ADR）

1. **JCS + 无浮点**：签名对象只允许 string / bool / null / int / array / object；金额 `amount_minor` 为整数，经纬度用 `latitude_e7` / `longitude_e7`（整数，1e-7 度）。这样既满足“规范化可复现”，又避免 Dart `double.toString()` 与 ECMAScript 的差异。
2. **签名域分离**：签名字节 = UTF-8(`"PeerServe:v1:"` + JCS(payload))，防止同一密钥在其他协议中的签名被重放。签名放在信封外层，不参与自身规范化。
3. **身份标识**：优先 `did:key`（ed25519-pub, multibase base58btc），自描述、无注册中心；若依赖过重，退回 `osn1` + base32(SHA-256(pubkey))。两种都要有固定测试向量，且**不得**把昵称/手机号混入 ID。
4. **事件链**：`previous_event_hash` 按 `(agreement_id, actor_id)` 维度串链，值为上一条已签名事件的 SHA-256；冲突事件两条都保留，视图标记 `conflicting`。
5. **时间**：只接受 UTC ISO-8601（毫秒），设备时间仅作声明；另存 `received_at_local`，UI 必须区分。
6. **撤回与过期**：公告带 `expires_at`；撤回是新的签名事件，缓存节点收到后停止转发，但不承诺远端删除。
7. **评价约束**：`reviewer_id` 必须是 Agreement 参与者；同一 `(agreement_id, reviewer_id)` 只能有一条有效评价，修改发布新版本并引用旧 `review_id`。

## 6. Phase 0 技术验证清单（按顺序）

1. **JCS**：跑 RFC 8785 附录 B 与上游语料；重点 `-0`、`1e+30`、`333333333.33333329`、lone surrogate、UTF-16 键排序。决定用 `json_canonicalizer` 还是自持 150 行实现。
2. **Ed25519**：RFC 8032 向量；签名/验签 1 万次性能；确认 libp2p 可复用同一 Ed25519 密钥（PeerId 由公钥派生）。
3. **SQLite**：drift + `sqlite3` 3.8 在 Android 上建库、迁移、WAL、杀进程重启后数据仍在；确认不再需要 `sqlite3_flutter_libs`。
4. **libp2p on Android**：TCP 监听、mDNS 发现、Noise 握手、二维码 multiaddr 配对；前后台切换后的连接行为；UDP/UDX 是否可用。
5. **密钥存储**：`flutter_secure_storage` 保存包裹密钥；Ed25519 私钥 AES-GCM 加密落盘；Argon2id 备份口令；日志中无密钥。
6. **两机验收**：同一 Wi-Fi、手机热点、飞行模式三种场景；记录 NAT/发现/延迟的真实结果。
7. **体积与启动**：APK 大小、冷启动时间、首屏可用时间。

## 7. 风险登记

| 风险 | 影响 | 缓解 |
|---|---|---|
| `dart_libp2p` 单人维护、生态年轻 | 升级断档、Android 兼容问题 | 锁版本、适配器隔离、契约测试、保留 `nearby` 备选 |
| JCS 数字/Unicode 边界 | 跨端签名不一致 | 协议禁浮点 + 官方向量 + 双实现比对 |
| 公共 relay/bootstrap 依赖 | 可用性与隐私争议 | 文档披露、可配置多个、支持自托管、UI 显示连接路径 |
| Android BLE/mDNS 权限与省电策略 | 发现失败、后台断连 | 前台服务、明确“仅前台/局域网”限制、诊断页 |
| Keystore 对 Ed25519 支持不确定 | 无法硬件级签名 | 明确记录限制；用 Keystore 包裹密钥，签名在软件层完成 |
| 二维码配对 UX | 首次连接步骤多 | 仅 Phase 2 技术验证使用；后续再做附近发现 |
| 依赖许可 | 分发合规 | 只用 MIT/BSD/Apache；GPL/AGPL/Coopyleft 仅作阅读参考 |

## 8. 参考链接

- Flutter 版本与安装：[Flutter releases JSON](https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json)、[Android 环境配置](https://docs.flutter.dev/platform-integration/android/setup)、[手动安装](https://docs.flutter.dev/install/manual)
- 协议规范化：[RFC 8785](https://www.rfc-editor.org/rfc/rfc8785)、[JCS 参考实现与语料](https://github.com/cyberphone/json-canonicalization)
- 传输：[dart_libp2p](https://github.com/stephanfeb/dart_libp2p)、[nearby](https://pub.dev/packages/nearby)、[iroh](https://github.com/n0-computer/iroh)、[iroh_flutter](https://pub.dev/packages/iroh_flutter)
- 参考产品：[Briar](https://github.com/briar/briar)、[Berty](https://github.com/berty/berty)、[Nostr](https://github.com/nostr-protocol/nostr)、[OpenBazaar](https://github.com/OpenBazaar/openbazaar-go)、[Particl](https://github.com/particl/particl-desktop)、[CoopCycle](https://github.com/coopcycle/coopcycle-web)、[qaul.net](https://github.com/qaul/qaul.net)
