from PIL import Image, ImageDraw

def main():
    width = 64
    height = 64
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    tile_size = 16
    
    # Colors
    c_dirt = "#8B4513"
    c_grass = "#2E8B57"
    c_stone = "#708090"
    c_sand = "#F4A460"
    c_mud = "#2F4F4F"
    c_trunk = "#5D4037" # Darker brown for trunk
    c_leaves = "#32CD32"
    c_snow = "#FFFAFA"
    c_hard_rock = "#404040"
    
    # Helper to clean coords
    def t(x, y):
        return (x * tile_size, y * tile_size, (x + 1) * tile_size, (y + 1) * tile_size)
        
    def rect(x, y, color):
        x1, y1, x2, y2 = t(x, y)
        draw.rectangle([x1, y1, x2-1, y2-1], fill=color)

    def slope_left(x, y, color):
        # Bottom-Left triangle
        x1, y1, x2, y2 = t(x, y)
        # Points: Top-Left is (x1, y1). Bottom-Left is (x1, y2-1). Bottom-Right is (x2-1, y2-1)
        # Wait, Slope usually means 45 degrees.
        # "Tree Root Left": /| shape? Or |\ ?
        # Usually roots spread OUT. So Left side root looks like \ (Top-Left to Bottom-Right) filling bottom-left?
        # Let's assume "Left Root" connects to a trunk on its Right. So it slopes Up-Left. 
        # Shape: Bottom-Right filled?
        # Let's do Standard 45 degree ramps for general use first.
        
        # Tile (0, 2): Slope / (fill bottom-right)
        draw.polygon([(x1, y2-1), (x2-1, y2-1), (x2-1, y1)], fill=color)
        
    def slope_right(x, y, color):
        # Tile (1, 2): Slope \ (fill bottom-left)
        x1, y1, x2, y2 = t(x, y)
        draw.polygon([(x1, y1), (x1, y2-1), (x2-1, y2-1)], fill=color)
        
    def tree_root_left(x, y, color):
        # A root on the left of trunk. Should visually flow from ground up to right.
        # Shape: Right-Triangle at Bottom-Right of tile.
        x1, y1, x2, y2 = t(x, y)
        draw.polygon([(x1, y2-1), (x2-1, y2-1), (x2-1, y1)], fill=color) # / Slope

    def tree_root_right(x, y, color):
        # A root on the right of trunk. Flows from ground up to left.
        # Shape: Right-Triangle at Bottom-Left of tile.
        x1, y1, x2, y2 = t(x, y)
        draw.polygon([(x1, y2-1), (x2-1, y2-1), (x1, y1)], fill=color) # \ Slope

    # --- Row 0: Solids ---
    rect(0, 0, c_dirt)
    rect(1, 0, c_grass)
    rect(2, 0, c_stone)
    rect(3, 0, c_sand)
    
    # --- Row 1: Solids ---
    rect(0, 1, c_mud)
    rect(1, 1, c_trunk)
    rect(2, 1, c_leaves)
    rect(3, 1, c_snow)
    
    # --- Row 2: Slopes (Roots) ---
    # Using Trunk Color for roots
    # 0,2: Root Left 
    tree_root_left(0, 2, c_trunk)
    # 1,2: Root Center
    rect(1, 2, c_trunk)
    # 2,2: Root Right
    tree_root_right(2, 2, c_trunk)
    
    # 3,2: Stone Slope Left
    slope_left(3, 2, c_stone)
    
    # --- Row 3: Misc ---
    slope_right(0, 3, c_stone) # Stone Slope Right
    rect(1, 3, c_hard_rock)

    img.save("assets/minimalist_palette.png")
    print("Saved assets/minimalist_palette.png")

if __name__ == "__main__":
    main()
