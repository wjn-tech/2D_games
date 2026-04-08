## Context
本变更在已有 hostile 掉落和合成系统之上，新增三段 Boss 进度与终局通关链路。目标是保证玩法闭环可感知、工程实现可分层、验证路径可自动化。

## Goals / Non-Goals
- Goals:
  - 构建“掉落 -> 合成 -> 召唤 -> 击杀 -> 三核 -> 终局”的主线闭环。
  - Boss 房间主要复用教程场景风格，并与主世界流式系统隔离。
  - 允许重复挑战，保障后期可刷取循环。
  - 终局战后写入通关状态，且存档继续可玩。
- Non-Goals:
  - 不改造全局敌人 AI 框架。
  - 不引入新周目系统。
  - 不引入非必要外部依赖。

## Decisions
- Decision: 使用“道具消耗触发独立遭遇场景”。
  - Why: 可降低主世界地形和流式调度对 Boss 机制验证的干扰。
- Decision: 召唤证与禁忌钥匙统一采用“装备后交互键触发”。
  - Why: 复用现有玩家交互通道，避免新增 UI 操作分支。
- Decision: Boss 场景采用教程风格模板，而不是嵌入主世界区域。
  - Why: 满足视觉一致性，同时保留战斗机制隔离。
- Decision: 召唤证与禁忌钥匙均为可消耗道具。
  - Why: 形成清晰资源门槛和重复挑战循环。
- Decision: 所有 Boss 投射攻击统一走“可见实体弹药”契约。
  - Why: 保证伤害来源可读、可反馈、可测试。
- Decision: 入场流程统一执行“开场镜头 + 锁门”，结算后解锁退出。
  - Why: 保证遭遇节奏一致且避免开场阶段被跳过。
- Decision: 失败后仅消耗入场道具，玩家返回入场前原坐标。
  - Why: 规则清晰，风险可控，且不引入额外惩罚耦合。
- Decision: 米娜仅镜像开战时生命与当前法杖，且终局可重复挑战。
  - Why: 保留终局辨识度，同时避免战中同步造成不确定性。

## Risks / Trade-offs
- 跨场景快照与恢复容易出现状态漂移（生命、背包、当前法杖）。
  - Mitigation: 明确定义进入快照字段和退出恢复顺序。
- 可重复挑战可能导致核心材料经济通胀。
  - Mitigation: 在配方层控制核心用途，避免无限扩散。
- 终局镜像玩家构筑可能放大极端词条。
  - Mitigation: 对镜像字段做白名单复制并保留扩展点。

## Migration Plan
1. 先落数据：新增道具与配方。
2. 再落入口：召唤证/钥匙触发遭遇。
3. 再落规则：Boss 结算与核心掉落。
4. 最后落终局：米娜战、通关写入、回归验证。

## Confirmed Inputs
1. 三位 Boss 每次胜利都掉落核心，可重复刷取。
2. 召唤证与禁忌钥匙使用方式为装备后交互触发。
3. 失败惩罚仅为入场道具消耗并返回主世界。
4. 入场统一执行开场镜头和锁门。
5. 结算返回位置为入场前原坐标。
6. 米娜只镜像开战时生命与当前法杖。
7. 通关后可重复挑战米娜。

## Implementation Notes
- 提案阶段仅定义能力契约，不直接提交实现代码。
- apply 阶段严格按 `tasks.md` 顺序推进并在收尾时逐项勾选。

## Implementation Details (Applied)
- Data contract:
  - 新增道具资源：`data/items/boss/slime_king_sigil.tres`、`data/items/boss/skeleton_king_sigil.tres`、`data/items/boss/eye_king_sigil.tres`、`data/items/boss/slime_king_core.tres`、`data/items/boss/skeleton_king_core.tres`、`data/items/boss/eye_king_core.tres`、`data/items/boss/forbidden_key.tres`。
  - 本地化补充：`assets/translations.csv` 与 `data/npcs/hostile_drop_localization.json` 新增 Boss 进度键。
- Crafting contract:
  - `src/systems/crafting/crafting_manager.gd` 新增 `_add_resource_recipe` 与 `_add_boss_progression_recipes`，落地三条召唤证配方和禁忌钥匙配方。
- Encounter lifecycle:
  - 新增 Autoload：`src/systems/boss/boss_encounter_manager.gd`（在 `project.godot` 注册 `BossEncounterManager`）。
  - 玩家入口：`scenes/player.gd` 在 `_interact` 中优先尝试触发 Boss 遭遇；在 `_physics_process` 中识别独立遭遇态并隔离主世界流式处理；在 `take_damage` 致命路径接管为遭遇失败结算。
  - 独立场景：`src/systems/boss/boss_encounter_scene.gd` + `scenes/worlds/encounters/boss_*.tscn`，统一实现开场镜头焦点、锁门、激活战斗、胜败回调。
  - 交战 HUD：`scenes/ui/hud.gd` 新增 Boss 血条面板；`boss_base.gd` 暴露 `health_changed/current/max`；`boss_encounter_manager.gd` 负责在遭遇开始绑定血量信号、实时更新并在结算时隐藏与解绑。
- Boss mechanics:
  - Boss 基类与投射物：`src/systems/boss/boss_base.gd`、`src/systems/boss/boss_projectile.gd`、`scenes/entities/boss/boss_projectile.tscn`。
  - 三王与终局：`src/systems/boss/slime_king.gd`、`src/systems/boss/skeleton_king.gd`、`src/systems/boss/eye_king.gd`、`src/systems/boss/mina_finale.gd`。
  - 魔眼分裂阶段：`src/systems/boss/eye_split_fragment.gd` + `scenes/entities/boss/eye_split_fragment.tscn`。
  - 机制细化（澄清后落地）：
    - 史莱姆王：普通攻击收敛为近身冲刺碰撞；半血后解锁酸液喷吐，命中按玩家最大生命值百分比结算并叠加中毒持续伤害；后续调优中提升本体机动性（提高基础移速、冲刺倍率并缩短冲刺间隔）并延长酸液弹体续航（更高弹速 + 更长存在时间）以提升命中稳定性。
    - 骷髅王：保留近战冲击并新增“单波 10 支骨箭”远程齐射，骨箭使用强追踪；后续调优中提升本体机动性（更短冲刺冷却、更高冲刺倍率）与箭矢压迫感（更高弹速、更快转向、更窄散布），并延长骨箭飞行时间以减少提前消散导致的空窗；在最新调优中进一步将骨箭手感改为“更快、更轻”（更高弹速、较低追踪强度、较小弹体半径、较轻命中伤害）。
    - 魔眼王：普通攻击收敛为冲撞；半血后本体立即退场并分裂为 10 个恶魔眼，清空分裂体后判定通关并发放核心。
  - 运行时支持：`scenes/player.gd` 新增中毒状态处理，`boss_projectile.gd` 新增百分比命中伤害、追踪与中毒配置接口。
  - 战斗修复（后续回归）：
    - 米娜施法链路修正为“有法杖快照时仅走 `SpellProcessor.cast_spell`”，法杖冷却/回蓝帧不会再降级到自定义 fallback 弹幕。
    - 终局快照补强：`player.gd` 保留最近一次已装备法杖快照，`boss_encounter_manager.gd` 在钥匙触发时优先采集该快照，确保米娜在“先装备禁忌钥匙再入场”流程下仍使用玩家法杖构筑。
    - 终局体型对齐：`boss_encounter_scene.gd` 在米娜生成后将其全局缩放对齐玩家，保证米娜与玩家体型一致。
    - 终局施法约束：`mina_finale.gd` 移除自定义 Boss 弹幕 fallback，改为“仅允许法杖链路施法”；并新增米娜法杖可视化与枪口发射点，确保观感为“持杖发射”而非体内生弹。
    - 可视化兜底：`mina_finale.gd` 对法杖贴图增加可见性检测和 fallback 纹理，避免玩家法杖视觉网格为空时出现“看不到法杖模型”。
    - 可视化缩放补偿：`mina_finale.gd` 对法杖 pivot、枪口和贴图缩放做场景缩放补偿，避免在 4x 房间中米娜法杖因局部缩放过小而不可见。
    - 引擎兼容修复：`mina_finale.gd` 的贴图可见性检测移除 `Image.lock/unlock` 调用，改为兼容 Godot 4 的直接像素读取，消除运行时 `Nonexistent function 'lock' in base 'Image'` 报错。
    - 施法稳定性修复：`spell_processor.gd` 的延迟发射链路对 `casting_source/source` 增加实例有效性与类型保护，施法源被释放后自动回退到缓存发射位，不再触发 `_resolve_emission_transform` 的“previously freed”类型错误。
    - 阵营碰撞修复：`spell_processor.gd` 的法术弹体碰撞掩码改为按施法者阵营分流（玩家施法命中 NPC，NPC 施法命中玩家），修复米娜法术弹药可见但对玩家不掉血的问题。
    - 自伤防护：`spell_processor.gd` 在法术弹体生成时对施法者添加碰撞豁免，`projectile_base.gd` 在直击、爆炸与黑洞路径均加入施法者过滤，避免米娜被自身法杖弹体及其范围效果命中。
    - 投射物外观参数化：`boss_projectile.gd` 新增 `configure_visual_profile`，允许单个 Boss 在不影响其他 Boss 的情况下独立调节弹体半径与透明度。
    - `boss_base.gd` 的投射物出生点改为按 Boss 全局缩放修正 offset 并增加前向出膛距离，避免在放大房间中出现“弹体卡在模型里”。
    - `boss_base.gd` 的近战接触判定改为随 Boss 全局缩放扩展命中范围，修复房间放大后“贴脸不掉血”的体感偏差。
  - 场景视觉细化：`scenes/worlds/encounters/boss_slime_king.tscn`、`boss_skeleton_king.tscn` 增加远/中景装饰层节点，避免“普通蓝天”质感。
- Finale progression:
  - 米娜初始化镜像开战快照（生命 + 当前法杖）在 `mina_finale.gd:apply_player_snapshot`。
  - 米娜施法路径改为复用玩家同源执行器：`SpellProcessor.cast_spell(snapshot_wand_data, mina, dir, spawn_pos)`，不再走独立固定弹幕。
  - 通关持久化键：`GameState` meta `mina_finale_completed`，并保留可重复挑战。
- Verification assets:
  - 新增验证：`tests/test_boss_progression_contracts.gd`、`tools/check_boss_progression_pipeline.ps1`。
  - 运行结果：`tools/check_boss_progression_pipeline.ps1` 通过，`openspec validate add-boss-sigil-progression-and-finale --strict` 通过。
  - 受限项：当前环境无 `godot` CLI，未能在终端执行 `tests/test_boss_progression_contracts.gd` 的 headless 运行。
