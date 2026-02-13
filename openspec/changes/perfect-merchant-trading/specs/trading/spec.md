# Capability: Trading

## ADDED Requirements

### Requirement: Merchant Inventory Synchronization
系统必须能够同步商人的 `Inventory` 资源到交易界面。

#### Scenario: Populate Merchant Stock
- **WHEN** 玩家与商人交互
- **THEN** 交易窗口的“Merchant Stock”列应显示商人 Inventory 中的所有有效物品。

### Requirement: Dynamic Price Calculation
交易系统必须根据商人的价格倍率和物品基础价值动态计算最终交易价格。

#### Scenario: Calculate Buying Price
- **WHEN** 玩家将物品加入购物车
- **THEN** 总价计算公式应为 `item.value * merchant.price_multiplier` 的总和。

### Requirement: Automated Restocking
商人系统必须支持基于规则的自动补货。

#### Scenario: Refresh Stock on Initialization
- **WHEN** 商人 NPC 首次生成或游戏开始
- **THEN** 系统应根据 `MerchantProfile` 生成随机物品并填充其 Inventory。
