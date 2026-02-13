# Change: Perfect Merchant Trading System

## Why
当前商人的交易系统非常初级：商人没有自动补货机制，且其库存管理依赖于一个简单的数组而非标准的 `Inventory` 系统。这导致交易界面功能受限，且难以实现动态库存或多样化的商人类型。为了提升游戏性，需要一个完善的补货系统和更稳健的库存管理机制。

## What Changes
- **MODIFIED**: `MerchantNPC` 从直接管理 `Array[BaseItem]` 改为使用 `Inventory` 资源。
- **ADDED**: 引入 `MerchantProfile` 资源，用于定义不同类型商人的物品池和补货权重。
- **ADDED**: 实现 `TradeManager` 的补货(Restock)逻辑，支持基于游戏时间或特定触发器的补货。
- **MODIFIED**: 更新 `TradeWindow` UI，支持显示物品数量、正确计算价格倍率，并支持“反向交易”（玩家卖给商人）。
- **BREAKING**: 移除 `MerchantNPC.merchant_inventory` 字段，改用标准的 `inventory` 属性。

## Impact
- **Affected Specs**: `Trading`, `NPC`, `Inventory`.
- **Affected Code**: 
  - `src/systems/trading/merchant.gd`
  - `src/systems/trading/trade_manager.gd`
  - `scenes/ui/trade_window.gd`
  - `src/systems/inventory/inventory.gd` (确认适配)
