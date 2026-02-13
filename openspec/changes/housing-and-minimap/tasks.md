# Tasks: Housing Manager and Minimap Implementation

## Phase 1: Foundations & Backend (Prioritized)
- [ ] **Housing Data Update**: 
    - 修改 `HousingScanner` 以支持返回房屋的矩形区域和中心坐标。
    - 在现有的 `Resource` 系统中添加 NPC 与房屋的绑定关系持久化。
- [ ] **Minimap Buffer**:
    - 实现 `MinimapManager`，负责记录 Tilemap 到低精度图像的映射。
    - 实现探索足迹记录（Fog of War 数据结构）。

## Phase 2: Minimap UI
- [ ] **HUD Minimap**: 
    - 创建 `minimap.tscn` 并放置在屏幕右上角。
    - 实现实时更新纹理逻辑（分块更新，避免性能瓶颈）。
    - 添加玩家箭头标记。

## Phase 3: Housing Manager UI
- [ ] **Main UI Layout**: 
    - 为 `player_interface` 添加侧边栏切换按钮。
    - 实现 NPC 头像列表。
- [ ] **In-world Indicators**:
    - 实现进入管理模式时，在房屋中心显示的漂浮图标。
    - 实现点击/拖拽分配 NPC 的交互。

## Phase 4: Integration & Polish
- [ ] **BT Updates**: 确保 NPC 行为树会根据手动分配的住所进行移动。
- [ ] **FOW Shader**: 创建一个简单的 Shader 让战争迷雾看起来更平滑。
- [ ] **Persistence**: 确保玩家分配的 NPC 住所在存档中被正确保存。
