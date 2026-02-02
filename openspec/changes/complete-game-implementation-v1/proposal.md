# Change: 完整游戏实现与视觉美化 (Full Game Implementation & Beautification)

## Why
在完成了基础骨架和核心逻辑的初步细化后，项目需要从“功能原型”向“完整游戏”跨越。这包括补全剩余的沙盒系统、建立完整的游戏循环（主菜单、存档管理、死亡转生）、以及通过统一的 UI 主题和视觉特效提升游戏品质。

## What Changes
- **系统补完**：实现剩余的 14 大系统功能（AI 行为、阵法、天气影响、工业机器等）。
- **游戏循环 (Game Loop)**：
    - 实现主菜单 (Main Menu) 与设置界面。
    - 实现 HUD (Heads-Up Display) 显示玩家状态（生命、寿命、货币）。
    - 实现完整的死亡与转生流程 UI。
- **UI 美化 (Beautification)**：
    - 引入全局 `Theme` 资源，统一按钮、面板、文字风格。
    - 为 UI 窗口添加打开/关闭动画。
- **视觉与打击感增强**：
    - 增加挖掘/战斗时的屏幕抖动 (Screen Shake) 与粒子效果钩子。
    - 实现图层切换的视觉过渡（变暗/模糊非活跃层）。
- **存档系统可视化**：提供多档位存档选择界面。

## Collaboration Model
- **我（逻辑/架构）**：编写所有系统的深度逻辑、UI 框架动画、视觉特效脚本、存档管理逻辑。
- **你（视觉/配置）**：提供具体的像素素材、配置 UI Theme 的具体颜色/贴图、在编辑器中摆放场景装饰、配置动画状态机。

## Impact
- **Affected specs**: 扩展所有 14 个核心 capability，新增 GameLoop 与 UITheme 规范。
- **Affected code**: `res://src/` 下的所有模块，新增 `res://src/core/game_manager.gd`。
