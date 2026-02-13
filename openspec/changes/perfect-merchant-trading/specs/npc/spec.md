# Capability: NPC Behavior (Trading)

## MODIFIED Requirements

### Requirement: Merchant Role Implementation
**MODIFIED**: 商人不再是一个仅持有静态数组的实体，而是一个具备动态资源管理的复杂实体。

#### Scenario: NPC-driven Trade Initialization
- **WHEN** 触发交互事件（如 E 键）
- **THEN** MerchantNPC 必须确保其 `Inventory` 和 `TradeManager` 会话处于就绪状态。
- **AND** 调用 UIManager 以正确参数打开 TradeWindow。
