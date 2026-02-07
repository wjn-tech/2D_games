from PIL import Image, ImageDraw, ImageColor
import os

def create_palette():
    # 4 columns, 8 rows
    img_size_w = 64
    img_size_h = 128
    tile_size = 16
    img = Image.new('RGBA', (img_size_w, img_size_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    def draw_tile(gx, gy, fill_color, shape="rect", overlay=None):
        x = gx * tile_size
        y = gy * tile_size
        
        # Determine border color (darker version of fill)
        try:
            rgb = ImageColor.getrgb(fill_color)
            border_color = (max(0, rgb[0]-40), max(0, rgb[1]-40), max(0, rgb[2]-40))
        except:
            border_color = (0, 0, 0)
        
        def draw_shape(fill, outline):
            if shape == "rect":
                draw.rectangle([x, y, x + 15, y + 15], fill=fill, outline=outline)
            elif shape == "root_left":
                draw.rectangle([x+8, y, x+15, y+15], fill=fill, outline=None)
                draw.polygon([(x+8, y), (x, y+15), (x+8, y+15)], fill=fill, outline=None)
                draw.line([(x+15, y), (x+8, y), (x, y+15), (x+15, y+15)], fill=outline)
            elif shape == "root_right":
                draw.rectangle([x, y, x+7, y+15], fill=fill, outline=None)
                draw.polygon([(x+7, y), (x+15, y+15), (x+7, y+15)], fill=fill, outline=None)
                draw.line([(x, y), (x+7, y), (x+15, y+15), (x, y+15)], fill=outline)

        # Draw main shape
        draw_shape(fill_color, border_color)

        # Draw overlay if present
        if overlay == "iron":
            # Rusty Triangles
            tri_col = "#A0522D" # Sienna
            draw.polygon([(x+4, y+4), (x+8, y+10), (x+12, y+4)], fill=tri_col, outline=None)
            draw.polygon([(x+6, y+12), (x+10, y+12), (x+8, y+8)], fill=tri_col, outline=None)
        elif overlay == "copper":
            # Orange Squares
            sq_col = "#D2691E" # Chocolate
            draw.rectangle([x+3, y+3, x+6, y+6], fill=sq_col, outline=None)
            draw.rectangle([x+9, y+8, x+12, y+11], fill=sq_col, outline=None)
            draw.rectangle([x+4, y+10, x+6, y+12], fill=sq_col, outline=None)
        elif overlay == "crystal":
            # Purple Shard
            crys_col = "#9370DB" # MediumPurple
            draw.polygon([(x+8, y+2), (x+12, y+6), (x+8, y+14), (x+4, y+6)], fill=crys_col, outline="#FFFFFF")
        elif overlay == "core":
            # Blue Orb
            orb_col = "#00BFFF" # DeepSkyBlue
            draw.ellipse([x+4, y+4, x+12, y+12], fill=orb_col, outline="#FFFFFF")
        elif overlay == "speed":
            # Cyan Bolt
            bolt_col = "#00FFFF" # Cyan
            draw.polygon([(x+8, y+2), (x+4, y+8), (x+8, y+8), (x+6, y+14), (x+12, y+6), (x+8, y+6)], fill=bolt_col, outline="#FFFFFF")


    # -- Row 0 --
    draw_tile(0, 0, "#8B4513") # (0,0) Dirt (Medium Brown)
    draw_tile(1, 0, "#2E8B57") # (1,0) CANOPY - Forest Green
    draw_tile(2, 0, "#808080") # (2,0) Stone (Grey)
    draw_tile(3, 0, "#DAA520") # (3,0) Sand (Golden)

    # -- Row 1 --
    draw_tile(0, 1, "#4169E1") # (0,1) Water
    draw_tile(1, 1, "#FF4500") # (1,1) Lava
    draw_tile(2, 1, "#32CD32") # (2,1) Grass (Lime Green)
    draw_tile(3, 1, "#FFFFFF") # (3,1) Snow (Pure White) - FIXED MISSING
    
    # -- Row 2: Wood/Building --
    wood_col = "#5D4037"
    draw_tile(0, 2, wood_col, shape="root_left")  # (0,2) Root Left
    draw_tile(1, 2, wood_col, shape="rect")       # (1,2) Root Mid / Trunk
    draw_tile(2, 2, wood_col, shape="root_right") # (2,2) Root Right
    draw_tile(3, 2, "#4B3621") # (3,2) Mud (Dark Brown for Swamp)

    # -- Row 3 --
    draw_tile(0, 3, "#DEB887") # (0,3) Plank/Building
    draw_tile(1, 3, "#4A4A4A") # (1,3) Hard Rock (Dark Grey)
    draw_tile(2, 3, "#A5F2F3") # (2,3) Ice (Very Pale Blue)
    draw_tile(3, 3, "#2F4F4F") # (3,3) Dark Brick/Slated

    # -- Row 4: Minerals 1 --
    stone_base = "#808080"
    deep_base = "#2F4F4F"
    draw_tile(0, 4, stone_base, overlay="iron")    # (0,4) Iron
    draw_tile(1, 4, stone_base, overlay="copper")  # (1,4) Copper
    draw_tile(2, 4, deep_base, overlay="crystal")  # (2,4) Magic Crystal
    draw_tile(3, 4, deep_base, overlay="core")     # (3,4) Staff Core

    # -- Row 5: Minerals 2 --
    draw_tile(0, 5, "#000000", overlay="speed")    # (0,5) Magic Speed Stone

    output_path = "assets/minimalist_palette.png"
    img.save(output_path)
    print(f"Palette saved to {output_path}")

if __name__ == "__main__":
    create_palette()
