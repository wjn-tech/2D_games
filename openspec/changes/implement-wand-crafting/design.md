# Design: Wand Synthesis Architecture

## Data Model

### 1. Wand Embryo (`WandEmbryoDefinition`)
Defines the "Skeleton" of a wand.
-   **Level**: Tier (1-10).
-   **Visual Grid Resolution**: Determines the density of the editor grid (e.g., 4x4 for Tier 1, up to 16x16 for Tier 10). The final in-game sprite size remains constant (1 tile), but higher tiers allow finer detail and more material usage.
-   **Stat Capacity**: Max number of passive slots (distinct from visual materials).
-   **Logic Capacity**: Max number of circuit nodes.
-   **Nature**: Purely a container. Has no inherent attack; attacks are defined entirely by the Logic Circuit.

### 2. Wand Instance (`WandData`)
The actual item data held by the player.
-   **Embryo Reference**: Which base is used.
-   **Visual Map**: Dictionary `{(x,y): MaterialID}`. Used to render the sprite and calculate "Decoration Stats".
-   **Passive Materials**: List of materials added for raw stats (Core slots).
-   **Logic Circuit**: A Directed Acyclic Graph (DAG) of nodes.

## Systems

### 1. Visual Editor & Rendering
-   **Editor**: A grid UI where players place "Decoration Materials".
    -   **Grid Size**: Scales with Embryo Tier.
    -   **Cost**: Placing a block consumes the material item.
    -   **Effect**: Each visual block contributes minor attributes (e.g., Iron Block = +Weight, +Defense) to the final wand.
-   **Rendering**: A `SubViewport` will render the grid configuration into a `ViewportTexture`. This texture is then assigned to the Player's weapon sprite.

### 2. Logic Circuit (Spell Pipeline)
The core attack mechanics using a Free Node Graph.
-   **Structure**: Node-based Graph Editor (similar to ShaderGraph/Blueprint).
-   **Nodes**:
    -   **Input**: "Trigger" (Player Click).
    -   **Modifiers**: Change payload data (Damage, Element).
    -   **Flow Control**: Splitters (1 In -> 2 Out), Delay, Probabilistic paths.
    -   **Output**: "Emit Projectile", "Self Buff", "Summon".
-   **Execution Flow**:
    1.  **Trigger**: Fire pulse execution from valid Start Nodes.
    2.  **Breadth-First Traversal**: The pulse travels through connections.
    3.  **Branching**: Splitter nodes create parallel execution threads (multiple projectiles).
    4.  **Emission**: End-nodes spawn actual game objects.

### 3. Stat Calculation
-   `FinalStats = BaseEmbryoStats + Sum(PassiveMaterials)`.
-   Calculated once when the wand is saved/equipped.

## UI Architecture
-   **Wand Workshop UI**:
    -   **Tab 1: Visuals**: Palette of decoration blocks. Canvas grid.
    -   **Tab 2: Logic**: Slots connected by lines (or just a sequence strip). Inventory of logic materials.
    -   **Tab 3: Stats**: Slots for passive boosters.

## Integration
-   **PlayerController**: Needs to check `CurrentWeapon`. If `WandData`, use `WandSystem` to execute attack.
-   **Inventory**: Needs to handle `WandData` not just as a static ID, but as dynamic data (likely using Godot's `Resource` or dictionary metadata).
