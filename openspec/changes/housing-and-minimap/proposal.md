# Proposal: Housing Manager and Minimap System

## Problem Statement
随着游戏世界规模的扩大和 NPC 数量的增加，玩家需要一种直观的方式来管理居民及其住所，并能够通过小地图获知自己的地理位置与探索进度。

## Proposed Changes

### 1. Housing Manager (房屋管理器)
- **UI 入口**: 在现有背包/装备界面的侧边栏添加一个“房屋”图标按钮。
- **视图功能**:
    - 点击进入“房屋管理模式”，场景变暗，高亮显示所有检测到的房屋区域。
    - 每个房屋显示状态图标：有效（绿色检查）、无效（红色感叹号）。
    - 悬浮无效房屋时，显示缺失补全建议（如：“缺少光源”、“缺少桌子”、“缺少椅子”、“空间太小”）。
- **NPC 分配**:
    - 提供一个 NPC 头像面板，玩家可以拖拽头像到特定房屋进行手动入住分配。
    - 自动/手动分配切换逻辑。

### 2. Minimap (小地图)
- **UI 位置**: 屏幕右上角 (Top-Right HUD)。
- **渲染技术**:
    - 使用 `SubViewport` 配合专用的 `Camera2D`（设置剔除掩码，仅显示背景和地形）。
    - 或者使用 Canvas 绘图绘制 Tilemap 的缩略点阵（性能更优，适合大世界）。
- **战争迷雾 (Fog of War)**:
    - 仅显示玩家已探索（视野范围内）的区域。
    - 使用 `TextureProgressBar` 或 `CanvasItem` 自定义绘图记录已访问坐标。
- **标记系统**:
    - 显示玩家位置（箭头）。
    - 显示已分配房屋的 NPC 头像图标。

## Technical Implementation

### Housing Manager
- **System**: 扩展 `SettlementManager` 或创建 `HousingManager` 单例。
- **Logic**: 
    - 复用已有的 `HousingScanner` 逻辑。
    - `HousingUI` 节点处理拖拽事件。

### Minimap
- **System**: `MinimapCapture` 脚本附加到玩家。
- **Fog of War**: 维护一个与世界块对齐的二进制位图或低分辨率 texture，记录探索状态。
- **Scaling**: 支持缩放（通过 mouse scroll 在小地图区域）。

## Impact
- 增强玩家对聚落的掌控感。
- 解决在无限随机生成世界中迷失方向的问题。
- 增加 UI 复杂度，需注意 UI 层级管理。
