## 1. Proposal validation
- [x] 1.1 补全并校对本 change 的所有 delta specs（每条 Requirement 至少 1 个 Scenario）
- [x] 1.2 运行 `openspec validate add-open-world-sandbox-systems --strict` 并修复校验问题

## 2. Approval & clarifications (implementation-gated)
- [x] 2.1 确认游戏视角与移动形态：横版平台跳跃
- [x] 2.2 确认“多图层战斗”定义：仅切换碰撞/交互层（同屏隔离）
- [x] 2.3 你明确批准开始实现（OpenSpec Stage 2）

## 3. Architecture foundations (implementation-gated)
- [x] 3.1（我：脚本）定义模块目录结构（例如 `res://src/` 下按 capability 分包）
- [x] 3.2（我：脚本）定义“数据资源”基类（物品、配方、NPC、建筑、天气等）与加载策略
- [x] 3.3（我：脚本）定义事件/信号总线约定（跨模块通信）
- [x] 3.4（我：脚本）定义存档/读档接口（最小可用：玩家位置、背包、世界时间）
- [x] 3.5（你：编辑器）创建/调整测试场景并按我给的步骤挂载脚本、绑定导出变量

## 4. MVP vertical slice (implementation-gated)
- [x] 4.1 世界：可进入至少一个区域/地块并生成/摆放最小资源点（我：脚本生成/逻辑；你：编辑器摆放/绑定）
- [x] 4.2 NPC：至少 1 个中立 NPC（可交互）与 1 个敌对 NPC（可触发战斗）（我：脚本；你：编辑器场景/节点）
- [x] 4.3 采集/制作：采集 1 种材料 → 合成 1 种物品（我：脚本/数据资源；你：编辑器资源/配方绑定）
- [x] 4.4 交易：与商人 NPC 买/卖 1 种物品（我：脚本；你：编辑器 NPC/库存/界面节点搭建）
- [x] 4.5 分层战斗：通过门在 2 个“战斗图层”间切换并影响交互/碰撞（我：脚本；你：编辑器层/遮罩/门节点）
- [x] 4.6 生命周期：可建立婚姻关系 → 生成子嗣 → 角色死亡后继承（保留装备）（我：脚本/数据；你：编辑器交互入口节点）
