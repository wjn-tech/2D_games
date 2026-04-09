# Design: Start Menu Shell Beautification

## Context
- 主菜单当前由 `MainMenu.tscn` + `main_menu.gd` 共同驱动，视觉与交互逻辑耦合较高。
- 历史上已有多次主菜单美化提案，但存在变更碎片化与规范不一致问题。
- `assets/ui/start_menu_shell/` 已用于加载浮层 token，具备扩展为主菜单壳层目录的基础。

## Goals / Non-Goals
- Goals:
  - 建立可复用的“开始菜单壳层”视觉合同，提升一致性与可维护性。
  - 将视觉参数外置为 token，降低后续改版成本。
  - 保证资源异常时可降级，不影响进入游戏与设置等核心流程。
- Non-Goals:
  - 不重写主菜单业务逻辑（开始/加载/设置/退出流程）。
  - 不在本提案中改造全部子菜单页面。
  - 不引入重型渲染依赖作为硬前置。

## Decisions
- Decision 1: 壳层结构先行，细节样式后置
  - 先定义主菜单壳层结构（Header/Body/Footer）与交互状态合同。
  - 细节色值、字号、间距通过 token 调整，不在脚本中硬编码。

- Decision 2: 目录约束 + 显式降级
  - 主菜单壳层 token 统一放置于 `assets/ui/start_menu_shell/`。
  - token 缺失或非法时，回退 `MainMenu.tscn` 内建样式与默认 Theme。

- Decision 3: 场景主导，脚本辅助
  - 结构、层级、基础样式尽量在场景中配置。
  - `main_menu.gd` 仅负责状态反馈、轻动效和必要的数据驱动文案。

## Architecture
1. UI Layer Contract
- Header: 顶栏信息与窗口语义（例如 LOADING/READY 同类语气）。
- Body: 标题、主按钮组、次级按钮组。
- Footer: 快捷提示（例如 ESC 返回、版本号、状态字样）。

2. Token Contract
- 视觉 token 类型：
  - 颜色：背景、边框、强调色、禁用态。
  - 尺寸：标题字号、按钮高度、面板内边距。
  - 动效：hover/press 缩放时长、淡入时长。
- 应用顺序：
  - 读取 token -> 校验范围 -> 应用到场景节点 -> 缺失项使用 fallback。

3. Fallback Contract
- 当 token 文件不存在、字段缺失或类型不匹配时：
  - 菜单 MUST 继续可见与可交互。
  - 主按钮 MUST 可触发开始游戏。
  - 次级按钮 MUST 保持可导航。

## Risks / Trade-offs
- 风险：视觉 token 过多导致维护复杂。
  - 缓解：先定义最小必需 token 集，后续增量扩展。
- 风险：脚本与场景重复配置造成不一致。
  - 缓解：明确“场景优先、脚本补充”原则并在任务中检查。
- 风险：过强视觉特效影响低端设备。
  - 缓解：限定动效预算与可选降级级别。

## Validation Strategy
- 功能验证：开始/加载/设置/退出路径均可用。
- 一致性验证：开始菜单与加载浮层在视觉语义上保持同一壳层语言。
- 稳定性验证：删除或破坏 token 文件后，菜单自动回退且无报错阻断。
- 可读性验证：1080p 与较低分辨率下，标题与按钮状态可辨识。

## Implementation Details (Applied)
- `scenes/ui/MainMenu.tscn` 已落地新版壳层结构（贴近参考图）：
  - 中央主列 `MainColumn`：标题 + 副标题 + 主次按钮组。
  - 左右装饰 `LeftDecor/RightDecor`：竖向分段光条，形成终端感侧边框语义。
  - 底部信息 `BottomLeftStatus/BottomRightInfo`：在线状态与版本版权信息。
  - 背景由 `MenuEffects` + `BackdropTint` 叠加；`MenuEffects` 现为 WebView 优先的桥接链路。
- `scenes/ui/MenuEffects.tscn` 与 `scenes/ui/menu/components/menu_effects_bridge.gd` 已完成 WebView 直载接入：
  - 优先路径：运行时实例化 `WebView`，加载 `res://ui/web/main_menu_starfield/index.html`。
  - 兼容兜底：当 `WebView` 类不可用或资源缺失时，自动回退到 `FallbackStarfield`（`html_starfield_background.gd`）。
  - 运行要求：桥接层保持 `PROCESS_MODE_ALWAYS`，在菜单暂停态也能维持背景动态。
  - 输入安全加固：背景特效桥接在创建后与退出前统一关闭输入转发并释放焦点（`set_forward_input_events(false)` + `release_focus()` + `viewport.gui_release_focus()`），确保装饰层 WebView 不会参与键盘输入。
- `scenes/ui/main_menu.gd` 已新增整页 Web 菜单桥接（“全量开始菜单代码”接管）：
  - 优先路径：运行时实例化 `WebView`，加载 `res://ui/web/main_menu_shell/index.html`。
  - IPC 协议：Web 端发送 `menu_start/menu_continue/menu_settings/menu_exit`，Godot 端复用主菜单动作入口执行。
  - 状态同步：Web 端发送 `menu_ready` 后，Godot 通过 `post_message` 回传 `menu_state`（是否存在存档）以更新“继续游戏/加载存档”文案。
  - 兼容兜底：当 `WebView` 类不可用或 HTML 资源缺失时，自动显示原生 `MainMenu.tscn` 节点树，不阻断功能入口。
- `ui/web/main_menu_shell/index.html` 已按 `mainmenu00/src/app/page.tsx` 的新风格完成重构，并在纯 HTML/JS 下落地多视图菜单：
  - 主界面保持更新后的像素太空美术风格，保留旧版本悬停/点击音效反馈与静音开关逻辑。
  - 新增内嵌“存档选择”视图（继续游戏流程），槽位数据由 Godot `menu_state.save_slots` 注入，点击槽位通过 `menu_load_slot` 触发实际 `GameManager.load_game(slot_id)`。
  - 新增内嵌“设置面板”视图（General/Graphics/Audio/Input），字段映射到现有 `SettingsManager` 有效键值；通过 `menu_apply_settings` 与 `menu_reset_settings` 实际调用设置写入/重置，而非示例占位。
  - 已追加“像素风一致性”修订：统一方形像素边框、块状按钮阴影、CRT 扫描线+像素网格、像素飞船与分层星空滚动，避免回退到偏现代圆角 UI 语言。
  - 已追加“桥接解包容错”：Godot -> Web 消息改为最多 3 层 JSON 字符串解包，兼容 WebView 在不同平台的消息封装差异，防止 `menu_state` 被前端误丢弃。
  - 已追加运行期按键兜底：非输入控件场景下拦截 `W/A/S/D`、方向键与空格默认行为，降低焦点异常残留时的系统提示音风险。
- `scenes/ui/main_menu.gd` 已扩展 Web 接口对齐：
  - 新增 `menu_request_state/menu_load_slot/menu_apply_settings/menu_reset_settings` IPC 处理。
  - 新增 `menu_set_input_binding` IPC 处理：Web 设置页可直接提交按键 token，Godot 侧即时更新 `InputMap` 并持久化。
  - `menu_state` 回传内容扩充为：`has_save`、`save_slots`、`settings`（包含输入绑定快照），用于 Web 面板完整渲染。
  - 存档显示链路已补“元数据损坏兜底”：当 `metadata.json` 解析失败或缺失槽位时，`SaveManager` 会基于 `user://saves/slot_X/data.dat(.bak)` 自动重建槽位信息并回写磁盘，避免 Web 存档页误判为空槽。
  - 存档入口已补“磁盘硬兜底”：`_has_any_save_slot`、`_collect_web_save_slots` 与 `_load_game_slot_action` 均直接检查 `user://saves/slot_X/data.dat(.bak)`，即使 metadata 或状态同步异常也不会把真实存档判空。
  - 已移除 Web 菜单存档槽位 `1..3` 硬编码：改为“默认槽位 + `save_metadata` 键 + `user://saves/slot_*` 目录 + legacy `user://save_X.save`”的动态槽位发现；并放宽槽位合法性校验以支持历史存档槽位编号，修复“有存档但继续游戏列表全空”。
  - 已补 legacy 存档扫描上限问题：`_collect_save_slot_ids` 不再固定遍历 1..24，而是扫描 `user://` 下全部 `save_*.save` 文件，避免高编号历史槽位被菜单漏检。
  - 已补 Web 消息封装兼容：Godot -> Web payload 增加 `raw_payload` 冗余字段；Web 侧 `normalizeIncomingPayload` 增强为多层包装（`data/message/payload/detail` + `b64/raw`）解包，降低 WebView 平台差异导致 `menu_state` 丢弃的风险。
  - 已按 godot_wry 官方互操作机理修正事件入口：Web 端优先监听 `document.addEventListener("message")` 并读取 `event.detail`（兼容回退 `event.data` / `window.message`），同时发送侧优先使用 `ipc.postMessage`（回退 `window.ipc.postMessage`），避免仅依赖 `window.message` 导致状态不同步。
  - 已补语言切换即时生效链路：Web 设置点击“应用”后先本地更新 `state.settings.general.language` 并立即重渲染主菜单文案；Godot 侧 `_apply_settings_from_web` 在写入后额外调用 `SettingsManager.apply_all_settings` 并通过 `_sync_web_menu_state` 回传标准化语言值（统一 `zh/en`），修复“切换语言后开始菜单文案不变化”。
  - 原生按钮文案已按设置语言动态切换（中/英），并在 Web 应用设置后即时刷新，避免“语言已设置但主菜单仍固定中文”。
  - 继续游戏由“打开原生存档窗口”扩展为“支持 Web 槽位直接读档”，并保持失败回滚与 UI 恢复策略。
  - 启动防闪烁修复：点击“开始/读档”时不再提前隐藏 Web 菜单与切回原生层，改为等待 `GameManager` 黑场/loading 接管；反馈校验新增“启动进行中”检测，避免在 `_is_starting_new_game=true` 时误恢复菜单造成一闪。
  - 为适配 `WebView` 原生叠层特性，新增 `menu_transition` 握手：Godot 在开始/读档前先通知 Web 端显示全屏黑幕过渡，再启动场景切换；回滚到菜单时再关闭黑幕，抑制 compositor 首帧闪烁。
  - 输入焦点安全增强：开始菜单 WebView 创建时禁用自动抢焦点（`set_focused_when_created(false)`），并在隐藏/子窗口切换/场景切换时统一执行输入转发关闭与焦点回收（`set_forward_input_events(false)` + `focus_parent()` + `release_focus()` + `viewport.gui_release_focus()`），修复从开始菜单进入游戏后 WASD 仍触发系统提示音。
- `src/core/game_manager.gd` 已补启动链路根因修复（针对“闪一下后回开始菜单”）：
  - 新增“目标场景就绪等待”门控：`_on_reload_finished` 不再盲信固定 0.2 秒计时，而是等待 `current_scene.scene_file_path` 命中预期场景（`boot.tscn` -> `main.tscn` 过渡场景）。
  - 新增启动玩家解析兜底：优先 group 查找，超时后尝试命名节点，再兜底实例化 `res://scenes/player.tscn`，避免因玩家节点晚到或缺失直接触发回菜单。
  - `_abort_startup_to_menu` 现在会清理 `pending_startup_scene_path`，防止后续启动复用过期场景期望值。
  - 新增“场景切换重试”与“恢复重试”：开始/读档改为 `change_scene_to_file` 多次重试，切换成功后直接进入 `_on_reload_finished`；若就绪检测失败，自动再做一次恢复切换后复检，尽量避免误回退到主菜单。
  - 新增“启动标记判定”容错：当场景路径字符串不一致但已检测到 `WorldGenerator/Player/Entities/player group` 启动标记时，允许继续启动流程，避免路径抖动导致的假失败。
  - 新增“启动失败可见诊断”快照：记录 `last_abort_reason/last_abort_time_msec/emergency_recovered/pending_scene` 并通过 `get_startup_debug_snapshot()` 对外暴露，支持 UI 侧直接展示触发源。
  - 启动诊断已扩展 `last_abort_source`（如 `reload_scene_ready_timeout/startup_player_missing`），用于区分具体回退触发链路。
  - 新增“加载阶段紧急接管”策略：`_abort_startup_to_menu` 在 `LOADING_WORLD/GAME_OVER` 启动窗口都先尝试 `_try_emergency_startup_handoff`（含最多 120 帧标记等待 + 玩家解析 + 直接切 `PLAYING` 并收起 loading），仅在接管失败时才回主菜单。
- `scenes/ui/menu/components/html_starfield_background.gd` 与 `ui/web/main_menu_starfield/index.html` 已完成 Web 原项目算法对齐：
  - 参考源：`mainmenu00/src/app/page.tsx` 的 `canvas + requestAnimationFrame` 背景动画。
  - 已对齐效果：下落闪烁星点、像素十字高光、多层反向旋转星云、流星拖尾与头部高亮。
  - 运行策略：HTML 端使用 `requestAnimationFrame`；GDScript 回退端使用 `queue_redraw()`，并在窗口尺寸变化时重建星点分布。
- `scenes/ui/main_menu.gd` 已接入主菜单 token 读取与应用：
  - 新增 `MENU_SHELL_THEME_PATH` 指向 `assets/ui/start_menu_shell/menu_theme.json`。
  - 启动时加载 token，并按键值映射到标题/副标题、主次按钮层级与 stylebox、装饰色、底部文案。
  - token 缺失或类型不匹配时自动回退到场景内建样式（不阻断菜单可交互）。
- `assets/ui/start_menu_shell/menu_theme.json` 已新增并包含最小必需 token 集：
  - 颜色：overlay、标题副标题、主次按钮、侧边装饰、底部信息。
  - 尺寸：标题字号、副标题字号、按钮宽高、间距、边框与圆角。
- `assets/ui/start_menu_shell/README.md` 已补充维护约束：
  - `menu_theme.json` 作为主菜单壳层 token 来源。
  - 文件缺失或非法时回退场景默认样式。
- `scenes/ui/main_menu.gd` 与 Web 设置联动已补“有效动作对齐 + 运行态窗口模式反馈”修复：
  - 输入映射动作列表由旧的 `jump/attack` 调整为项目真实动作（`space/interact/inventory/build/craft/settlement/mouse_left/mouse_right` 等），避免“可编辑但无实际效果”的伪选项。
  - 输入 token 解析范围扩展到更多键位（字母、数字、导航键、删除键、Home/End/PageUp/PageDown、鼠标中键等），配合 Web 端直接监听输入可稳定写回 `InputMap`。
  - `menu_state` 的全屏状态改为优先读取运行态 `DisplayServer.window_get_mode()`，减少“配置值已改但窗口实际状态不一致”导致的 UI 假象。
- `src/core/settings_manager.gd` 已补图形/音频设置生效链路：
  - `window_mode` 应用改为双通道（`DisplayServer.window_set_mode` + `get_window().mode`）并在全屏失败时回退 `Window.MODE_MAXIMIZED`，提升跨环境稳定性。
  - `brightness/contrast/gamma` 不再依赖必须存在 `world_environment` group：若 group 未配置，会回退扫描首个 `WorldEnvironment` 节点并应用参数，修复默认场景下亮度滑杆“保存了但看不到变化”。
  - `particles_quality` 不再仅持久化：会遍历并更新场景中的 `GPUParticles2D/CPUParticles2D` 的 `amount`，并对后续新加入树的粒子节点应用同一倍率。
  - `ui_vol` 在无 `UI` bus 时自动回退到 `SFX`（再兜底 `Master`），避免默认音频总线布局下“界面音量滑杆无效”。
- `ui/web/main_menu_shell/index.html` 与 `v1.0.0/ui/web/main_menu_shell/index.html` 已同步改造输入映射交互：
  - 由“下拉框 + 应用按钮”改为“点击后直接监听下一次键盘/鼠标输入”。
  - 支持 `Esc` 取消监听、`Delete/Backspace` 清空绑定，并新增对应中英文本地化文案与提示。
  - 仅渲染 Godot 回传的可用动作并按预设顺序展示，避免前端展示无效动作键位。
- 原生设置窗口（Web 回退路径）已补齐生效链路：
  - `scenes/ui/settings/settings_window.gd` 的“应用并返回”按钮不再空实现：会显式执行 `apply_all_settings + save_settings` 后再关闭窗口。
  - `scenes/ui/settings/settings_window.gd` 的“重置默认”按钮不再空实现：调用 `reset_to_defaults()` 并触发各面板 `refresh_ui`，避免“重置了但界面不刷新”。
  - `scenes/ui/settings/panels/audio_panel.gd` 键名修正为 `master_vol/music_vol/sfx_vol/ui_vol`（替换错误的 `*_volume`），并补 UI 通道行，修复音频滑杆“可拖动但不持久/不生效”。
  - `scenes/ui/settings/panels/graphics_panel.gd` 全屏勾选状态兼容 `WINDOW_MODE_FULLSCREEN` 与 `WINDOW_MODE_EXCLUSIVE_FULLSCREEN`。
  - `scenes/ui/settings/panels/general_panel.gd` 新增 `refresh_ui()`，确保重置后语言下拉即时回显当前值。