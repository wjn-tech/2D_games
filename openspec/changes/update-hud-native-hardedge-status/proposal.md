# Change: Update Native Hard-Edge HUD Status

## Why
- 当前 HUD 状态区的信息层级仍不够集中，血量/法力/Age 的视觉统一性不足。
- 本次已明确不使用 HTML 壳，需在 Godot 原生 UI 内完成像素硬边科幻风升级。
- 需要将状态读数反馈做成轻量动画，提高可读性但不干扰操作。

## What Changes
- 重构左上角状态区为一体化原生 HUD 面板（HP/Mana/Age），沿用像素硬边科幻方向。
- 明确 Age 条语义为“已消耗年龄值”，显示 current_age / max_life_span。
- 状态数值变化时增加轻微缩放与颜色闪烁反馈（低强度）。
- 统一状态区在多比例分辨率下的安全区与排版规则（全适配目标）。
- 明确非目标：不引入 WebView/HTML，不新增技能栏/冷却系统，不改世界场景美术和天气全局视觉表现。

## Impact
- Affected specs: hud-native-hardedge-status
- Affected code (implementation stage): scenes/ui/HUD.tscn, scenes/ui/hud.gd, src/ui/hud/player_status_widget.gd, src/ui/hud/hud_styles.gd
- Sequencing: 建议先落地本提案，再进入 HUD 反馈层与小地图提案。
