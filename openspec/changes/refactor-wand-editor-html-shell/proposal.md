# Change: Refactor Wand Editor HTML Embedded Shell (Style Transplant, Logic Locked)

## Why
本次目标已明确为“换壳不换核”：
1. 美术上：完整移植示例项目最终效果图对应的视觉主题。
2. 布局上：保持现有项目的排版比例与空间分配。
3. 逻辑上：不做任何逻辑修改，若出现冲突，现有逻辑优先。

当前 Godot 端已具备 WebView 接入入口，但嵌入壳目录仍为空，且尚无“美术迁移边界 + 逻辑优先规则 + 比例保持规则”的统一规范。因此需要本提案将这些约束固化为可验证要求。

## What Changes
- 定义 `wand-editor-html-shell` 的“样式完整移植”约束：
  - 以示例项目最终效果图为主题基线，迁移其色彩层级、像素边框、扫描层、发光反馈、面板层次感。
  - 视觉目标为“基本还原”，但不引入示例项目中的业务语义变化。
- 定义“排版比例沿用现有项目”约束：
  - 左侧库区 / 中央工作区 / 右侧详情区 / 顶栏的比例与布局节奏以现有项目为准。
  - 允许样式替换，不允许因主题迁移改变核心布局比例策略。
- 定义“逻辑冲突现有优先”硬规则：
  - 所有法杖编程逻辑、编译、保存、测试、热键、文案保持 1:1。
  - 如果示例主题实现与现有逻辑行为冲突，必须保留现有逻辑行为。
- 保留嵌入桥接路线：
  - Godot 仍是权威状态源，HTML 壳仅负责渲染与意图上报。
  - 异常时自动回退原生编辑器，保证编辑可持续。

## Scope
- In scope:
  - 示例主题美术迁移与嵌入式壳重构（桌面优先）。
  - 按现有项目比例约束进行布局还原。
  - 逻辑、文案、行为一致性校验。
- Out of scope:
  - 新增或修改法杖逻辑功能。
  - 修改节点语义、编译算法、测试语义。
  - 移动端专项适配。

## Impact
- Affected specs:
  - `wand-editor-html-shell` (new delta)
- Affected code (apply stage):
  - `src/ui/wand_editor/wand_editor.gd`
  - `ui/web/wand_editor_shell/index.html` (+ 对应静态资源)
  - `wand_editor/src/app/page.tsx` (仅用于主题映射与风格令牌对齐)
  - `wand_editor/src/lib/wand-store.ts` (仅在序列化字段对接需要时，语义不变)
- Related existing artifacts:
  - `openspec/changes/refactor-wand-editor-html-shell/verification.md`
  - `openspec/changes/refactor-wand-editor-html-shell/chinese-copy-after.txt`

## Resolved Clarifications
- 美术主题：完整对齐示例项目效果图，目标“基本还原”。
- 布局比例：按现有项目比例，不按示例项目比例强行改版。
- 冲突处理：所有逻辑冲突以现有逻辑为准。
- 范围边界：仅做提案，不做实现代码。
