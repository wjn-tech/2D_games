## Tasks for `add-ui-beautify`

### 1. Discovery / Prep
- [ ] 1.1 盘点当前 UI 入口（列出关键场景/控件：`WandEditor`, 主菜单, 背包等），并截图当前状态。
- [ ] 1.2 选定开源许可友好的字体资源（或使用内置像素字体作为过渡），准备导入路径 `res://assets/fonts/`。

### 2. Theme Scaffold (低侵入)
- [ ] 2.1 创建 `res://ui/theme/theme_default.tres`，定义基础颜色、控件样式（`StyleBoxFlat`）、Button 样式与 Label 字体。
- [ ] 2.2 在 `WandEditor` 根 `Control` 中应用该 Theme（`theme` 属性），并验证无脚本错误。

### 3. WandEditor 快速美化（示例驱动）
- [ ] 3.1 替换 `WandEditor` 的关键字体为导入字体。
- [ ] 3.2 为面板/库按钮应用圆角、轻微阴影与 hover 效果（使用 `StyleBoxFlat` 与 `Tween`）。
- [ ] 3.3 为主要交互按钮添加按下/悬停过渡（scale 或 modulate）。

### 4. 小规模视觉增强
- [ ] 4.1 为投射物/法术预览添加微粒/Glow（仅示例，低开销）。
- [ ] 4.2 提交一份视觉比对截图（Before/After）供设计审核。

### 5. Validation & Docs
- [ ] 5.1 编写简短使用说明到 `openspec/changes/add-ui-beautify/tasks.md`（如何应用 theme 到其他 UI）。
- [ ] 5.2 运行手动验收：在编辑器中打开 `WandEditor` 并截图，记录任何回归或控件错位。

### 6. Optional follow-ups (后续可选任务)
- [ ] 6.1 把 Theme 转为可配置（颜色变量）并接入设置面板。
- [ ] 6.2 提供一套图标（SVG）替换现有文本或低分辨率图标。

#### Validation Notes
- 验证者应确认：字体加载成功、按钮样式一致、主要交互（打开面板、拖拽模块、测试法术）无逻辑回归。
