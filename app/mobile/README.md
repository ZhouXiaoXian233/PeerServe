# app/mobile — PeerServe 客户端

Flutter 应用（Android 优先）。Phase 0.1 只有应用外壳，不含身份、协议、存储与网络。

## 运行

```bash
flutter pub get
flutter run            # 需要连接 Android 设备或启动模拟器
```

## 检查与测试

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
```

## 结构

```text
lib/
├── main.dart          # 入口
├── app.dart           # MaterialApp、主题装配
└── ui/
    ├── theme.dart     # 配色与排版
    └── home_page.dart # 首页骨架（阶段说明、路线、设计边界）
test/
├── app_test.dart      # 应用启动冒烟
└── home_page_test.dart# 首页文案与禁用态断言
```

## 约束

- UI 不直接访问数据库或套接字；业务能力通过 `packages/osn_*` 注入（Phase 1 起）。
- 任何"未实现"的入口保持禁用，并写明阶段，不制造假的成功路径。
- 文案必须区分"事实 / 单方声明 / 主观评价"。

仓库根目录的 [`../../README.md`](../../README.md) 与 [`../../docs/`](../../docs/) 是权威说明。
