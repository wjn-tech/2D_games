# Capability: Cracking Visuals

## MODIFIED Requirements

### Req 1: Progressive Texture Switching
#### Scenario: Digging a stone block
- **Given** 玩家开始挖掘一个硬度为 1.0 的瓦片。
- **When** 挖掘进度达到 30% 时。
- **Then** 对应的瓦片位置应显示第 3 级别的碎裂纹理。
- **When** 挖掘进度达到 90% 时。
- **Then** 对应的瓦片位置应显示第 9 级别的碎裂纹理。

### Req 2: Multi-Tile Support
#### Scenario: Multiple tiles being hit
- **Given** 某些系统同时破坏多个瓦片。
- **Then** 每个挖掘中的瓦片都应在 CrackingLayer 上有独立的裂痕表示，互不干扰。
