# Fix Black Hole Brightness Artifacts

## What changes
We will fundamentally alter the way the Black Hole spell handles lighting (`PointLight2D`). Currently, the Black Hole uses the default setup which instantiates a `PointLight2D` with an energy of 0.5 and additive properties. The change disables or inverses the default `_light` node for Void class spells so it casts no light, and properly utilizes subtractive particles. Furthermore, we will fix the background clear color/blend modes of the screen distortion shader so it doesn't leave a bright, hard-edged bounding box.

## Why
As seen in the screenshot, the subtractive particles and shaders are functioning computationally, but they are sitting on top of a massive, super-bright `PointLight2D` (the bright white square gradient in the center) and a `ColorRect` background that hasn't properly ignored its own alpha layer, causing the "Black Hole" to inadvertently act as a giant flashbang. Dark spells cannot emit standard additive PointLights. 

## Scope
Tight scope targeting `src/systems/magic/visuals/magic_projectile_visualizer.gd`. specifically the `setup()` and `_apply_behavior_identity()` flow concerning `_light.energy` and `_light.visible`, as well as tweaking the subtractive shader's alpha clamping.