## Spec Delta: Art Style Unification

### ADDED Requirements

Requirement: Shared Palette Resource
#### 描述:
创建 `assets/ui/palette.tres`（Theme/Color resource 或 Godot 的自定义资源），包含至少三个命名颜色：`scene_blue`, `ui_purple`, `accent_warm`，并导入到仓库。
#### Scenario:
当运行场景时，`DynamicBackground` 的 `grad_top/grad_bottom` 应优先从该 palette 中的 `scene_blue` 取值（或其变体），`main_theme.tres` 使用 `ui_purple` 作为按钮边框/高亮而非面板主要背景。

Requirement: Menu Shader Presets
#### 描述:
`ui/shaders/menu_bg.shader` 必须暴露 `preset_day`/`preset_night` uniforms 或显式 `grad_top`/`grad_bottom`/`nebula_strength`/`star_density`，并支持被 `MenuDynamicBackground` 读取和写入。
#### Scenario:
当 `MenuDynamicBackground` 初始化且 `debug_hour` 为 12（白昼），它会将 `preset_day` 的参数写入 shader，使显示为白昼并减少星点。

Requirement: UI Overlay Behavior
#### 描述:
`MainMenu` 中的 `Overlay` 不应完全覆盖背景色。必须在 `MainMenu` 的显示逻辑中使用透明度 <= 0.15 或在 shader 成功附加后自动将 `Overlay.visible` 设为 false。
#### Scenario:
当 shader 被附加并可见时，`MainMenu` 会自动隐藏或透明化 `Overlay`，以便背景 shader 可被玩家看到。

Requirement: Non-destructive Theme Update
#### 描述:
在修改 `main_theme.tres` 前，必须创建副本 `main_theme_unified.tres` 进行测试。替换默认主题必须通过 PR 并包含视觉回归截图。
#### Scenario:
美术/工程合并主题变更前，CI 检查到 `main_theme_unified.tres` 文件及至少两张对比截图作为变更附件。

### MODIFIED Requirements

Requirement: `DynamicBackground` Exports
#### 变更:
增加导出 `scene_palette` 引用允许在 Inspector 中指定 `assets/ui/palette.tres`，并优先使用其中颜色作为 `grad_top`/`grad_bottom`。
#### Scenario:
用户在 Inspector 里把 `scene_palette` 指向 `assets/ui/palette.tres`，`DynamicBackground` 在 `_ready()` 读取并应用 palette 的 `scene_blue` 值。
