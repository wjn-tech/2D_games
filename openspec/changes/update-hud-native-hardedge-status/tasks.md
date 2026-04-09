## 1. Scope & Contract
- [ ] 1.1 锁定原生 UI 约束：HUD 状态区不得依赖 WebView/HTML，保持 Godot 控件链路。
- [ ] 1.2 盘点现有状态数据来源（GameState.player_data、EventBus.stats_changed、stat_changed），确认不改数据语义。

## 2. Status Panel Rework
- [ ] 2.1 将 HP/Mana/Age 重排为一体化硬边科幻面板，统一图标、间距、边框与层级。
- [ ] 2.2 明确 Age 条展示为已消耗年龄值，格式统一为 Age: current/max。
- [ ] 2.3 清理数值拥挤问题（字体、留白、对齐、文本截断策略）。

## 3. Lightweight Feedback
- [ ] 3.1 为数值变化添加轻微缩放反馈（短时、低幅度）。
- [ ] 3.2 为数值变化添加颜色闪烁反馈（低饱和、短时恢复）。
- [ ] 3.3 确保反馈不会遮挡状态条填充和关键数字。

## 4. Responsive Adaptation
- [ ] 4.1 定义并实现 16:9、16:10、21:9 的布局规则与安全边距。
- [ ] 4.2 验证状态区不与 Hotbar、Boss 血条、小地图区域冲突。

## 5. Validation
- [ ] 5.1 人工回归：进入游戏、受伤、耗蓝、年龄增长三类状态变化都可读。
- [ ] 5.2 运行检查：HUD 路径不出现 WebView 创建/调用。
- [ ] 5.3 记录验收截图与分辨率测试结果。
