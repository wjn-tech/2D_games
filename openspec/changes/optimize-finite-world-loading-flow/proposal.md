# Change: Optimize Finite World Loading Flow

## Why
当前启动流程把“场景重载完成”近似当成了“世界已经可进入”。这对现在的遗留无限区块路径已经偏脆弱，对后续 finite/planetary world 的完整启动更是不成立：

- GameManager 在 _on_reload_finished() 中直接切到 PLAYING，而不是等待明确的 world-ready 检查点。
- change_state(State.PLAYING) 会立即隐藏 MainMenu、打开 HUD、触发 WorldGenerator.start_generation()，并尝试生成/恢复玩家位置。
- WorldGenerator.start_generation() 只做初始化与清理，没有 completion/progress contract，无法告诉 UI 或 GameManager “还差多少”。
- _spawn_player_safely() 最多只等待出生 chunk 就绪，不能覆盖 finite world 所需的 world plan、关键区域预热、关键存档恢复或首批关键内容落地。

用户现在明确要求：有限地图加载时要有进度条动画，并且在地图未生成完之前玩家不可进入。要满足这个目标，必须把“进入游戏”的判定从场景切换完成，升级为启动加载门控完成。

## What Changes
- 为新游戏和读档进入世界增加显式的 startup loading gate，而不是在场景重载后立即进入 PLAYING。
- 为 finite/planetary world 启动定义 world-ready contract，明确哪些步骤属于 critical-ready，哪些步骤允许 deferred。
- 为 GameManager、WorldGenerator、InfiniteChunkManager、存档恢复路径增加统一的 staged progress reporting 语义。
- 新增加载覆盖层与进度条动画，在加载期间持续阻断玩家输入、HUD 暴露和过早的世界交互。
- 统一新游戏与读档的世界进入路径，使二者都经由同一套 loading -> ready -> handoff 流程。
- 定义失败/超时时的安全表现，确保加载异常时玩家不会被提前放入半初始化世界。

## Detailed Scope
- 该 proposal 面向 finite/planetary world 的启动体验，但要求 legacy_infinite 路径也接入同一套加载门控契约，以避免出现两套互相漂移的入口逻辑。
- startup progress 需要来自真实阶段和真实完成信号，不能仅依赖固定时长 tween 或盲目时间插值伪装加载完成。
- loading gate 的 critical-ready 至少要覆盖：场景切换、world metadata/topology 恢复、世界生成启动、出生安全区/关键落点预热、必要的存档状态恢复、玩家安全出生前检查。
- HUD、玩家输入、玩家 process、敌对或高风险运行时系统必须在 critical-ready 之前保持禁用或隐藏。
- 加载 UI 应作为跨场景持久层或等价 transition layer 管理，避免在 change_scene_to_file() 期间丢失。
- 该 proposal 关注“启动加载编排、进度表达、进入门控”，不替代底层 worldgen 算法性能优化 proposal；它只要求把 critical path 与 deferred path 明确切开。

## Current Baseline
- src/core/game_manager.gd: _on_reload_finished() 在数据恢复后直接调用 change_state(State.PLAYING)。
- src/core/game_manager.gd: change_state(State.PLAYING) 中会立刻关闭阻塞窗口、打开 HUD、启动世界生成并放置/恢复玩家。
- src/systems/world/world_generator.gd: start_generation() 只有初始化和清理逻辑，没有进度汇报，也没有 ready/completed 信号。
- src/core/game_manager.gd: _spawn_player_safely() 仅等待出生 chunk 加载，不代表整个 finite world 启动关键路径完成。
- src/ui/ui_manager.gd: 当前只有 play_fade() 黑幕淡入淡出，没有加载覆盖层、阶段文本或进度模型。
- scenes/ui/main_menu.gd 与 scenes/ui/save_selection.gd: 入口都直接切入 GameManager 的新游戏/读档流程，没有单独的 loading orchestration。

## Impact
- Affected specs: world-startup-gating, world-startup-progress, startup-loading-presentation
- Affected code: src/core/game_manager.gd, src/ui/ui_manager.gd, scenes/ui/main_menu.gd, scenes/ui/save_selection.gd, src/systems/world/world_generator.gd, src/systems/world/infinite_chunk_manager.gd, src/systems/world/world_topology.gd, startup transition UI scenes/resources
- Relationship to existing changes:
  - 该 proposal 补足 finite world 进入体验与状态安全，不替代 refine-terrain-relief-and-cave-topology 中的底层 worldgen 性能优化。
  - 该 proposal 应与 shift-worldgen-to-planetary-wraparound 的 finite/planetary world 方向兼容，并为其提供可靠的进入门控。