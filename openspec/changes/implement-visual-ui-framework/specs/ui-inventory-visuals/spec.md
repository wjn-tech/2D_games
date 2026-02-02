# Capability: ui-inventory-visuals

## ADDED Requirements

### Requirement: 网格化背包显示
背包界面必须以网格形式展示 `InventoryManager` 中的所有槽位，并实时反映物品数量与图标。

#### Scenario: 采集木头后背包更新
- **Given** 玩家采集了 10 个木头。
- **When** `InventoryManager` 发出 `inventory_changed` 信号。
- **Then** 背包 UI 自动刷新，对应的格子里显示木头图标和数字 "10"。

### Requirement: 物品拖拽与交换
玩家必须能够通过鼠标拖拽在不同槽位间移动物品。

#### Scenario: 交换两个物品的位置
- **Given** 玩家左键按住槽位 A 中的物品并拖动到槽位 B。
- **When** 在槽位 B 释放鼠标。
- **Then** 槽位 A 与槽位 B 的物品数据在 `InventoryManager` 中完成交换，UI 同步更新。
