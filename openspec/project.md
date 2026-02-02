# Project Context

## Purpose
- 这是一个 Godot 2D 游戏项目（当前为原型阶段）。
- 当前已有：基础玩家移动/跳跃、简单测试场景（`res://scenes/test.tscn`）。
- 长期目标：做一个“可探索的大世界沙盒 + NPC 交互 + 建造 + 多层战斗 + 人物生命周期（婚姻/繁育/继承）+ 制造/交易 + 天气/生态”等系统化玩法的 2D 游戏。

## Tech Stack
- 引擎：Godot 4.5（见 `project.godot` 的 `config/features`）
- 语言：GDScript（强类型/类型标注优先）
- 资产：PNG 像素风贴图与动画序列（`assets/`）
- 主要场景：
	- `res://scenes/test.tscn`（当前 main scene）
	- `res://scenes/player.tscn` + `res://scenes/player.gd`

## Project Conventions

### Code Style
- 严格遵循 Godot 4.5 / GDScript 语言规范：
	- 对外/跨模块 API 必须写类型标注（参数、返回值、字段），避免“全动态”写法。
	- 使用 `@export` 暴露可调参；使用 `@onready` 延迟获取节点引用。
	- 优先用 `signal` + `connect` 做解耦通信；避免硬引用导致循环依赖。
- 命名约定：
	- 文件：`snake_case.gd` / `snake_case.tscn`
	- 变量/函数：`snake_case`
	- 常量：`UPPER_SNAKE_CASE`（如 `SPEED`）
	- 类：如需 `class_name`，使用 `PascalCase`
- 脚本组织：
	- 原型阶段允许脚本与场景同目录（如 `scenes/player.gd`）。
	- 当系统增多时，建议将“系统代码”集中到 `res://src/`（或 `res://systems/`）并通过明确边界拆分模块。

### Architecture Patterns
- 模块化优先：按“能力/系统”拆分（世界、NPC、战斗、建造、经济、天气等），每个模块暴露最小 API。
- 全可视化交互 (Visual-First UI)：所有游戏功能必须通过游戏内 UI 控件（背包、建造菜单、对话框等）实现，严禁依赖控制台或脚本调试指令。
- 数据驱动：配方、物品、NPC 配置、建筑定义等使用 `Resource`（`.tres/.res`）或结构化数据文件统一描述。
- 组合优于继承：用节点组合（例如 `CharacterBody2D` + 子节点组件）或轻量组件脚本组合能力。
- 单例/Autoload 谨慎使用：仅用于“跨场景的基础服务”（存档、时间、全局事件），避免把所有逻辑塞进一个 God Object。

### Testing Strategy
- 当前以“可运行的测试场景/关卡”做回归（例如 `res://scenes/test.tscn`）。
- 未来如需自动化测试，可引入 Godot 测试插件（例如 GUT）或编写最小化的场景级脚本测试；引入前需通过 OpenSpec proposal 明确依赖与约束。

### Git Workflow
- 建议：`main` 保持可运行；功能开发使用短生命周期分支（`feature/<topic>`）。
- 提交信息建议采用语义化前缀：`feat:`, `fix:`, `refactor:`, `docs:`。
- 大改动必须先走 OpenSpec change proposal → 审阅通过后再实现。

## Domain Context
- 玩法域关键词：大世界探索、NPC（敌对/中立/商人）、城邦建造、分层战斗（通过门/开关在图层间移动）、人物属性与寿命、婚姻/繁育/继承、锻造/炼药/弹药、采集、交易、天气、生态、阵法、工业制造电路。
- 当前工程处于原型早期：已有玩家移动/动画切换与基础物理。

## Important Constraints
- 严格使用 Godot 4.5 的语言/工程规范（GDScript 风格、节点生命周期、资源导入）。
- 强调模块化编程：避免跨模块的隐式耦合（例如直接访问彼此内部节点）。
- 需求规模较大：建议按 OpenSpec 提案拆分为多个里程碑与分阶段交付。

## External Dependencies
- 当前无外部服务依赖（离线单机原型）。
- 若未来引入联网、数据库或第三方服务，必须先写 OpenSpec proposal。

