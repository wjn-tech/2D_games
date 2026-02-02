## Context
本 change 目标是为大型系统群提供可扩展的模块化骨架，并用 OpenSpec 先锁定“最小可用需求”。当前工程为 Godot 4.5 2D 原型，仅含少量脚本与场景。

## Collaboration Contract
- 你负责：场景创建、节点层级、资源导入、动画与碰撞配置、Layer/Mask、导出变量赋值、UI 节点搭建。
- 我负责：节点上挂载的 GDScript 编写、模块化目录与脚本结构、以及“在编辑器里怎么搭”的逐步指引。
- 原则：脚本通过 `@export` 暴露引用点；你在编辑器中完成绑定，避免脚本里硬编码场景路径。

## Goals / Non-Goals
- Goals:
  - 以 capability 为边界拆分模块，建立清晰依赖方向。
  - 数据驱动（Resource/配置）优先，减少硬编码。
  - 通过信号/事件实现跨模块解耦。
  - 先完成 MVP 玩法闭环，再逐步扩展深度。
- Non-Goals:
  - 不在本提案阶段承诺完整内容量（大量 NPC/配方/生态复杂度等）。
  - 不在未评审通过前直接开始实现代码。

## Decisions
- 模块边界：按 OpenSpec capabilities 建目录与 API（例如 `world_exploration/`, `npc_interaction/`）。
- 通信方式：模块对外仅暴露“接口节点/服务脚本”与 `signal`，内部节点结构不被外部依赖。
- 数据格式：优先 Godot `Resource`（便于编辑器可视化与导出），必要时可辅以 JSON 作为只读数据源。
- 游戏类型：横版平台跳跃沙盒（保留当前 CharacterBody2D + 重力/跳跃方向）。
- 分层/多图层战斗：同屏“碰撞层/遮罩 + 分组”建模；通过门/开关切换玩家与实体所在 layer，从而改变可交互对象集合（不切换到独立子场景）。

## Godot Editor Setup Guidance (manual)
以下是“实现阶段”我会按任务逐步提供的编辑器侧操作类型（你来执行）：

### 1) 创建一个系统测试场景（推荐）
- 创建新场景：`Node2D` 作为根（例如 `WorldTest`）。
- 添加玩家实例：实例化现有 `player.tscn`（或你后续创建的新玩家场景）。
- 添加 Camera2D：跟随玩家（或将 Camera2D 作为玩家子节点）。
- 添加地面：`StaticBody2D` + `CollisionShape2D`（你负责形状与位置）。

### 2) NPC 场景约定（中立/敌对/商人）
- 根节点建议：`CharacterBody2D` 或 `Node2D`（根据是否需要物理移动）。
- 必备子节点建议：
  - 可交互区域：`Area2D` + `CollisionShape2D`
  - 可视：`Sprite2D` 或 `AnimatedSprite2D`
- 脚本挂载：把我提供的 NPC 脚本挂在 NPC 根节点上。
- 导出变量绑定：在 Inspector 给脚本的 `@export` 字段绑定对应子节点引用。

### 3) 门/开关与图层切换（分层战斗）
- 创建门节点：`Area2D`（检测进入）+ `CollisionShape2D`。
- 配置 Layer/Mask：
  - 门的 `collision_layer/mask` 与玩家交互层一致
  - 目标图层切换相关字段通过脚本 `@export` 暴露（你在 Inspector 选择枚举/数字）
- 运行时验证：通过门后，玩家仅与目标层对象发生碰撞/交互。

### 4) 采集点/资源点
- 创建资源点：`Area2D` + `CollisionShape2D` + 可视节点。
- 脚本挂载：资源点脚本挂在 Area2D 或其父节点。
- 资源数据绑定：把材料 `Resource`（你创建 `.tres`）绑定到脚本导出字段。

### 5) 制造/交易/生命周期的“入口节点”
- 你创建入口（例如一个 `Area2D` 或 UI Button）作为交互触发点。
- 我提供脚本只负责：校验条件、发出信号、写入数据、调用服务接口。
- UI 具体布局与节点树由你来做；脚本只要求最小的引用点（通过 `@export` 绑定）。

## Risks / Trade-offs
- 需求规模大：若一次性实现全部系统，容易失控 → 通过 MVP 垂直切片与后续拆分 proposals 控制风险。
- 过度单例：Autoload 过多会变成全局耦合 → 仅保留少量基础服务，其它系统挂在场景树并通过依赖注入/信号连接。

## Migration Plan
当前为原型工程：以增量方式引入模块目录与新系统，不强制立即重构已有 `scenes/player.gd`，但后续可逐步迁移到统一架构。

## Open Questions
- 世界是否需要分块加载/流式加载？（影响大世界实现复杂度）
- 生命周期与时间推进机制：是实时、日夜循环、还是回合式/跳时？
