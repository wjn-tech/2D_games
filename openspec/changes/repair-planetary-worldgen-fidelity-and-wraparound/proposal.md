# Change: Repair Planetary Worldgen Fidelity and Wraparound

## Why
近期真实游玩反馈暴露了 4 个核心问题：
- 到达世界边缘后没有无缝回环，行星拓扑体验失效。
- 地底分层不明显且液体缺失，地下探索缺乏层次感。
- 生态区数量偏少，长距离探索获得的地表变化不足。
- 生态区边界仍呈直线切边，不符合自然地貌预期。

本次 proposal 也包含一次明确的自我反省：此前工作强调了“107 步映射结构”和“预加载门控”，但没有把“视觉与可玩验收结果”作为同等级约束，导致实现与体验之间出现落差。

## What Changes
- 新增行星坐标回环约束：将玩家/相机/区块查询统一到同一套 world-topology 坐标语义，确保穿越东西边界必然回到对侧。
- 新增地底分层与液体可见性约束：要求土层厚度、石层分布、地下液体口袋在多 seed 下可观测且稳定复现。
- 新增地表生态覆盖度约束：按世界尺寸预设定义最低 major biome 数量与最大片段上限，防止“只有 2-3 个生态区”的情况。
- 新增边界自然化约束：将直线切边替换为 domain-warp + blend corridor + 深度去相关方案。
- 新增 107 步审计完整性约束：将“步骤存在”升级为“步骤行为可核验”，尤其覆盖“土中夹石、石中夹土”类材质互混行为。

## Impact
- Affected specs:
  - planetary-player-wraparound
  - underground-strata-and-liquid-fidelity
  - surface-biome-coverage
  - biome-boundary-naturalization
  - terraria-107-step-audit-fidelity
- Affected code (apply stage):
  - src/systems/world/world_generator.gd
  - src/systems/world/world_topology.gd
  - src/systems/world/world_structure_planner.gd
  - src/systems/world/infinite_chunk_manager.gd
  - scenes/player.gd
  - startup/save metadata paths used by world generation
- Related existing changes:
  - align-worldgen-to-terraria-107-steps-and-full-preload
  - shift-worldgen-to-planetary-wraparound
  - update-worldgen-staged-passes-and-bedrock-floor

## Scope Notes
- 本提案只定义规范与验收，不在 proposal 阶段写实现代码。
- 不追求 1:1 复制 Terraria 全部系统，仅要求当前映射步骤具备可验证行为与观感目标。
- 若现有存档缺少新元数据，apply 阶段需提供迁移或重建策略。