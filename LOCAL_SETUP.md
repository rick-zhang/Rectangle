# 本地安装和运行

本文说明如何从源码一键构建、安装并运行 Rectangle。

## 环境要求

- macOS 14 或更高版本。
- Xcode 27（与当前上游 CI 保持一致）。
- Git，用于获取源码。
- 可访问 GitHub，Xcode 会通过 Swift Package Manager 自动解析 Sparkle 和 MASShortcut 依赖。

## 一键构建、安装并运行

在仓库根目录执行：

```bash
scripts/build-install-run-local.sh
```

脚本会执行以下步骤：

1. 使用 `xcodebuild` 构建 `Rectangle` 的 Debug 版本。
2. 检测正在运行的 Rectangle 相关进程。
3. 尝试正常退出旧进程；如果无法退出，会依次发送 `TERM` 和 `KILL`。
4. 替换本机已有的 `/Applications/Rectangle.app`。
5. 启动新安装的 Rectangle，并验证启动进程来自 `/Applications/Rectangle.app`。

如果 `/Applications` 需要管理员权限，脚本会在安装阶段提示输入本机密码。

首次运行本地构建版本时，需要授予辅助功能权限：

```text
System Settings -> Privacy & Security -> Accessibility
```

如果窗口移动或缩放没有生效，先确认 Rectangle 已经出现在该列表中并处于启用状态。

## 自定义安装位置

默认安装到 `/Applications/Rectangle.app`。如需安装到其他目录，可以设置 `INSTALL_DIR`：

```bash
INSTALL_DIR="$HOME/Applications" scripts/build-install-run-local.sh
```

脚本仍会安装为 `Rectangle.app`，并在启动后确认运行的是该安装目录中的版本。

## 手动在 Xcode 中运行

如需调试源码，可以直接打开工程：

```bash
open Rectangle.xcodeproj
```

然后在 Xcode 中选择 `Rectangle` scheme 和 `My Mac`，点击 Run 或按 `Cmd + R`。

## 运行测试

提交改动前建议运行完整测试：

```bash
xcodebuild test \
  -project Rectangle.xcodeproj \
  -scheme Rectangle \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-"
```

## 常见问题

### Xcode 无法解析依赖

确认网络可以访问 GitHub，然后在 Xcode 中选择：

```text
File -> Packages -> Reset Package Caches
```

随后重新打开工程或再次运行脚本。

### 本地构建在较旧 macOS 上失败

由于项目包含 Liquid Glass 图标和旧系统回退资源，macOS 26 以下版本可能出现资源构建失败。仅本地开发时，可以在 Xcode Build Settings 中临时删除 `Asset Catalog Other Flags` 后再构建。

不要把该临时配置改动提交到仓库。

### 辅助功能权限异常

可以先退出 Rectangle，然后重置权限：

```bash
tccutil reset All com.knollsoft.Rectangle
```

之后重新启动 Rectangle，并在系统设置中重新授权辅助功能权限。
