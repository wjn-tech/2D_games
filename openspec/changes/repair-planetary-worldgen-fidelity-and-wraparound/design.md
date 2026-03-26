## Context
当前世界生成已经具备行星预设、区块流式和 107 步映射目录，但在真实游玩时出现“回环失败、分层不明显、生态稀疏、边界切直线”的组合问题。根因不在单一函数，而在拓扑语义、宏观布局、材质互混和边界塑形之间缺少统一验收闭环。

## Goals / Non-Goals
- Goals:
  - 保证玩家跨越世界边界时确定性回环。
  - 提升地下层次与液体可见性，形成稳定探索反馈。
  - 提高地表生态覆盖度与多样性。
  - 消除直线式生态切边，改为自然过渡。
  - 将 107 步映射升级为可核验行为。
- Non-Goals:
  - 不引入全新生态体系或大型新资源包。
  - 不在本次变更中重做战斗、NPC、经济等非世界生成模块。

## Decisions
- Decision 1: Topology-first wraparound contract
  - 玩家位置、相机限制、chunk 查询必须共享相同坐标系定义，禁止“生成层回环但实体层不回环”。
  - 采用 topology 提供的周长与 wrap 函数作为单一真值来源。

- Decision 2: Underground layering and liquid visibility as first-class requirements
  - 将“土层厚度变化、石土互混、液体口袋”定义为可测目标，而非仅依赖噪声参数“看起来可能出现”。
  - 引入 seed 矩阵验收，避免单 seed 偶然通过。

- Decision 3: Biome coverage budget by preset
  - 对 small/medium/large 预设定义最小 major biome 数量与单 biome 最大占比，防止宏观布局过度集中。
  - WorldStructurePlanner 负责宏观配额，WorldGenerator 负责边界细化。

- Decision 4: Domain-warped boundary pipeline
  - 边界采用“低频位移 + 中频扰动 + 局部抖动”的三层方案，并加入纵向去相关，避免上下完全同相。
  - 过渡带宽度采用范围约束，避免重新退化为硬切边或过宽糊边。

- Decision 5: 107-step audit from catalog to behavior
  - 继续保留 step catalog 与 skip reason，但新增“行为映射断言”：关键步骤必须对应可观测地形结果。
  - 特别约束材质互混步骤，避免仅有标签无效果。

## Risks / Trade-offs
- 更自然边界和更高生态密度会增加生成成本。
  - Mitigation: 约束在 chunk 预算内，优先列级缓存与复用噪声采样。
- 液体可见性提升可能影响早期可达性。
  - Mitigation: 在出生安全区与关键路径保持液体风险上限。
- 回环修复可能影响相机、粒子和网络插值（如未来联机）。
  - Mitigation: 明确跨边界时的视觉平滑策略与状态同步点。

## Migration Plan
1. 为新生成规则增加 world metadata 版本号。
2. 对旧存档提供兼容分支：
   - 无法满足新规则的存档提示重建世界。
   - 可兼容存档通过一次性重索引修复 wrap 坐标语义。
3. 记录变更后 seed 验收报告，作为回归基线。

## Open Questions
- 液体系统目标是“先可见、后拟真”还是同步追求 CA 稳定求解？
- 是否需要在 UI 上展示当前世界生态覆盖统计，便于玩家自检？