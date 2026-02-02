# Proposal: Enhance Digging Visuals

## Change ID
`enhance-digging-visuals`

## Overview
这一更改旨在提升挖掘瓦片（Digging）时的视觉反馈质量。目前的单纯“白色方块缩放”将被替换为：
1. **物块逐渐碎裂效果**：根据挖掘进度（0-100%）动态切换碎裂贴图（类似 Minecraft/Terraria）。
2. **渐进式尘土粒子**：在挖掘过程中，根据瓦片材质持续产生飞溅粒子。

## Context
当前 `DiggingManager.gd` 使用一个简单的程序化生成的 `Sprite2D` 进行缩放和透明度变化。这种方式缺乏“阻击感”和行业标准沙盒游戏的颗粒度。

## Proposed Changes
- **Cracking System**: 引入一个具有 10 个阶段的碎裂纹理序列。
- **Dust System**: 在 `DiggingManager` 的 `mine_tile_step` 中集成持续的粒子发射。
- **Material Awareness**: 碎裂效果和粒子的颜色将根据瓦片材质（草、石、木）自动适配。

## Risks
- **性能**: 大量粒子可能在高吞吐量挖掘时造成卡顿（需使用 `GPUParticles2D` 或受限的 `CPUParticles2D`）。
- **资源缺失**: 如果没有预置的 10 帧碎裂贴图，需要程序化生成一套更好的裂痕。
