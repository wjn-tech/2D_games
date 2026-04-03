## 1. Proposal Alignment
- [x] 1.1 锁定四个 Boss 房“统一模板 + 轻差异化美术”边界。
- [x] 1.2 固化中小型封闭空间阈值（宽度 <= 1400，高度 <= 700）与节点验收项。

## 2. Scene Contract Delivery
- [x] 2.1 在 `boss_encounter_scene.gd` 明确教程式基线节点契约与校验接口。
- [x] 2.2 将四个 Boss 场景对齐到统一节点骨架与中小型封闭布局。
- [x] 2.3 保证四个场景均不依赖主世界流式节点即可独立运行。

## 3. Encounter Flow Hardening
- [x] 3.1 固化四个触发道具到独立场景的确定性映射与兜底日志。
- [x] 3.2 固化战前“镜头聚焦 Boss 1.2 秒”时序，避免直接跳战斗。
- [x] 3.3 保持失败/胜利回传原坐标逻辑不回归。

## 4. Verification
- [x] 4.1 增加场景结构校验：四房节点契约与隔离依赖检查。
- [x] 4.2 增加入场链路校验：每个 Boss 至少 30 次触发均进入对应独立场景（成功率 100%）。
- [x] 4.3 增加回传校验：失败与胜利均返回入场前坐标。
- [x] 4.4 运行 `openspec validate refine-boss-room-tutorial-baseline --strict` 并修复全部问题。
