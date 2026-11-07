# 贡献指南

感谢你愿意参与信约阁（PeerServe）。这是一个**协议优先**的实验性项目：比起功能数量，我们更在意数据是否可验证、行为是否可解释。

## 在开始之前

1. 读 [`README.md`](README.md) 了解范围与"不做什么"。
2. 读 [`AGENTS.md`](AGENTS.md)——它对人类与 AI 贡献者同样有效。
3. 读 [`docs/DECISIONS.md`](docs/DECISIONS.md)，那里记录了已经定下的取舍。
4. 涉及协议、状态机、字段语义的改动，**先开 Issue 讨论**，再写代码。

## 好的贡献

- 一个 PR 只做一件事，并附带"如何手动验证"的步骤。
- 修复 bug 时先写一个能复现的失败测试，再让它变绿。
- 新协议字段必须同时更新：`schema`、`docs/PROTOCOL_SPEC.md`、测试向量、`schema_version`。
- 新依赖必须在 `docs/DEPENDENCIES.md` 记录版本、许可证、维护状态与风险。
- UI 变更请附截图，并说明它如何区分"事实 / 单方声明 / 评价"。

## 提交信息

采用 Conventional Commits 风格，中文或英文均可：

```text
feat(protocol): 增加 Request 的 canonical 序列化测试向量
fix(ui): 修正过期公告仍然显示为可响应的问题
docs(adr): 记录 Phase 2 传输方案选型
test(identity): 补充 RFC 8032 Ed25519 向量
```

## 提交前自检

```bash
cd app/mobile
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
```

三项都必须真实通过；CI 会执行同样的命令。**不要在 PR 中声称未运行过的结果。**

## 不接受的内容

- 代币、NFT、积分币、挖矿或链上共识机制
- 中心化业务后端、用户数据托管、账号体系
- 自动裁决、自动封禁、全局黑名单、官方信用分
- 自创密码学算法
- 未脱敏的真实用户数据、密钥、令牌
- 引入 GPL/AGPL/Coopyleft 代码（可阅读借鉴思路，但不得复制代码）

## 报告问题

- 功能缺陷与建议：GitHub Issue（请使用模板）
- 安全漏洞：**不要开公开 Issue**，按 [`SECURITY.md`](SECURITY.md) 私下报告

## 许可证

提交即表示你同意以 [MIT](LICENSE) 许可贡献这些代码与文档。
