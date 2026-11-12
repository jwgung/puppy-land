"""The start screen picture, step 2: the red ribbon banner over the trio's lower edge (splash.py
renders the trio). A red ribbon with folded tails and the characters' brown outline, no letters: the
app's name is drawn over the ribbon by the title screen in the language (TitleScreen.title_label,
ui.json `app.title`; #128, 2026-11-12 user: "문자열 처리하면 번역하기도 좋잖아"; until then the name was
painted in here, one picture per language). One picture for every language. Transparent around it.

Run (system Python with Pillow and NumPy), from the repository root:
    python3 apps/lab3d/art_src/characters/splash_banner.py [--trio /tmp/op-splash/splash_trio.png] \
        [--out apps/lab3d/assets/icon/splash.png]
It prints the ribbon band's rect in fractions of the picture (RIBBON): TitleScreen.RIBBON.
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SS = 2                       # drawn at 2x, then halved (smooth edges)
OUT_W = 1200                 # final width (px); the boot splash shows it at its own size
RED = (226, 72, 60, 255)
RED_DARK = (170, 46, 40, 255)
OUTLINE = (110, 70, 48, 255)   # ArtPalette.OUTLINE #6e4630
CREAM = (255, 246, 230, 255)   # UiTheme.DIALOGUE_PAPER


def ribbon(w, top, h):
    """The ribbon (main band and two folded tails) on a transparent canvas of width w (x SS)."""
    line = 7 * SS
    canvas = Image.new("RGBA", (w, top + h + int(h * 0.28) + 40 * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    band_l, band_r = int(w * 0.12), int(w * 0.88)
    tail = int(h * 0.9)
    drop = int(h * 0.28)
    for side in (-1, 1):   # tails: behind the band, lower, with a V notch at the outer end
        inner = band_l + tail * 0.55 if side < 0 else band_r - tail * 0.55
        outer = band_l - tail if side < 0 else band_r + tail
        y0, y1 = top + drop, top + drop + h
        notch = outer - side * h * 0.35
        poly = [(inner, y0), (outer, y0), (notch, (y0 + y1) / 2), (outer, y1), (inner, y1)]
        d.polygon(poly, fill=RED, outline=OUTLINE, width=line)
        fold = band_l if side < 0 else band_r   # the dark fold under the band's end
        d.polygon([(fold, top + h), (fold, top + h + drop), (fold - side * tail * 0.35, top + h + drop)],
                  fill=RED_DARK, outline=OUTLINE, width=line)
    d.rounded_rectangle((band_l, top, band_r, top + h), radius=int(h * 0.18), fill=RED, outline=OUTLINE, width=line)
    # No highlight line along the band's top (#128, 2026-11-12 user: "상단에 또 빈줄 생긴다", "아직도
    # 보이는데"): over the plain band it read as a blank stripe.
    return canvas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--trio", default="/tmp/op-splash/splash_trio.png")
    ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "assets", "icon", "splash.png"))
    args = ap.parse_args()

    trio = Image.open(args.trio).convert("RGBA")
    tw, th = trio.size
    trio = trio.resize((tw * SS, th * SS), Image.LANCZOS)
    band_h = int(th * 0.27) * SS
    top = th * SS - int(band_h * 0.95)   # its bottom just past the trio's cut edge: hides it, under the faces
    banner = ribbon(tw * SS, top, band_h)
    canvas = Image.new("RGBA", (tw * SS, banner.height), (0, 0, 0, 0))
    canvas.alpha_composite(trio, (0, 0))
    # A soft shadow under the ribbon, so it sits in front of the characters.
    shadow = Image.new("RGBA", banner.size, (0, 0, 0, 0))
    shadow.putalpha(banner.getchannel("A").point(lambda a: int(a * 0.25)))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10 * SS)), (0, 8 * SS))
    canvas.alpha_composite(banner)

    bbox = canvas.getbbox()
    canvas = canvas.crop((0, bbox[1], canvas.width, bbox[3]))
    band = (int(canvas.width * 0.12), top - bbox[1], int(canvas.width * 0.88), top - bbox[1] + band_h)
    print("RIBBON %.4f %.4f %.4f %.4f" % (band[0] / canvas.width, band[1] / canvas.height,
                                          (band[2] - band[0]) / canvas.width, band_h / canvas.height))
    out_h = round(canvas.height * OUT_W / canvas.width)
    canvas = canvas.resize((OUT_W, out_h), Image.LANCZOS)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    canvas.save(args.out)
    print("SPLASH", os.path.abspath(args.out), canvas.size)


if __name__ == "__main__":
    main()
