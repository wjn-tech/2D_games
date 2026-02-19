设计说明（概览）

目标视觉方向：
- 深邃的暗色背景（蓝黑紫混合），带有柔和的光晕与远景颗粒，形成“纵深感”。
- 局部亮紫作为主题点缀（按钮高亮、标题渐变），并使用细腻的阴影与发光（Glow）营造魔法感。
- 魔法圆/符文采用同心圆与细线粒子，使用透明度动画与轻微旋转，营造转动与能量流动感。

关键实现建议：
- 背景分层：远景暗噪点（低频）、中景大雾（ColorRect + shader）、前景粒子（GPUParticles2D）。
- 时间驱动变化：通过 `OS.get_datetime()` 或 `Time.get_time_dict_from_system()` 获取本地时间，驱动 shader uniform 或 `ColorRect` 混合比例以产生日间/夜间差异（色温/亮度/星光强度）。
- 标题文本：使用两个 Label 层次，一个大标题（渐变填充或使用着色器渲染渐变），一个副标题（细间距字母）。
- 按钮：使用 `MagicButton`，内部包含 `ColorRect` 作为 glow，`NinePatchRect` 或 StyleBoxTexture 用于外框，hover 时发光强度提升并播放小粒子喷发。

资源与授权：
- 不使用 `logo.svg`；推荐从 Font Awesome（SIL OFL 字体/图标）、Heroicons（MIT）、或 Feather Icons（MIT）中挑选开源图标并导出为 SVG/PNG，在 `res://assets/ui/startmenu/` 中保存。具体来源将在实现前列出。

降级方案：
- 若目标设备性能不足：降低 GPUParticles 发射率、关闭投影模糊、降低 shader 采样次数。

实现风险与缓解：
- 风险：缺少字体/资源导致视觉差异。缓解：实现主题回退（默认系统字体与保守配色）。
- 风险：Shader 在部分平台出现兼容性问题。缓解：提供纯 ColorRect/Texture 的替代实现，并在运行时检测支持情况。
