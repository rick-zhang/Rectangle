## 1. Baseline and Reproduction

- [x] 1.1 确认当前分支基于最新 `origin/main`，记录 HEAD 与 issue #1529 的复现路径。
- [x] 1.2 在当前未修复实现上执行或复核手动复现，收集 Next Display 后 Maximize 的日志表现。
- [x] 1.3 确认现有跨显示器移动相关提交与 v0.86 后修复不会覆盖本次行为契约。

## 2. Core Implementation

- [x] 2.1 扩展窗口历史记录结构，使 Rectangle 动作结果可以携带目标显示器身份，优先 `NSScreenNumber` / `CGDirectDisplayID`，并以 frame 兜底。
- [x] 2.2 在 `WindowManager.postProcess` / `recordAction` 路径中保存动作结果的目标显示器上下文。
- [x] 2.3 在下一次动作执行前，若窗口未被外部移动且目标显示器仍存在，则优先使用保存的目标显示器身份构造 `UsableScreens`。
- [x] 2.4 在窗口外部移动、显示器布局变化或无法匹配保存显示器身份时回退到现有 `ScreenDetection` 逻辑。
- [x] 2.5 保持 Next Display / Previous Display 的既有 adjacent ordering、单屏 traversal、快捷键、URL action 和 defaults 行为不变。
- [x] 2.6 将显示器上下文选择、历史 frame 匹配和跨屏应用结果匹配提取到独立可测试的辅助类型，降低 `WindowManager` 冲突面。
- [x] 2.7 保持跨显示器移动后的非 Maximize 布局，并避免退回默认居中。
- [x] 2.8 对跨显示器窗口应用结果使用完整 frame 匹配和有限重试，降低 Accessibility 首次应用不完整造成的偶发失败。
- [x] 2.9 修复 bottom-half 等底部锚定布局跨屏到较小下方屏幕时的上下跳动。
- [x] 2.10 保留 Debug 诊断菜单项，但默认关闭日志写入，菜单项使用中文开关名称。

## 3. Tests

- [x] 3.1 提取或新增可测试的屏幕上下文选择辅助逻辑，避免单元测试依赖真实 `NSScreen` 和 Accessibility。
- [x] 3.2 添加测试覆盖 Next Display 后 Maximize 使用目标显示器。
- [x] 3.3 添加测试覆盖 Previous Display 后 Maximize 使用目标显示器。
- [x] 3.4 添加测试覆盖窗口 frame 与记录结果不一致时清理保存上下文并回退检测。
- [x] 3.5 添加测试覆盖保存的目标显示器 frame 不在当前显示器列表时回退检测。
- [x] 3.6 添加测试覆盖显示器身份优先匹配 screen number，并在 screen number 不可用或变化时 frame fallback。
- [x] 3.7 添加测试覆盖跨显示器移动后的非 Maximize 布局保持。
- [x] 3.8 添加测试覆盖跨屏应用结果完整 frame 匹配和小幅漂移容差。
- [x] 3.9 添加测试覆盖底部锚定布局跨屏高度被系统矫正时的 origin 修正。

## 4. Verification

- [x] 4.1 运行 `xcodebuild test -project Rectangle.xcodeproj -scheme Rectangle -destination 'platform=macOS' CODE_SIGN_IDENTITY="-"`。
- [x] 4.2 构建 Debug 版 Rectangle，并确认产物路径为 `~/Library/Developer/Xcode/DerivedData/Rectangle-eddesbpxbbwqvmfzkgawobnvqwnf/Build/Products/Debug/Rectangle.app` 或记录实际路径。
- [x] 4.3 本机临时运行或替换安装 Debug 版 Rectangle，必要时重置并重新授予 Accessibility 权限。
- [ ] 4.4 手动验证内建屏到外接屏、外接屏到内建屏两条路径：Next/Previous Display 后立即 Maximize 均停留在目标显示器。
- [ ] 4.5 在 Rectangle 日志中确认连续动作的 `srcScreen`、`destScreen`、`resultScreen` 与目标显示器一致。
- [x] 4.6 记录回滚步骤：退出 Rectangle 后恢复备份的 `/Applications/Rectangle.app.backup-codex-display-move`。
