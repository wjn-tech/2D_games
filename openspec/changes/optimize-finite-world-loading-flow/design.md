# Design: Optimize Finite World Loading Flow

## Context
当前世界进入链路的核心问题不是“没有黑幕”，而是“没有 readiness contract”。

现状大致如下：

- MainMenu / SaveSelection 调用 GameManager.start_new_game() 或 GameManager.load_game()。
- GameManager 在场景切换后通过 _on_reload_finished() 恢复部分数据，并立即切换到 PLAYING。
- PLAYING 状态中同时承担 UI 切换、世界初始化、玩家出生、HUD 打开等多项职责。
- WorldGenerator.start_generation() 不暴露启动阶段或完成状态。
- _spawn_player_safely() 只保证出生 chunk 已经装载，不保证 finite world 的关键初始化已完成。

这会导致有限地图或未来 planetary world 的启动体验无法被严格门控。即使后续底层算法更快，如果“进入时机”仍然绑定在 scene reload 完成而不是 world-ready 完成，玩家仍可能看到半生成世界、HUD 先于世界出现、或在关键系统尚未稳定时获得输入权。

## Goals / Non-Goals

### Goals
- 为新游戏和读档统一提供显式的 startup loading state 与 handoff 契约。
- 在 finite/planetary world 启动期间，阻止玩家输入、HUD 暴露和过早世界交互。
- 让加载进度条基于真实阶段完成状态，而不是纯视觉占位。
- 让 loading overlay 在场景切换期间保持稳定存在，并且只在 world-ready 后退场。
- 定义 critical-ready 与 deferred-ready 的分界，保证安全进入与流畅体验同时成立。

### Non-Goals
- 不在本 proposal 中重写所有 worldgen 算法或一次性解决所有加载性能热点。
- 不要求 finite world 必须整张地图预生成后才允许进入；关键是定义“足够可玩”的 ready checkpoint。
- 不在本 proposal 中扩展主菜单美术风格或 HUD 视觉语言，除非加载覆盖层本身需要基本样式约束。
- 不替代 terrain/cave proposal 中关于 richer generation 的预算、缓存和调度设计。

## Decisions

### Decision: Introduce a distinct startup loading phase before PLAYING
GameManager 不应继续把 scene reload 完成直接映射为 PLAYING。新设计需要显式的 startup loading phase，例如 LOADING_WORLD 或等价状态。

Reasoning:
- 这允许 GameManager 把“场景切换完成”和“世界可进入”拆开。
- 这让 UI、玩家输入、HUD 和 world bootstrap 可以围绕单一状态机收敛，而不是散落在多个回调里各自猜测时机。

Alternatives considered:
- 继续复用 PLAYING，再靠额外布尔量阻断输入。这样会让 HUD、玩家、世界系统各自增加 if 判断，状态边界更模糊。

### Decision: Define startup readiness as explicit providers with weighted stages
进度与 ready 检查不应由单一脚本硬编码，而应允许多个启动提供方汇报阶段完成度。

Expected providers:
- scene transition / scene stable
- world metadata + topology restore
- world generator startup
- critical chunk warmup or finite world bootstrap
- save-state rehydration
- player spawn safety check
- final activation handoff

Reasoning:
- finite/planetary world 的关键路径不会永远与 legacy_infinite 一样。
- 加权阶段模型既能让 UI 呈现稳定进度，也能让未来增加 finite bootstrap 步骤时不破坏总契约。

### Decision: Separate critical-ready from deferred-ready
启动流程需要把“玩家现在可以安全进入”的工作，与“还可以继续在后台补完但不该再阻塞加载”的工作区分开。

Critical-ready examples:
- 拓扑元数据就绪
- 世界生成器已完成关键启动
- 出生带/落点周边关键区域已可用
- 必要存档对象已恢复
- 玩家出生不会立即坠落、卡体、掉进未加载区

Deferred-ready examples:
- 远距离装饰补齐
- 二级背景细化
- 非关键提示或统计刷新
- 不影响出生安全的额外预热

Reasoning:
- 如果所有启动相关工作都被算进 blocking load，finite world 的进度条会变成“永远差一点”。
- 如果完全不分 critical/deferred，玩家又会被过早放进不稳定世界。

### Decision: Keep the loading overlay outside the reloaded gameplay scene
加载覆盖层不应挂在会被 change_scene_to_file() 销毁的当前场景内，而应位于持久 Autoload 或根级 transition layer。

Reasoning:
- 当前 UIManager 已经能管理全局 fade layer，这证明 transition UI 适合走跨场景持久路径。
- 这样能避免主菜单消失后到新场景 UI 出现前的视觉空窗。

### Decision: Block gameplay activation, not only raw input
“玩家不可进入”不能只理解为 EventBus.player_input_enabled(false)。还需要门控玩家 process、HUD 显示、实体层暴露，以及其他会让玩家感知自己已经进入世界的反馈。

Minimum gate direction:
- 玩家输入关闭
- 玩家 process / physics 暂停或受控
- HUD 保持隐藏
- 关键实体层或危险交互不提前开启
- 只有在 final handoff 时统一释放

Reasoning:
- 单独关输入仍可能让玩家看到半初始化 HUD、错误背景、或敌对系统已开始运行。

### Decision: Use the same startup gate for both new game and load game
新游戏与读档不应拥有两套不同的进入时序，否则 finite world 的 ready/blocked/visible 语义会很快分叉。

Reasoning:
- 当前两个入口都通过 GameManager 进入，天然适合在同一 orchestration 上汇合。
- 读档路径还有额外的 save-state rehydration，更需要统一 staged progress，而不是另开一套特例逻辑。

### Decision: Fail safely when startup cannot reach critical-ready
如果某个启动阶段失败、超时或无法确认 ready，系统应维持 loading gate，不允许继续放玩家进入不一致状态。

Recommended failure behavior:
- loading overlay 切换到 failure state
- 输入仍保持阻断，只开放 retry / return to menu 等安全操作
- 不提前打开 HUD 或释放玩家

## Architecture

### 1. Startup State Flow
推荐流程：

1. MainMenu / SaveSelection 发起进入世界请求。
2. Transition layer 打开 loading overlay，开始 fade-out。
3. GameManager 切场景并进入 startup loading state，而非 PLAYING。
4. 场景稳定后注册 startup providers，并按阶段推进进度。
5. 当 critical-ready 达成时，执行 final handoff：安全出生、显示必要场景层、打开 HUD、恢复输入。
6. overlay 淡出，状态切换到 PLAYING。
7. deferred work 按预算继续运行，但不再阻塞玩家。

### 2. Stage Model
建议将启动阶段固定成有限集合，而不是完全自由文本，便于 UI 和调试一致：

- scene_transition
- scene_stable
- topology_restore
- world_bootstrap
- spawn_area_ready
- save_restore
- gameplay_handoff

Each stage should define:
- 是否为 critical stage
- 预估权重
- 完成条件
- 可选的细粒度子进度

### 3. Progress Aggregation
UI 不应直接读取单个脚本变量，而应读取统一 startup progress model。

Expected semantics:
- 0% 到 100% 由阶段权重聚合
- 某阶段只能在真实完成后被计满
- 当前阶段可暴露 stage label / status text
- 100% 只能在 critical-ready 已满足且即将 handoff 时出现

For legacy mode:
- 允许 world_bootstrap 只覆盖 spawn 周边关键区块预热

For planetary / finite mode:
- 允许 world_bootstrap 纳入 world plan 准备、关键区域预计算、有限地图关键落地区生成等更重步骤

### 4. Visibility and Activation Gate
最终 handoff 前，以下对象或能力必须被统一协调：

- MainMenu / SaveSelection 已退场
- loading overlay 仍在最上层
- HUD 不可见
- 玩家不可操作
- 场景层仅暴露加载所需的安全子集
- 高风险系统不应在玩家可见前无约束开始运行

Release order should prefer:
- 先确认出生点安全与关键世界可达
- 再放置/恢复玩家
- 再显示 HUD 与实体可见层
- 最后恢复输入并淡出 overlay

### 5. Finite World Compatibility
该 proposal 虽然由“有限地图加载”驱动，但需要兼容当前遗留无限区块路径。

Compatibility direction:
- legacy_infinite 使用同一 startup gate，但 critical-ready 可退化为“出生带关键区块 + 必要数据恢复完成”
- planetary_v1 / finite world 使用同一 gate，但允许更重的 finite bootstrap 阶段
- UI 和状态机不因 topology_mode 分叉成两套不同入口体验

### 6. Failure and Recovery
Failure state 至少要定义：

- 哪些错误仍允许 retry
- 哪些错误需要 return to menu
- overlay 上展示什么信息
- 如何确保失败后不会遗留半激活的玩家/HUD/世界系统

## Risks / Trade-offs
- 更严格的 loading gate 可能让“进入世界”体感更慢。
  Mitigation: 使用真实进度、清晰阶段文案和 deferred work 分层，减少无意义等待感。

- 如果 startup providers 边界定义不清，进度可能卡死在某一阶段。
  Mitigation: 为每个阶段写清完成条件、超时策略和调试日志要求。

- 若 HUD、玩家、实体层释放顺序不一致，可能引入新的闪烁或短暂错误状态。
  Mitigation: 把 final handoff 作为单独阶段统一编排，不让多个脚本自行“觉得准备好了就放行”。

- legacy 与 planetary 共用流程会增加设计复杂度。
  Mitigation: 共用状态机和 UI，仅允许 provider 集合与 critical-ready 条件按 topology_mode 做受控差异化。

## Migration Plan
1. 先定义 startup loading state、阶段模型和 progress contract。
2. 将 MainMenu / SaveSelection 的进入世界路径切到统一 loading orchestration。
3. 接入 GameManager、WorldGenerator、InfiniteChunkManager、Save 恢复路径的关键 ready/progress 汇报。
4. 增加 loading overlay 与 blocked handoff。
5. 最后再验证 legacy 和 planetary/future finite world 的进入体验是否共用同一契约。

## Validation Strategy
- 验证新游戏进入时不会在 world-ready 前显示 HUD 或释放输入。
- 验证读档进入时也经过相同 loading gate，而不是绕过进度与门控。
- 验证 finite/planetary world 关键 bootstrap 未完成时，overlay 不会错误消失。
- 验证 legacy 路径不会因为引入 loading gate 而退化为长时间黑屏且无进度信息。
- 验证失败或超时场景下，玩家不会被放进半初始化世界。