# app/mobile — PeerServe 客户端

Flutter 应用（Android 优先；web 仅本地预览）。Phase 0.2b 已有首页、内存身份演示、内存需求公告板与功能清单；仍不含 Offer/Agreement、存储与网络。

## 运行

```bash
flutter pub get
flutter run -d chrome   # 没有 Android 设备时快速预览
flutter run             # 需要连接 Android 设备或启动模拟器
```

> 本仓库使用 pub workspace；依赖解析以仓库根 `pubspec.yaml` 为准。

## 检查与测试

```bash
flutter analyze app/mobile
flutter test app/mobile
dart format --output=none --set-exit-if-changed app/mobile/lib app/mobile/test
```

## 结构

```text
lib/
├── main.dart             # 入口
├── app.dart              # MaterialApp、主题装配
└── ui/
    ├── theme.dart        # 配色与排版
    ├── home_page.dart    # 首页（阶段说明、入口、边界）
    ├── identity_page.dart# 内存身份、信封签名与篡改验签演示
    ├── requests_page.dart# 内存需求公告板：签名 Request + 验签
    └── features_page.dart# 已完成 / 部分完成 / 计划中
test/
├── app_test.dart         # 应用启动冒烟
├── home_page_test.dart   # 首页文案、导航、公告板发布
└── identity_page_test.dart # 签名有效 / 篡改失败
web/                      # 本地预览宿主（非发布目标）
android/                  # Android 宿主工程
```

## 约束

- UI 不直接访问数据库或套接字；业务能力通过 `packages/osn_*` 注入（Phase 1 起）。
- 任何"未实现"的入口保持禁用，并写明阶段，不制造假的成功路径。
- 文案必须区分"事实 / 单方声明 / 主观评价"。
- 身份演示页只持有内存私钥：不显示、不导出、不写日志；关闭页面即丢失。

仓库根目录的 [`../../README.md`](../../README.md) 与 [`../../docs/`](../../docs/) 是权威说明。
