## ADDED Requirements

### Requirement: Runtime SHALL Not Create Upward Insertion Paths
液体运行时 SHALL 不创建向上方新增液体质量的行为路径，任何质量迁移必须满足重力优先与可解释的局部守恒转移。

#### Scenario: Active-cell simulation step
- **WHEN** 某液体单元执行一次主路径模拟
- **THEN** 该步不允许向 `y-1` 方向新增液体写入
- **AND** 仅允许向下或受限侧向转移（满足容量与可达约束）

#### Scenario: Historical patch compatibility
- **WHEN** 代码中存在历史补丁函数或兼容垫片
- **THEN** 这些路径不得向上方单元执行新增液体写入
- **AND** 不得作为运行时正确性的必要条件

### Requirement: Runtime SHALL Converge Bubbles Through Core Flow Path
液体系统 SHALL 通过主模拟路径完成空泡收敛，不依赖后置补丁 pass 才能消除可达空泡。

#### Scenario: Enclosed bubble under active simulation
- **WHEN** 水体内部出现可达且非稳定空泡
- **THEN** 空泡体积在有界步数内下降
- **AND** 收敛过程保持质量守恒

#### Scenario: Near-equilibrium thin-film cavity
- **WHEN** 空泡邻域处于低流量薄膜状态
- **THEN** 系统仍应保持可推进收敛
- **AND** 不得长期停留在“无移动但未稳定”的假稳态

### Requirement: Cell Representation SHALL Keep Liquid Bottom-Anchored
同一格内液体表达 SHALL 始终以底部占据为准，避免出现同格悬浮层或视觉假空洞。

#### Scenario: Single cell render mapping
- **WHEN** 某单元液体量处于 `(0, 1]`
- **THEN** 渲染高度从格子底部向上累积
- **AND** 不得在该格内部出现顶部贴附而底部留空的表现

#### Scenario: Vertical continuity with thin links
- **WHEN** 上下相邻单元以薄膜量保持连通
- **THEN** 连通表达仍遵守各自单元底部占据规则
- **AND** 不得通过上方插液制造伪连通

### Requirement: Codebase SHALL Remove Invalid Bubble Patch Surface
代码库 SHALL 移除无效补丁面，避免失活逻辑继续充当行为合同。

#### Scenario: Runtime loop integrity
- **WHEN** `_process` 执行液体模拟
- **THEN** 行为来源应可追溯到主路径和明确启用的流程
- **AND** 不得依赖已失活补丁函数达成核心验收

#### Scenario: Test contract alignment
- **WHEN** 回归测试验证空泡与沉底行为
- **THEN** 测试应针对运行时有效路径
- **AND** 不得把仅历史补丁函数的结果当作必需验收条件
