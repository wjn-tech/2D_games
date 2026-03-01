
import io

def fix(path, old, new):
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old, new)
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)

fix('src/ui/ui_manager.gd', 'parent.layer = 100', 'parent.layer = 1')
fix('src/ui/ui_manager.gd', 'ui_root.layer = 100', 'ui_root.layer = 1')
fix('scenes/main.tscn', 'layer = 100', 'layer = 1')
fix('scenes/test.tscn', 'layer = 100', 'layer = 1')
print('Done!')

