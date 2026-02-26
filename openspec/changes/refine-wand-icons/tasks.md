# Refine Wand Icons Tasks

1.  Create `assets/ui/icons/wand_base.svg`.
2.  Update `scenes/player.gd` `_create_debug_wand` to use `wand_base.svg`.
3.  Update `src/systems/crafting/crafting_manager.gd` logic for wand recipes to use `wand_base.svg` if no visual blocks.
4.  Update `src/systems/debug/debug_tools.gd` to use `wand_base.svg`.
