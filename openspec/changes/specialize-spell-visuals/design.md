# Spell Specialization Plan

## Concept
The problem with the current implementation is "HDR Washout". Because we scaled the colors uniformly (e.g., `Color(4, 4, 5)`), the trail gradient simply faded from "White HDR" to "Transparent White HDR". To get rich colors, particles MUST transition from `HDR White-Hot -> Saturated Base Color -> Transparent Base Color`.

Furthermore, physical movement logic in `ParticleProcessMaterial` must be exaggerated to contrast the spells.

### Proposed Identities:

1. **Magic Bolt (法术箭)**
   - **Visual**: A focused, tight stream of classic arcane energy.
   - **Color**: HDR Cyan -> Deep Blue -> Transparent.
   - **Physics**: Very low spread, zero gravity, forms a sleek "line" of particles.

2. **Spark Bolt (火花弹)**
   - **Visual**: Erratic, unstable electric discharge. 
   - **Color**: HDR Electric Blue -> Purple -> Transparent.
   - **Physics**: High tangential acceleration (causes zigzag/spiral offshoots), wide spread, very short lifespan (looks like a flickering wire).

3. **Fireball (火球)**
   - **Visual**: A burning clump that leaves thick, rising smoke and falling embers.
   - **Color**: HDR Yellow -> Saturated Orange/Red -> Dark Grey (Smoke) -> Transparent.
   - **Physics**: Core drips downward sparks, trail has negative gravity (smoke rises), uses a scale curve to make smoke particles grow larger over time.

4. **Bouncing Burst (弹跳爆裂)**
   - **Visual**: Heavy, cohesive acidic slime.
   - **Color**: HDR Yellow-Green -> Neon Green -> Dark Green -> Transparent.
   - **Physics**: High gravity (arcs downwards heavily), leaves "wet" dropping particle trails that hit the floor and stop. 

5. **Chainsaw (电锯)**
   - **Visual**: Violent mechanical spray covering a melee radius.
   - **Color**: HDR White -> Bright Yellow/Orange sparks.
   - **Physics**: High velocity, extreme angular spread (180 degrees), fast fade. Looks like cutting metal.

6. **Black Hole / Void (黑洞/虚空 - Optional)**
   - **Visual**: Absorbing light.
   - **Color**: Deep purple to pitch black. (Using `BLEND_MODE_SUB` if supported, or dark alpha).
   - **Physics**: Radial acceleration pulling particles inward rather than outward.