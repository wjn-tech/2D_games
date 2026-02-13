# Tasks: NPC Housing and Settlement System

- [x] **Phase 1: Foundation & Registry**
    - [x] 创建 `TileItemData` 资源类，添加 `target_layer` 与规则标志位。
    - [x] 为现有家具（火把、桌椅、门）添加对应的 Godot 群组标识。
    - [x] 在 `CharacterData` 中增加 `home_pos`, `happiness`, `pylon_unlocked` 字段。

- [x] **Phase 2: Enhanced Placement System**
    - [x] 重构 `BuildingManager` 以支持距离检查、连续摆放与背景墙相邻规则。
    - [x] 优化预览视觉效果（合法：绿色/蓝绿色，非法：红色）。

- [x] **Phase 3: Housing Detection Algorithm**
    - [x] 在 `SettlementManager` 中实现泛洪填充算法（限定 64x64 单区块）。
    - [x] 实现背景墙完整度及家具实体查询。

- [x] **Phase 4: NPC AI & Hammer Tool**
    - [x] 实现“锤子”工具，支持 Layer 2 瓦片移除与物品掉落。
    - [x] 编写 NPC 周期性重生系统 (基于迁徙逻辑)。

- [x] **Phase 5: Happiness, Pylons & UI**
    - [x] 实现社交/环境快乐度计算与晶塔传送服务。
    - [x] 完成“房屋检查模式”核心逻辑与状态查询。
    - [x] 增加可视化 UI 反馈 (通过 UIManager 通知)。
