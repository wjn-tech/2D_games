extends Control

@onready var main_layout = /MainLayout
@onready var content_hbox = main_layout.get_node("ContentHBox")
@onready var inventory_col = content_hbox.get_node("InventoryColumn")
@onready var stats_col = content_hbox.get_node("StatsColumn")
@onready var detail_col = content_hbox.get_node_or_null("DetailColumn") # Check if exists

func _ready():
    # 1. Structure Cleanup & Creation
    
    # Create the Three Main Columns if not structured right
    var col_left = stats_col # Already exists
    var col_center = inventory_col # Already exists
    var col_right = detail_col 

    if not col_right:
        # If detail column doesn't exist in HBox, we might need to find where DetailPanel is.
        # It seems DetailPanel was in DetailColumn in the .tscn text but the variable detail_panel pointed to it
        # Let's find DetailPanel and move it to a new Right Column if needed.
        var detail_panel = find_child("DetailPanel", true, false)
        if detail_panel:
            var parent = detail_panel.get_parent()
            if parent == content_hbox:
                 # It's already a direct child?
                 col_right = parent
            else:
                 # It might be inside a VBox or something
                 pass

    # Actually, simpler approach:
    # Just ensure we have 3 clear columns with proper spacing and styling.
    
    # Apply Theme Variations for 'Zones'
    # Left Zone (Character)
    if stats_col:
        # Wrap in a PanelContainer for background
        var bg_inv = PanelContainer.new()
        bg_inv.name = "StatsPanel"
        bg_inv.theme_type_variation = "PanelContainer" # Uses inner panel style
        
        # We need to swap parents.
        # But doing this at runtime is just for testing.
        # I need to edit the scene file or use a tool script to modifying the .tscn
        pass

    print('Inventory Layout Script Loaded')