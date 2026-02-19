# Change: 增强主菜单视觉与交互（MainMenu Visuals Polish）

## Why
- 当前主菜单视觉已初步实现（星空 + 同心环 + 渐变文字 + 按钮 glow），但与设计参考仍有差距，并存在若干兼容性与可访问性问题（例如图标浮于其他面板、部分 Godot 4 API 不一致）。
- 需要一个小范围、可审阅的提案来明确可交付项、验收准则与回退策略，以便在不破坏现有场景与行为的前提下逐步完成视觉打磨。

## What changes
- 新增或完善主菜单背景着色器参数与默认值（star density、ring count、ring blur、nebula 强度），并把这些参数暴露为可调整的资源/控制节点属性。  
- 统一按钮视觉样式：多层 StyleBox、内发光 shader、外发光 ColorRect、悬停/按下 tween 行为与动画曲线。  
- 文字渐变效果（已存在 shader）推广至欢迎文字与按钮文本，并随时间动画；为低端设备提供降级（关闭噪声/减低星密度）的运行时选项。  
- 修复图标层级问题：确保图标为按钮子节点、启用裁剪 `clip_contents`，不再悬浮于其它 UI 之上。  
- 兼容性整治：修正 Godot 4 不再可用的属性/API（示例：替换 `rect_min_size` → `custom_minimum_size`，避免 `Button.ICON_*` 常量依赖）。

## Impact
- 受影响能力/规格：`ui/menu`（新增视觉/交互行为），`ui/theme`（字体/风格），以及 runtime 性能配置。  
- 受影响代码/资源：`scenes/ui/main_menu.gd`、`ui/shaders/menu_bg.shader`、`ui/shaders/text_gradient.shader`、主题资源（.tres）与若干新/更新的 SVG 图标、字体资源引用。  
- 兼容性：变更以向后兼容为目标，但涉及 shader 的视觉行为在不同 GPU/驱动上可能可见差异；将提供运行时回退参数。  

## Risks & Mitigations
- 风险：复杂 shader 在低端 GPU 上造成性能问题。  
  - 缓解：导出 `star_density`、`use_noise`、`ring_count` 等参数供运行时调整；在 `ProjectSettings` 或运行时设置中提供“低/中/高”预设。  
- 风险：太多视觉改动导致按钮交互行为不一致。  
  - 缓解：定义明确的交互验收准则（悬停/按下动画时长、可视化反馈幅度），并在 `tasks.md` 要求录制短视频或截图以人工核验。

## Rollout
- 该提案分阶段实施：第 1 阶段为兼容性修复与基础 shader 参数化，第 2 阶段为渐变与按钮视觉增强，第 3 阶段为性能预设与回退。每阶段完成后运行 `openspec validate <change-id> --strict` 并提交审阅。

## Non-goals
- 不在本提案范围内的内容包括游戏玩法逻辑改动、后端服务变更、或大范围 UI 重构（例如整个 UI 框架替换）。

## Deliverables
- 提交 `openspec/changes/add-mainmenu-visuals-2026-02-17/`，包含 `proposal.md`、`tasks.md`、`design.md`（技术理由）、和 `specs/visuals/spec.md`（delta）。
- 对应的实现 PR（在提案批准后）将包含最小化的 shader 与脚本改动，并附带运行时参数与回退选项。
