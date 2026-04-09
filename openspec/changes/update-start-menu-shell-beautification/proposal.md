# Change: Update Start Menu Shell Beautification

## Why
当前主菜单已有多轮视觉迭代，但风格合同分散在场景、脚本和历史提案中，缺少统一“开始菜单壳层”约束，导致以下问题：
- 美术风格不稳定：同一入口在不同版本之间出现明显漂移。
- 维护成本高：`MainMenu.tscn` 与 `main_menu.gd` 中存在大量视觉相关逻辑，难以快速定制。
- 资源目录未形成规范：`assets/ui/start_menu_shell/` 当前只覆盖加载界面 token，尚未覆盖主菜单。

本提案用于基于现有工程结构，定制并固化开始菜单美化方案，确保“可读、可回退、可持续维护”。

## What Changes
- 新增 `start-menu-shell-beautification` 能力增量：
  - 定义开始菜单“终端壳层”视觉结构合同（头栏、标题区、主操作区、底栏状态区）。
  - 明确主操作层级：开始游戏为主按钮，加载/设置/退出为次级按钮。
  - 统一交互反馈合同：hover/focus/pressed 动效与键盘导航可见性。
- 新增 `start-menu-visual-token-sync` 能力增量：
  - 在 `assets/ui/start_menu_shell/` 扩展主菜单视觉 token 规范（颜色、边框、字号、间距、动效时长）。
  - 约束 `MainMenu.tscn` 与 `main_menu.gd` 对 token 的读取与降级策略。
  - 约束与“开始游戏加载浮层”视觉方向保持一致（同一壳层语言，不要求像素级一致）。

## Scope
- In scope:
  - 开始菜单单页视觉结构与交互反馈规范。
  - 主菜单视觉 token 的来源、映射和降级规则。
  - 开始菜单与加载浮层之间的风格一致性约束（颜色语言、边框语言、状态文案语气）。
  - 方案验证标准（可读性、可用性、稳定性）。
- Out of scope:
  - 世界生成/存档流程逻辑改写。
  - 设置页、存档页、HUD 的全面重构。
  - 全局 Theme 系统重写。

## Impact
- Affected specs:
  - `start-menu-shell-beautification` (new)
  - `start-menu-visual-token-sync` (new)
- Related changes:
  - `redesign-start-menu`
  - `beautify-main-menu`
  - `refine-main-menu-visuals`
  - `beautify-start-game-loading-progress-bar`
- Affected code (apply stage):
  - `scenes/ui/MainMenu.tscn`
  - `scenes/ui/main_menu.gd`
  - `scenes/ui/MenuEffects.tscn`
  - `src/ui/ui_manager.gd`（仅当主菜单与加载浮层 token 对齐需要共享读取逻辑）
  - `assets/ui/start_menu_shell/`（新增主菜单 token 与维护说明）

## Defaults for Ambiguous Inputs
1. “参考该文件夹”默认解释为：以现有项目内 `assets/ui/start_menu_shell/` 作为开始菜单壳层资源目录基线。
2. 默认视觉方向采用“科幻终端壳层”，与加载浮层保持同语义风格，不强制 1:1 复刻示例图。
3. 默认保持主菜单功能入口不变（开始/加载/设置/退出），仅调整视觉与交互表现。
4. token 缺失或解析失败时，默认回退到 `MainMenu.tscn` 的内建样式，禁止阻断菜单可用性。
5. 默认优先场景声明式配置（theme/stylebox），脚本仅处理动态状态与小幅动效。

## Open Questions
- 当前无阻塞性未决问题，可进入评审。