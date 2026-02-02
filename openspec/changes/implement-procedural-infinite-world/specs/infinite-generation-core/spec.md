# Capability: Infinite Generation Core

实现地图的区块化动态加载与卸载。

## ADDED Requirements

### Requirement: Deterministic Chunk Generation
系统 SHALL 基于全局种子和区块坐标生成的每一块地形，且在多次加载中 MUST 保持一致。

#### Scenario: Return to explored area
- **Given** 全局种子为 12345
- **When** 玩家移动到坐标 (10000, 0)，区块 A 被生成
- **And** 玩家离开区块 A 视距导致其被卸载
- **And** 玩家重新返回 (10000, 0)
- **Then** 重新生成的区块 A 必须与首次生成时完全相同（除非有玩家修改）

### Requirement: Delta-Only Persistence
系统 SHALL 仅存储玩家对地形的修改（Delta），而非整个区块数据，以节省存储空间。

#### Scenario: Digging a hole
- **Given** 一个由噪声新生成的区块
- **When** 玩家在该区块挖掘了坐标 (5, 5) 的瓦片
- **Then** `DeltaStorage` 应新增一个条目：`{chunk_coord: {(5,5): -1}}`
- **And** 存档文件体积仅增加该条目的字节数

### Requirement: Multi-threaded Loading
生成新区块的过程 SHALL 使用多线程处理，且 MUST 不导致游戏逻辑主线程卡顿。

#### Scenario: Rapid Movement
- **Given** 玩家处于高速移动状态
- **When** 连续 5 个新区块需要加载
- **Then** 生成逻辑应在后台线程排队执行
- **And** 游戏窗口仍能保持 60+ FPS
