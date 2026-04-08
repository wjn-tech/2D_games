# Change: Add Hostile Unique Drop Tables

## Why
当前敌对怪物死亡奖励以经验、金币和法术吸收为主，缺少稳定的“怪物身份化物品掉落”，导致战斗回报辨识度不足。

用户要求对当前全部可刷新敌对怪物建立差异化掉落，并确保每个怪物都有不同的掉落特征。

## What Changes
- 新增“敌对怪物掉落表”能力，覆盖当前可刷新敌对怪物（基于 `data/npcs/hostile_spawn_table.json`）。
- 为每个敌对怪物定义一个独占签名掉落（signature drop），并提供“怪物材料”通用池用于经济平衡。
- 定义数据驱动掉落结构（基础池 + 按规则 ID 的覆盖项），支持同一怪物在不同地层/生态规则下做微调。
- 保持现有法术吸收机制、经验与金币奖励不变；物品掉落作为并行奖励层。
- 明确约束：怪物常规掉落不使用草/泥土/石头等地形块资源，避免奖励语义错位。
- 增加验证要求，确保：
  - 每个敌对怪物都映射到掉落配置。
  - 每个怪物签名掉落唯一。
  - 常规掉落池不包含地形块物品（除非后续有显式例外规则）。
  - 规则覆盖优先级可预测且可测试。

## Scope
- In scope:
  - 当前 hostile 刷怪表对应敌对类型（8 个怪物类型，10 条规则）。
  - 掉落数据结构与校验规范。
  - 与现有死亡结算链路的兼容约束。
- Out of scope:
  - 新增怪物家族。
  - 改造法术吸收视觉表现。
  - 交易系统、配方系统的经济再平衡。

## Impact
- Affected specs:
  - hostile-drop-tables (new)
- Related existing specs/changes:
  - absorb_spells_on_kill（需保持兼容，不覆盖其行为）
- Affected code (implementation stage):
  - `src/systems/npc/base_npc.gd`
  - `src/systems/magic/spell_absorption_manager.gd` (integration boundary only)
  - `data/npcs/hostile_spawn_table.json` (rule-id mapping source)
  - `data/items/*.tres`
  - `data/items/hostile/*.tres` (new monster-material items)
- Affected docs:
  - `docs/hostile_spawn_table.md`
