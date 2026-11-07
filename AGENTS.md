# AGENTS.md

本文件面向在本仓库工作的 AI 编程助手（DeepSeek 等）与人类贡献者。**任何任务开始前先读本文件。**

---

## 0. 开工前必读

1. `README.md`
2. `docs/PROJECT_OVERVIEW.md`
3. `docs/ARCHITECTURE.md`
4. `docs/DECISIONS.md`
5. 与本任务相关的模块文档（`docs/PROTOCOL_SPEC.md`、`docs/DATA_MODEL.md`、`docs/NETWORK_DESIGN.md`、`docs/TEST_PLAN.md`）

## 1. 总规则

1. 不要一次性生成整个项目。**每个任务只交付一个可验证的垂直切片**。
2. 修改前先检查现有文件、依赖版本与测试，不得假设文件不存在或版本是自己熟悉的那个。
3. 不得擅自更换已确定的技术栈、协议字段或状态定义；确有必要时先写 ADR（`docs/DECISIONS.md`）并获得维护者同意。
4. 不得虚构 API、库方法或第三方 SDK 能力。不确定时先做最小技术验证，并把结论记录到 ADR。
5. 不得自创密码学算法。使用成熟依赖，并写测试向量。
6. 不得把私钥、助记词、访问令牌或真实用户数据写入日志、测试快照或 Git 提交。
7. 不得加入发币、代币、NFT、中心业务服务器或强制全局信用评分，除非维护者明确修改项目范围。
8. 不得把单方投诉自动转成"违规事实"或自动惩罚。
9. 所有协议变更必须同步更新 **schema + 文档 + 测试向量 + 版本号**，四者缺一不可。
10. 每次修改后运行格式化、静态分析与相关测试；**报告真实执行的命令与真实输出**。
11. 不得声称测试通过，除非真的执行过并看到通过结果。失败就贴失败。
12. 优先少量、可读、可维护的代码，不要为架构"炫技"增加抽象。
13. 外部依赖须记录版本、许可证、维护状态与已知限制（`docs/DEPENDENCIES.md`）。
14. 任务含糊时先列出最少必要假设，不要自行扩展产品范围。

## 2. 每个任务的输出格式

**开始前**简短说明：目标 / 将查看的文件 / 计划修改的文件 / 验收标准 / 可能的风险。

**完成后**说明：改动文件 / 实现了什么 / 真实运行的命令与结果 / 尚未实现的部分 / 如何手动验证。

## 3. 当前仓库状态（Phase 0.2c）

- `packages/osn_protocol` 与 `packages/osn_identity` 已创建，可用 `dart test` 独立验证。
- `app/mobile` 是可运行的 Flutter 应用：首页 + 个人中心 + 内存身份 + 内存需求公告板（含示例数据与发布表单）；`web/` 仅用于本地预览。
- 开发者详情/技术详情只在 `kDebugMode` 显示，release 构建不出现。
- 已实现：无浮点 JCS 子集、严格 JSON、信封、Ed25519、`did:key`、Request v1、Offer v1、固定测试向量。
- 尚未实现：Agreement / Event / Review 等业务对象模型、数据库、网络、P2P 与真实交易流程。
- 文档中描述的协议字段仍是**设计目标**；不要把未实现的业务对象当成已有 API 调用。

## 4. 常用命令

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
flutter run                    # 需要设备/模拟器
flutter run -d chrome          # 仅本地预览（web 非发布目标）
```

格式检查：

```bash
dart format --output=none --set-exit-if-changed app/mobile/lib app/mobile/test packages tool
```

Windows 开发机若 `flutter` 不在 PATH，用 `D:\Tools\flutter\bin\flutter.bat`，`dart` 用 `D:\Tools\flutter\bin\dart.bat`。

## 5. 硬性边界（不可越过的设计约束）

| 约束 | 说明 |
| --- | --- |
| 无中心业务服务器 | 不得引入项目方运营的 API/数据库来保存任务、匹配或裁决 |
| 用户持有密钥 | 私钥不得上传，不得写入日志，不得进仓库 |
| 事实与评价分离 | 不得把评价聚合成一个"官方信用分" |
| 不托管资金 | 不得实现支付、担保、退款逻辑 |
| 自描述数据 | 每份签名对象必须带 `schema_version`，并且可独立验证 |
| 无浮点 | 协议层禁止 JSON 浮点数：金额用最小单位整数，经纬度用 1e-7 整数 |
| 可替换基础设施 | 若使用 relay/bootstrap/STUN，必须文档化并可在配置中替换 |

## 6. 提示词模板

```text
请先阅读 AGENTS.md、README.md 以及与本任务相关的 docs 文档。
先检查仓库现状，不要直接重写项目。

本次任务：
[只描述一个明确的小功能]

验收标准：
1. [可验证标准]
2. [可验证标准]
3. [可验证标准]

约束：
- 不新增中心业务服务器。
- 不引入代币。
- 不改变无关模块。
- 不虚构依赖 API。
- 修改协议时同步更新文档与测试。
- 完成后运行相关测试，并报告真实结果。

先给出简短实施计划，再开始修改。
```
