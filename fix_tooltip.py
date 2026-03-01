# -*- coding: utf-8 -*-
import io

file_path = 'src/ui/wand_editor/components/logic_node_script.gd'
with io.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Change type of _tooltip_instance
content = content.replace("var _tooltip_instance: PanelContainer", "var _tooltip_instance: Node")

# 2. Modify _show_custom_tooltip
old_func = '''func _show_custom_tooltip(text: String):
\tif _tooltip_instance and is_instance_valid(_tooltip_instance):
\t\t_tooltip_instance.queue_free()
\t\t
\tvar container = PanelContainer.new()
\tcontainer.top_level = true
\tcontainer.z_index = 100 # 确保最上层
\tcontainer.mouse_filter = Control.MOUSE_FILTER_IGNORE # 不拦截鼠标'''

new_func = '''func _show_custom_tooltip(text: String):
\tif _tooltip_instance and is_instance_valid(_tooltip_instance):
\t\t_tooltip_instance.queue_free()
\t\t
\tvar canvas_layer = CanvasLayer.new()
\tcanvas_layer.layer = 120 # 确保在所有UI面板之上
\t
\tvar container = PanelContainer.new()
\tcontainer.mouse_filter = Control.MOUSE_FILTER_IGNORE # 不拦截鼠标'''

if old_func in content:
    content = content.replace(old_func, new_func)
    print("Replaced func start.")
else:
    print("Could not find func start.")

old_tail = '''\tcontainer.add_child(label)
\tadd_child(container)
\t_tooltip_instance = container
\t
\t# 下一帧设置位置，确保尺寸已计算
\tawait get_tree().process_frame
\tif is_instance_valid(container) and is_instance_valid(label):
\t\t# 跟随鼠标或固定在节点旁
\t\tvar mouse_pos = get_global_mouse_position()
\t\tcontainer.global_position = mouse_pos + Vector2(16, 16) # 鼠标右下偏移'''

new_tail = '''\tcontainer.add_child(label)
\tcanvas_layer.add_child(container)
\tadd_child(canvas_layer)
\t_tooltip_instance = canvas_layer
\t
\t# 下一帧设置位置，确保尺寸已计算
\tawait get_tree().process_frame
\tif is_instance_valid(canvas_layer) and is_instance_valid(container) and is_instance_valid(label):
\t\t# 获取视口相对鼠标位置
\t\tvar mouse_pos = get_viewport().get_mouse_position()
\t\tcontainer.global_position = mouse_pos + Vector2(16, 16) # 鼠标右下偏移'''

if old_tail in content:
    content = content.replace(old_tail, new_tail)
    print("Replaced tail.")
else:
    print("Could not find func tail.")

with io.open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done writing file.")

