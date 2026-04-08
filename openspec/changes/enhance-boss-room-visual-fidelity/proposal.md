# Change: Enhance Boss Room Visual Fidelity

## Why
当前四个 Boss 独立房间在功能上已经稳定，但视觉表达仍停留在“纯色背景 + 基础几何碰撞体 + 低氛围反馈”，与玩家对 Boss 战“压迫感、仪式感、辨识度”的预期明显不匹配。实机反馈已经明确指出“太丑，需要美化”。

## What Changes
- 新增 Boss 房视觉保真能力：
  - 将房间背景升级为分层构图（远景/中景/前景），替代单层纯色背板。
  - 引入统一氛围组件契约（环境粒子、轻动态光、地面细节、门体材质状态）。
  - 为四个 Boss 房定义风格化主题 token（色相、对比、雾强度、门光颜色），确保“统一模板 + 强辨识”。
- 新增 Boss 遭遇镜头演出 v2 能力：
  - 在不改变玩法规则前提下，增强开场镜头节奏（焦点过渡、微抖、恢复控制时机）。
  - 补充战斗关键时刻的可读性反馈（门锁状态、Boss 阶段切换视觉信号）。
- 保持现有硬约束：
  - 不改变掉落、数值、失败/胜利回传规则。
  - 不改变“独立场景隔离”与紧凑房间尺寸阈值（1400 x 700）。

## Scope
- In scope:
  - 四个 Boss 房场景的视觉结构与氛围组件规范。
  - 遭遇开场镜头与关键视觉反馈规范。
  - 对应验证脚本与视觉门禁指标。
- Out of scope:
  - Boss 技能与伤害数值重做。
  - 新增剧情系统或对白系统。
  - 全局 UI 主题重做。

## Impact
- Affected specs:
  - boss-arena-visual-fidelity (new)
  - boss-encounter-cinematics-v2 (new)
- Related changes:
  - refine-boss-room-tutorial-baseline
  - add-boss-sigil-progression-and-finale
  - enhance-cinematic-system
- Affected code (apply stage):
  - scenes/worlds/encounters/boss_slime_king.tscn
  - scenes/worlds/encounters/boss_skeleton_king.tscn
  - scenes/worlds/encounters/boss_eye_king.tscn
  - scenes/worlds/encounters/boss_mina_finale.tscn
  - src/systems/boss/boss_encounter_scene.gd
  - src/systems/boss/boss_encounter_manager.gd
  - tools/check_boss_progression_pipeline.ps1

## Success Criteria
1. 四个 Boss 房在同一模板下具备可肉眼区分的主题风格。
2. 开场 2 秒内玩家可明确感知“Boss 房氛围已建立”，不再出现“空白测试房”观感。
3. 视觉升级后仍通过现有 Boss 流程门禁与 OpenSpec strict 校验。