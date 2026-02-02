# Tasks: Enhance Digging Visuals

- [ ] **Phase 1: Cracking Foundation**
    - [ ] 创建程序化碎裂贴图生成脚本（如果没有外部资源），生成 10 帧裂纹。
    - [ ] 在 `DiggingManager` 中初始化 `CrackingLayer` (TileMapLayer)。
    - [ ] 重构 `_update_cracking_visual` 以使用 `CrackingLayer.set_cell` 替代 `Sprite2D`。

- [ ] **Phase 2: Dust Particle System**
    - [ ] 设计通用的 `DiggingDustParticles` 节点（CPUParticles2D 预设）。
    - [ ] 在 `DiggingManager` 中实现粒子池或单例调用，在挖掘步进中持续发射。
    - [ ] 对接材质颜色识别系统，确保“挖草出绿屑，挖石出灰屑”。

- [ ] **Phase 3: Integration & Polish**
    - [ ] 优化 `mining_progress_map` 清理逻辑，确保瓦片挖完后碎裂层立即清除。
    - [ ] 调整粒子爆发力，增加“物块碎裂感”。
    - [ ] 测试跨区块挖掘时的视觉一致性。
