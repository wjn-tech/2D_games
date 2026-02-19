# Design Notes

本节记录在实现多个系统（shader、theme、UI 布局）时的架构权衡与约束：

1. 参数化优先：优先通过调整现有 `MenuDynamicBackground` 的 uniform 与 `MenuDynamicBackground` 的导出属性来实现视觉变化，而不是新增 shader 文件。优势是快速回退与现场调试。
2. Theme 驱动：按钮样式与字体使用 `Theme` 资源（`main_theme.tres`）进行统一控制，减少在场景中散落的颜色常量。
3. Palette 资源：将 palette 作为单一可替换资源（建议 `palette.tres`），使设计师可以在不改代码的情况下替换整套色调。
4. 可观测性与回退：在开发阶段保留 `debug_hour` 和短期回退（`HardFallbackSky`）以便快速对比，但在上线前需清理。
5. 兼容性：所有变更须在 Godot 4.x 编辑器中可编辑并在运行时无警告。Avoid deprecated API.

Implementation notes for matching reference:

- Ring and star layers: implement concentric ring geometry as part of the canvas shader (thin stroke rings using distance fields) with independent opacity and scale; keep ring opacity low (0.03~0.08) so it reads as a framing device rather than a UI element.
- Nebula: use fbm noise layers with palette-tinted gradients; nebulas should be soft, large-scale (low-frequency) elements behind stars.
- Stars: layered points with two scales (small dense faint stars, sparse larger bright stars). Provide `star_density` and `star_brightness` uniforms.
- Button glow: two-layer approach — a blurred `ColorRect` or `NinePatch` behind the button (soft halo) plus an additive highlight on hover. Glow color should reference `accent` token.
- Typography: use Poppins (or a close metric match) for title; provide fallback to system sans. Title should be large, letter-spaced, and slightly embossed by a subtle gradient and inner shadow.

Performance and fallbacks:

- Provide a low-quality preset that disables nebula FBM and reduces star count for low-end GPUs. This preset should be selectable via an exported `quality_level` on `MenuDynamicBackground`.
- Keep all resources small: prefer procedural shader noise and godot `ImageTexture` for cloud overlays; avoid high-res bitmaps.


Trade-offs
- 直接写死颜色常量更快，但维护成本高；采用 palette 资源初始成本较高但长期收益更大。
