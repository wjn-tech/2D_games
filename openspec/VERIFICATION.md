# Milestone Verification Guide

This guide provides the user with manual test procedures to verify the "Phase Results" after implementation.

## Milestone 1: Foundation (Phases 01-03)
**Objective**: Basic 3-layer world physics, character stats, and time.
1.  **3-Layer Check**: Run `test.tscn`. Walk through a "Layer Door". Verify that you teleport to a different background depth and can only collide with tiles on that new depth.
2.  **Attribute Inspector**: Open the Player node in the remote scene tree during runtime. Modify `Strength` manually. Verify that jump height or movement speed (if linked) changes instantly.
3.  **Clock Watch**: Wait in-game for 2 minutes. Verify the UI clock advances and a "New Day" message appears in the console/UI.

## Milestone 2: World Interaction (Phases 04-06)
**Objective**: NPCs, Harvesting, and Trading.
1.  **AI Aggro Test**: Approach a "Wolf" or "Bandit" NPC. Verify it transitions from `Idle` to `Chase` when you enter its radius.
2.  **Loot Drop**: Hit a tree or rock node with a tool. Verify it shatters and adds an item (Wood/Stone) to your inventory.
3.  **Shop Transaction**: Interact with a Merchant NPC. Buy an item. Verify your gold decreases and the item appears in your bag.

## Milestone 3: Manufacturing & Construction (Phases 07-09)
**Objective**: Crafting, Building, and Layered Combat.
1.  **Crafting Bench**: Open the Crafting UI. Use 5 Wood to create a "Wooden Sword". Verify the resource is consumed.
2.  **Blueprint Placement**: Enter "Build Mode". Place a wall tile. Verify it costs resources and immediately provides collision.
3.  **Tactical Door**: During combat, use a door to escape to the "Underground" layer. Verify the surface enemies stop attacking you as you are no longer in their physics layer.

## Milestone 4: Social & Lineage (Phases 10-12)
**Objective**: Marriage, Children, and Succession.
1.  **Wedding Event**: Reach high affinity with an NPC. Use a "Marriage" action. Verify the NPC now follows the player or stays in the player's house.
2.  **Growth Sim**: Have a child NPC. Observe them over several game days. Verify their sprite size/attributes grow as they "age".
3.  **Succession Trigger**: Use a debug command or wait for lifespan death. Verify the `Succession UI` appears and allows choosing a child. The new character should have the old character's inventory.

## Milestone 5: Advanced Automation (Phases 13-15)
**Objective**: Arrays, Circuits, and Ecosystem.
1.  **Array Trigger**: Place 4 "Spirit Stones" in a square. Verify a "Formation Effect" graphic appears and provides a stat buff.
2.  **AND Gate logic**: Build a circuit with two levers and one door. Verify the door only opens when BOTH levers are ON.
3.  **Ecology Alert**: Over-harvest a forest. Verify that "Ecology UI" shows a warning and no new trees grow in that biome for several days.
