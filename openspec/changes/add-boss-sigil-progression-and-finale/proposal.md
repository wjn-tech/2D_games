# Change: Add Boss Sigil Progression and Finale

## Why
当前 hostile 掉落体系已经存在核心材料（例如 `slime_essence`、`bone_fragment`、`void_eyeball`），但缺少“掉落 -> 合成 -> 挑战 -> 终局”的主线闭环。

本提案用于将掉落系统升级为三位首领进度链，并在三核合成后开启米娜终局战，形成可重复、可验证、可继续游玩的主流程。

## What Changes
- 新增 `boss-sigil-crafting` 能力：
  - `10 x slime_essence -> slime_king_sigil`
  - `10 x bone_fragment -> skeleton_king_sigil`
  - `10 x void_eyeball -> eye_king_sigil`
- 新增 `boss-instance-encounters` 能力：
  - 使用召唤证后进入对应 Boss 独立场景（装备道具后按交互键触发）。
  - 入场统一执行开场镜头与锁门流程，战斗结束后解锁退出。
  - Boss 房间以新手教程风格为基线，但保持独立场景隔离。
  - 三位 Boss 通关后分别掉落唯一核心材料，且重复挑战重复掉落。
- 新增 `finale-forbidden-key` 能力：
  - `10 x arcane_dust + slime_king_core + skeleton_king_core + eye_king_core -> forbidden_key`
  - 使用 `forbidden_key`（装备后交互）进入米娜终局场景并完成通关标记。
  - 米娜按开战快照仅镜像玩家生命与当前法杖，终局支持重复挑战。

## Scope
- In scope:
  - Boss 召唤证、Boss 核心、禁忌钥匙的数据契约。
  - 遭遇入口、场景切换、失败返回、胜利结算与通关写入。
  - Boss 房间教程风格复用约束与独立场景约束。
- Out of scope:
  - 二周目/New Game+。
  - 多人联机同步。
  - 全局战斗系统重构。

## Impact
- Affected specs:
  - `boss-sigil-crafting`
  - `boss-instance-encounters`
  - `finale-forbidden-key`
- Related changes:
  - `add-hostile-unique-drop-tables`
  - `integrate-crafting-system`
  - `upgrade-boss-encounter-scene-completeness`
- Affected code (apply stage):
  - `src/systems/crafting/`
  - `src/systems/boss/`
  - `scenes/worlds/encounters/`
  - `data/items/hostile/`
  - `assets/translations.csv`

## Confirmed Inputs
1. 三位 Boss 可重复挑战，且每次胜利都掉对应核心。
2. 召唤证与禁忌钥匙统一采用“装备后按交互键”触发。
3. Boss 战失败后仅消耗入场道具并返回主世界，不追加额外惩罚。
4. 所有 Boss 入场统一执行开场镜头与锁门流程。
5. 战斗结束返回主世界时，回到入场前原坐标。
6. 米娜仅镜像开战时玩家生命与当前法杖。
7. 通关后米娜终局可重复挑战。

## Open Questions
- 当前无阻塞性未决问题，可进入 apply 阶段。
