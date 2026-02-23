## ADDED Requirements

1. Requirement: 提升 `wand_editor` 主界面视觉风格

#### Description
在不修改任何编译/运行逻辑的前提下，对 `wand_editor` 的 UI 进行视觉升级，包含按钮、卡片、表单、整体布局与间距调整。

#### Scenario: 按钮样式一致性
- Given: `wand_editor` 项目已存在多个按钮组件（Primary/Secondary）
- When: 执行视觉更新 PR，将按钮样式替换为统一的 design token（颜色/圆角/高度）
- Then: 所有按钮在视觉上表现一致，功能与事件绑定不变；开发者能通过审查确认未改动逻辑文件。

#### Scenario: 页面布局与可用性
- Given: 编辑器页面在多个分辨率下显示不一致
- When: 应用统一容器宽度与间距变量
- Then: 页面在 1366x768 与 1920x1080 分辨率下无显著溢出或遮挡，交互控件点击区域满足触控尺寸。

Validation
---
- 静态验证：运行 `rg` 搜索确认 PR 中未包含对 `wand_editor/src/**` 下以 `upload`, `compile`, `network`, `run` 等关键字的逻辑性改动（以人工审查为准）。
- 运行验证：在本地启动 `wand_editor`（开发服务器），手工执行关键路径（打开编辑器、载入素材、触发编译），行为应与变更前一致。
