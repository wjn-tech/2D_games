# Design: Advanced Merchant & Trading System

## Architecture Overview
交易系统将从“临时脚本逻辑”转向“数据驱动的系统”。核心在于解耦商人的身份（NPC）与其持有的商店逻辑（Inventory + Profile）。

## Components

### 1. MerchantProfile (Resource)
定义一个商人“应该”卖什么的静态模板。
- `possible_items: Array[WeightedItemData]`: 包含 item_data、权重、最小/最大数量。
- `restock_interval: float`: 补货的时间间隔（游戏内小时或天）。
- `base_multiplier: float`: 基础价格系数。

### 2. MerchantNPC (Refactor)
- 持有一个 `Inventory` 实例作为实时的商店库存。
- 持有一个 `MerchantProfile` 引用。
- 逻辑：在 `_ready` 或指定触发时调用 `restock()`。

### 3. TradeManager (Autoload)
- 处理购物车逻辑（已存在）。
- **New**: 处理玩家与商人的“货币交换”逻辑的标准化细节。
- **New**: 处理商人的库存扣除逻辑（即交易完成时从商人 Inventory 移除物品）。

## Trading Logic Flow
1. **Interaction**: 玩家与 NPC 交互，触发 `_open_trade`。
2. **Setup**: `TradeWindow` 被打开，`TradeManager` 设置 `current_merchant`。
3. **Display**: `TradeWindow` 从商人的 `Inventory` 资源中提取 slots 并渲染。
4. **Checkout**: `TradeManager` 扣除玩家金钱 $\rightarrow$ 增加玩家物品 $\rightarrow$ 扣除商人库存。

## Trade Window Enhancements
- 增加“出售模式”：允许玩家从自己的背包中选择物品卖给商人。
- 价格动态计算：$Price = ItemValue \times MerchantMultiplier \times Scale$。
