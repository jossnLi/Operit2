# Operit2 页面视觉重构未完成清单

## 目标

以 ChatGPT 的界面风格为视觉参考，逐页重做 Operit2 Flutter 应用的布局、层级、留白、导航、卡片、表单、空状态和移动端适配。必须保留现有功能、状态、路由、快捷键、导入/导出、权限确认、加载/错误恢复和平台行为。

这项工作要求改写实际页面和页面组件。单独修改全局主题配置不算完成。用户自定义主题和背景应继续工作；不要通过替换全局颜色强行覆盖自定义主题。

## 当前进度

- 已推送提交：`edd256c`（`ui: redesign settings and package navigation pages`）。
- 已改动 `apps/flutter/app/lib/ui/features/settings/components/SettingsCategoryList.dart`：设置分类导航增加页面标题，改为紧凑的图标与文本行、灰阶选中态；分类选择回调不变。原先显示的分类副标题已移除，后续评估是否在窄屏或悬停时保留辅助说明。
- 已改动 `apps/flutter/app/lib/ui/features/settings/components/SettingsDetailView.dart`：各设置分类详情页增加标题、说明和分隔线，并把对应面板放入剩余页面区域；分类到面板的映射及回调未改。需在运行中验证所有面板的高度约束和滚动行为。
- 已改动 `apps/flutter/app/lib/ui/features/packages/screens/PackageManagerScreen.dart`：为包管理页单独实现“扩展 / 市场”顶部切换器；计数、问题提醒、选择回调、搜索、快捷键和导入入口保留。
- 修改前执行过 `dart format` 与针对上述 UI 文件的 `git diff --check`。没有运行 Flutter analyze、构建或测试，也没有做设备截图验收。

## 待重做页面

### 聊天与工作区

- [ ] `apps/flutter/app/lib/ui/features/chat/screens/AIChatScreen.dart`：新对话、消息流、输入区、顶部动作、响应状态和窄屏布局。
- [ ] `apps/flutter/app/lib/ui/features/chat/components/ChatMessageLocatorPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/chat/components/ChatToolPermissionPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/chat/components/workspace/WorkspacePanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/chat/tts/TtsFloatingPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/chat/components/style/input/common/ChatPendingMessageQueuePanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/chat/components/style/input/common/MentionSuggestionPanel.dart`
- [ ] 盘点并重做 `apps/flutter/app/lib/ui/features/chat/components/style/input/` 下实际使用的输入栏、附件、工具/模型选择器和输入菜单。
- [ ] 盘点并重做 `apps/flutter/app/lib/ui/features/chat/components/style/bubble/` 下消息、工具过程、错误和多模态内容样式。
- [ ] 盘点会话列表、空状态、加载状态、搜索、选择/批量操作、附件预览与各类消息菜单。

### 扩展、市场与发布

- [ ] `apps/flutter/app/lib/ui/features/packages/screens/ExtensionsPane.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/MarketPane.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/ExtensionDetailScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/MarketEntryDetailScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/StoreBrowseScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/MarketCreatorScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/OfficialExtensionsScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/ArtifactPublishScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/RepoMarketPublishScreen.dart`
- [ ] 盘点并重做 `apps/flutter/app/lib/ui/features/packages/components/` 中的扩展卡片、列表项、详情区、安装/更新/删除确认和市场筛选控件。
- [ ] `apps/flutter/app/lib/ui/features/packages/screens/ToolPkgUiLauncherScreen.dart` 与 `ToolPkgDesktopWidgetsScreen.dart`：重做宿主页面容器和导航；插件提供的实际内容与动作协议保持兼容。

### 设置页面

- [ ] `apps/flutter/app/lib/ui/features/settings/screens/SettingsScreen.dart`：重新设计手机与宽屏设置导航框架，并核对已更新的分类列表和详情标题。
- [ ] `apps/flutter/app/lib/ui/features/settings/model/ModelSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/local_models/LocalModelSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/data/DataSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/data/UsageStatisticsDetailScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/appearance/AppearanceSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/global_behavior/GlobalBehaviorSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/tools/ToolSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/workspace/WorkspaceSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/access_links/AccessLinksSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/profile/UserProfileSettingsPanel.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/about/AboutOperitScreen.dart`
- [ ] `apps/flutter/app/lib/ui/features/settings/runtime/RuntimeSettingsPanel.dart` 和 `NetworkControlPanel.dart`：核对其导航入口和是否属于用户要求的页面范围；若可从设置访问，则纳入逐页重做。
- [ ] `apps/flutter/app/lib/ui/features/settings/tts/TtsSettingsPanel.dart`：核对路由映射；当前 `SettingsDetailView` 的 `tts` 分支映射到 `ModelSettingsPanel`，不要在重构时无意改变既有行为。
- [ ] 检查 `apps/flutter/app/lib/ui/features/settings/components/SettingsControlStyles.dart`、`SettingsCategoryList.dart` 与各设置面板之间的重复样式，按页面实际结构调整；不要把所有页面仅换成统一主题配置。

### 其他宿主页面与弹层

- [ ] `apps/flutter/app/lib/ui/features/settings/runtime/`、`apps/flutter/app/lib/ui/features/update/`、`apps/flutter/app/lib/ui/features/onboarding/` 和 `apps/flutter/app/lib/ui/rescue/` 下可见页面。
- [ ] 盘点 `apps/flutter/app/lib/ui/features/` 中以 `Screen.dart`、`Panel.dart`、`Pane.dart`、`Dialog.dart` 结尾的可见界面，逐个对照路由、导航入口与弹层入口补齐清单。
- [ ] 盘点 `apps/flutter/app/lib/ui/common/` 中作为整页使用的备份恢复、设备空间、错误、空状态和引导界面。

## 接手约束

1. 先阅读 `AGENTS.md`、`BUILDING.md` 和相关页面/路由实现，再开始改动。
2. 页面重做只改 UI 层。保留现有控制器、服务、模型、事件订阅、路由参数和回调语义；避免通过改 Core/协议来实现视觉效果。
3. 逐页核对手机、平板/桌面、浅色/深色、自定义背景、长文本/大字体、加载/空/失败/禁用状态。适配方式要服从页面用途，不把所有内容硬套成同一种卡片布局。
4. ChatGPT 风格指中性、克制的层级和直接的操作布局；不要复制 ChatGPT 品牌标志或移除 Operit 品牌身份。
5. 每完成一组页面，运行格式化、相关静态检查和可行的目标平台构建；制作运行截图检查布局。最终报告要分别记录通过项和未验证项。
6. 每次暂存或提交时明确指定本次 UI 文件路径。不要顺带提交工作区既有修改。

## 工作区遗留修改

记录时以下文件在工作区已有未提交修改，不属于本次 UI 重构提交。接手前重新运行 `git status --short` 并确认归属；不得直接 `git add -A` 或覆盖：

- `apps/flutter/app/linux/flutter/generated_plugin_registrant.cc`
- `apps/flutter/app/linux/flutter/generated_plugin_registrant.h`
- `apps/flutter/app/linux/flutter/generated_plugins.cmake`
- `apps/flutter/app/macos/Flutter/GeneratedPluginRegistrant.swift`
- `apps/flutter/app/windows/flutter/generated_plugin_registrant.cc`
- `apps/flutter/app/windows/flutter/generated_plugin_registrant.h`
- `apps/flutter/app/windows/flutter/generated_plugins.cmake`
- `plugins/packages/buildin/workflow/resources/THIRD_PARTY_NOTICES.txt`
- `plugins/types/` 下多个生成的 `.d.ts` 文件

这些遗留修改未包含在 `edd256c` 中。
