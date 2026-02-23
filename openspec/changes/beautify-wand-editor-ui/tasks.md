# Tasks for change-id: beautify-wand-editor-ui

1. 准备（文档）
   - 输出本提案（proposal.md），并在变更目录下创建 tasks/design/spec 框架（已完成）。
2. 代码/样式审计（只读）
   - 列出 `wand_editor/src/components/ui/` 下所有组件文件与依赖样式。
   - 标注每个文件是否包含业务逻辑（禁改）。
3. 视觉设计（小步）
   - 设计统一的调色板与间距变量（Tailwind 变量或 CSS 变量）。
   - 定义按钮、卡片、列表项的视觉样式（hover/active 状态）。
4. 实施（分 PR）
   - PR 1：样式变量与基础 utilities（Tailwind 配置/全局 CSS）。
   - PR 2：全局组件视觉替换（按钮、表单控件、卡片）。
   - PR 3：页面级布局微调（间距、对齐、字体大小）。
5. 验证
   - 手工回归：启动 `wand_editor`，执行关键流程（打开编辑器、上传/载入素材、运行编译）并比对行为。
   - 静态检查：`rg` 搜索确认未改动逻辑文件。
6. 文档与交付
   - 在变更目录提交 `design.md` 和变更说明。

每项任务都应包含具体校验点（如何确认未触及逻辑、样式是否生效），并由代码评审人签署验收。
