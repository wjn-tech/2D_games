# Design: Embedded HTML UI via WebView

## Context
- 项目已具备 Godot 原生 UI 管线（`UIManager` + `EventBus` + `InventoryWindow`）以及可复用的 HTML/React 资源基础。
- 用户目标已明确：仅在现有原生游戏内嵌入 HTML UI，不将游戏改为网页发布。
- 关键约束：
  - 必须保留可回退路径，避免 UI 技术选型影响可玩性。
  - 方案需要覆盖插件能力差异与性能/包体权衡。

## Goals / Non-Goals
- Goals:
  - 给出 WebView 嵌入路线的可执行技术方案与插件选型标准。
  - 在不改动核心玩法逻辑的前提下，先完成 `InventoryWindow` 试点。
  - 明确通信协议、安全边界、输入焦点与回退机制。
- Non-Goals:
  - 不在本提案中将游戏转为 HTML5 网页发布形态。
  - 不在本提案中实现全量 UI HTML 化。
  - 不承诺某个第三方插件在所有平台“零差异”运行。

## Adapter Decision Matrix
| 场景 | 首选适配器 | 理由 |
|---|---|---|
| 轻量 PC 项目、快速接入 | `godot_wry` | 依赖轻、安装快、双向通信直接 |
| 复杂现代 Web 应用（重 JS/WASM） | `gdcef` | Chromium 能力更完整 |
| 需要多 WebView/透明等高级能力 | `godot-webview` | 提供多实例与纹理化能力 |

## Plugin/Path Analysis
1. WebView 嵌入方案
- `godot_wry`：系统原生 WebView，支持 URL 与本地资源加载、JS/GDScript 双向通信；桌面支持成熟，移动/HTML5 仍在规划。
- `gdcef`：基于 CEF，功能强且兼容现代网页；代价是安装体积大（官方资产页说明 artifacts 为 500MB+）。
- `godot-webview`：站点展示多 WebView、透明、高帧率渲染等能力；但授权模式与商业条款需项目侧法务确认。
- 共性限制：WebView 常见顶层覆盖与输入焦点冲突，需要专门协调。

## Architecture
1. 统一抽象层
- 定义 `WebUIAdapter` 抽象接口（apply 阶段实现）：
  - `open_inventory(payload)`
  - `close_inventory()`
  - `send_event(type, payload)`
  - `on_message(callback)`
  - `health_check()`
- 不同 WebView 插件分别实现 Adapter，`UIManager` 仅依赖抽象层。

2. 通信协议
- 统一消息模型：`{ type, version, request_id, payload, ts }`
- 统一最小事件：
  - `ui.open.inventory`
  - `ui.close.inventory`
  - `inventory.snapshot`
  - `inventory.action.move`
  - `inventory.action.use`
  - `inventory.action.drop`
  - `bridge.error`

3. 输入与回退
- Godot 侧是输入裁决者：HTML UI 激活时禁用玩法输入，关闭后恢复。
- 任何适配器异常必须在 SLA 时间内回退原生 `InventoryWindow`。

## Risks / Trade-offs
- 包体风险：`gdcef` 能力最强但体积大。
- 平台风险：`godot_wry` 的移动端与 Web 仍在规划，短期不应作为移动目标主路径。
- 维护风险：双端 UI 并行可能增加状态一致性成本。
- 安全风险：动态 JS 执行与不受信任 URL 可能扩大攻击面。

## Validation Strategy
- 功能一致性：同一背包操作在 HTML UI 与原生 UI 结果一致。
- 可靠性：连接失败、超时、异常渲染必须触发自动回退。
- 性能：记录 UI 打开延迟、内存占用、帧时间变化。
- 平台：至少验证 Windows 与 Linux 桌面端行为差异。

## External References
- Godot WRY README：`doceazedo/godot_wry`
- GDCEF README 与资产页：`Lecrapouille/gdcef`、asset 2508
- godot-webview 官方站点：`godotwebview.com`
