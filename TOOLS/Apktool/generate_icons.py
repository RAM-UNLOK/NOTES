import os
from PIL import Image, ImageDraw

SOURCE_IMAGE = "source.png"
OUTPUT_DIR = "app/src/main/res"
BG_HEX = "#f2f2f2"
PREFIX = "etk_"

ADAPTIVE_SIZES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

LEGACY_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

def hex_to_rgba(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4)) + (255,)

def main():
    if not os.path.exists(SOURCE_IMAGE):
        print(f"Error: Place your lens image as '{SOURCE_IMAGE}'")
        return

    src = Image.open(SOURCE_IMAGE).convert("RGBA")
    bg_rgba = hex_to_rgba(BG_HEX)

    for density, ad_size in ADAPTIVE_SIZES.items():
        density_dir = os.path.join(OUTPUT_DIR, density)
        os.makedirs(density_dir, exist_ok=True)
        leg_size = LEGACY_SIZES[density]

        # 1. Adaptive Foreground (Safe zone ~66%)
        fg = Image.new("RGBA", (ad_size, ad_size), (0, 0, 0, 0))
        c_size = int(ad_size * 0.66)
        scaled = src.resize((c_size, c_size), Image.Resampling.LANCZOS)
        fg.paste(scaled, ((ad_size - c_size) // 2, (ad_size - c_size) // 2), scaled)
        fg.save(os.path.join(density_dir, f"{PREFIX}ic_launcher_foreground.png"), "PNG")

        # 2. Legacy Fallback (for Settings / App Info)
        legacy = Image.new("RGBA", (leg_size, leg_size), bg_rgba)
        c_size_leg = int(leg_size * 0.85)
        scaled_leg = src.resize((c_size_leg, c_size_leg), Image.Resampling.LANCZOS)
        legacy.paste(scaled_leg, ((leg_size - c_size_leg) // 2, (leg_size - c_size_leg) // 2), scaled_leg)
        legacy.save(os.path.join(density_dir, f"{PREFIX}ic_launcher.png"), "PNG")

        # 3. Legacy Round Fallback
        mask = Image.new("L", (leg_size, leg_size), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, leg_size, leg_size), fill=255)
        round_icon = Image.new("RGBA", (leg_size, leg_size), (0, 0, 0, 0))
        round_icon.paste(legacy, (0, 0), mask=mask)
        round_icon.save(os.path.join(density_dir, f"{PREFIX}ic_launcher_round.png"), "PNG")

        print(f"Generated {density} files.")

if __name__ == "__main__":
    main()
