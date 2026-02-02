# Capability: Dust Particles

## MODIFIED Requirements

### Req 1: Continuous Emission
#### Scenario: Persistent digging
- **Given** 玩家按住鼠标左键持续挖掘。
- **Then** 在点击位置应每秒产生至少 20 个对应瓦片颜色的碎片粒子，向外散射。

### Req 2: Material Color Mapping
#### Scenario: Changing materials
- **When** 挖掘草方块（Grass Block）。
- **Then** 产生的粒子颜色应为绿色（#2d5a27 或近似色）。
- **When** 挖掘岩石（Stone）。
- **Then** 产生的粒子颜色应为灰色（#808080 或近似色）。
