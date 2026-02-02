# Capability: enchanted-ammo

## ADDED Requirements

### Requirement: 弹药附魔效果
通用弹药应当 (SHALL) 支持附魔状态，并在命中时触发。

#### Scenario: 使用火附魔箭矢攻击
- **Given** 玩家装备了“火附魔箭矢”。
- **When** 箭矢命中敌人。
- **Then** 敌人进入“燃烧”状态，每秒受到持续伤害。
