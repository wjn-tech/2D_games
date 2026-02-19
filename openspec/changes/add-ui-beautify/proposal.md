# Change: Add UI beautify theme

## Why
当前游戏内工具（如 `WandEditor`）的 UI 风格偏功能性、缺少现代化视觉主题。为提高可用性与吸引力，需要一套可复用的全局 UI 主题与小规模视觉改造方案，优先采用低成本的 Godot 原生控件与资源实现。

## What Changes
- 新增一个可复用的全局 `Theme` 样板（颜色、字体、StyleBox）并在示例场景中应用。
- 为 `WandEditor` 提供快速整容（字体、按钮样式、面板样式、少量过渡动画）。
- 在 `openspec/specs/ui/spec.md` 中添加需求与场景，作为 capability delta。

## Impact
- 受影响的能力: UI/Theming（openspec/specs/ui/spec.md 新增 delta）
- 受影响的代码/文件（示例）: `src/ui/wand_editor/wand_editor.gd`, `res://assets/fonts/`（新增字体资源）, 顶层 `Theme` 资源（路径待定）
- 风险: 视觉资源体积增加（字体/图标），需注意资源管理与授权

## Non-Goals
- 不在此变更中实现复杂的 HTML/JS 嵌入或完整的 UI 动画库。优先使用 Godot 原生控件和小范围动画。

## Acceptance Criteria
- 项目包含 `openspec/changes/add-ui-beautify/specs/ui/spec.md` 的 delta 文件并通过审阅。
- `WandEditor` 在默认主题下外观明显改进（更好字体、圆角面板、按钮 hover 动画）；由审阅者通过截图/录屏确认视觉改进。
