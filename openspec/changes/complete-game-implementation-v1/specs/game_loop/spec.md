# Capability: Game Loop Management

## ADDED Requirements

### Requirement: 游戏状态切换 (Game State Transitions)
系统必须 (MUST) 能够管理游戏在不同阶段（菜单、运行、暂停、转生）之间的切换。

#### Scenario: 玩家死亡触发转生
- **Given** 玩家的寿命或生命值归零。
- **When** 死亡逻辑触发。
- **Then** 游戏进入 `REINCARNATING` 状态，暂停世界运行，并弹出子嗣选择界面。

### Requirement: 存档与加载 (Save & Load)
系统必须 (MUST) 支持多档位存档，并能持久化所有核心系统状态。

#### Scenario: 从主菜单加载存档
- **Given** 玩家在主菜单选择了一个有效的存档槽位。
- **When** 点击“加载”。
- **Then** 系统读取 `.save` 文件，恢复 `GameState`、`Inventory` 和 `TileMap` 状态，并切换到 `PLAYING` 状态。
