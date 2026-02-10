# Trading Interface System

## ADDED Requirements

#### Scenario: Cart-Based Trading
Given the player opens a trade with a Merchant
Then the UI should display three areas:
1. **Merchant Stock**: Items available for purchase.
2. **Player Cart**: Items currently selected for this transaction.
3. **Transaction Summary**: Total Cost, Current Balance, Predicted Balance.

#### Scenario: Adding to Cart
Given the player clicks an item in "Merchant Stock"
Then a copy (phantom) of the item is added to "Player Cart"
And the Total Cost is increased by the item's `buy_price`
And the quantity in "Merchant Stock" remains visually but logic tracks pending decrement (if finite stock).

#### Scenario: Transaction Validation
Given the Cart contains items with a total value of 500 gold
And the player has 400 gold
When the player attempts to "Checkout"
Then the "Confirm" button should be disabled
And the Total Cost label should turn Red.

#### Scenario: Successful Checkout
Given a valid cart
When "Checkout" is pressed
Then `TradeManager.execute_transaction(cart_items, merchant)` is called
And items are added to Player Inventory
And Money is deducted from Player Data
And the UI refreshes to clear the cart and update stock.

#### Logic: Price Multipliers
Given a Merchant with `relationship_level`
- If Relationship > 80: Price Multiplier is 0.8x (20% Discount)
- If Relationship < 20: Price Multiplier is 1.5x (50% Markup)
- Otherwise: Price Multiplier is 1.0x

## Architecture

### TradeManager (Autoload)
- `current_cart: Array[Dictionary]` (Items to buy)
- `calculate_total(cart, merchant) -> int`
- `validate_transaction(total, player_money) -> bool`
- `execute_transaction(cart, merchant)`
