# Design: 完整游戏架构与美化方案

## 1. 游戏状态管理 (Game Manager)
引入 `GameManager` 单例，负责管理游戏的高层状态：
- `START_MENU`: 显示主菜单。
- `PLAYING`: 正常游戏逻辑。
- `PAUSED`: 游戏暂停，UI 拦截输入。
- `REINCARNATING`: 玩家死亡，进入子嗣选择界面。
- `GAME_OVER`: 彻底失败（无子嗣可继承）。

## 2. UI 主题与动画 (UI Theme & Animations)
- **全局主题**: 创建 `res://assets/ui/main_theme.tres`，定义通用的面板样式 (StyleBoxFlat/Texture)、字体大小和颜色。
- **窗口控制器**: `UIManager` 增加对 `CanvasLayer` 的层级管理，并支持通过 `Tween` 实现窗口的缩放/淡入淡出效果。
- **HUD**: 实时显示 `GameState` 中的数据（寿命进度条、金币数量、当前天气）。

## 3. 视觉反馈系统 (Visual Feedback)
- **屏幕抖动**: `Camera2D` 脚本增加 `shake` 方法，由 `DiggingManager` 和 `CombatManager` 调用。
- **粒子系统**: 预留 `GPUParticles2D` 节点池，用于挖掘碎屑、攻击火花、升级特效。
- **图层视觉**: 使用 `CanvasModulate` 或 Shader 实现非活跃图层的变暗效果。

## 4. 存档与继承逻辑
- **存档槽位**: 支持 3 个独立的存档槽位。
- **继承数据流**: 
    1. 玩家死亡 -> 触发 `GameManager` 切换状态。
    2. 打开转生 UI -> 从 `GameState.lineage_data` 读取成年子嗣。
    3. 选择子嗣 -> 将子嗣属性写入 `player_data` -> 刷新玩家实例 -> 保留背包中标记为“遗产”的物品。

## 5. 14 大系统深度集成
- **AI**: 使用简单的行为树或状态机组件，支持 NPC 在城镇闲逛和在野外捕食。
- **工业**: 电路节点支持“能量流”传递，自动采矿机需要连接到电源节点才能工作。
- **天气**: 天气控制器根据随机权重切换状态，并改变全局光照和玩家移动速度乘数。
