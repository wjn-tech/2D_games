# Tasks: 实现全可视化交互框架

## 1. 基础框架搭建 (Foundation)
- [ ] 1.1（我：脚本）创建 `src/ui/ui_manager.gd` 并注册为 Autoload。
- [ ] 1.2（我：脚本）定义 `BaseWindow` 基类，处理通用开关逻辑与信号。
- [ ] 1.3（你：编辑器）创建 `scenes/ui/main_canvas.tscn` 作为 UI 根节点，包含 HUD 层与 Window 层。

## 2. 背包与物品可视化 (Inventory UI)
- [ ] 2.1（我：脚本）编写 `src/ui/inventory/inventory_ui.gd`，绑定 `InventoryManager`。
- [ ] 2.2（我：脚本）编写 `src/ui/inventory/item_slot_ui.gd`，处理单个格子的显示与点击。
- [ ] 2.3（你：编辑器）搭建 `InventoryWindow.tscn`（含 GridContainer）与 `ItemSlot.tscn`（含 TextureRect 和 Label）。

## 3. 建造与快捷栏 (Building & Hotbar)
- [ ] 3.1（我：脚本）编写 `src/ui/hud/hotbar_ui.gd`，支持数字键切换建造蓝图。
- [ ] 3.2（我：脚本）在 `BuildingManager` 中增加 UI 交互接口（如 `select_blueprint(id)`）。
- [ ] 3.3（你：编辑器）搭建 HUD 快捷栏界面，绑定建筑图标。

## 4. NPC 对话与交易 (NPC UI)
- [ ] 4.1（我：脚本）编写 `src/ui/npc/dialogue_ui.gd`，支持打字机效果与选项分支。
- [ ] 4.2（我：脚本）编写 `src/ui/npc/trade_ui.gd`，实现买卖逻辑与价格计算。
- [ ] 4.3（你：编辑器）搭建对话框与交易双栏界面。

## 5. 角色属性与血脉 (Character UI)
- [ ] 5.1（我：脚本）编写 `src/ui/character/stats_ui.gd`，显示血量、法力、寿命等。
- [ ] 5.2（我：脚本）编写 `src/ui/character/lineage_tree_ui.gd`，可视化展示家族传承。
- [ ] 5.3（你：编辑器）搭建属性面板与树状图界面。

## 6. 工业与电路可视化 (Industrial UI)
- [ ] 6.1（我：脚本）编写 `src/ui/industrial/circuit_config_ui.gd`，支持可视化配置逻辑门。
- [ ] 6.2（你：编辑器）搭建工业设备配置弹窗。

## 7. 验证与优化 (Validation)
- [ ] 7.1 运行 `openspec validate implement-visual-ui-framework --strict`。
- [ ] 7.2 测试所有系统是否都能通过 UI 完成闭环操作。
