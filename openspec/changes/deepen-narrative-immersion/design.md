# Design: Deepen Narrative Immersion

## Cinematic State Control

### 1. `ShipEnvironmentController`
Controls the atmospheric tension of the tutorial scene.
- **State**: `AlertLevel` (0-3).
    - **0 = Calm**: White ambient light, low rumble.
    - **1 = Yellow Alert**: Flashing yellow, intermittent pings.
    - **2 = Red Alert**: Flashing red, persistent loud alarm, sparks.
    - **3 = Critical**: Fast red strobe, steam venting, heavy camera shake, suction force.
    - **4 = Breach**: Whiteout, pulling force maxed, sound fades to muffled underwater effect.

### 2. `TutorialSequenceManager` Integrations
The dialogue triggers drive the environmental state:
- `<emit:intro>` -> `AlertLevel.1` (Yellow rumble, wake up).
- `<emit:give_items>` -> `AlertLevel.2` (Sparks start flying).
- `<emit:wait_program>` -> **Calm Moment** (UI Focus Mode).
    - `AlertLevel.1` visually, but heavily dimmed.
    - Audio: `AudioServer.set_bus_volume_db(sfx_bus, -10db)`.
- `<emit:test_fire>` -> `AlertLevel.3` (Panic).
- `<emit:crash_start>` -> `AlertLevel.4` (Explosion).

### 3. Dynamic Camera & Letterboxing
To feel cinematic without cutscenes (taking control away), we limit camera movement but frame the action.
- **Letterboxing**: simple top/bottom `ColorRect` overlays that slide in.
- **Pan Targets**:
    - Default `Target: Player`.
    - `<emit:cam_focus:mage>` -> `Target: CourtMage` (Lerp over 1.0s).
    - `<emit:cam_focus:wall>` -> `Target: BreachPoint` (Pre-spawn location).

### 4. NPC Acting
The Court Mage is the emotional anchor.
- **Pose**: Instead of idle standing, use a `Strain.tres` animation where the sprite vibrates slightly and glows.
- **VFX**: A `Barrier` particle system (Blue shield) emanating from the Mage to the Hull Breach point.
    - This visualizes *why* the Mage can't fix the wand themselves—they are occupied holding the ship together.
    - Dialogue: "I... cannot... hold it! Fix the wand yourself!"

## Key Interactions
1.  **The "Calm Before the Storm" (Wand Editor)**:
    - The most complex task (Learning Node Logic) happens amidst chaos. This is bad for learning.
    - **Design Choice**: When `WandEditor` opens, time slows or "focuses". The screen darkens (vignette), sound muffles, the shaking stops. The player enters a "Mental Palace".
    - When `WandEditor` closes, the chaos resumes instantly (Crash back to reality).

## Scene Structure
- `IntroScene`
    - `WorldEnvironment` (Glow enabled).
    - `CanvasModulate` (Controls lighting color).
    - `ShipEnvironmentController`
        - `SparkEmitters (Group)`
        - `SteamVents (Group)`
        - `AlarmLight (Light2D)`
    - `CourtMage` (with `BarrierEmitter`).
    - `BreachPoint` (Marker2D + Particle/ForceField).
