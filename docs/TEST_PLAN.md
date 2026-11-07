# 测试计划

> 现状：Phase 0.2b 已有协议/身份/Request 纯 Dart 测试与 UI 演示测试；下表 `状态` 列以代码为准。

## 1. 单元测试（纯 Dart，秒级）

| # | 用例 | 阶段 | 状态 |
| --- | --- | --- | --- |
| U1 | 身份标识派生稳定（同公钥 → 同 ID） | 0.2 | ✅ |
| U2 | 合法签名可验证 | 0.2 | ✅ |
| U3 | 篡改任意已签名字段后验签失败 | 0.2 | ✅（payload / sent_at / sender_id / 签名） |
| U4 | JCS 规范化对 RFC 8785 向量一致（无浮点子集；`-0`、`1e30`、边界浮点作为拒绝用例） | 0.2 | ✅ |
| U5 | 含浮点的 payload 被拒绝 | 0.2 | ✅ |
| U6 | 未知 `schema_version` 安全拒绝 | 0.2 | ✅ |
| U7 | 过期 Request 不显示为有效新任务 | 1 | ⬜ |
| U8 | Offer 必须关联存在的 Request | 1 | ⬜ |
| U9 | Agreement 只有双方签名齐全才是 `mutually_signed` | 1 | ⬜ |
| U10 | 单方完成声明 ≠ 双方完成确认 | 1 | ⬜ |
| U11 | Review 必须关联有效 Agreement 且作者是参与者 | 1 | ⬜ |
| U12 | 同一参与者对同一 Agreement 只能有一条有效评价 | 1 | ⬜ |
| U13 | 重复消息不重复创建事件 | 1 | ⬜ |
| U14 | 争议陈述不改变对方任何"权限/分数" | 1 | ⬜ |
| U15 | 状态投影对乱序事件收敛到同一结果 | 1 | ⬜ |
| U16 | Widget：首页渲染、导航、身份演示页、签名有效/篡改失败 | 0.2 | ✅ |
| U17 | Request v1 字段校验：浮点金额、超长字段、倒置时间窗、越界坐标、非法 nonce | 0.2b | ✅ |
| U18 | Request 装入签名信封后可独立验签；公告板 UI 可发布并显示签名状态 | 0.2b | ✅ |

## 2. 集成测试

| # | 用例 | 阶段 |
| --- | --- | --- |
| I1 | 创建身份 → 发布 Request → 收 Offer → 双方签署 Agreement | 1 |
| I2 | 追加事件 → 重启应用 → 记录仍在 | 0.3 / 1 |
| I3 | 导出 → 清库 → 导入 → 签名与历史可验证 | 1 |
| I4 | 节点断线 → 重连 → 去重同步（`InMemoryTransport`） | 2 |
| I5 | 两节点提交冲突声明 → 两条都保留 | 2 |
| I6 | 导入被篡改的导出文件 → 逐条拒绝并报告 | 1 |

## 3. 安全测试

- 超长字符串（每个字段的上限 + 1）；
- 非法 JSON、重复键、`NaN`/`Infinity`、深度嵌套；
- 超大消息（> 64 KiB）；
- 不支持的 `schema_version`；
- 无效签名 / 空签名 / 截断签名；
- 重放消息与重复 ID；
- 伪造 reviewer（非参与者）；
- 日志中不出现私钥（断言日志输出）；
- 精确坐标不进入广播摘要。

## 4. 人工验收（本地 UI 快速检查）

没有 Android 设备时可用 Chrome 预览：

```bash
flutter run -d chrome
```

1. 首页点“功能清单”，确认“已完成 / 部分完成 / 计划中”与当前实现一致；
2. 返回首页点“需求公告板”，应看到一条“签名有效”的示例 Request；
3. 点“发布示例需求”，列表应新增一条，仍为“签名有效”；
4. 点“身份与签名演示”，再点“篡改标题并验签”，应显示“篡改后验签失败（符合预期）”。

> web 只用于本地预览；Android 真机与两台设备验收仍按下一节执行。

## 5. 人工验收（两台真机）

1. A 发布"从 X 到 Y"的出行需求；
2. B 提交响应；
3. A 选择 B，双方看到同一组条款；
4. 双方签署协议；
5. B 记录开始服务；
6. B 声明完成；
7. A 确认完成；
8. 双方各自评价对方；
9. 第三方设备能区分：协议事实 / 单方声明 / 评价；
10. 断开网络后，双方仍可查看本地记录。

## 6. 运行方式

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
```

格式检查：

```bash
dart format --output=none --set-exit-if-changed app/mobile/lib app/mobile/test packages
```

> Windows 下若 `dart`/`flutter` 不在 PATH，用 `D:\Tools\flutter\bin\dart.bat` 与 `D:\Tools\flutter\bin\flutter.bat`。

## 7. 报告规则

- CI 与 PR 必须贴**真实命令与真实输出**；
- 失败就是失败，不得写"应该可以通过"；
- 新增测试必须能在干净环境中独立运行（不依赖本机已有数据）。
