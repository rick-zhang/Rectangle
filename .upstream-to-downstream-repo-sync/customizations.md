# Rectangle 下游定制保护清单

<!-- customizations-schema: 1 -->

## 维护约定

当前上下游身份、remote、目标分支及检查模式覆盖以 `config.yaml` 为唯一依据；检查命令默认由 Skill 从当前工程自动发现；本文件由 Skill 自动增量维护，用户无需随配置手工修改。用户本地定制默认全部保留，包括尚未登记、其他分支及工作区中的定制；保留不等于擅自提交或合并所有分支。覆盖状态不等于测试通过。

无法自动判断的行为冲突由 Skill 说明选项和影响，用户决策后由 Skill 自动更新实现、证据及决策记录。已确认的决定在相同条件下复用。下列状态基于本地缓存与静态检查，不代表远端最新状态；每次同步须重新核对。

## 接入依据与目标

历史接入依据：当时定制位于 `fix-maximize-after-display-move`，main 未包含这些实现，因此选择功能分支作为目标。本次按用户要求将该功能分支快进合并回主分支，并将配置目标切换为下游主分支；合并完整保留功能提交及 C001–C008 的实现、测试和协作文件。当前目标始终读取配置，后续切换由 Skill 自动核查覆盖并维护清单。

历史接入时本地 main 跟踪上游，功能分支跟踪下游同名分支；本次合并保留这些 Git 跟踪关系，配置目标与 Git 跟踪关系应分别核实。跟踪关系每次从 Git 核实，不能用裸 git pull 代替同步流程，也不顺手修改其他分支。

以下实现和测试已在合并后的配置目标中静态核查；本轮完整 XCTest 的执行结果见验证边界，多显示器手工验收未执行。上游和下游远端状态仅使用本地缓存，可见性未验证，因此配置不设置 expected_visibility。

## 行为契约

### C001：Next/Previous Display 后立即 Maximize 留在目标屏

- 行为契约：Next/Previous Display 后立即 Maximize 留在目标屏。
- 来源与实现证据：`Rectangle/WindowManager.swift`、`DisplayScreenContextResolver.swift`；OpenSpec display-move-screen-context；已在配置目标的本地提交中静态核查，实际行为仍需验证。
- 证据路径：`Rectangle/WindowManager.swift`、`Rectangle/DisplayScreenContextResolver.swift`、`RectangleTests/RectangleTests.swift`
- 目标覆盖状态：已纳入
- 验证要求：`RectangleTests.swift` 中 resolver 与 PreviousDisplayContext 测试；真实双屏双向移动后最大化
- 验证记录：本次已尝试完整 XCTest，但 Xcode 27 不支持工程的 macOS 10.15 部署目标，构建阶段失败，测试用例未执行；属于工具链兼容阻塞，尚不能判断运行时行为。相关手工验收仍待完成。
- 决策记录：默认保留；尚无例外决策。

### C002：屏幕编号优先、frame 兜底；外部移动或屏幕失效时回退检测

- 行为契约：屏幕编号优先、frame 兜底；外部移动或屏幕失效时回退检测。
- 来源与实现证据：`DisplayIdentity`、`DisplayScreenContextResolver`、`WindowHistoryRectMatcher`；已在配置目标的本地提交中静态核查，实际行为仍需验证。
- 证据路径：`Rectangle/DisplayScreenContextResolver.swift`、`RectangleTests/RectangleTests.swift`
- 目标覆盖状态：已纳入
- 验证要求：screen number 优先、frame fallback、窗口外部移动、目标屏消失测试
- 验证记录：本次已尝试完整 XCTest，但 Xcode 27 不支持工程的 macOS 10.15 部署目标，构建阶段失败，测试用例未执行；属于工具链兼容阻塞，尚不能判断运行时行为。相关手工验收仍待完成。
- 决策记录：默认保留；尚无例外决策。

### C003：跨屏保留 half/third/bottom-half 等原布局和原有 gap/visible frame 语义

- 行为契约：跨屏保留 half/third/bottom-half 等原布局和原有 gap/visible frame 语义。
- 来源与实现证据：`WindowCalculation/NextPrevDisplayCalculation.swift`、`WindowManager.swift`；已在配置目标的本地提交中静态核查，实际行为仍需验证。
- 证据路径：`Rectangle/WindowCalculation/NextPrevDisplayCalculation.swift`、`Rectangle/WindowCalculation/SpecificDisplayCalculation.swift`、`Rectangle/WindowManager.swift`
- 目标覆盖状态：已纳入
- 验证要求：DisplayMoveLayoutMatchResolver 测试；不同分辨率双屏及指定显示器移动手工验收
- 验证记录：本次已尝试完整 XCTest，但 Xcode 27 不支持工程的 macOS 10.15 部署目标，构建阶段失败，测试用例未执行；属于工具链兼容阻塞，尚不能判断运行时行为。相关手工验收仍待完成。
- 决策记录：默认保留；尚无例外决策。

### C004：窗口应用结果按完整 frame 容差匹配，并保持有限重试

- 行为契约：窗口应用结果按完整 frame 容差匹配，并保持有限重试。
- 来源与实现证据：`WindowApplyResultMatcher`、`WindowManager.swift`、`AccessibilityElement.swift`；已在配置目标的本地提交中静态核查，实际行为仍需验证。
- 证据路径：`Rectangle/WindowManager.swift`、`Rectangle/AccessibilityElement.swift`、`RectangleTests/RectangleTests.swift`
- 目标覆盖状态：已纳入
- 验证要求：WholeFrameMatch 与漂移容差测试
- 验证记录：本次已尝试完整 XCTest，但 Xcode 27 不支持工程的 macOS 10.15 部署目标，构建阶段失败，测试用例未执行；属于工具链兼容阻塞，尚不能判断运行时行为。相关手工验收仍待完成。
- 决策记录：默认保留；尚无例外决策。

### C005：跨屏 resize 被系统修正高度时保持底部锚定，避免跳动

- 行为契约：跨屏 resize 被系统修正高度时保持底部锚定，避免跳动。
- 来源与实现证据：`WindowMover/StandardWindowMover.swift`、`Utilities/CGExtension.swift`；已在配置目标的本地提交中静态核查，实际行为仍需验证。
- 证据路径：`Rectangle/WindowMover/StandardWindowMover.swift`、`Rectangle/Utilities/CGExtension.swift`
- 目标覆盖状态：已纳入
- 验证要求：WindowFrameApplyStrategy 测试；下方小屏 bottom-half 场景
- 验证记录：本次已尝试完整 XCTest，但 Xcode 27 不支持工程的 macOS 10.15 部署目标，构建阶段失败，测试用例未执行；属于工具链兼容阻塞，尚不能判断运行时行为。相关手工验收仍待完成。
- 决策记录：默认保留；尚无例外决策。

### C006：Debug 跨屏诊断默认关闭，中文菜单按需启停，不强制显示菜单栏图标

- 行为契约：Debug 跨屏诊断默认关闭，中文菜单按需启停，不强制显示菜单栏图标。
- 来源与实现证据：`AppDelegate.swift`、`Logging/LogViewer.swift`、`RectangleStatusItem.swift`；已在配置目标的本地提交中静态核查，实际行为仍需验证。
- 证据路径：`Rectangle/AppDelegate.swift`、`Rectangle/Logging/LogViewer.swift`、`Rectangle/RectangleStatusItem.swift`
- 目标覆盖状态：已纳入
- 验证要求：Debug 默认不写日志，开关与清空日志手工检查
- 验证记录：本次已静态核查实现随功能提交完整纳入目标；完整 XCTest 在构建阶段因工具链兼容问题阻塞，相关手工验收未执行。
- 决策记录：默认保留；尚无例外决策。

### C007：保留本地构建安装入口与说明

- 行为契约：保留本地构建安装入口与说明。
- 来源与实现证据：`scripts/build-install-run-local.sh`、`LOCAL_SETUP.md`；已在配置目标的本地提交中静态核查，实际行为仍需验证。
- 证据路径：`scripts/build-install-run-local.sh`、`LOCAL_SETUP.md`
- 目标覆盖状态：已纳入
- 验证要求：静态检查构建、退出、替换、启动流程；安装需单独授权
- 验证记录：本次已静态核查入口文件及说明在合并后完整保留；未运行安装脚本，安装与启动流程尚未实测。
- 决策记录：默认保留；尚无例外决策。

### C008：标题栏重复动作在窗口 frame 微小漂移时仍可恢复

- 行为契约：标题栏重复动作在窗口 frame 微小漂移时仍可恢复。
- 来源与实现证据：本地定制提交 8c46cc6 对 TitleBarManager 的精确比较改为容差比较。
- 证据路径：`Rectangle/TitleBarManager.swift`、`Rectangle/Utilities/CGExtension.swift`
- 目标覆盖状态：已纳入
- 验证要求：标题栏同一动作重复触发及 frame 微小漂移场景手工验收
- 验证记录：本次已静态核查实现随功能提交完整纳入目标；完整 XCTest 在构建阶段因工具链兼容问题阻塞，相关手工验收未执行。
- 决策记录：默认保留；尚无例外决策。

## 兼容约束与高风险文件

- 保持快捷键、URL action、默认配置、显示器排序和窗口计算 API 的既有约定。
- 本次定制不要求修改 Bundle Identifier、entitlements、发布签名或 Sparkle。沿用现有身份，不凭下游仓库名称自动改应用身份。
- `Rectangle.xcodeproj/project.pbxproj` 必须保留 resolver 的编译入口与测试配置；合并工程文件后检查新增源码仍属于正确 target。
- 保留 `AGENTS.md`、`openspec/`、本地测试和其他协作技能；不要把它们误当成可直接丢弃的上游差异。
- 旧系统图标资源 workaround 仅临时用于本地构建，不提交 Asset Catalog Other Flags 临时修改。

## 验证边界

检查从共享 scheme、工程、AGENTS.md 与 LOCAL_SETUP.md 自动发现；构建和 XCTest 的本地 ad-hoc 签名及 macOS 测试 destination 可从现有说明恢复，无需在 config.yaml 重复登记。需要 macOS、可用 Xcode/SDK 和 SPM 依赖；环境失败不等于功能回归。本次已执行完整 XCTest，退出码为 65：本机 Xcode 27 的部署目标支持范围为 macOS 12.0–27.0，而工程三个 target 均设置为 10.15，构建失败并取消测试，未执行任何测试用例。未修改工程部署目标或签名配置；后续需使用兼容工具链重新验证。

OpenSpec tasks 中历史构建和测试已勾选，但真实双屏双向移动及日志屏幕身份检查仍未完成。本轮不能用历史勾选代替通过记录。不要自动运行安装脚本、替换 `/Applications/Rectangle.app`、重启用户应用或重置辅助功能权限。

## 检查发现维护

config.yaml 省略 checks，使用 Skill 的默认自动发现。每次同步在合并后的隔离候选重新核查入口、脚本调用链和环境参数，再自动选择并执行必要检查；不依赖本次发现结果长期不变。status 只读，接入仅静态核查。本次合并已重新发现并审查共享 scheme、测试 target 与构建配置，选择完整 XCTest（包含测试所需构建）进行验证；结果见验证边界，既有人工验收缺口继续保留。
