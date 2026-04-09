# Change: Enhance Minimap with Custom Pins and Multi-Zoom

## Why
- 当前小地图交互较基础，缺少完整缩放操作入口与玩家自定义标记能力。
- 时间与天气信息与小地图视觉关联不够紧密，信息获取路径分散。
- 本轮目标限定在 HUD/小地图/UI，不触及世界美术与天气世界渲染增强。

## What Changes
- 小地图视觉升级为像素硬边科幻风（与现有 HUDStyles 方向一致）。
- 缩放交互并存：点击展开、滚轮缩放、按钮缩放三者同时可用。
- 仅支持玩家自定义标记点，不引入 NPC/资源自动标记。
- 在小地图下方增加悬浮信息卡片，仅展示时间与天气。
- 明确非目标：不改天气世界视觉反馈，不接入技能系统，不引入 WebView/HTML。

## Impact
- Affected specs: minimap-custom-pins-and-multi-zoom
- Affected code (implementation stage): src/ui/minimap/minimap.tscn, src/ui/minimap/minimap_ui.gd, scenes/ui/HUD.tscn, src/ui/world_info_ui.gd
- Sequencing: 可独立实施，也可在 HUD 状态区重构后统一视觉 token。
