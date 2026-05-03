## Why

当窗口通过 Rectangle 的 Next Display / Previous Display 移动到另一个显示器后，紧接着执行 Maximize 可能会把窗口重新最大化到原显示器。这个问题会破坏多显示器工作流，尤其是在内建屏与外接屏尺寸、缩放或排列方式不同的环境中。

当前 `main` 已包含若干跨显示器移动修复，但 issue #1529 描述的“移动后再次最大化回到原屏”仍需要用明确行为契约和回归验证来覆盖。

## What Changes

- 保证 Rectangle 发起跨显示器移动后，后续窗口动作可以正确识别窗口所在的目标显示器。
- 修复 Next Display / Previous Display 后立即执行 Maximize 时错误使用源显示器的情况。
- 使用独立的屏幕上下文 resolver 保存目标显示器身份，优先匹配 `NSScreenNumber` / `CGDirectDisplayID`，并以 frame 作为兜底。
- 为跨显示器移动后的 Maximize、布局保持、窗口应用重试和底部锚定行为补充测试与手动验证路径。
- 保留 Debug 诊断日志入口，但默认关闭，仅在菜单中按需开启。
- 不改变用户可见快捷键、URL action 名称、默认配置或窗口计算 API。

## Capabilities

### New Capabilities

- `display-move-screen-context`: 定义 Rectangle 在跨显示器移动窗口后，后续窗口动作应使用目标显示器作为当前屏幕上下文。

### Modified Capabilities

无。

## Impact

- 主要影响 `WindowManager`、新增的 `DisplayScreenContextResolver`、跨显示器移动计算、窗口移动应用策略和 Debug 日志入口。
- 测试影响集中在 `RectangleTests`，需要增加可测试的屏幕身份、几何判断、布局保持和底部锚定覆盖。
- 不引入新的第三方依赖，不修改签名、bundle identifier、entitlements 或发布配置。
- 本机验证需要构建 Debug 版 Rectangle，并重新启动/授权本机安装的应用。
