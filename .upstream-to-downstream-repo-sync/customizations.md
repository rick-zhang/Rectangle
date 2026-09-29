# Rectangle 下游定制保护清单

<!-- customizations-schema: 1 -->

## 维护约定

当前上下游身份、remote、目标分支及检查模式覆盖以 `config.yaml` 为唯一依据；检查命令默认由 Skill 从当前工程自动发现；本文件由 Skill 自动增量维护，用户无需随配置手工修改。用户本地定制默认全部保留，包括尚未登记、其他分支及工作区中的定制；保留不等于擅自提交或合并所有分支。覆盖状态不等于测试通过。

无法自动判断的行为冲突由 Skill 说明选项和影响，用户决策后由 Skill 自动更新实现、证据及决策记录。已确认的决定在相同条件下复用。覆盖状态针对配置目标分支；隔离候选的自动测试结果单独记录。每次同步须重新核对远端与目标状态。

## 接入依据与目标

历史接入依据：当时定制位于 `fix-maximize-after-display-move`，main 未包含这些实现，因此选择功能分支作为目标。本次按用户要求将该功能分支快进合并回主分支，并将配置目标切换为下游主分支；合并完整保留功能提交及 C001–C008 的实现、测试和协作文件。当前目标始终读取配置，后续切换由 Skill 自动核查覆盖并维护清单。

历史接入时本地 main 跟踪上游，功能分支跟踪下游同名分支；本次合并保留这些 Git 跟踪关系，配置目标与 Git 跟踪关系应分别核实。跟踪关系每次从 Git 核实，不能用裸 git pull 代替同步流程，也不顺手修改其他分支。

历史接入时，原有实现和测试已纳入配置目标。本轮已 fetch 上下游目标分支，在独立同步候选中合并上游并适配全部定制；候选尚未合回配置目标，因此下列条目标记为待纳入。远端可见性未验证，配置继续省略 expected_visibility。完整 XCTest 结果见验证边界，多显示器手工验收仍未执行。

## 行为契约

### C001：Next/Previous Display 后立即 Maximize 留在目标屏

- 行为契约：Next/Previous Display 后立即 Maximize 留在目标屏。
- 来源与实现证据：`Rectangle/WindowManager.swift`、`DisplayScreenContextResolver.swift`；OpenSpec display-move-screen-context；历史版本已纳入配置目标，本轮适配位于待合回的同步候选。
- 证据路径：`Rectangle/WindowManager.swift`、`Rectangle/DisplayScreenContextResolver.swift`、`RectangleTests/RectangleTests.swift`
- 目标覆盖状态：待纳入
- 验证要求：`RectangleTests.swift` 中 resolver 与 PreviousDisplayContext 测试；真实双屏双向移动后最大化
- 验证记录：本轮候选完整 XCTest 通过（474 项，0 失败），覆盖目标屏身份匹配、动作记录及动画计数兼容；真实双屏双向移动后立即最大化仍待人工验收。
- 决策记录：默认保留；尚无例外决策。

### C002：屏幕编号优先、frame 兜底；外部移动或屏幕失效时回退检测

- 行为契约：屏幕编号优先、frame 兜底；外部移动或屏幕失效时回退检测。
- 来源与实现证据：`DisplayIdentity`、`DisplayScreenContextResolver`、`WindowHistoryRectMatcher`；历史版本已纳入配置目标，本轮适配位于待合回的同步候选。
- 证据路径：`Rectangle/DisplayScreenContextResolver.swift`、`RectangleTests/RectangleTests.swift`
- 目标覆盖状态：待纳入
- 验证要求：screen number 优先、frame fallback、窗口外部移动、目标屏消失测试
- 验证记录：本轮候选完整 XCTest 通过（474 项，0 失败），屏幕编号优先、frame 兜底、外部移动和目标屏消失的 resolver 用例通过；显示器热插拔仍待人工验收。
- 决策记录：默认保留；尚无例外决策。

### C003：跨屏保留 half/third/bottom-half 等原布局和原有 gap/visible frame 语义

- 行为契约：跨屏保留 half/third/bottom-half 等原布局和原有 gap/visible frame 语义。
- 来源与实现证据：`WindowCalculation/NextPrevDisplayCalculation.swift`、`WindowManager.swift`；历史版本已纳入配置目标，本轮适配位于待合回的同步候选。
- 证据路径：`Rectangle/WindowCalculation/NextPrevDisplayCalculation.swift`、`Rectangle/WindowCalculation/SpecificDisplayCalculation.swift`、`Rectangle/WindowManager.swift`
- 目标覆盖状态：待纳入
- 验证要求：DisplayMoveLayoutMatchResolver 测试；不同分辨率双屏及指定显示器移动手工验收
- 验证记录：本轮候选完整 XCTest 通过（474 项，0 失败）。新增 next/previous/指定显示器的 half、third、bottom-half 计算入口回归，覆盖默认布局重放、显式关闭后的上游位置转移、最大化保持和窗口 ID 缺失。保留上游 gap 与可见区域流程；真实不同分辨率双屏仍待人工验收。
- 决策记录：默认保留；尚无例外决策。

### C004：窗口应用结果按完整 frame 容差匹配，并保持有限重试

- 行为契约：窗口应用结果按完整 frame 容差匹配，并保持有限重试。
- 来源与实现证据：`WindowApplyResultMatcher`、`WindowManager.swift`、`AccessibilityElement.swift`；历史版本已纳入配置目标，本轮适配位于待合回的同步候选。
- 证据路径：`Rectangle/WindowManager.swift`、`Rectangle/AccessibilityElement.swift`、`RectangleTests/RectangleTests.swift`
- 目标覆盖状态：待纳入
- 验证要求：WholeFrameMatch 与漂移容差测试
- 验证记录：本轮候选完整 XCTest 通过（474 项，0 失败），包含完整 frame 容差、仅位置不匹配时重试、宽度受限重试，以及新动作取消旧异步重试的用例。
- 决策记录：默认保留；尚无例外决策。

### C005：跨屏 resize 被系统修正高度时保持底部锚定，避免跳动

- 行为契约：跨屏 resize 被系统修正高度时保持底部锚定，避免跳动。
- 来源与实现证据：`WindowMover/StandardWindowMover.swift`、`Utilities/CGExtension.swift`；历史版本已纳入配置目标，本轮适配位于待合回的同步候选。
- 证据路径：`Rectangle/WindowMover/StandardWindowMover.swift`、`Rectangle/Utilities/CGExtension.swift`
- 目标覆盖状态：待纳入
- 验证要求：WindowFrameApplyStrategy 测试；下方小屏 bottom-half 场景
- 验证记录：本轮候选完整 XCTest 通过（474 项，0 失败），底部锚定几何用例通过；回调已接入上游 ResultParameters 和 Enhanced UI 调整流程，下方小屏的实际窗口跳动仍待人工验收。
- 决策记录：默认保留；尚无例外决策。

### C006：Debug 跨屏诊断默认关闭，中文菜单按需启停，不强制显示菜单栏图标

- 行为契约：Debug 跨屏诊断默认关闭，中文菜单按需启停，不强制显示菜单栏图标。
- 来源与实现证据：`AppDelegate.swift`、`Logging/LogViewer.swift`、`RectangleStatusItem.swift`；历史版本已纳入配置目标，本轮适配位于待合回的同步候选。
- 证据路径：`Rectangle/AppDelegate.swift`、`Rectangle/Logging/LogViewer.swift`、`Rectangle/RectangleStatusItem.swift`
- 目标覆盖状态：待纳入
- 验证要求：Debug 默认不写日志，开关与清空日志手工检查
- 验证记录：本轮 Debug 应用构建及完整 XCTest 通过（474 项，0 失败）；静态核查确认日志默认关闭、中文菜单启停及状态栏图标保护仍保留。日志开关、清空和菜单显示仍待人工验收。
- 决策记录：默认保留；尚无例外决策。

### C007：保留本地构建安装入口与说明

- 行为契约：保留本地构建安装入口与说明。
- 来源与实现证据：`scripts/build-install-run-local.sh`、`LOCAL_SETUP.md`；历史版本已纳入配置目标，本轮适配位于待合回的同步候选。
- 证据路径：`scripts/build-install-run-local.sh`、`LOCAL_SETUP.md`
- 目标覆盖状态：待纳入
- 验证要求：静态检查构建、退出、替换、启动流程；安装需单独授权
- 验证记录：入口脚本 bash -n 语法检查通过；本轮完整 XCTest 包含应用构建。LOCAL_SETUP 已同步上游 macOS 14 与 Xcode 27 环境说明；未执行安装、替换应用或启动脚本。
- 决策记录：默认保留；尚无例外决策。

### C008：标题栏重复动作在窗口 frame 微小漂移时仍可恢复

- 行为契约：标题栏重复动作在窗口 frame 微小漂移时仍可恢复。
- 来源与实现证据：本地定制提交 8c46cc6 对 TitleBarManager 的精确比较改为容差比较。
- 证据路径：`Rectangle/TitleBarManager.swift`、`Rectangle/Utilities/CGExtension.swift`
- 目标覆盖状态：待纳入
- 验证要求：标题栏同一动作重复触发及 frame 微小漂移场景手工验收
- 验证记录：本轮候选完整 XCTest 通过（474 项，0 失败），新增标题栏恢复用例覆盖微小漂移、动画尚未完成时采用逻辑目标 frame，以及明显外部移动时不恢复；真实标题栏交互仍待人工验收。
- 决策记录：默认保留；尚无例外决策。

### C009：保持同步后的测试接口兼容

- 行为契约：保留上下游测试覆盖，测试替身能够承载跨屏位置回调、诊断屏幕名称与身份信息，不能通过跳过测试掩盖同步回归。
- 来源与实现证据：本轮发现上游 DisplayTransfer 返回值已改为元组，但测试辅助方法仍返回整个元组；仅改为提取 rect。上游窗口测试替身同步增加下游 setFrame 回调参数，合成屏幕补充名称与设备信息；新增同步兼容回归。
- 证据路径：`RectangleTests/DisplayTransferTests.swift`、`RectangleTests/RectangleTests.swift`
- 目标覆盖状态：待纳入
- 验证要求：完整 XCTest；保留跨屏、动画和窗口尺寸约束用例。
- 验证记录：本轮完整 XCTest 通过，474 项测试、0 失败；未跳过测试。DisplayTransfer 原测试调用与上游内容一致，属于上游既有编译问题；测试替身签名和属性适配属于本轮兼容修复。
- 决策记录：依默认保留原则完成接口适配，不改变 DisplayTransfer 产品行为或放宽测试断言。

## 兼容约束与高风险文件

- 保持快捷键、URL action、默认配置、显示器排序和窗口计算 API 的既有约定。
- 本次定制不要求修改 Bundle Identifier、entitlements、发布签名或 Sparkle。沿用现有身份，不凭下游仓库名称自动改应用身份。
- `Rectangle.xcodeproj/project.pbxproj` 必须保留 resolver 的编译入口与测试配置；合并工程文件后检查新增源码仍属于正确 target。
- 保留 `AGENTS.md`、`openspec/`、本地测试和其他协作技能；不要把它们误当成可直接丢弃的上游差异。
- 旧系统图标资源 workaround 仅临时用于本地构建，不提交 Asset Catalog Other Flags 临时修改。

## 验证边界

历史接入曾因 Xcode 27 与原工程 macOS 10.15 部署目标不兼容而在构建阶段失败，未执行测试；该记录不代表本轮结果。本轮沿用上游推荐部署目标（macOS 14），未引入本地签名或 Asset Catalog 临时配置。

本轮在隔离候选重新发现并审查共享 scheme、工程 Build Phases、测试 target、CI 和本地构建说明。完整 XCTest（包含 Debug 构建）最终通过：474 项、0 失败。最初沙箱内 SwiftPM 缓存写入受限，经授权在沙箱外运行；中途发现并修复测试返回类型、方法签名及合成屏幕属性兼容问题。配置、清单结构、工程 plist、脚本语法和候选相对上游的 diff 检查结果见本轮运行记录。

真实多屏双向移动、系统窗口尺寸修正、辅助功能权限、诊断菜单开关和实际安装流程仍未人工验收。自动测试通过不代表这些运行时场景已验收。候选仅交付本地同步分支，尚未进入配置目标，也未推送远端、安装或重启用户应用；原工作区保持不变。运行 SHA、恢复入口、完整日志和结果包保存在 Git 本地元数据中。

## 检查发现维护

config.yaml 继续省略 checks，使用 Skill 的自动发现。每次同步在隔离候选重新审查入口和命令，再执行必要检查。本轮选择完整 XCTest，覆盖新增接口与跨屏兼容测试；脚本仅做语法检查。检查命令和结果保存在 Git 本地运行记录，不写入稳定配置；真实多屏与交互验收缺口继续保留。
