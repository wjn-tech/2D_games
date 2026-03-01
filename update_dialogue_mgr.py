# -*- coding: utf-8 -*-
import io

file_path = 'src/ui/dialogue_manager.gd'
with io.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "signal dialogue_event(event_name: String)" not in content:
    old_str = "signal dialogue_finished"
    new_str = "signal dialogue_finished\nsignal dialogue_event(event_name: String) # Added for tutorial sequences"
    content = content.replace(old_str, new_str)
    
    with io.open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Modified dialogue_manager.gd")
else:
    print("already modified dialogue_manager.gd")
