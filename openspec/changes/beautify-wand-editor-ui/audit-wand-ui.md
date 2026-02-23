# wand_editor UI 审计报告

路径: `wand_editor/src/components/ui/`

列出的文件:

- accordion.tsx — 纯展示/交互组件（Radix wrapper），可安全调整样式
- alert-dialog.tsx — UI 对话框，含交互逻辑（打开/关闭）但与魔杖编译无关，样式可调整
- alert.tsx — 展示组件，仅视觉
- aspect-ratio.tsx — 展示/布局工具
- avatar.tsx — 纯展示
- badge.tsx — 纯展示
- breadcrumb.tsx — 展示/导航，仅样式影响
- button.tsx — 关键全局按钮样式入口（已检查），仅样式/变体定义，无网络或编译逻辑
- calendar.tsx — 组件库日历展示（可能包含少量内部状态），可在外观层面修改
- card.tsx — 视觉容器，安全修改
- carousel.tsx — 交互组件（状态和键盘/触控处理），可改变样式但保留交互逻辑
- chart.tsx — 可视化（依赖图表库），仅样式/容器改变建议谨慎
- checkbox.tsx — 表单控件，样式/焦点/可访问性调整安全
- collapsible.tsx — UI 状态管理（展开/收起），仅样式可改
- command.tsx — 命令面板（含键盘交互），改样式需保留键盘行为
- context-menu.tsx — 交互菜单（打开/关闭/焦点），样式改变可做，但不要移除逻辑钩子
- dialog.tsx — 对话框容器，样式可变
- drawer.tsx — 抽屉组件，样式可变
- dropdown-menu.tsx — 下拉交互，样式可变但保留事件处理
- form.tsx — 含 `react-hook-form` 集成（已检查），包含表单状态管理；样式可变，但勿更改字段/校验/Controller 行为
- hover-card.tsx — 交互增强，样式可变
- input-otp.tsx — 具有输入行为（聚焦/跳位），勿更改行为逻辑，仅样式调整
- input.tsx — 表单控件，样式/可访问性优先调整，勿更改 value/onChange 等行为
- label.tsx — 纯展示/可访问性标签
- menubar.tsx — 菜单栏交互（键盘/焦点），保留键盘行为
- navigation-menu.tsx — 导航组件，样式可变
- pagination.tsx — 分页控制，样式可变
- popover.tsx — 悬浮面板，保留打开/关闭逻辑
- progress.tsx — 进度条/指示器，样式可变
- radio-group.tsx — 表单控件，样式可变
- resizable.tsx — 可调整大小组件，含行为；只做样式容器层面的改动
- scroll-area.tsx — 滚动容器（性能相关），样式微调安全
- select.tsx — 复杂表单控件（下拉 + 选择），勿改事件/数据处理，只改样式
- separator.tsx — 视觉分割线
- sheet.tsx — 抽屉/模态容器，样式可变
- sidebar.tsx — 侧边栏容器，样式可变
- skeleton.tsx — 占位样式，安全修改
- slider.tsx — 交互控件（拖拽），勿更改事件处理逻辑
- sonner.tsx — 通知库包装，样式可改
- switch.tsx — 表单开关控件，样式可改
- table.tsx — 表格组件（可能含排序/分页钩子），慎重改动交互
- tabs.tsx — 选项卡（键盘/焦点交互），保留行为
- textarea.tsx — 文本域，样式可改
- toast.tsx / toaster.tsx — 通知呈现，样式可改
- toggle-group.tsx / toggle.tsx — 分组切换控件，保留行为
- tooltip.tsx — 悬浮提示，样式可改

总体结论

1. `wand_editor` 的 `ui` 目录以可复用、无网络的 UI 组件为主；大多数文件仅包含样式/交互封装。未发现网络/API/编译相关调用（审计中无 `fetch`/`axios`/`upload`/`compile` 等关键字）。
2. 有少数组件包含内部行为（例如 `form.tsx`、`input-otp.tsx`、`slider.tsx`、`resizable.tsx`、`table.tsx`、`tabs.tsx`），这些应当只在视觉层面修改，谨慎保留所有事件与键盘/焦点处理。
3. 建议的安全改造顺序（低风险→中风险）：
   - `button.tsx`, `card.tsx`, `label.tsx`, `input.tsx`, `textarea.tsx`, `badge.tsx`, `skeleton.tsx`（基础样式变量与 token）
   - 全局样式/变量（Tailwind / globals.css）
   - 页面容器与布局（`src/app/layout.tsx`, `src/app/page.tsx`）
   - 含少量行为的组件（`carousel.tsx`, `popover.tsx`, `dialog.tsx`）——先视觉后微调交互
   - 高交互组件（`input-otp.tsx`, `slider.tsx`, `resizable.tsx`, `table.tsx`）——最后并附带回归测试

校验建议

- 每个 PR 附带 before/after 屏幕截图与简单 smoke 测试要点清单。
- 在 PR 中运行 `rg` 检查已改动文件是否包含关键字 `fetch|upload|compile|post|socket|axios|FormData`，确保未触及网络或编译逻辑。

审计人员: 自动化提案器
