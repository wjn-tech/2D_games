## Context
当前敌对怪物来自 `data/npcs/hostile_spawn_table.json`，共 10 条规则，映射到 8 个敌对怪物类型（slime、bog_slime、zombie、skeleton、cave_bat、frost_bat、antlion、demon_eye）。

现有死亡结算链路中，`BaseNPC._die()` 已包含经验/金币奖励，并调用 `SpellAbsorptionManager` 处理法术吸收。普通物品掉落层尚未成体系。

## Goals / Non-Goals
- Goals:
  - 为当前 8 个敌对怪物建立可配置、可验证的差异化掉落表。
  - 每个怪物至少一个独占签名掉落，确保战斗收益辨识度。
  - 与法术吸收机制并行兼容，不互相覆盖。
- Non-Goals:
  - 不在本提案中新增怪物。
  - 不重构法术吸收 VFX。
  - 不做跨系统经济总量重平衡。
- Apply Scope Update:
  - 已进入 apply，并完成数据契约、运行时接入、校验脚本与文档落地。

## Key Decisions
- Decision: 采用两层掉落池。
  - Signature Pool: 每个怪物独占标识物，强调身份。
  - Common Pool: 可复用怪物材料，承担资源循环。
- Decision: 按怪物类型定义默认表，按 spawn rule id 做可选覆盖。
- Decision: 怪物常规掉落默认禁止使用地形块资源（grass/dirt/stone/sand/snow 等），保持“击杀怪物获得怪物材料”的语义一致性。
- Decision: apply 采用最小侵入接入，不改变现有 XP/金币主流程，只补充 hostile 物品掉落链路。

## Baseline Monster Drop Matrix (For Review)

| Monster Type | Signature Drop (unique) | Signature Chance | Common Pool (examples) |
| --- | --- | --- | --- |
| slime | slime_essence | 0.78 (qty 1-2) | gelatin_residue 0.42 (1-2), arcane_dust 0.28 (1) |
| bog_slime | bog_core | 0.73 (qty 1-2) | toxic_slurry 0.40 (1-2), arcane_dust 0.22 (1) |
| zombie | rotten_talisman | 0.66 (qty 1) | tainted_flesh 0.48 (1-2), torn_cloth 0.31 (1) |
| skeleton | bone_fragment | 0.74 (qty 1-3) | bone_dust 0.46 (1-2), cursed_powder 0.24 (1) |
| cave_bat | echo_wing | 0.64 (qty 1-2) | bat_fur 0.44 (1-2), sonar_membrane_shard 0.25 (1) |
| frost_bat | frost_gland | 0.70 (qty 1-2) | frozen_membrane 0.41 (1-2), chill_dust 0.30 (1) |
| antlion | antlion_mandible | 0.76 (qty 1-2) | chitin_fragment 0.45 (1-2), desert_resin 0.27 (1) |
| demon_eye | void_eyeball | 0.60 (qty 1) | shadow_ichor 0.38 (1-2), arcane_shard 0.28 (1) |

Notes:
- 上述 common pool 物品均为“怪物材料”新资源规划，不复用地形块掉落。
- `sand` 保留为 antlion 的环境关联候选，仅允许作为未来可选覆盖项，不作为默认常规池条目。

### Rule Overrides
- `skeleton_underworld_legion`
  - bone_fragment chance +0.08
  - cursed_powder chance +0.10
- `cave_bat_underworld_swarm`
  - echo_wing chance +0.06
  - sonar_membrane_shard chance +0.12

## Runtime Roll Contract (Implementation Target)
1. Resolve hostile identity from death context.
2. Read loot config via `rule_id` if present, else monster default.
3. Roll signature pool once.
4. Roll common pool once（or zero times if gated by configuration）.
5. Emit item rewards through existing item delivery path.
6. Execute existing spell absorption and XP/gold logic unchanged.

## Risks / Trade-offs
- 过高的签名掉落概率会导致早期资源溢出。
  - Mitigation: 通过固定种子 Monte Carlo 采样验证 1k 次击杀产出分布。
- 规则覆盖过多会增加维护复杂度。
  - Mitigation: 仅对 underworld 两条规则做覆盖，其余沿用怪物默认表。

## Validation Strategy
- Schema validation: 字段完整性、概率区间、数量区间。
- Coverage validation: hostile 刷怪规则必须全部可解析到掉落配置。
- Uniqueness validation: signature drop 在 8 个怪物类型中不得重复。
- Compatibility validation: 击杀后法术吸收信号链与 XP/Gold 奖励保持生效。

## Open Questions
- 无（范围与差异口径已在提案前确认）。

## Implementation Mapping (Apply)
- Drop data contract:
  - `data/npcs/hostile_loot_table.json`
  - 覆盖 8 个 hostile 类型 + 2 条 underworld 规则覆盖。
- Runtime resolver:
  - `src/systems/npc/hostile_loot_table.gd`
  - 负责优先级解析与掉落掷骰。
- Death flow integration:
  - `src/systems/npc/base_npc.gd`
  - `SpellAbsorptionManager` 与 `_drop_normal_loot()` 并行执行。
  - 物品优先入背包，失败则生成 `LootItem` 场景掉落。
- Spawn context propagation:
  - `src/systems/npc/npc_spawner.gd`
  - 为每个 spawn 实例写入 `spawn_rule_id` 和 `hostile_monster_type` 元数据。
- Item resource loading:
  - `src/core/game_state.gd`
  - 改为递归加载 `res://data/items/`，支持 `data/items/hostile/` 子目录。
- Verification and regression:
  - `tools/validate_hostile_loot_table.ps1`
  - `tools/simulate_hostile_loot_distribution.ps1`
  - `tools/check_hostile_death_pipeline.ps1`
- Designer documentation:
  - `docs/hostile_drop_table.md`
  - `docs/hostile_spawn_table.md`（补充掉落联动与优先级语义）
