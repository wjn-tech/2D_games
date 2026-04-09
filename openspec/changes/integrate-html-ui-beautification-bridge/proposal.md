# Change: Embed HTML UI for Beautification

## Why
当前项目已有较完整的 Godot 原生 UI 链路，但高复杂度界面（背包、配方、信息面板）在视觉表达和动效复用上仍受限。用户目标是“在现有游戏内嵌入 HTML 代码来美化 UI”，而不是将整款游戏改造成网页发布形态。

本提案用于定义单一路线：在 Godot 原生项目中嵌入 WebView 承载 HTML UI，并保持可回退、可验证、可维护。

## What Changes
- 新增 `ui-webview-embedding` 能力增量（嵌入浏览器路线）：
  - 在游戏内加载网页 UI，用于背包等高复杂度界面美化。
  - 约束 WebView 插件选型与能力差异：
    - `godot_wry`：轻量、系统原生 WebView、支持本地资源和 JS/GDScript 通信，桌面优先。
    - `gdcef`：Chromium 能力最全，但包体与内存开销显著增大。
    - `godot-webview`：多 WebView 与透明等高级能力强，需在授权/商业条款上单独评估。
  - 定义输入焦点、层级遮挡、失败回退规则。
- 新增统一桥接协议约束：
  - Godot 作为权威状态源，HTML UI 只做展示与交互回传。
  - 首批试点限定 `InventoryWindow`，其余窗口维持 Godot 原生实现。
  - 运行异常时必须自动回退到原生窗口，避免影响可玩性。

## Scope
- In scope:
  - WebView 嵌入路线的技术边界、平台支持、通信方式、输入与回退策略。
  - 首批试点窗口默认限定为 `InventoryWindow`。
  - 方案验证标准（可运行、可回退、可测量）。
- Out of scope:
  - 将整款游戏导出为网页（HTML5/WebAssembly）并作为主要发布形态。
  - 一次性迁移所有 UI 到 HTML。
  - 战斗/世界生成/NPC 等核心玩法重构。
  - 直接绑定单一第三方插件作为不可替换方案。

## Impact
- Affected specs:
  - `ui-webview-embedding` (new)
- Related changes:
  - `add-ui-beautify`
  - `implement-visual-ui-framework`
- Affected code (apply stage):
  - `src/ui/ui_manager.gd`
  - `src/core/event_bus.gd`
  - `src/core/game_manager.gd`
  - `src/ui/inventory/inventory_ui.gd`
  - `inventory/src/app/page.tsx`
  - `project.godot` (导出配置与可选 feature tag 检查)

## Defaults for Ambiguous Inputs
1. 默认采用 WebView 嵌入路线，不引入“整游网页导出”作为本提案目标。
2. 首批 HTML 化范围默认仅包含 `InventoryWindow`，其余窗口保持 Godot 原生。
3. 默认优先以 `godot_wry` 作为首个 PoC 适配器，若能力不足再评估 `gdcef` 或 `godot-webview`。
4. 启动失败或运行异常时，系统默认必须回退到原生 `res://scenes/ui/InventoryWindow.tscn`。
5. 默认禁用动态 `eval` 作为业务主通道，仅允许白名单消息协议调用。

## Open Questions
- 当前无阻塞性未决问题，可进入评审。
