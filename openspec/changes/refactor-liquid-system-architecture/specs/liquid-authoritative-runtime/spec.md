## ADDED Requirements

### Requirement: Liquid Runtime SHALL Preserve Mass Across Simulation and Chunk Lifecycle
液体运行时 SHALL 在模拟步进、跨区块交接、区块卸载与保存恢复全过程中保持质量守恒。

#### Scenario: Per-tick conservation in active simulation
- **WHEN** 任意活跃液体单元在一个模拟 tick 内完成垂向/侧向/压差转移
- **THEN** 来源与目标单元的液体总量变化保持守恒
- **AND** 不允许出现负质量或超容量写入

#### Scenario: Conservation during chunk boundary handoff
- **WHEN** 液体尝试流向暂不可写的相邻区块
- **THEN** 该流量进入可恢复的边界交接状态
- **AND** 目标区块可写后回放交接流量且总量守恒

#### Scenario: Conservation across save and reload
- **WHEN** 玩家在液体演化过程中执行保存、卸载、重载
- **THEN** 重载后液体总量与保存时一致（允许固定精度量化误差范围）
- **AND** 不得因生命周期切换丢失边界交接中的流量

### Requirement: Liquid Runtime SHALL Prioritize Downward Reachability and Bounded Equalization
液体主求解路径 SHALL 优先满足垂向可达流动，并在可达约束下执行有界侧向均压，避免长期空泡与反直觉悬滴。

#### Scenario: Vertical path available
- **WHEN** 源单元存在可写且可达的下方路径
- **THEN** 本轮求解优先执行垂向转移
- **AND** 不得出现优先侧漂导致的反重力观感

#### Scenario: Temporary vertical blocking
- **WHEN** 垂向路径因冷却或下游短时阻塞暂不可执行
- **THEN** 系统必须进行受控延迟重试
- **AND** 侧向行为不得制造新增悬空滴水模式

#### Scenario: Internal cavity convergence
- **WHEN** 大水体内部存在可连通且非稳定的空泡结构
- **THEN** 主路径在有界时间内降低空泡体积
- **AND** 空泡不会长期停留在可达均衡态之外

### Requirement: Liquid Scheduler SHALL Provide Fairness Under Budget Constraints
调度器 SHALL 在帧预算约束下保证热点吞吐与公平性，避免局部永久饥饿。

#### Scenario: High-load waterfall scene
- **WHEN** 同时存在大量活跃液体单元且预算紧张
- **THEN** 调度器仍能在连续帧中推进每个活跃区域
- **AND** 不允许单一局部永久占用预算导致其他区域冻结

#### Scenario: Cooldown and retry orchestration
- **WHEN** 单元被冷却门限、重试延迟或边界交接暂时阻塞
- **THEN** 该单元进入可追踪的等待队列
- **AND** 到期后按公平策略重新激活，不依赖全量扫描

### Requirement: Liquid Rendering Contract SHALL Remain Consistent With Authoritative Simulation
渲染层 SHALL 与权威模拟合同一致，避免逻辑连通与视觉结果长期不一致。

#### Scenario: Thin-film continuity
- **WHEN** 某单元承担逻辑连通职责但液体量处于低可见区间
- **THEN** 渲染策略需保持最小可感知连通表达
- **AND** 不得长期显示为视觉断裂导致“浮空水体”错觉

#### Scenario: Incremental rendering updates
- **WHEN** 模拟步仅影响局部液体区域
- **THEN** 渲染更新应以增量脏区为主
- **AND** 不得对全量液体状态执行每帧深复制刷新
