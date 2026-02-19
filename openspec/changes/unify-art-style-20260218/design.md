## 设计说明：美术风格统一化

目的：以最小改动达成视觉连贯性，优先使用共享配色与 shader 参数，而非直接替换大量像素素材。

技术决策要点：
- 共享资源优先：创建 `assets/ui/palette.tres` 作为主色板资源，供 `main_theme.tres` 与 `menu_bg.shader` 读取参数（通过导入或手动复制）。
- 非破坏性回退：每次更改先通过 `main_theme.tres` 的副本进行实验（`main_theme_unified.tres`），并在确认后替换默认主题。
- Shader 兼容：在 `menu_bg.shader` 中提供显式 day/night preset uniform（例如 `preset_day`, `preset_night`），并支持外部脚本读取/写入，方便 `MenuDynamicBackground` 与世界天气系统共享参数。
- 渲染优先级：将场景背景的 `SkyLayer` 放在 `MainMenu` 的 CanvasLayer 下方，并确保 `Overlay` 使用 `CanvasLayer` 或透明化以避免覆盖。

Trade-offs：
- 更改主题（`main_theme.tres`）影响全局 UI，可能需要小范围修正（例如按钮边框）。但它是最有效的统一点。
- 完全像素化菜单（替换 shader 发光）会耗费较多美术资源，短期不推荐。

实施注意事项：
- 在代码里避免长期保留 `HardFallbackSky` 或强制颜色覆盖；这些仅作调试。
- 将关键视觉参数（主/次色、太阳强度、星云强度）纳入 `DynamicBackground` 的导出字段以便调试和 Inspector 调整。
