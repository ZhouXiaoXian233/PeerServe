# 变更日志

本项目的重要变更都记录在此文件。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划中

- Phase 0.2：JCS 规范化 + Ed25519 签名/验签（含 RFC 8785 / RFC 8032 测试向量）
- Phase 0.3：SQLite 持久化与重启恢复验证

## [0.1.0] - 2026-11-07

### 新增

- Flutter 应用骨架（`app/mobile`）：应用外壳、主题、欢迎页 → 首页占位流程。
- Widget 冒烟测试与 `flutter test` 基线。
- GitHub Actions CI：`flutter analyze`、格式检查、`flutter test`。
- 项目文档基线：README、架构、协议、数据模型、网络安全、测试计划、ADR（001–011）、路线图。
- 仓库治理文件：MIT LICENSE、AGENTS.md、CONTRIBUTING.md、CODE_OF_CONDUCT.md、SECURITY.md、Issue/PR 模板。

### 说明

- 本版本**不含**身份、签名、数据库、网络与任何业务逻辑；不可用于真实交易。
- 尚未推送远端、尚未配置 release 流程。

[Unreleased]: https://github.com/YOUR_GITHUB_OWNER/peerserve/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/YOUR_GITHUB_OWNER/peerserve/releases/tag/v0.1.0
