## Context
当前项目已经具备：
- 基于 chunk 的按需生成与流式加载。
- `critical` / `enrichment` 双阶段框架。
- `WorldTopology` 的深度带定义（含 `terminal` 带）。
- 已有自然洞口与深洞改进提案（可作为本变更的子能力来源）。

但仍存在两个核心问题：
- 新区块加载仍有阶段性峰值，说明生成与应用阶段的职责边界和优先级还不够明确。
- 纵向没有硬性封底机制，导致极深路径可能持续触发更深区块请求。
- 世界表现多样性受限于当前纯色瓦片集规模。
- 液体系统尚未正式接入主项目运行链路。

## Goals / Non-Goals
- Goals:
  - 建立可配置、可验证的 Terraria-core 风格 staged pass worldgen 框架。
  - 对“后阶段覆盖前阶段”的冲突规则进行显式规范。
  - 增加地底基岩封底与下界加载控制，防止无限向下加载。
  - 新增同风格纯色瓦片集扩展能力，支撑多样化地形。
  - 新增液体系统接入能力并保持流式预算安全。
  - 保持 seed/坐标确定性与跨 chunk 连续性。
- Non-Goals:
  - 不实现泰拉瑞亚 107 步逐函数 1:1 复制。
  - 不改动与本问题无关的 UI/NPC 系统。

## Decisions
- Decision: 引入“Terraria 核心逻辑分组映射”的阶段家族，而不是随机 pass 拼接。
  - Why: 用户要求逻辑核心尽量贴近泰拉瑞亚，同时项目仍需保持流式预算与可维护性。
  - Step group mapping（拟）:
    - `foundation_and_relief`：初始化、地形、沙丘/海岸基础、土石互嵌
    - `cave_and_tunnel`：隧道、土层/石层/地表洞穴、大型洞群
    - `biome_macro`：冰雪、丛林、沙漠、地下变体与宏观群系塑形
    - `ore_and_resources`：矿石、宝石、泥沙、微型资源补丁
    - `structures_and_micro_biomes`：房屋/遗迹/神龛/微型群落
    - `liquid_settle_and_cleanup`：液体安置、重力沙补位、最终清理

- Decision: 冲突规则采用“后阶段默认覆盖前阶段 + 显式避让”机制。
  - Why: 与用户给出的泰拉瑞亚覆盖经验一致，且便于控制例外（如 spawn 安全区、关键通路）。

- Decision (Locked 1.B/2.B/3.A/4.A/5.A):
  - `bedrock_start_depth` 与 `bedrock_hard_floor_depth` 按 world-size preset 配置。
  - 采用“封底过渡带 + 硬下界”两段式。
  - 硬下界以下 chunk 请求直接拒绝（不入加载队列）。
  - 允许岩浆湖停留在封底上方，但封底区内不继续向下扩散。
  - 仅新世界启用该边界策略；旧存档不强制迁移。

- Decision: 引入同风格纯色瓦片集扩展流水线。
  - Why: 当前瓦片不足以支撑更接近 Terraria-core 的世界多样化阶段输出。
  - Scope:
    - 地表/地下/深层/封底/液体接触边专用纯色瓦片。
    - 保持现有项目极简纯色视觉语言。
  - Delivery:
    - 先交付最小可用集，再按阶段分批扩容。

- Decision: 液体系统采用“参考算法 + 项目兼容重构”方式接入。
  - Why: 用户提供的参考工程展示了可行方向（PhysicsServer2D 驱动 + 视觉 shader），但需按本项目 streaming、chunk、存档约束重构。
  - Reference input:
    - `d:\godot\fluid-water-physics-2d-simulator-for-godot-4+\README.md`
    - `d:\godot\fluid-water-physics-2d-simulator-for-godot-4+\water2Dsimulation\script\waterGenerator.gd`
  - Phase scope:
    - 首期实现水与岩浆。
    - 同时预留蜂蜜/特殊液体扩展接口。

- Decision: 采用双验收指标约束 Terraria-core 对齐程度。
  - Metrics:
    - `核心阶段覆盖率`
    - `步骤条目覆盖率`
  - Why: 兼顾体系级对齐与可量化条目覆盖，避免“只对齐框架不对齐内容”。

- Decision: `critical` 只保留“立即可玩必需阶段”，其余一律后置。
  - Why: 行走卡顿主要来自新区块首帧峰值，必须保证首帧最小工作集。

## Trade-offs
- 增加阶段控制元数据会提高实现复杂度。
- 基岩封底会改变“无限深探索”玩法，需要明确设计预期。
- 下界请求拒绝策略若处理不当，可能与救援逻辑（freefall rescue）产生交互风险。
- 液体系统若直接按参考工程接入，可能与现有 chunk 生命周期冲突。
- 纯色瓦片扩展若无统一命名规范，后续维护成本会显著上升。

## Migration Plan
1. 在 `WorldTopology` 增加按 world-size preset 的深度边界元数据（仅新世界启用）。
2. 在 `WorldGenerator` 接入 Terraria-core 分组阶段调度与封底判定。
3. 在 `InfiniteChunkManager` 加入硬下界以下请求拒绝策略。
4. 增加同风格纯色瓦片集并绑定到阶段输出映射。
5. 引入液体系统并完成与 chunk 生命周期、性能预算、存档接口的边界适配。
6. 回归验证：固定 seed、固定路线、重复往返、自由落体边界测试。

## Validation Strategy
- 确定性：同 seed/同 chunk 重建结果一致。
- 连续性：跨 chunk seam 无断层。
- 性能：新区块 critical 阶段预算不回退到当前基线之上。
- 边界：到达封底后不再触发无限向下加载链路。
- 视觉：新瓦片集保持当前纯色风格一致性。
- 液体：流动/安置在预算内稳定运行，且不破坏封底规则。

## Open Questions
- 当前无阻塞性开放问题；后续若新增范围将通过增量提案补充。
