# Change: Add HUD Feedback and Persistent Hints

## Why
- 当前 HUD 受击反馈存在但强度与层级仍偏基础，命中反馈在 HUD 层缺少统一表现。
- 你已明确希望快捷按键提示常驻，以减少关键操作遗忘。
- 本轮要在不引入技能系统、不改战斗结算逻辑前提下，提升 HUD 交互可感知性。

## What Changes
- 增强 HUD 受击反馈：保留红色受击层并优化触发节奏与恢复曲线。
- 增加 HUD 命中反馈：在命中确认时提供轻量颜色/缩放脉冲提示。
- 新增长驻快捷提示条：持续展示核心按键提示，不依赖悬停触发。
- 保持低扰动视觉：反馈动画以轻微缩放/颜色闪烁为主。
- 明确非目标：不新增技能栏/冷却系统，不改伤害公式，不改世界层攻击特效资产。

## Impact
- Affected specs: hud-feedback-and-hints
- Affected code (implementation stage): scenes/ui/HUD.tscn, scenes/ui/hud.gd, src/ui/hud/player_status_widget.gd, src/ui/ui_manager.gd
- Sequencing: 可与状态区重构并行，但建议在状态区重构后统一调参。
