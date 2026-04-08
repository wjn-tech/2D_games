## Context
现有 Boss 遭遇功能已可用，但“教程风格复用”在场景模板、视觉节奏和可验证指标上定义过宽，导致交付结果与预期理解出现偏差。

## Goals / Non-Goals
- Goals:
  - 四个 Boss 房统一采用教程式中小型封闭空间基线。
  - 确保 Boss 房运行完全独立于主世界流式系统。
  - 保持现有入场/退场与结算规则，避免引入机制回归。
  - 将“100% 独立场景入场”转化为可自动验证门禁。
- Non-Goals:
  - 不重做 Boss 技能与数值平衡。
  - 不新增教程对白系统或复杂引导 UI。
  - 不调整 Boss 掉落与终局进度规则。

## Decisions
- Decision: 范围覆盖四个 Boss 房统一收敛，而非仅修单个房间。
  - Why: 你明确要求四房统一改造，避免体验割裂。
- Decision: “仿照新手教程”优先落在构图与配色基线，而非教程脚本移植。
  - Why: 已确认首要诉求是视觉与空间语义一致。
- Decision: 保持完全独立场景隔离，禁止对主世界流式节点产生运行时依赖。
  - Why: 这是你明确确认的硬约束，也是稳定复现的前提。
- Decision: 维持既有入场/退场规则，仅强化链路稳定性与可验证性。
  - Why: 避免在本轮改进中扩大机制变更面。
- Decision: 战前演出只强制镜头聚焦 Boss，其他演出元素保持可选。
  - Why: 与当前确认输入一致，先做最小闭环。

## Architecture Notes
- Scene side:
  - 四个 Boss 房统一遵循同一节点骨架（Background/Arena/Gates/PlayerSpawn/BossSpawn/IntroFocus）。
  - 每个房间允许在美术贴图、障碍细节与色彩上做轻差异化。
- Runtime side:
  - EncounterManager 负责触发道具到场景的确定性映射。
  - EncounterScene 负责统一开战前镜头聚焦与战斗激活门控。
- Validation side:
  - 静态校验：节点结构、碰撞闭合、无流式依赖。
  - 动态校验：多次触发入场成功率、回传坐标一致性。

## Risks / Trade-offs
- 风险: 四房统一模板后可能造成视觉同质化。
  - Mitigation: 保留每个 Boss 房的局部地形与色彩差异窗口。
- 风险: 强化入场确定性可能暴露历史存档边界问题。
  - Mitigation: 补充触发前状态检查和失败日志，便于定位。
- 风险: 中小型空间压缩会影响部分 Boss 机动表现。
  - Mitigation: 先定义尺寸区间而非固定值，预留 Boss 个性化缓冲。

## Resolved Decisions
1. 视觉策略采用统一节点模板，允许轻差异化美术，不改变节点契约。
2. 镜头聚焦时长统一固定为 1.2 秒，保证四个房间节奏一致。
3. 中小型空间阈值采用硬性约束：房间总宽度 <= 1400，总高度 <= 700。
4. 入场稳定性采用强制门禁：每个 Boss 至少 30 次触发回归，独立场景入场成功率必须为 100%。

## Implementation Details (Applied)
- 场景契约收敛：`src/systems/boss/boss_encounter_scene.gd` 新增统一节点路径校验、紧凑尺寸计算与阈值判断（1400x700），并提供流式依赖隔离检查接口。
- 遭遇流程硬化：`src/systems/boss/boss_encounter_manager.gd` 固化 `INTRO_FOCUS_DURATION` 为 1.2 秒，入场时执行场景基线验证，补充非法触发道具兜底日志。
- 实机可见性修复：`src/systems/boss/boss_encounter_manager.gd` 将遭遇实例原点回调到安全坐标带（`y=-3200`），并在玩家传送后强制 `Camera2D` 接管与位置同步；同时入场时将玩家碰撞层归一到世界0层、遭遇期间临时扩展玩家世界碰撞遮罩到全部世界层、结算后恢复原层和原碰撞参数；此外新增遭遇期保底地板与下坠阈值回拉（超阈值自动回传至遭遇出生点并清零速度），彻底兜住“传送后持续下坠”链路。
- 稳定性自检能力：`src/systems/boss/boss_encounter_manager.gd` 新增 30 次入场映射自检方法，用于验证四个触发道具到独立场景的确定性加载。
- 回归验证补强：`tests/test_boss_progression_contracts.gd` 增加紧凑尺寸阈值、镜头时长契约、30 次映射稳定性检查。
- 脚本门禁扩展：`tools/check_boss_progression_pipeline.ps1` 增加新阈值与方法模式检查，并校验四个 Boss 场景骨架节点完整性。
