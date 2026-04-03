## 1. Visual Baseline Contract
- [x] 1.1 定义 Boss 房视觉分层契约（远景/中景/前景）与必备节点清单。
- [x] 1.2 定义门体视觉状态契约（锁定/解锁的颜色、发光、动画反馈）。
- [x] 1.3 定义四个 Boss 房主题 token（主色、事件色、雾强度、粒子类型）。

## 2. Cinematic Rhythm Contract
- [x] 2.1 在不改现有入场规则前提下，定义开场镜头增强节奏（焦点过渡与恢复控制时机）。
- [x] 2.2 定义阶段切换视觉信号（Boss phase change、门状态与 HUD 提示联动）。
- [x] 2.3 定义“演出不抢输入”的硬约束（可操作时间与阻塞上限）。

## 3. Readability and Performance Guardrails
- [x] 3.1 定义战斗实体可读性指标（玩家、Boss、投射物与背景对比门槛）。
- [x] 3.2 定义视觉预算与降级策略（粒子数量、灯光数量、动画频率）。
- [x] 3.3 补充验证脚本检查项，确保视觉增强不破坏现有 Boss 流程门禁。

## 4. Verification
- [x] 4.1 运行 `tools/check_boss_progression_pipeline.ps1` 并确认通过。
- [x] 4.2 运行 `openspec validate enhance-boss-room-visual-fidelity --strict` 并修复全部问题。
- [x] 4.3 记录四个 Boss 房视觉门禁检查结果（结构、可读性、性能三类）。