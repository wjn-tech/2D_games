# Change: Refine Boss Room Tutorial Baseline

## Why
当前 Boss 遭遇已经采用独立场景，但你反馈“不是要的仿照新手教程独立场景”，说明现有实现在“教程风格复用”的表达和验收口径上仍不够明确。

本提案将把需求收敛为可验证契约：四个 Boss 房全部采用教程式的紧凑独立场景基线，且维持既有入场/退场规则不变。

## What Changes
- 新增并收敛 Boss 房模板契约：
  - 四个 Boss 房（史莱姆王/骷髅王/魔眼王/米娜）统一按教程式中小型封闭空间构图。
  - 场景完全隔离于主世界流式地形系统，运行不依赖 chunk/streaming 节点。
- 强化遭遇流程契约：
  - 入场后 100% 进入对应独立场景，不出现落回主世界战斗的分支。
  - 保留既有规则：道具消耗入场，失败返回原坐标，胜利结算后返回原坐标。
  - 开战前固定保留“镜头聚焦 Boss”环节。
- 补充验证口径：
  - 增加场景节点结构与运行态隔离验证。
  - 增加入场成功率与回传坐标一致性验证。

## Impact
- Affected specs:
  - `boss-instance-encounters`
  - `boss-room-scene-template`
- Affected code (apply stage):
  - `scenes/worlds/encounters/boss_slime_king.tscn`
  - `scenes/worlds/encounters/boss_skeleton_king.tscn`
  - `scenes/worlds/encounters/boss_eye_king.tscn`
  - `scenes/worlds/encounters/boss_mina_finale.tscn`
  - `src/systems/boss/boss_encounter_scene.gd`
  - `src/systems/boss/boss_encounter_manager.gd`
  - `tools/check_boss_progression_pipeline.ps1`

## Confirmed Inputs
1. 作用范围是四个 Boss 房全部统一改造。
2. “教程风格”优先级最高的是场景构图与配色，而非增加教程文案流程。
3. Boss 房必须保持完全独立场景隔离。
4. 入场/退场沿用现规则，不改变掉落与惩罚逻辑。
5. 战前演出至少保留“镜头聚焦 Boss”。
6. 战斗空间基线为教程式中小型封闭空间。
7. 核心验收优先级：入场后 100% 进入独立场景。
8. 四个 Boss 房采用“统一模板 + 轻差异化美术”策略。
9. 镜头聚焦时长统一为 1.2 秒。
10. 中小型空间校验阈值为：房间总宽度 <= 1400，总高度 <= 700。
11. “100% 独立场景入场”通过批量回归门禁验证：每个 Boss 至少 30 次触发，成功率必须为 100%。

