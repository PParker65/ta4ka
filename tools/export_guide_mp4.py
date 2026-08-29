#!/usr/bin/env python3
"""Render the Apex function slideshow as a vertical film MP4."""

from __future__ import annotations

import math
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1920
FPS = 30
DURATION = 14.0
FRAMES = int(FPS * DURATION)
SLIDES = 5

BG = [(11, 34, 51), (7, 20, 31), (4, 10, 16)]
INK = (232, 232, 237)
ACCENT = (72, 160, 200)
MUTED = (142, 154, 168)
TITLE = "ЯК ПРАЦЮЄ APEX"
STEPS = ["МАРКА АВТО", "ЩО ТРЕБА", "ОБЕРІТЬ СТО", "ПОСЛУГИ", "ЗАПИС У ВІКНО"]
FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
OUT = os.path.join(os.path.dirname(__file__), "..", "exports", "apex_mini_guide_tiktok.mp4")


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c0, c1, t: float):
    return tuple(int(lerp(c0[i], c1[i], t)) for i in range(3))


def bg_color(y: int) -> tuple[int, int, int]:
    u = y / (H - 1)
    if u < 0.55:
        return mix(BG[0], BG[1], u / 0.55)
    return mix(BG[1], BG[2], (u - 0.55) / 0.45)


def ease_out_cubic(x: float) -> float:
    return 1 - (1 - x) ** 3


def pulse(x: float) -> float:
    u = max(0.0, min(4.0, x * 10))
    return math.exp(-u * u * 1.6)


def draw_text(draw, text, xy, font, fill):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x, y = xy[0] - tw / 2, xy[1] - th / 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=fill)


def make_gradient() -> Image.Image:
    strip = Image.new("RGB", (1, H))
    px = strip.load()
    for y in range(H):
        px[0, y] = bg_color(y)
    return strip.resize((W, H), Image.Resampling.BILINEAR)


def seal(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int, alpha: int):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=ACCENT + (alpha,), width=5)
    d.ellipse((cx - int(r * 0.86), cy - int(r * 0.86), cx + int(r * 0.86), cy + int(r * 0.86)), outline=ACCENT + (int(alpha * 0.35),), width=2)
    for k in range(24):
        a = k * math.pi / 12 - math.pi / 2
        major = k % 6 == 0
        inner = r * (0.90 if major else 0.94)
        d.line(
            (
                cx + math.cos(a) * inner,
                cy + math.sin(a) * inner,
                cx + math.cos(a) * r * 0.99,
                cy + math.sin(a) * r * 0.99,
            ),
            fill=ACCENT + (alpha,),
            width=3 if major else 1,
        )


def mark_brand(d, cx, cy, a):
    seal(d, cx, cy, 210, a)
    d.rounded_rectangle((cx - 120, cy - 36, cx + 120, cy + 36), 14, fill=(242, 242, 246, a), outline=ACCENT + (a,), width=4)
    d.rounded_rectangle((cx - 20, cy - 62, cx + 70, cy - 18), 8, fill=(42, 51, 64, a))
    d.ellipse((cx - 70, cy + 20, cx - 30, cy + 60), fill=(17, 17, 20, a))
    d.ellipse((cx + 30, cy + 20, cx + 70, cy + 60), fill=(17, 17, 20, a))
    d.ellipse((cx + 100, cy - 10, cx + 116, cy + 6), fill=(255, 213, 74, a))


def mark_issue(d, cx, cy, a, hold):
    seal(d, cx, cy, 210, a)
    d.polygon(
        [(cx - 90, cy + 20), (cx - 70, cy - 10), (cx - 20, cy - 28), (cx + 40, cy - 28), (cx + 90, cy - 4), (cx + 100, cy + 20)],
        outline=INK + (a,),
        width=4,
    )
    spots = [(cx - 18, cy - 70), (cx + 60, cy + 8), (cx - 64, cy + 4)]
    for k, (x, y) in enumerate(spots):
        beat = 0.5 + 0.5 * math.sin((hold * 6 + k) * math.pi)
        rr = int(14 + beat * 8)
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=ACCENT + (int(50 + 70 * beat),))
        d.ellipse((x - 8, y - 8, x + 8, y + 8), fill=ACCENT + (a,))


def mark_shop(d, cx, cy, a):
    seal(d, cx, cy, 220, a)
    d.rounded_rectangle((cx - 90, cy - 40, cx + 100, cy + 90), 10, fill=(21, 32, 44, a), outline=ACCENT + (a,), width=3)
    d.polygon([(cx - 100, cy - 40), (cx + 6, cy - 110), (cx + 112, cy - 40)], outline=ACCENT + (a,), width=4)
    d.rectangle((cx - 30, cy + 10, cx + 40, cy + 90), fill=(10, 18, 24, a))
    d.ellipse((cx - 70, cy - 20, cx - 54, cy - 4), fill=(255, 213, 74, a))


def mark_services(d, cx, cy, a, hold):
    seal(d, cx, cy, 220, a)
    for k in range(3):
        y = cy - 70 + k * 56
        lit = int(hold * 3) % 3 == k
        fill = ACCENT + (70,) if lit else (21, 32, 44, a)
        d.rounded_rectangle((cx - 90, y, cx + 90, y + 40), 8, fill=fill, outline=ACCENT + (a,), width=3)
        d.line((cx - 70, y + 20, cx + 40, y + 20), fill=INK + (a,), width=3)


def mark_slot(d, cx, cy, a, hold):
    r = 200
    seal(d, cx, cy, r, a)
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), outline=ACCENT + (a,), width=3)
    ang = -math.pi / 2 + hold * math.pi * 1.4
    d.line((cx, cy, cx + math.cos(ang) * 90, cy + math.sin(ang) * 90), fill=ACCENT + (a,), width=6)
    d.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=ACCENT + (a,))


def make_frame(t: float, fonts, gradient: Image.Image) -> Image.Image:
    raw = min(SLIDES - 0.0001, t * SLIDES)
    i = int(raw)
    u = raw - i
    appear = ease_out_cubic(min(1.0, u / 0.22))
    hold = max(0.0, min(1.0, (u - 0.18) / 0.62))
    fade = 1.0 if u < 0.82 else 1 - ((u - 0.82) / 0.18)
    heart = (0.0 if u < 0.18 else pulse(u - 0.20)) + (0.0 if u < 0.44 else 0.4 * pulse(u - 0.48))
    alpha = int(255 * max(0.0, min(1.0, appear * fade)))
    grow = (0.55 + 0.45 * appear) * (1.0 + 0.08 * heart) * fade

    img = gradient.copy()
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    for g in range(1, 6):
        y = int(H * g / 6)
        d.line((0, y, W, y), fill=(168, 212, 238, 18), width=2)
    for g in range(1, 8):
        x = int(W * g / 8)
        d.line((x, 0, x, H), fill=(168, 212, 238, 18), width=2)

    cx, cy = W // 2, int(H * 0.42)
    bloom = int(280 * grow)
    d.ellipse((cx - bloom, cy - bloom, cx + bloom, cy + bloom), fill=ACCENT + (int(40 + 50 * heart),))

    mark = (mark_brand, mark_issue, mark_shop, mark_services, mark_slot)[i]
    if i in (1, 3, 4):
        mark(d, cx, cy, alpha, hold)
    else:
        mark(d, cx, cy, alpha)

    draw_text(d, TITLE, (W * 0.50, H * 0.12), fonts["sm"], INK + (alpha,))
    draw_text(d, STEPS[i], (W * 0.50, H * 0.72), fonts["xl"], INK + (alpha,))
    gap = 36
    start = cx - (SLIDES - 1) * gap / 2
    for k in range(SLIDES):
        rr = 8 if k == i else 5
        col = ACCENT if k == i else MUTED
        d.ellipse((start + k * gap - rr, H * 0.82 - rr, start + k * gap + rr, H * 0.82 + rr), fill=col + (alpha,))

    img_rgba = img.convert("RGBA")
    img_rgba.alpha_composite(overlay)
    return img_rgba.convert("RGB")


def ffmpeg_exe() -> str:
    import imageio_ffmpeg

    return imageio_ffmpeg.get_ffmpeg_exe()


def main() -> None:
    out = os.path.abspath(OUT)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    fonts = {
        "sm": ImageFont.truetype(FONT, 34),
        "xl": ImageFont.truetype(FONT, 56),
    }
    gradient = make_gradient()
    cmd = [
        ffmpeg_exe(), "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
        "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "17",
        "-preset", "medium", "-movflags", "+faststart", "-an", out,
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
    assert proc.stdin is not None
    for i in range(FRAMES):
        t = i / (FRAMES - 1)
        frame = make_frame(t, fonts, gradient)
        proc.stdin.write(frame.tobytes())
        if i % 30 == 0:
            print(f"{i}/{FRAMES}", flush=True)
    proc.stdin.close()
    err = proc.stderr.read().decode("utf-8", errors="replace")
    code = proc.wait()
    if code != 0:
        sys.stderr.write(err)
        raise SystemExit(code)
    print(out)
    print(f"{os.path.getsize(out) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
