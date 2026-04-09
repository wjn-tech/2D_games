# Design: Wand Editor HTML Embedded Shell Refactor (Sample Style, Existing Ratio, Logic Priority)

## Context
本变更的本质是“美术完整移植 + 逻辑完全保留”。
- 美术来源：示例项目最终效果图（本次确认目标）。
- 排版比例来源：现有项目 Wand Editor 的布局比例。
- 运行宿主：Godot `WandEditor`（`src/ui/wand_editor/wand_editor.gd`）。
- 约束重点：若示例主题与现有行为冲突，必须保留现有逻辑行为。

## Goals / Non-Goals
- Goals:
  - 在嵌入式 HTML 壳中基本还原示例项目美术主题。
  - 维持现有项目布局比例，不因主题迁移改变版式骨架。
  - 保持现有逻辑、文案、行为语义 1:1。
  - 冲突决策统一为“现有逻辑优先”。
- Non-Goals:
  - 迁移示例项目的业务逻辑到现有项目。
  - 新增法杖编程功能或调整算法。
  - 移动端专项优化。

## Architecture
### 1. Priority Model (Conflict Resolution)
- 决策: 建立“逻辑 > 比例 > 主题细节”的优先级。
- 含义:
  - 第一级：现有逻辑不可变。
  - 第二级：现有布局比例不可破坏。
  - 第三级：示例主题在前两级约束内尽量完整还原。

### 2. Visual Transplant Model
- 决策: 完整迁移示例主题视觉令牌，但不搬运其业务结构。
- 视觉令牌范围:
  - 背景层（深空、星点、网格、扫描线）。
  - 面板边框与发光体系。
  - 组件状态反馈（hover/active/focus）。
  - 像素字体与图标风格。
- 比例约束:
  - 左/中/右与顶栏占比沿用现有项目基线。
  - 允许像素装饰变化，不允许破坏现有功能区密度与可达性。

### 3. Bridge Behavior Model
- 决策: 保持 Godot 为权威状态源，HTML 壳只做渲染与意图转发。
- 行为边界:
  - Web 发送意图，不直接定义最终法杖数据。
  - Godot 使用既有逻辑处理后回推状态。
  - 任何“示例实现逻辑”均不得覆盖现有处理链。

### 4. Failure & Recovery
- 决策: 保留自动回退原生编辑器。
- 触发条件:
  - 壳资源不可用。
  - WebView 初始化失败。
  - 桥接异常不可恢复。
- 恢复要求:
  - 回退后继续使用现有逻辑链路。
  - 用户编辑状态可恢复或不丢失。

## Implementation Mapping (Apply 实际落地)
- Godot 端桥接落地：`src/ui/wand_editor/wand_editor.gd`
  - WebView 初始化与回退：`_try_setup_web_editor_webview()`
  - 输入焦点安全增强：创建时禁用自动抢焦点（`set_focused_when_created(false)`）；显示/隐藏时同步切换输入转发（`set_forward_input_events`）；隐藏/关闭时显式回焦父级（`focus_parent`）并执行 `_release_web_editor_focus()`。
  - Web 选杖可用性：`_set_web_editor_visible()` + `_open_wand_selector()`（打开原生选杖时临时隐藏 WebView，避免叠层遮挡）
  - 选杖关闭回调：`_on_wand_selector_closed()`（取消切换时恢复 WebView 显示）
  - 状态下发：`_sync_web_editor_state()` + `_build_web_editor_state_payload()`
  - 元件描述下发：`_collect_logic_palette_for_web()` 增加 `description` 字段，`_create_mock_item()` 在缺省时生成可读描述文本供 Web 悬停提示展示。
  - 意图接收：`_on_wand_web_ipc_message()`
  - 打开态选杖一致性：`_sync_opened_wand_context()`（Web/Native 统一执行“当前装备法杖优先、无则打开选择器”）
  - 选杖回推时序修正：`_on_wand_selected()` 与 `_on_wand_selector_closed()` 改为“先恢复 WebView 可见，再 deferred 同步状态”，避免隐藏态消息丢失导致切杖显示晚一拍。
  - 选杖数据源回退：`_resolve_inventory_manager()` + `_resolve_equipped_wand_item()`（player.inventory 与 `GameState.inventory` 双路径）
  - 图逻辑应用：`_apply_web_graph_data()`（复用现有 `logic_board.load_from_data`）
  - 容量约束补齐：Web 壳 `addNodeFromPalette(...)` 在 `logicNodes.size >= logic_capacity` 时前端即拦截并提示；Godot 端 `_apply_web_graph_data(...)` 对超量 payload 再次按 `embryo.logic_capacity` 截断并过滤越界连线，防止桥接绕过导致超容。
  - 实时回推修正：`_apply_web_graph_data()` 在应用连线/节点后 deferred 执行 `_sync_web_editor_state()`，避免锁窗口期丢失同步导致右侧编译/统计卡不随当前线路实时刷新。
  - 编译状态修正：`_collect_compile_info_for_web()`（将“无可发射投射物/连线路径不完整”归类为不可用）
  - 端口约束一致性：`_infer_ports_for_logic_type()`（`source/generator` 强制 0 输入 1 输出）
  - 外观网格应用：`_apply_web_visual_cells()`（复用 `normalize_grid`/预览/统计链路）
  - 比例快照：`_collect_layout_ratio_snapshot()`
- LogicBoard 落地：`src/ui/wand_editor/logic_board.gd`
  - 清理时序修正：`clear_board()` 对 `GraphNode` 使用同步释放，避免“旧节点延迟销毁 + 新节点已创建”导致同帧数据采集重复。
  - 数据导出防重：`get_logic_data()` 跳过 `is_queued_for_deletion()` 节点，防止保存/同步窗口期把待销毁节点再次写回权威状态。
  - 结果：保存与状态回推链路不再因节点清理时序造成倍增叠加。
- Web 壳落地：`ui/web/wand_editor_shell/index.html`
  - 消息桥接：`postToGodot()` / `onGodotMessage()`
  - 全量状态消费：`applyWandState(...)`
  - 编辑意图上报：`wand_graph_changed` / `wand_visual_changed` / `wand_save` / `wand_test` 等
  - 切杖意图去重：切换按钮仅发送 `wand_open_selector`，移除重复 `wand_switch` 并发消息，避免重复打开/竞态时序。
  - 元件样貌完整移植：节点卡片、端口连接点、法力角标、分类标题与元件条目样式按示例工程视觉令牌重建（含像素边框、发光层、类型配色）
  - 像素级细节对齐：顶部栏高度/字号/按钮阴影参数、左右栏渐变方向、分组标题与条目间距、统计卡标题条与边框强度均回收至示例参数区间。
  - 图标体系对齐：节点与元件库图标从符号字形切换为 8x8 像素 SVG（generator/trigger/damage/element/projectile/logic）以匹配示例的像素轮廓。
  - 法术显示区对齐：右侧默认态改为“法杖属性 + 法术统计 + 编译状态”三段式结构（含状态色块与文案语义），与示例统计面板层级一致。
  - 悬停详情恢复：逻辑元件库项恢复 hover 详情浮层（名称/描述/法力/端口/关键参数），补回原有“悬停查看法术说明”能力。
  - 文本可读性修正：节点标题文字移除阴影叠层，消除元件标题重影感并保持像素字形清晰。
  - 节点结构对齐：标题栏图标 + 参数双行 + 端口大命中区（28px 包裹 / 14px 核心）
  - 布局约束增强：默认压缩左右/顶部占比并将中心工作区最小占比锁定为 `>=80%`
  - 交互增强：新增左右分隔条拖拽，支持运行时动态调节左右面板宽度（带最小占比与中心区下限约束）
  - 本地计数一致性：节点增删/清空时同步刷新顶部节点统计（避免与右侧统计短暂不一致）
  - 连线可编辑性：连线命中层可选中并支持右键/按钮/Delete 删除
  - 拆线能力增强：端口支持右键一键拆线；同时支持 Alt/Ctrl/Meta + 点击端口按端口维度拆线，Alt/Ctrl/Meta + 点击连线直接删除。
  - 外观涂抹恢复：恢复“按住左键连续放置、按住右键连续擦除”输入链路，改为窗口级鼠标移动跟踪落笔，避免依赖单格 `mouseenter` 导致拖拽涂抹中断。
  - 干扰入口清理：移除 issue 角标与顶栏“测试”按钮，仅保留保存与编辑主流程入口，降低误触和状态噪音。
  - 连线可见性修正：将图逻辑连线层抬升到节点层之上，同时端口命中层保持最上层，避免连线被元件主体遮挡导致端口出线关系不可辨。
  - 绕障布线优化：连线改为“端口桩点 + 正交避障路由”（候选水平走廊 + 外侧旁路评分），主路径在全节点障碍集中求解，避免因端点节点被排除而穿过元件主体；连线层保持在节点层下方以减少正文覆盖。
  - 批量删除：支持鼠标框选节点（marquee）并通过 Delete 一次性删除
  - 框选触发健壮性：图板空白点击兼容 `graphBoard/graphLayer/svg` 命中，不与节点拖拽和连线点击冲突
- 原生选杖 UI 落地：`src/ui/wand_editor/components/wand_selector.tscn` + `src/ui/wand_editor/components/wand_selector.gd`
  - 深空终端风弹层（遮罩 + 居中面板 + 统计副标题 + 底部提示）
  - 列表主题覆盖（文本、选中态、悬停态）
  - 交互补充（Esc 关闭、返回按钮、`selector_closed` 信号）
  - 比例约束应用：`applyLayoutRatios(...)`
- 冲突优先级落地方式：
  - 逻辑层：Godot 权威状态 + 回推
  - 比例层：Godot 基线快照 + Web clamp
  - 主题层：在上述两层约束内完成视觉迁移

## Alternatives Considered
- 方案 A: 连同示例项目行为逻辑一起迁移。
  - 放弃原因: 与“逻辑保持不变、冲突现有优先”目标冲突。
- 方案 B: 只迁移部分视觉元素。
  - 放弃原因: 无法满足“完整移植示例美术风格、基本还原效果”的目标。

## Risks / Trade-offs
- 风险: 示例主题完整迁移与现有比例约束之间出现视觉挤压。
  - 缓解: 先冻结比例基线，再按区域逐层替换视觉令牌。
- 风险: 主题替换过程误触逻辑事件映射。
  - 缓解: 以行为回归清单做每轮验收，任何偏差立即回退。
- 风险: “基本还原”主观性导致验收争议。
  - 缓解: 以示例图关键视觉特征清单做客观比对。

## Verification Strategy
- 核验“主题还原度”：关键视觉特征逐项对照通过。
- 核验“比例保持”：布局占比与基线一致。
- 核验“逻辑不变”：交互与结果与原生编辑器一致。
- 核验“冲突优先级”：冲突用例全部体现“现有逻辑优先”。
