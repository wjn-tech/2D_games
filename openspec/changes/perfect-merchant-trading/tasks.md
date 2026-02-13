# Tasks: Perfect Merchant Trading

## 1. Data Layer
- [x] 创建 `WeightedItemData` 辅助类（或 Dictionary 结构）用于物品生成。
- [x] 创建 `MerchantProfile` 资源类，支持物品池定义。
- [x] 定义几个基础测试物品资源（Potion, Bread, BasicBlade）。

## 2. System Layer
- [x] 重构 `MerchantNPC`：
    - 添加 `Inventory` 实例。
    - 实现 `restock()` 方法，根据 `MerchantProfile` 生成随机库存。
    - 在初始化时执行第一次补货。
- [x] 增强 `TradeManager`：
    - 实现 `current_merchant.inventory` 的同步扣除逻辑。
    - 添加 `sell_to_merchant()` 接口，处理玩家回售。

## 3. UI Layer
- [x] 更新 `trade_window.gd`：
    - 适配 `Inventory` 槽位布局业务。
    - 修复 `get_inventory()` 缺失导致的无法加载问题。
    - 添加玩家金钱的实时刷新逻辑。
    - 实现“商品详情”显示（点击商品显示价格和描述）。

## 4. Validation
- [x] 手动测试：在测试场景中放置商人，确认其初始库存不为空。
- [x] 手动测试：完成交易后，检查玩家背包增加、玩家金钱减少、商人库存减少。
- [x] 手动测试：确认补货机制有效（或通过调试按钮触发补货）。
