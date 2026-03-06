import math
import random
from PIL import Image, ImageDraw

def create_tileset():
    # 64x64 tiles, 3x3 layout
    # Row 0: Floor
    # Row 1: Wall
    # Row 2: Ceiling/Decor
    
    width = 192
    height = 192
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    pixels = img.load()
    draw = ImageDraw.Draw(img)

    # Helper colors
    c_metal_dark = (40, 40, 45, 255)
    c_metal_light = (70, 70, 75, 255)
    c_rust = (100, 60, 40, 255)
    c_hazard_yellow = (180, 160, 20, 255)
    c_hazard_black = (20, 20, 20, 255)

    def add_noise(x, y, w, h, intensity=10):
        for i in range(x, x+w):
            for j in range(y, y+h):
                r, g, b, a = pixels[i, j]
                noise = random.randint(-intensity, intensity)
                pixels[i, j] = (
                    max(0, min(255, r + noise)),
                    max(0, min(255, g + noise)),
                    max(0, min(255, b + noise)),
                    a
                )

    # --- Floor Tiles (Row 0) ---
    for i in range(3):
        x = i * 64
        y = 0
        # Base
        draw.rectangle([x, y, x+63, y+63], fill=c_metal_dark)
        # Grid pattern
        draw.rectangle([x+2, y+2, x+61, y+61], outline=c_metal_light, width=2)
        draw.line([x+32, y+2, x+32, y+61], fill=c_metal_light, width=2)
        draw.line([x+2, y+32, x+61, y+32], fill=c_metal_light, width=2)
        # Bolts
        draw.point([x+4, y+4], fill=c_metal_light)
        draw.point([x+60, y+4], fill=c_metal_light)
        draw.point([x+4, y+60], fill=c_metal_light)
        draw.point([x+60, y+60], fill=c_metal_light)
        add_noise(x, y, 64, 64)

    # --- Wall Tiles (Row 1) ---
    for i in range(3):
        x = i * 64
        y = 64
        # Base
        draw.rectangle([x, y, x+63, y+63], fill=c_metal_dark)
        # Vertical Pipes/Vent
        draw.rectangle([x+10, y, x+20, y+63], fill=c_metal_light)
        draw.rectangle([x+44, y, x+54, y+63], fill=c_metal_light)
        # Hazard Stripe (on one tile)
        if i == 1:
            for k in range(0, 64, 16):
                draw.polygon([(x, y+k), (x+16, y+k), (x, y+k+16)], fill=c_hazard_yellow)
                draw.polygon([(x+16, y+k), (x+64, y+k+48), (x+48, y+k+64)], fill=c_hazard_black) 
                # This logic is a bit messy for stripes, let's keep it simple
            draw.rectangle([x, y+20, x+63, y+40], fill=c_hazard_yellow)
            for k in range(0, 64, 10):
                 draw.line([x+k, y+20, x+k+10, y+40], fill=c_hazard_black, width=3)
        
        # Rust patches
        for _ in range(5):
            rx = random.randint(x, x+50)
            ry = random.randint(y, y+50)
            draw.ellipse([rx, ry, rx+10, ry+10], fill=c_rust)
            
        add_noise(x, y, 64, 64)

    # --- Ceiling/Details (Row 2) ---
    for i in range(3):
        x = i * 64
        y = 128
        draw.rectangle([x, y, x+63, y+63], fill=(30, 30, 35, 255))
        # Wires
        for _ in range(3):
            points = []
            cur_x = x
            cur_y = y + random.randint(10, 50)
            while cur_x < x + 64:
                points.append((cur_x, cur_y))
                cur_x += 5
                cur_y += random.randint(-2, 2)
            draw.line(points, fill=(20, 20, 20, 255), width=2)
        add_noise(x, y, 64, 64)

    img.save("assets/visuals/spaceship/tileset_industrial.png")

def create_props():
    # Cryo Pod
    img = Image.new('RGBA', (64, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([10, 10, 54, 118], fill=(50, 60, 80, 255), outline=(100, 100, 120, 255), width=2)
    draw.ellipse([20, 20, 44, 40], fill=(100, 200, 255, 100)) # Window
    img.save("assets/visuals/spaceship/prop_cryopod.png")

    # Console
    img = Image.new('RGBA', (96, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(10, 60), (86, 60), (96, 40), (0, 40)], fill=(60, 60, 70, 255)) # Base
    draw.rectangle([10, 10, 86, 40], fill=(20, 20, 30, 255), outline=(100, 100, 100, 255)) # Screen
    draw.rectangle([15, 15, 81, 35], fill=(0, 20, 0, 255)) # Screen inner
    draw.text((20, 20), "_SYSTEM_", fill=(0, 255, 0, 255))
    img.save("assets/visuals/spaceship/prop_console.png")

    # Broken Pipe
    img = Image.new('RGBA', (32, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([10, 0, 22, 64], fill=(80, 80, 90, 255))
    draw.rectangle([8, 20, 24, 40], fill=(0,0,0,0)) # Break (transparent)
    draw.polygon([(10, 20), (22, 20), (16, 25)], fill=(60, 60, 70, 255)) # Jagged top
    draw.polygon([(10, 40), (22, 40), (16, 35)], fill=(60, 60, 70, 255)) # Jagged bottom
    img.save("assets/visuals/spaceship/prop_pipe_broken.png")

def create_particles():
    # Spark
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.line([8, 2, 8, 14], fill=(255, 200, 100, 255), width=2)
    draw.line([2, 8, 14, 8], fill=(255, 200, 100, 255), width=2)
    img.save("assets/visuals/spaceship/particle_spark.png")

    # Steam
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for i in range(10):
        x = random.randint(5, 25)
        y = random.randint(5, 25)
        r = random.randint(2, 6)
        draw.ellipse([x-r, y-r, x+r, y+r], fill=(200, 200, 200, 100))
    img.save("assets/visuals/spaceship/particle_steam.png")
    
    # Debris
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(0,0), (16,4), (8,16), (4,8)], fill=(50, 50, 50, 255))
    img.save("assets/visuals/spaceship/particle_debris.png")

def create_bg():
    img = Image.new('RGBA', (512, 512), (5, 5, 10, 255))
    draw = ImageDraw.Draw(img)
    for _ in range(100):
        x = random.randint(0, 511)
        y = random.randint(0, 511)
        draw.point([x, y], fill=(255, 255, 255, random.randint(100, 255)))
    img.save("assets/visuals/spaceship/bg_stars.png")

if __name__ == "__main__":
    create_tileset()
    create_props()
    create_particles()
    create_bg()
