# 问题诊断报告

## 故障现象
在新手教程中，玩家组装好法术（Generator -> Projectile）后：
1. **无法发射法术**：即使装备了法杖并左键点击。
2. **目标巨石未生成**：任务阶段卡死在“等待测试发射”。

## 根本原因分析
1.  **法力值初始化问题**：`tutorial_sequence_manager.gd` 中虽然给法杖设置了 `current_mana = 1000.0`，但 `WandData` 实际上并没有 `@export` 一个叫 `current_mana` 的变量，它是一个普通变量且在 `_ready` 或类似时机可能被重置。此外，`SpellProcessor` 在教程中虽然有绕过检查的代码，但其逻辑可能因为 `id` 匹配失败而未生效。
2.  **法杖 ID 匹配失效**：`SpellProcessor` 中检查 `wand_data.id == "starter_wand"`，但在 `tutorial_sequence_manager.gd` 中，赋予玩家的是 `wand_item.id = "starter_wand"`，而内部的 `wand_data.id` 仍然是默认值 `"wand"`。
3.  **编译版本不匹配**：`SpellProcessor` 使用了编译版本 `COMPILE_VERSION = 1`，如果教程中预设的 `WandData` 没经过重新编译（`compile` 调用之前就被使用了旧缓存），则无法发射。
4.  **目标生成位置偏移**：`_spawn_target` 逻辑中，如果 `TargetMarker` 缺失，默认在法师前方生成。如果场景结构发生变化，巨石可能生成在玩家视野外或墙体内部。
5.  **玩家输入冲突**：玩家脚本中 `_handle_continuous_actions` 是连发逻辑，但如果 `action_cooldown` 因为某些原因（如 `SpellProcessor` 返回了极大的值）卡死，则无法再次发射。

## 修复计划
1.  **修正法杖 ID**：确保 `WandData.id` 也被设置为 `"starter_wand"`。
2.  **强制法力充足**：在教程中将法杖的法力回复速度设为极大值，并确保初始法力满额。
3.  **修复任务触发信号**：确保巨石生成后，玩家能够通过发射动作正确触发销毁逻辑。
4.  **优化目标生成**：增加调试信息并确保巨石生成在合理的全局位置。
