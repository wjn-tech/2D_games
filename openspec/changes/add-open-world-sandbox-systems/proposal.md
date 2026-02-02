# Change: 增加大世界沙盒核心系统（模块化）

## Why
当前工程仅有基础玩家移动与测试场景。为了支撑“可探索大世界 + NPC 交互 + 建造 + 多层战斗 + 人物生命周期 + 制造/交易 + 天气/生态”等长期目标，需要先建立模块化、数据驱动的系统骨架与最小可用玩法闭环。

## What Changes
- 新增一组“能力规格（capabilities）”的 OpenSpec delta，用于定义各系统的最小需求与场景。
- 定义模块边界与依赖方向（世界 → NPC/采集/天气 → 经济/制造 → 战斗/生命周期等），避免强耦合。
- 明确 Godot 4.5 + GDScript 强类型、数据驱动、信号解耦等工程约定。

## Collaboration Model
- 你（Godot 编辑器）：负责所有场景创建、子节点搭建、资源与属性绑定（含动画、碰撞形状、层/遮罩、导出变量赋值等）。
- 我（脚本/指导）：只负责编写挂载在节点上的脚本（GDScript），并提供在 Godot 编辑器内创建/配置场景的明确步骤清单。
- 提案阶段不写任何实现代码；仅在你批准后进入实现阶段。

## Clarified Decisions
- 游戏类型：横版平台跳跃沙盒（CharacterBody2D + 重力/跳跃等），不是俯视角。
- 多图层战斗：同屏“碰撞/交互层”切换模型（不切换到独立子场景）。
- 当前状态：你尚未批准进入实现阶段（仅保持 proposal）。

## Impact
- Affected specs (new capabilities proposed):
  - world-exploration
  - npc-interaction
  - settlement-building
  - layered-combat
  - character-progression
  - lineage-systems
  - crafting-and-alchemy
  - gathering
  - trading
  - weather-and-ecology
  - formations
  - industrial-circuits
- Affected code (expected, later implementation): `res://scenes/` 与未来新增的系统脚本目录（如 `res://src/`）
