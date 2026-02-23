# Design notes — beautify-wand-editor-ui

目标与原则
---
- 保持低侵入性：尽量复用现有组件结构，仅替换样式与布局。
- 可回滚：每次视觉改动以单独 PR 提交，便于回退。
- 一致性：使用一套统一的调色板与间距系统（基于 Tailwind 变量）。

视觉要点
---
- 字体与层次：标题、次级标题、正文、按钮文字分别使用明确的字号与行高。
- 按钮：明确 Primary / Secondary / Ghost 风格，交互态（hover/active/focus）使用轻微的缩放与色相变化替代过度阴影。
- 卡片与面板：使用一致的圆角与内边距，视觉上突出交互可点击区域。

可用性改进
---
- 增强触控目标：把按钮高度提升到 44-56 px 之间，确保触控设备可用。
- 增加焦点指示：键盘导航时显示明显 focus 状态。

组件映射（建议只读审计后再实际更改）
---
- `wand_editor/src/components/ui/button.tsx` -> 统一 Primary/Secondary 变量。
- `wand_editor/src/components/ui/card.tsx` -> 应用统一内边距与圆角。
- 页面容器 `wand_editor/src/app/page.tsx` -> 对齐与最大宽度约束（例如 1200px 居中）。

实现注意事项
---
- 在变更 PR 中同时包含视觉截图（before/after）以帮助评审。
- 所有改动需有 smoke test 脚本或手动验证步骤（见 tasks.md）。
