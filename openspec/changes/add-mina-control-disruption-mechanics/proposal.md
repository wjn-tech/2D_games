# Change: Add Mina Control Disruption Mechanics

## Why
当前米娜终局战已具备“镜像生命与法杖”的核心身份，但对玩家控制权与战斗节奏的压制仍不足，难以体现终局 Boss 的独特威胁层次。

本提案用于为米娜增加“位移扰动 + 控制干扰 + 属性压制”的机制组合，形成清晰的终局压迫曲线，同时保持可读性与可验证性。

## What Changes
- 新增 `finale-forbidden-key` 能力增量（米娜终局战机制扩展）：
  - 米娜可触发“双方位置互换”。
  - 米娜可对玩家施加“心绞痛（Angina）”：玩家最大生命值降至 50%，持续 10 秒。
  - 米娜可施加“禁射（Projectile Lock）”：玩家 10 秒内无法发射投射物。
  - 米娜可施加“输入颠倒（Input Inversion）”：玩家战斗移动输入在 10 秒内反转。
  - 米娜可施加“重力翻转（Gravity Flip）”：玩家重力方向在 10 秒内翻转。
  - 米娜每 10 秒进入一次“无敌 + 投射物吞噬”窗口。
  - 米娜吞噬场内投射物时，每吞噬 1 个投射物，米娜伤害提升 1%（战斗内累计）。
  - 米娜每损失 1/5 生命，玩家攻击力衰减 20%（分段叠加）。
  - 米娜每损失 1/5 生命时额外获得 3 秒无敌，并在该窗口持续吞噬所有投射物。

## Scope
- In scope:
  - 米娜终局战新增机制的触发条件、持续时间、叠加规则和恢复规则。
  - 米娜“无敌 + 吞噬”机制与投射物吞噬计数伤害成长规则。
  - 玩家状态系统在终局战中的临时异常状态挂载与回滚。
  - 终局战 HUD/反馈约束（状态可读性、阈值提示）。
  - 机制验证与回归检查规范。
- Out of scope:
  - 非米娜 Boss 的控制类机制复用改造。
  - 全局输入系统重构。
  - 角色基础属性系统的大规模重写。

## Impact
- Affected specs:
  - `finale-forbidden-key`
- Related changes:
  - `add-boss-sigil-progression-and-finale`
- Affected code (apply stage):
  - `src/systems/boss/mina_finale.gd`
  - `src/systems/boss/boss_encounter_scene.gd`
  - `src/systems/boss/boss_encounter_manager.gd`
  - `scenes/player.gd`
  - `src/systems/magic/spell_processor.gd`（仅当禁射需要投射入口统一拦截）
  - `scenes/ui/hud.gd`（状态提示）

## Defaults for Ambiguous Inputs
1. “输入映射颠倒”默认作用于战斗移动轴（左右与重力方向上的上下移动），不影响菜单/暂停/背包快捷键。
2. “每降低 1/5 血，玩家攻击力降低 20%”采用分段叠乘（倍率 ×0.8），并设置最小攻击倍率下限 0.2，避免出现 0 伤害死锁。
3. “可能施加”解释为：米娜在机制窗口中按权重选择可用机制，不要求每次固定触发同一效果。
4. “每吞噬一个投射物，米娜伤害上升 1%”采用战斗内累乘（倍率 ×1.01），遭遇结束后清零。
5. 定时无敌（每 10 秒）与阈值无敌（每 20% 血量）重叠时，窗口时长按结束时间取更晚值，不重复缩短。

## Open Questions
- 当前无阻塞性未决问题，可进入评审。
