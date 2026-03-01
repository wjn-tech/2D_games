# -*- coding: utf-8 -*-
import io
import re

file_path = 'scenes/ui/dialogue_window.gd'
with io.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# We need to add logic in _show_line()
# Find:
# if _current_line < _lines.size():
# if text_label: text_label.text = _lines[_current_line]

old_func = '''func _show_line() -> void:
\tif _current_line < _lines.size():
\t\tif text_label: text_label.text = _lines[_current_line]'''

new_func = '''func _show_line() -> void:
\tif _current_line < _lines.size():
\t\tvar line_text: String = _lines[_current_line]
\t\t
\t\t# --- Parse Embedded Action Tags <emit:event_name> ---
\t\tvar regex = RegEx.new()
\t\tregex.compile("<emit:(\\\\w+)>")
\t\tfor result in regex.search_all(line_text):
\t\t\tvar event_name = result.get_string(1)
\t\t\tDialogueManager.dialogue_event.emit(event_name)
\t\tline_text = regex.sub(line_text, "", true) # Remove tags from visible text
\t\t
\t\tif text_label: text_label.text = line_text'''

if old_func in content:
    content = content.replace(old_func, new_func)
    with io.open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Modified dialogue_window.gd")
else:
    print("Could not find _show_line block.")
