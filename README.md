关于游戏背景设定的简单设定可参考：[游戏剧情介绍.pdf](https://github.com/user-attachments/files/25826076/default.pdf)

## 导出说明（WebView / HTML 嵌入）

项目中的主菜单、背景特效、法杖编辑器和背包窗口使用 `ui/web/*/index.html` 作为嵌入式 WebView 页面。

为保证导出后 WebView 正常运行，`export_presets.cfg` 需要包含以下 `include_filter`：

`ui/web/main_menu_shell/*,ui/web/main_menu_starfield/*,ui/web/wand_editor_shell/*,ui/web/inventory_shell/*,addons/godot_wry/WRY.gdextension,addons/godot_wry/bin/x86_64-pc-windows-msvc/godot_wry.dll`

如果导出后看到回退到 Godot 原生界面，请先检查导出预设中的该字段是否被覆盖或清空。
