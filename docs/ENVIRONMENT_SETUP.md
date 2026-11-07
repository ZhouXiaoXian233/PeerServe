# 开发环境清单（Windows）

> 实测日期：2026-10-25  
> 目标：用最少的安装量跑通 Flutter Android 开发与测试。  
> 结论：**只缺两样——Flutter SDK 和 Android SDK**。其余（Git、Android Studio、JDK 21、VS Code、adb、scrcpy）本机已有。  
> 而且这两样可以分开装：**现在只装 Flutter** 就能写协议、跑单元测试；Android SDK 等到要打 APK 或上真机时再装。

## 0. 安装顺序（重要）

| 阶段 | 需要安装 | 能做什么 |
|---|---|---|
| **现在（Phase 0/1）** | 只装 Flutter SDK（约 1 GB） | 建纯 Dart 包、Ed25519/JCS、SQLite、状态机、`flutter test`，全部不需要 Android SDK |
| **Phase 2（上真机）** | 再用 Android Studio 装 Android SDK（约 4 GB） | 打包 APK、连真机、双机 P2P 验证 |
| 可选 | 模拟器系统镜像（约 2 GB） | 没有真机时做 UI 调试；不能替代双机验收 |

> 如果连 Flutter 都想再等等，也可以只装 Dart SDK（约 300 MB）先做纯 Dart 核心；但不推荐，因为后面装 Flutter 会带一份 Dart，容易出现两个 SDK 版本不一致。

## 1. 本机现状（已核实）

| 组件 | 状态 | 版本 | 位置 |
|---|---|---|---|
| Git for Windows | ✅ 已装 | 2.55.0.windows.3 | `C:\Program Files\Git\cmd\git.exe` |
| Android Studio | ✅ 已装（未首次启动） | AI-253.30387.90.2532.14935130 | `D:\Program Files\Android\Android Studio` |
| JDK（Android Studio 自带 JBR） | ✅ 已装 | OpenJDK 21.0.9 | `D:\Program Files\Android\Android Studio\jbr` |
| VS Code | ✅ 已装 | — | `D:\Program Files\Microsoft VS Code` |
| adb / platform-tools | ✅ 已装 | 37.0.1 | scoop：`C:\Users\bin\scoop\apps\adb\current\platform-tools` |
| scrcpy / 7-Zip / ffmpeg | ✅ 已装 | — | scoop |
| Node.js / pnpm / Python | ✅ 已装 | — | 本项目当前不需要 |
| **Flutter SDK / Dart** | ✅ **已装（2026-11-07）** | Flutter 3.47.8 · Dart 3.13.7 | `D:\Tools\flutter`，其 `bin` 已加入**用户 PATH**（新开终端生效） |
| **Android SDK** | ❌ **缺失** | — | 仅有 adb，无 platforms/build-tools |

> 已实际执行：`flutter --version` → `Flutter 3.47.8 • channel stable`，`Dart 3.13.7`；`flutter analyze` 与 `flutter test` 在 `app/mobile` 下通过。
> Flutter 自带 Dart，**不要再单独安装 Dart SDK**，否则会出现两个 SDK 版本不一致。
| 磁盘 | ✅ 充足 | C: 372 GB 空闲，D: 649 GB 空闲，E: 477 GB 空闲 | — |

> Android Studio 已安装但从未启动，因此 SDK 组件尚未下载；它的 JBR 21 可直接给 Flutter/Gradle 用，**不需要另装 JDK**。

## 2. 必须新装（2 项）

### 2.1 Flutter SDK 3.47.8（含 Dart 3.13.7）

> **状态：已完成（2026-11-07）。** 实际安装到 `D:\Tools\flutter`，下载包约 1.8 GB，解压后可用；以下步骤保留作为换机/复现参考。

- 下载：<https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.8-stable.zip>（约 1 GB）
- 解压到 `D:\Tools`，得到 `D:\Tools\flutter`（路径不要含空格/中文）。
- 加入用户 PATH（PowerShell）：

```powershell
$flutterBin = 'D:\Tools\flutter\bin'
$userPath  = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$flutterBin", 'User')
}
```

- 重新打开终端，验证：

```powershell
flutter --version   # 首次运行会初始化缓存与引擎产物
```

> 国内网络慢时，可选设置官方中国镜像（社区维护，可随时撤掉）：
> ```powershell
> [Environment]::SetEnvironmentVariable('PUB_HOSTED_URL', 'https://pub.flutter-io.cn', 'User')
> [Environment]::SetEnvironmentVariable('FLUTTER_STORAGE_BASE_URL', 'https://storage.flutter-io.cn', 'User')
> ```

### 2.2 Android SDK（Phase 2 前安装即可）

不需要新装软件：启动已有的 Android Studio，用它的 SDK Manager 装组件。**Phase 0/1 可以先跳过这一节**，等要打包/上真机时再回来。

1. 启动 `D:\Program Files\Android\Android Studio\bin\studio64.exe`，完成首次向导。
2. **More Actions → SDK Manager**（或 Tools → SDK Manager）。
3. **SDK Platforms**：勾选 **Android 16.0（API 36）**。
4. **SDK Tools**：勾选
   - Android SDK Build-Tools **36.0.0**
   - Android SDK Command-line Tools (latest)
   - Android SDK Platform-Tools
   - Android Emulator（需要模拟器时）
   - CMake / NDK (Side by side) —— **仅当**后续引入原生插件（如 iroh）才需要，现在不装
5. 建议把 SDK 路径设为 `D:\Android\Sdk`（默认在 C 盘用户目录，也可）。
6. 配置环境变量并让 Flutter 识别：

```powershell
[Environment]::SetEnvironmentVariable('ANDROID_HOME', 'D:\Android\Sdk', 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', 'D:\Android\Sdk', 'User')
flutter config --android-sdk D:\Android\Sdk
flutter config --jdk-dir "D:\Program Files\Android\Android Studio\jbr"
```

7. 接受许可：

```powershell
flutter doctor --android-licenses
```

8. Windows 上构建插件需要符号链接支持，开启“开发人员模式”：

```powershell
start ms-settings:developers
```

## 3. 设备：真机优先，模拟器可选

| 方式 | 需要安装 | 优点 | 缺点 |
|---|---|---|---|
| **Android 真机（推荐）** | 无 | 真实 P2P/Wi-Fi/蓝牙行为，验收必需 | 需要数据线/无线调试 |
| Android 模拟器 | 系统镜像（约 1.5–2.5 GB） | 不依赖手机 | 模拟不了真实 Wi-Fi/蓝牙/多机场景，P2P 验收不够 |

真机步骤：开发者选项 → USB 调试 → 连接后 `adb devices` 授权。  
模拟器步骤：Device Manager → Create Virtual Device → API 36 Google APIs x86_64 → 启动一次。

> 最终验收（两台设备互发签名消息）**必须用两台真机**，模拟器只能辅助 UI 开发。

## 4. 可选（按需再装）

- VS Code 扩展：**Dart**、**Flutter**（扩展不算独立软件，建议装）。
- `DB Browser for SQLite`：查看本地库，非必需。
- Rust 工具链：仅在选定 `iroh` 传输方案时才需要（`iroh_flutter` 首次构建会自动装，但不建议现在引入）。
- Android NDK / CMake：仅在引入原生插件时安装。

## 5. 明确不装

| 不装 | 原因 |
|---|---|
| 独立 JDK 17/21 | Android Studio 自带 JBR 21，满足 Flutter/AGP 的 JDK 17+ 要求 |
| Git（再装） | 已有 2.55，`flutter doctor` 只要求可用 |
| Node.js 后端 / PostgreSQL / Redis / Docker | 项目无中心服务器、无后端 |
| Melos / Nx / Turborepo | Dart 3.13 用 pub workspaces 足够 |
| 区块链节点 / 钱包 / IPFS 守护进程 | 首版不引入链、不托管、不存证 |
| 第三方 P2P SDK 安装包 | 传输层用 Dart 包，随 pub 依赖走 |
| Android Studio 之外的 IDE | VS Code 已够；IntelliJ 不必要 |

## 6. 安装后验证清单

**Phase 0/1（只装 Flutter 后）：**

```powershell
flutter --version          # Flutter 3.47.8 • Dart 3.13.7
dart --version
flutter doctor -v          # Flutter / VS Code 应为 ✓；Android toolchain 暂缺属正常
```

此时能跑 `flutter test`、`dart test`、`flutter analyze`，就可以开始协议与本地核心。

**Phase 2（装完 Android SDK 后）：**

```powershell
flutter doctor -v          # Android toolchain / Android Studio 也应为 ✓
flutter doctor --android-licenses
flutter devices            # 至少一台 Android 设备
adb devices                # device（不是 unauthorized）
```

预期 `flutter doctor` 关键项：

- `[✓] Flutter (Channel stable, 3.47.8, ...)`
- `[✓] Android toolchain - develop for Android devices (Android SDK version 36.0.0)`
- `[✓] Android Studio (version 2025.2)`
- `[✓] VS Code`
- `[✓] Connected device`

## 7. 常见问题

| 现象 | 处理 |
|---|---|
| `flutter` 不是内部或外部命令 | 重开终端；确认 PATH 含 `D:\Tools\flutter\bin` |
| `Unable to locate a Java Runtime` | 执行 `flutter config --jdk-dir "D:\Program Files\Android\Android Studio\jbr"` |
| `Android license status unknown` | 确认装了 cmdline-tools，再跑 `flutter doctor --android-licenses` |
| 构建报 symlink / 插件错误 | 开启 Windows 开发人员模式 |
| Gradle 下载卡住 | 配置代理或镜像；首次构建需下载 Gradle 9.x 与依赖，属正常 |
| 构建慢/被杀毒软件拦截 | 把 `D:\Tools\flutter`、`D:\Android\Sdk`、项目目录加入 Defender 排除 |
| 路径过长 | 项目保持在 `E:\Projects\AIProjects\PeerServe`，Flutter/Gradle 放 D 盘短路径 |

## 8. 时间与空间预算

| 项目 | 下载 | 安装后占用 |
|---|---|---|
| Flutter SDK + 引擎产物 | ~1.0–2.0 GB | ~3–4 GB |
| Android SDK（API 36 + build-tools + platform-tools） | ~1.5–2.5 GB | ~3 GB |
| 模拟器系统镜像（可选） | ~1.5 GB | ~2.5 GB |
| Gradle / pub 缓存 | ~0.5 GB | ~1–2 GB |
| **合计** | **~4–6 GB** | **~9–11 GB** |

预计 30–90 分钟（取决于网络）。装完后本项目不需要再安装其他常驻软件。
