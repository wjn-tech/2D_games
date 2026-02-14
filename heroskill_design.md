# Hero Skill 设计文档（基于魔杖法术组合）

## 1. 目标与核心约束

### 1.1 目标

- 在游戏中增加“技能（Hero Skill）”系统。
- 技能在表现层看起来是“一个完整技能动作”（特效动画 + 触发条件）。
- 技能在实现层不引入新的伤害系统，而是**在特定时机释放多个已有魔杖法术**，组合出技能效果。

### 1.2 核心约束（简化开发）

- 技能本体不直接计算弹道/伤害，只负责“编排施法”。
- 伤害、触发器、投射物逻辑继续复用现有法术链路：
  - `src/systems/magic/wand_data.gd`
  - `src/systems/magic/compiler/wand_compiler.gd`
  - `src/systems/magic/spell_processor.gd`
- 技能特效动画是“外壳”，与法术发射调度解耦。

### 1.3 非目标（当前阶段不做）

- 不新增独立于魔杖系统的技能伤害公式。
- 不新增第二套触发系统（技能只消费统一事件）。
- 不做复杂技能编辑器（先数据驱动 + 配置文件）。

## 2. 能力定义

### 2.1 技能定义

技能 = `触发条件` + `表现外壳` + `法术发射计划(Spell Cast Plan)`

- 触发条件：按键、命中、受击、位移距离、连击数等。
- 表现外壳：前摇/后摇、角色动画、音效、屏幕特效。
- 法术发射计划：在技能时间轴的多个时间点，从不同发射位置/方向，调用 `SpellProcessor.cast_spell(...)` 发射一个或多个 `WandData`。

### 2.2 设计原则

- 单一职责：
  - HeroSkill 负责“何时、在哪、朝哪、发什么”；
  - SpellProcessor 负责“法术如何执行”。
- 可组合：
  - 一个技能可绑定多个 `WandData`（同一魔杖可重复释放）。
- 可回放与可调试：
  - 技能执行应产生日志事件（触发、阶段开始、法术发射、结束/中断）。

## 3. 建议架构拆分

### 3.1 模块清单

- `HeroSkillData`（Resource）
  - 技能静态配置：名称、冷却、触发规则、动画资源、法术发射计划。
- `HeroSkillRuntime`
  - 技能运行态：冷却计时、激活状态、阶段推进、中断状态。
- `HeroSkillSystem`（Manager）
  - 输入与事件监听、触发判定、技能实例驱动、统一更新。
- `SkillEventBus`（可选）
  - 为“命中/受击/击杀”等条件提供统一事件入口。

### 3.2 与现有系统对接

- 法术发射：调用 `SpellProcessor.cast_spell(wand_data, source_entity, direction, start_pos)`。
- 发射方向与位置：由技能计划提供（角色朝向、目标方向、固定角度扇形、环形等）。
- 伤害结算：保持在现有投射物/触发器链路内，不在技能层重复实现。

## 4. 数据结构草案

```gdscript
# HeroSkillData.gd (Resource)
class_name HeroSkillData
extends Resource

@export var skill_id: String
@export var display_name: String
@export var cooldown_sec: float = 5.0
@export var cast_time_sec: float = 0.2
@export var recovery_sec: float = 0.3

@export var trigger_rules: Dictionary = {}
# 例: {"type":"input_pressed","input":"skill_1"}
# 例: {"type":"on_hit","min_combo":3}

@export var vfx_profile: Dictionary = {}
# 例: 动画名、特效场景、音效

@export var cast_plan: Array[Dictionary] = []
# 每项示例:
# {
#   "time": 0.0,
#   "wand_ref": Resource,        # WandData
#   "origin_mode": "caster|target|offset",
#   "offset": Vector2.ZERO,
#   "direction_mode": "facing|target|fixed|spread",
#   "fixed_angle_deg": 0.0,
#   "count": 1,
#   "spread_deg": 0.0,
#   "interval_sec": 0.0
# }
```

## 5. 运行流程

1. 玩家输入或战斗事件进入 `HeroSkillSystem`。
2. 系统检查：
   - 是否满足触发条件；
   - 是否不在冷却；
   - 是否未被沉默/硬直等状态禁用。
3. 创建/激活 `HeroSkillRuntime`，播放技能外壳（动画/VFX/SFX）。
4. 随时间推进执行 `cast_plan`：
   - 计算发射点与方向；
   - 对每个发射条目调用 `SpellProcessor.cast_spell(...)`。
5. 技能结束，进入冷却。
6. 若被中断，按配置决定：
   - 立即结束并进入全冷却，或
   - 按比例退还冷却。

## 6. 触发条件分层

- L1（立即可做）：
  - 按键触发（主动技能）。
- L2（中期）：
  - 命中后触发、受击触发、闪避后触发。
- L3（后期）：
  - 连击阈值、状态机组合条件（如“空中 + 暴击后 2 秒内”）。

建议先完成 L1 + 部分 L2，避免一开始构建过重规则引擎。

## 7. 开发任务分解（可直接执行）

### 阶段 A：最小可用版本（MVP）

- 新增 `HeroSkillData` 资源与加载流程。
- 新增 `HeroSkillSystem`，支持按键触发 + 冷却。
- 支持技能时间轴里发射多个法术（多段调用 `SpellProcessor.cast_spell`）。
- 完成一个示例技能（例如“三连火球”）。

### 阶段 B：表现与手感

- 接入角色动画状态（前摇/后摇/中断）。
- 接入技能特效与音效配置。
- 增加常用发射模式：扇形、环形、追踪目标方向。

### 阶段 C：事件触发与扩展

- 接入命中/受击事件触发。
- 增加技能中断策略与冷却返还策略。
- 增加调试面板（显示技能状态、剩余冷却、计划执行指针）。

## 8. 验收标准

- 技能系统不新增独立伤害链路，所有攻击效果均来自法术发射。
- 一个技能至少可在 1 次施放中触发 3 次法术发射（可带角度或位置变化）。
- 技能冷却、前摇、后摇、中断逻辑可配置。
- 新增技能时主要通过配置 `HeroSkillData` 完成，不需要改 `SpellProcessor` 核心逻辑。

## 9. 风险与规避

- 风险：技能频繁多发射导致性能波动。  
  规避：限制单技能同帧最大发射数；必要时分帧调度。

- 风险：技能层与法术层都做触发，导致重复执行。  
  规避：明确边界，技能层只做“调度发射”，不做二次伤害触发。

- 风险：调参困难。  
  规避：统一 `HeroSkillData` 参数命名 + 调试日志 + 可视化时间轴指针。

## 10. 下一步建议

1. 先实现阶段 A，并做 2 个样例技能：
   - `skill_fire_burst`：0/0.15/0.30 秒各释放一次同一法术；
   - `skill_arc_fan`：同一时刻按 -15/0/+15 度释放 3 次法术。
2. 验证“技能只编排法术”的边界是否满足玩法需求，再进入阶段 B。
