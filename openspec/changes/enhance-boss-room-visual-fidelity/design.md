## Context
当前 Boss 房已经满足结构与功能契约，但视觉层次不足：单层纯色背景、静态门体、缺乏环境动态与灯光层，导致玩家体感接近测试关卡而非首领遭遇场。

## Goals / Non-Goals
- Goals:
  - 在不改玩法规则的前提下，让四个 Boss 房达到“可玩且可看”的战斗空间质量。
  - 保持教程式紧凑模板，同时提升主题辨识度和战斗氛围。
  - 提供可验证的视觉门禁，避免后续回归到“能打但难看”。
- Non-Goals:
  - 不改 Boss 机制、数值、掉落。
  - 不引入重型后处理链路（避免低端机压力激增）。
  - 不扩大房间尺寸或破坏封闭碰撞结构。

## Decisions
- Decision: 使用“统一骨架 + 主题 token”而非四套完全独立美术。
  - Why: 保留维护效率，降低后续新增 Boss 房的复制成本。
- Decision: 视觉组件化接入（背景层、环境粒子层、门体状态层、轻灯光层）。
  - Why: 便于按场景开关与性能降级，不与核心战斗脚本耦合。
- Decision: 镜头演出采取“短时增强”，不延长玩家失控时间。
  - Why: 保证节奏体验，不让演出抢占战斗输入。

## Architecture Notes
- Scene Layering:
  - Background 拆分为远景/中景/前景三层。
  - Arena 保持现有碰撞节点结构，视觉改动与碰撞逻辑解耦。
- VFX/Lighting:
  - 添加低成本循环环境粒子（尘、雾、火星等按 Boss 主题分配）。
  - 添加门体锁定/解锁材质态（颜色 + 发光强度 + 轻动画）。
- Cinematics:
  - 复用已有 IntroFocus 管线，增加可配置镜头曲线与阶段信号反馈。

## Risks / Trade-offs
- 风险: 视觉增强导致可读性下降（技能弹道被背景干扰）。
  - Mitigation: 对战斗实体建立最低对比度门槛，必要时自动压低背景饱和度。
- 风险: 粒子与灯光叠加导致帧耗上升。
  - Mitigation: 设定每房粒子实例上限与灯光预算，并提供降级开关。
- 风险: 过度演出影响玩家输入节奏。
  - Mitigation: 限制失控时长，镜头增强不阻塞战斗激活窗口。

## Validation Strategy
1. 结构回归：四房节点契约与碰撞闭合继续通过。
2. 视觉门禁：每房必须存在分层背景、环境动态、门体状态反馈。
3. 可读性回归：Boss 投射物与玩家在典型战斗帧的可见对比达标。
4. 性能抽检：统一场景下视觉增强帧耗增量在预算阈值内。

## Open Questions
- 默认先采用低饱和深色基底 + 高亮事件色方案；若后续有统一品牌配色，再在 apply 阶段替换 token 表。

## Implementation Details (Applied)
- 场景视觉分层落地：四个 Boss 房场景 `scenes/worlds/encounters/boss_*.tscn` 均从单层 `Backdrop` 升级为 `Background/FarLayer`、`Background/MidLayer`、`Background/ForeLayer`，并加入 `AtmosphereDrift`/`ForeDrift` 轻动态节点。
- 主题 token 落地：`src/systems/boss/boss_encounter_scene.gd` 新增 `theme_primary_color`、`theme_accent_color`、`theme_fog_intensity`、`theme_particle_profile` 导出字段，四房分别配置差异化主题。
- 门体状态增强：`src/systems/boss/boss_encounter_scene.gd` 的 `lock_gates` 改为统一走 `_apply_gate_visual_state`，实现颜色 + 亮度 + 动态脉冲三通道反馈；场景中新增 `Gates/*/Glow` 节点用于锁定/解锁亮度表达。
- 阶段视觉信号：`src/systems/boss/boss_encounter_scene.gd` 在 Boss `phase_changed` 时触发 `encounter_phase_visual_event`，并执行 MidLayer 闪变与浮字提示。
- 演出节奏与输入保护：`src/systems/boss/boss_encounter_manager.gd` 新增 `MAX_INPUT_LOCK_DURATION := 2.0`、预对焦分段与轻微镜头震动，开场演出增强但不改变入场/结算规则。
- 预算与可降级：`src/systems/boss/boss_encounter_scene.gd` 新增 `set_visual_budget_mode()` 与 `get_visual_budget_limits()`，在压力模式下优先关闭非关键氛围节点，保留 Boss/玩家/门状态可读性。
- 门禁扩展：`tools/check_boss_progression_pipeline.ps1` 新增 visual/cinematic 关键模式校验（视觉分层、视觉与可读性验证函数、输入锁定上限常量）。

## Verification Record (Applied)
1. 结构门禁：四个 Boss 房均满足 `Background/FarLayer + MidLayer + ForeLayer` 节点契约，且原有 `Arena/Gates/Spawn` 结构未破坏。
2. 可读性门禁：`BossEncounterScene.validate_combat_readability_baseline()` 采用主题亮度差阈值校验，低对比主题将触发失败。
3. 性能/降级门禁：`BossEncounterScene.set_visual_budget_mode()` 支持 `low/critical` 降级路径，优先关闭非关键 ambience 节点。
4. 脚本回归：`tools/check_boss_progression_pipeline.ps1` 通过。
5. OpenSpec 回归：`openspec validate enhance-boss-room-visual-fidelity --strict` 通过。