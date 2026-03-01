# -*- coding: utf-8 -*-
import io

file_path = 'src/systems/npc/npc_spawner.gd'
with io.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_str = '''\tvar spawn_pos = _get_random_spawn_pos(player.global_position)
\tif spawn_pos == Vector2.ZERO:
\t\treturn
\t
\tvar context = _analyze_context(spawn_pos)'''

new_str = '''\tvar spawn_pos = _get_random_spawn_pos(player.global_position)
\tif spawn_pos == Vector2.ZERO:
\t\treturn
\t
\t# --- 局部密度控制 (Localized Density Check) ---
\t# 限制同一区域内的刷怪上限密度，防止刷出一堆怪堆在一起
\tvar active_mobs = get_tree().get_nodes_in_group("hostile_npcs")
\tfor mob in active_mobs:
\t\tif spawn_pos.distance_to(mob.global_position) < 400.0:
\t\t\t# 区域内存在其他怪物，放弃本次生成
\t\t\treturn
\t
\tvar context = _analyze_context(spawn_pos)'''

if old_str in content:
    content = content.replace(old_str, new_str)
    with io.open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Success")
else:
    print("Not found")
    idx = content.find('spawn_pos == Vector2.ZERO')
    print(repr(content[idx-50:idx+150]))
