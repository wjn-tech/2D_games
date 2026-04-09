# Change: Refactor Gameplay Guide HTML Shell Skin (Style-1:1, Logic Locked)

## Why
当前新手引导窗口已具备完整可用逻辑（目录树、分页、图鉴、资源加载），但视觉风格仍是 Godot 原生基础面板，和已交付的 guide 项目目标美术（HandbookWindow 像素科幻主题）不一致。

本次目标是“只换壳不换核”：以 guide 项目风格对引导窗口做嵌入式 HTML 壳重构，同时严格保留现有逻辑内容与行为路径，确保玩家体验只发生视觉变化，不发生语义变化。

## What Changes
- 新增 `gameplay-guide-html-shell` 能力增量，定义引导窗口 HTML 壳改造约束：
  - 视觉上以 guide 项目 HandbookWindow 风格为基线，尽量 1:1 还原像素科幻主题。
  - 逻辑上保持现有 GameplayGuideWindow 行为完全不变（目录构建、分页切换、图鉴生成、按钮行为、数据来源）。
  - 内容上保持现有 GuideSectionData 与目录树结构为权威来源，不迁移为 guide 子项目数据模型。
- 约束运行策略：
  - 运行时默认优先启用 WebView HTML 壳。
  - WebView/资源/桥接异常时必须自动回退到现有原生窗口，且可继续完整使用。
- 约束平台验收：
  - 桌面端为强制验收目标。
  - 移动端可降级，不作为本次阻塞项。

## Scope
- In scope:
  - Gameplay Guide 主窗口视觉壳替换（嵌入式 HTML）。
  - 视觉主题迁移、静态资源打包、双向桥接契约、失败回退。
  - 逻辑/内容一致性验证与回归清单。
- Out of scope:
  - 修改 HUD 入口、快捷键、暂停逻辑、分页逻辑、章节结构与文案。
  - 修改 GuideSectionData 数据结构和业务语义。
  - 扩展到其他窗口（背包、法杖编辑器等）或全量 UI HTML 化。
  - 移动端专项适配与性能调优。

## Impact
- Affected specs:
  - `gameplay-guide-html-shell` (new delta)
- Related changes:
  - `integrate-html-ui-beautification-bridge`
  - `add-gameplay-guide-system`
  - `refactor-inventory-html-shell-skin`
  - `refactor-wand-editor-html-shell`
- Affected code (apply stage):
  - `src/ui/guide/gameplay_guide_window.gd`
  - `scenes/ui/gameplay_guide_window.tscn`
  - `ui/web/gameplay_guide_shell/index.html` (+ static assets)
  - `scenes/ui/hud.gd` (仅在窗口创建路径需要壳路由接入时)

## Resolved Clarifications
- 变更归属：新建 change-id，不挂靠既有提案。
- 换壳范围：仅 gameplay guide 主窗口壳，不改 HUD 入口与交互逻辑。
- 内容基线：严格沿用当前游戏内 GuideSectionData 与目录树。
- 风格标准：尽量 1:1 对齐 guide/HandbookWindow 视觉风格。
- 运行策略：WebView 优先，失败自动回退原生窗口。
- 验收边界：桌面强制；移动端可降级。
