## Context

Rectangle 的窗口动作执行入口在 `WindowManager.execute`。每次动作都会先通过 `ScreenDetection` 判断当前窗口所在显示器，再把该显示器的可见区域传给对应的 `WindowCalculation`。

`NextPrevDisplayCalculation` 在执行 Next Display / Previous Display 时会明确选择目标显示器，移动成功后 `WindowManager.postProcess` 会记录动作历史。然而后续 Maximize 会重新从窗口矩形推断当前显示器。如果 macOS Accessibility 返回的窗口 frame、全局坐标翻转、显示器排列或缩放组合导致推断错误，Maximize 会使用源显示器的 visible frame，从而把窗口带回原显示器。

当前仓库 `RectangleTests` 几乎没有相关回归测试，因此本次修复需要同时补齐可测试的行为边界。

## Goals / Non-Goals

**Goals:**

- Next Display / Previous Display 后立即执行 Maximize 时，Maximize 必须使用窗口被移动到的目标显示器。
- 对 Rectangle 自己刚刚完成的跨显示器移动使用更可信的目标屏上下文，避免下一次动作完全依赖几何推断。
- 对跨显示器移动后的非 Maximize 布局继续保持原布局，例如 half、third、bottom-half 等。
- 在 macOS 对跨屏 resize 进行高度矫正时，避免 bottom-half 等底部锚定布局出现先跳动再归位。
- 保持现有快捷键、URL action、默认配置和窗口计算接口稳定。
- 增加回归测试，覆盖跨显示器移动后 Maximize 使用目标屏、显示器身份匹配、布局保持、重试匹配和底部锚定行为。
- 保留 Debug 诊断能力，但默认关闭，仅通过菜单按需开启。
- 给出本机 Debug 版构建、安装、验证和回滚步骤。

**Non-Goals:**

- 不重写全局坐标系统或所有 `screenFlipped` 调用。
- 不改变显示器排序策略、用户隐藏配置或屏幕边缘 gap 语义。
- 不解决 macOS Spaces、全屏空间或第三方应用拒绝 resize 的独立问题。
- 不修改发布签名、bundle identifier、entitlements 或 Sparkle 更新逻辑。
- 不新增发布版偏好设置或全局配置项；Debug 诊断开关只用于本地排障。

## Decisions

### Decision 1: 优先复用上一次 Rectangle 目标屏上下文

实现时在窗口历史中保留上一次 display action 的目标显示器身份。下一次执行动作时，如果当前窗口 frame 与上次记录的结果 frame 一致，且目标显示器仍存在，则优先用该目标显示器构造 `UsableScreens`。

理由：

- 这个上下文来自 Rectangle 自己刚刚完成的动作，比“再次根据窗口矩形猜测屏幕”更可靠。
- 作用范围小，主要覆盖 `nextDisplay` / `previousDisplay` 后连续动作，不会大范围改变拖拽吸附、Stage Manager 或多窗口平铺路径。
- 如果窗口被外部移动，现有 `windowMovedExternally` 逻辑会清理历史，修复自然回退到原检测路径。

备选方案：

- 直接修改 `ScreenDetection.screenContaining` 或 `CGRect.screenFlipped`。这可能修复更多坐标问题，但影响面更大，容易改变历史兼容行为。
- 在 Maximize 特判读取上一次动作。特判更窄，但会把跨显示器上下文和某个 action 绑定，后续其他动作仍可能遇到相同问题。

### Decision 2: 屏幕匹配优先使用 `NSScreenNumber`，frame 作为兜底

实现时把目标屏记录为 `DisplayIdentity(screenNumber, frame)`。`screenNumber` 来自 `NSScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]`，类型上等价于 `CGDirectDisplayID`。匹配时优先用 `screenNumber`，如果无法取得或当前系统返回的编号不一致，再用 frame 兜底。若二者都找不到，说明显示器布局已变化或目标屏不可用，必须回退到 `ScreenDetection`。

理由：

- `NSScreen` 对象不可持久化，localizedName 也不保证唯一或稳定。
- `NSScreenNumber` 比单纯 frame 更能表达“同一块显示器”，可减少缩放、分辨率或排列微调造成的误判。
- frame 兜底保留了当前 adjacent/display ordering 逻辑的兼容性，也覆盖无法取得屏幕编号的情况。
- 屏幕身份和 frame 都无法匹配时不强行复用旧上下文，避免把窗口送到已不存在的区域。

备选方案：

- 记录 localizedName。外接同型号显示器或重名显示器会冲突。
- 只记录 frame。实现更简单，但在长期本地自用和不定期同步上游时，对显示器缩放、排列变化的鲁棒性较差。

### Decision 3: 提取可测试的屏幕上下文选择逻辑

把“是否可复用上次目标屏”抽到独立的 `DisplayScreenContextResolver`，让 XCTest 可以用简单 `DisplayIdentity` 和 frame 数据覆盖成功、外部移动、屏幕布局变化、screen number 优先和 frame fallback 等场景。

理由：

- 直接单测 `NSScreen` 和 AccessibilityElement 很重，且依赖真实多屏环境。
- 纯逻辑测试能稳定覆盖 issue #1529 的行为核心：连续动作必须保留目标屏上下文。

备选方案：

- 只做手动验证。风险是后续重构再次破坏该行为。
- 完整 mock `NSScreen`/AXUIElement。实现成本高，不符合这次窄修复的范围。

### Decision 4: 对跨显示器移动后的布局保持做通用处理

`NextPrevDisplayCalculation` 在 display action 期间，如果上一次 Rectangle action 不是 Maximize 且该 action 有对应 calculation，则在目标显示器的 visible frame 上重新计算相同布局，而不是退回 center 或只处理 Maximize。

理由：

- 用户期望不只 Maximize 能跨屏保持，left-half、bottom-half 等布局也应随 display move 转换到目标屏。
- 复用既有 `WindowCalculationFactory` 可保持每个布局原本的尺寸、gap 和 visible frame 语义。

### Decision 5: 对跨显示器应用结果使用完整 frame 容差重试

跨显示器移动后 macOS 可能第一次没有完全应用目标 frame。实现使用 `WindowApplyResultMatcher` 比较完整 normalized frame，并进行有限重试，而不是只看宽高或只看 origin。

理由：

- 从小屏到大屏或大屏到小屏时，单独比较尺寸可能误判成功。
- 有限重试能降低 Accessibility 异步应用造成的偶发失败，同时避免无限循环。

### Decision 6: 修复底部锚定布局的跨屏跳动

`StandardWindowMover` 在跨显示器且目标布局贴住目标 visible frame 底部时，如果 macOS 首次 resize 把高度矫正为非目标高度，则调整 origin 以保持底部锚定，避免 bottom-half 等布局先跳到错误 y 再归位。

理由：

- bottom-half 的用户感知锚点是底边，不是顶部 origin。
- 只在跨显示器和尺寸被系统矫正时应用，避免改变普通同屏移动。

### Decision 7: Debug 诊断日志默认关闭，菜单按需开启

保留 Debug 菜单项，但名称使用中文，并作为单项开关：`开启跨屏诊断日志` / `关闭跨屏诊断日志`。默认不写 `/private/tmp/rectangle-display-move.log`，开启时清空并写入诊断日志，同时可打开日志文件。

理由：

- 长期本地自用时不应持续写临时日志，也不应强制显示菜单栏图标。
- 需要复现问题时仍能快速开启日志收集证据。

## Risks / Trade-offs

- 记录目标屏身份可能在显示器布局变化后失效 -> 每次复用前都从当前 `NSScreen.screens` 重新匹配，编号和 frame 都找不到就回退原检测逻辑。
- 如果 macOS 在跨屏移动后返回的窗口 frame 与记录结果存在小幅差异，严格相等可能误判为外部移动 -> `WindowHistoryRectMatcher` 对普通布局保留紧容差，对 Maximize 使用更宽容差，并用测试覆盖。
- 有限重试可能仍无法修复拒绝 resize 或特殊 Space 下的第三方应用 -> 保持回退路径和诊断日志，不把该问题误归因到屏幕上下文。
- 只修复 Rectangle 连续动作上下文和已复现的跨屏应用问题，不全面重写所有坐标翻转逻辑 -> 保持本次变更小而可验证，后续若发现独立坐标问题再单独提 change。
- 本机安装 Debug build 会使用相同 bundle id，可能需要重新授予 Accessibility 权限 -> 任务中包含权限重置和回滚步骤。

## Migration Plan

1. 从最新 `origin/main` 创建本地分支 `fix-maximize-after-display-move`。
2. 实现窗口历史中的目标屏身份记录与复用逻辑。
3. 实现跨显示器布局保持、应用结果重试和底部锚定修复。
4. 增加单元测试并运行 `xcodebuild test`。
5. 构建 Debug 版 `Rectangle.app`，在本机替换或临时运行。
6. 手动验证 issue #1529 路径，并在需要时开启 Debug 菜单中的跨屏诊断日志检查 `srcScreen`、`destScreen`、`resultScreen`。
7. 如需回滚，退出 Rectangle 后恢复备份的 `/Applications/Rectangle.app`。

## Open Questions

- 如果发现最新版 `main` 已无法复现 issue #1529，仍建议保留回归测试和目标屏上下文保护，避免后续回归。
