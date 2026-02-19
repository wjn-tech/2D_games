# Proposal: Polish Main Menu UX — polish-main-menu-20260218

## Summary
本提案旨在解决主菜单“缺乏吸引力”和“体验割裂”的问题，通过一组小而可验证的改进来提升第一印象与交互感受。目标是在不改变现有场景结构的前提下，通过视觉层次、配色与交互反馈三方面的改进，使主菜单在 10-15 分钟内部署并可在编辑器中快速预览。

## Goals
- 提升视觉层级与信息引导，使玩家一眼识别主要操作入口。
- 用蓝色统一色调（替换当前紫色）并提供共享 palette 资源，便于后续全局一致性调整。
- 为按钮增加可感知的交互反馈（hover、pressed、glow、微动效）。
- 在主菜单引入参考级背景：星空、同心环、发光光晕、云层和昼夜渐变，支持 Inspector 的 `debug_hour` 快速预览。

## Reference & Target Look
目标参考图已上传（示例效果），总体视觉目标为：
- 中央大标题（strong logotype），使用冷蓝的渐变填充与弱高光。
- 背景为层次化的深蓝星空，带宽大的节奏同心环（非常低不透明度），与局部 nebula 光晕形成深度。
- 按钮有柔和的发光（按时间段色调）、圆角、轻微内阴影与交互缩放。

为便于实现与验收，提案将在下列方面提供可操作的值与资源：
- 统一 palette（hex tokens）和 `palette.tres` 建议
- 四个时间段的 shader presets（dawn/day/dusk/night）与数值建议
- 按钮交互参数（hover glow 色、强度、scale/animation 时长）
- 验收清单：编辑器截图（四时段）、contrast check、hover/pressed 动画录像或 GIF

## Constraints
- 优先使用现有 shader 与 `MenuDynamicBackground`，仅在必要时微调参数，无需重写渲染管线。
- 保持 Godot 4 兼容性，不引入第三方非内置插件。

## Deliverables
- openspec tasks.md、design.md
- spec deltas：VisualHierarchy、InteractionFeedback、Theming、DecorativeElements、Typography
- 验证清单与建议的验收场景（editor preview + screenshot）
