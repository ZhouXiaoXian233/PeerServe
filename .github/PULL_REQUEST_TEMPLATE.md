## 变更说明

<!-- 这个 PR 做了什么，为什么 -->

## 类型

- [ ] 修复 bug
- [ ] 新功能（一个垂直切片）
- [ ] 文档
- [ ] 重构（无行为变化）
- [ ] 协议 / schema 变更（必须附 ADR 或 Issue 链接）

## 关联 Issue

Closes #

## 自检（必须真实执行并粘贴结果）

```text
$ flutter analyze
<粘贴输出>

$ dart format --output=none --set-exit-if-changed lib test
<粘贴输出>

$ flutter test
<粘贴输出>
```

- [ ] 我真实运行了上述命令，并粘贴了真实输出
- [ ] 未新增中心业务服务器、代币或自动裁决逻辑
- [ ] 未提交任何密钥、令牌、真实用户数据
- [ ] 协议变更已同步更新 schema + 文档 + 测试向量 + 版本号
- [ ] 新依赖已登记到 `docs/DEPENDENCIES.md`

## 如何手动验证

<!-- 评审者照着做就能确认这个 PR 有效 -->
