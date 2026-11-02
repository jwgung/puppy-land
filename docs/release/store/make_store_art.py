"""Makes the Play Store pictures from the app's own art (pip install pillow):
- icon-512.png: the launcher icon (assets/icon/icon_bg_432.png + icon_fg_432.png) at 512 x 512,
- feature-graphic-ko.png: 1024 x 500, the throw lab's 3D scene alone (scene-throw.png,
  apps/lab3d/tools/capture_store_shots.gd) with the app's name on a paper card in the app's font.
Run from the repository root: python3 docs/release/store/make_store_art.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
STORE = Path(__file__).resolve().parent
ICON = ROOT / "apps/lab3d/assets/icon"
FONT = ROOT / "apps/lab3d/assets/fonts/NotoSansKR-Lab3dSubset-Bold.otf"
INK = (27, 42, 74)            # UiTheme INK
PAPER = (255, 246, 230, 240)  # UiTheme.DIALOGUE_PAPER
OUTLINE = (110, 70, 48)       # ArtPalette.OUTLINE
TITLE = "빵고양이 과학섬"
LINE = "직접 해 보는 물리 실험"


def icon() -> None:
    bg = Image.open(ICON / "icon_bg_432.png").convert("RGBA")
    fg = Image.open(ICON / "icon_fg_432.png").convert("RGBA")
    bg.alpha_composite(fg)
    bg.resize((512, 512), Image.LANCZOS).save(STORE / "icon-512.png")


def feature_graphic() -> None:
    shot = Image.open(STORE / "scene-throw.png").convert("RGBA")
    # Cover 1024 x 500 from the scene's middle band.
    scale = 1024 / shot.width * 1.2
    shot = shot.resize((round(shot.width * scale), round(shot.height * scale)), Image.LANCZOS)
    left = (shot.width - 1024) // 2
    top = round(shot.height * 0.12)
    art = shot.crop((left, top, left + 1024, top + 500))
    card = Image.new("RGBA", art.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)
    draw.rounded_rectangle((40, 140, 520, 360), radius=28, fill=PAPER, outline=OUTLINE, width=5)
    title = ImageFont.truetype(str(FONT), 64)
    line = ImageFont.truetype(str(FONT), 34)
    draw.text((280, 222), TITLE, font=title, fill=INK, anchor="mm")
    draw.text((280, 300), LINE, font=line, fill=OUTLINE, anchor="mm")
    art.alpha_composite(card)
    art.convert("RGB").save(STORE / "feature-graphic-ko.png")


if __name__ == "__main__":
    icon()
    feature_graphic()
    print("make_store_art:", STORE / "icon-512.png", STORE / "feature-graphic-ko.png")
