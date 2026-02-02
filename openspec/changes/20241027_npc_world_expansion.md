# 提案：NPC 与大世界探索扩展 (NPC & World Exploration Expansion)

## 1. 目标 (Goals)
完善大世界探索体验，增加 NPC 的深度交互，实现 10 项核心需求：
- 气泡对话系统。
- 永久存在的 NPC。
- 区域化 NPC 生成（营地、城镇）。
- 交易、任务、招募系统。
- 动态阵营与群体 AI。
- 战争迷雾与 POI 探索。

## 2. 架构变更 (Architectural Changes)

### 2.1 NPC 系统增强
- **SpeechBubble.tscn**: 新的 UI 组件，挂载在 NPC 头顶，用于显示简短对话。
- **BaseNPC.gd**: 扩展 AI 状态机，增加 `TRADING`, `FOLLOWING`, `QUEST_GIVER` 状态。
- **InteractionManager**: 处理玩家与 NPC 的交互逻辑（按 E 键触发）。

### 2.2 世界生成增强
- **WorldGenerator.gd**: 
    - 增加 `spawn_poi(type, position)` 函数，生成营地或小镇。
    - 增加 `spawn_npc_by_biome(biome_type, count)`。
    - 记录已生成的 NPC 坐标，确保持久化。

### 2.3 探索系统
- **FogOfWar.tscn**: 使用 `TileMapLayer` 或 `CanvasLayer` 实现迷雾遮罩。
- **DiscoveryManager**: 记录玩家已探索的区域和发现的 POI。

## 3. 详细设计 (Detailed Design)

### 3.1 气泡对话 (Bubble Dialogue)
- 玩家靠近 NPC 时，NPC 随机播放气泡文字。
- 交互时，弹出选项（交易、任务、招募）。

### 3.2 招募与跟随 (Recruitment)
- 检查 `CharacterData.loyalty`。
- 招募后，NPC 进入 `FOLLOWING` 状态，使用简单的 A* 或距离跟随逻辑。

### 3.3 阵营与群体 AI (Alignment & Group AI)
- 增加 `FactionManager` 全局单例。
- 当玩家攻击某个阵营的 NPC 时，降低该阵营声望。
- 群体意识：NPC 受到攻击时，向半径 500 像素内的同阵营 NPC 发送 `help_requested` 信号。

## 4. 实施计划 (Implementation Plan)
1. **基础组件**: 实现 `SpeechBubble` 和 `InteractionManager`。
2. **世界扩展**: 修改 `WorldGenerator` 增加 POI 和 NPC 生成。
3. **交互逻辑**: 实现交易窗口和任务数据结构。
4. **探索系统**: 实现战争迷雾。
5. **AI 升级**: 实现跟随逻辑和群体仇恨。
