#!/usr/bin/env python3
"""Apex promo — 8 fast, denser scenes, vertical MP4, Russian."""

from __future__ import annotations

import math
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1920
FPS = 30
SCENE_SEC = 2.15
SCENES = 8
DURATION = SCENE_SEC * SCENES
FRAMES = int(FPS * DURATION)

INK = (244, 245, 248)
LEAD = (196, 204, 214)
ACCENT = (86, 168, 206)
RED = (215, 2, 0)
GOLD = (255, 213, 74)
MUTED = (154, 164, 176)
DIM = (92, 104, 118)
BG = [(8, 18, 30), (5, 11, 18), (3, 7, 12)]

FONT_HN = "/System/Library/Fonts/HelveticaNeue.ttc"
FONT_DIN = "/System/Library/Fonts/Supplemental/DIN Alternate Bold.ttf"
OUT_DIR = os.path.expanduser("~/Desktop/промо-видео")
OUT = os.path.join(OUT_DIR, "Apex_promo.mp4")

COPY = [
    ("01", "APEX", "Одно приложение вместо десятков звонков в сервис"),
    ("02", "Своя лента", "Соцсеть СТО: ролики, живые боксы, запись в один тап"),
    ("03", "СТО рядом", "Карта, рейтинг и свободное окно — без угадывания"),
    ("04", "Любые работы", "Мойка, диагностика, ходовая, малярка — всё здесь"),
    ("05", "Живой бокс", "Камера ремонта, пока машина в сервисе"),
    ("06", "Авто из США", "Copart / IAAI под ключ: океан, таможня, ключи в городе"),
    ("07", "Страховка", "Полис рядом с записью — без очередей и бумаг"),
    ("08", "Заработок", "Приводи СТО в Apex — доля с каждой записи клиента"),
]


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c0, c1, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(lerp(c0[i], c1[i], t)) for i in range(len(c0)))


def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def ease_out_cubic(x):
    x = clamp(x)
    return 1 - (1 - x) ** 3


def ease_in_out_cubic(x):
    x = clamp(x)
    return 4 * x * x * x if x < 0.5 else 1 - (-2 * x + 2) ** 3 / 2


def ease_out_back(x):
    x = clamp(x)
    c = 1.70158
    return 1 + (c + 1) * (x - 1) ** 3 + c * (x - 1) ** 2


def pulse_at(t, at, k=16.0):
    x = (t - at) * k
    if x < -0.15:
        return 0.0
    if x < 0:
        return ease_out_cubic((x + 0.15) / 0.15)
    return math.exp(-x * x * 2.4)


def heart(t):
    return clamp(pulse_at(t, 0.10) + 0.55 * pulse_at(t, 0.42))


def A(c, a):
    a = int(clamp(a) * 255)
    return (c[0], c[1], c[2], a)


def bg_color(y):
    u = y / (H - 1)
    return mix(BG[0], BG[1], u / 0.52) if u < 0.52 else mix(BG[1], BG[2], (u - 0.52) / 0.48)


def make_gradient():
    strip = Image.new("RGB", (1, H))
    px = strip.load()
    for y in range(H):
        px[0, y] = bg_color(y)
    return strip.resize((W, H), Image.Resampling.BILINEAR)


def load_fonts():
    return {
        "eye": ImageFont.truetype(FONT_DIN, 22),
        "title": ImageFont.truetype(FONT_HN, 68, index=1),
        "lead": ImageFont.truetype(FONT_HN, 30, index=0),
        "chip": ImageFont.truetype(FONT_HN, 18, index=1),
        "sm": ImageFont.truetype(FONT_HN, 22, index=1),
        "md": ImageFont.truetype(FONT_HN, 30, index=1),
        "lg": ImageFont.truetype(FONT_HN, 44, index=1),
        "tiny": ImageFont.truetype(FONT_DIN, 16),
        "brand": ImageFont.truetype(FONT_DIN, 18),
    }


def tsize(draw, text, font):
    b = draw.textbbox((0, 0), text, font=font)
    return b[2] - b[0], b[3] - b[1], b[1]


def draw_tracked(draw, text, xy, font, fill, tracking=1.2, align="center"):
    if not text:
        return 0
    widths = []
    for ch in text:
        w, _, _ = tsize(draw, ch, font)
        widths.append(w)
    total = sum(widths) + tracking * (len(text) - 1)
    x0 = xy[0] - total / 2 if align == "center" else xy[0]
    _, th, top = tsize(draw, text, font)
    y = xy[1] - th / 2 - top
    x = x0
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=font, fill=fill)
        x += w + tracking
    return total


def wrap_lines(draw, text, font, max_w):
    words = text.split()
    lines, cur = [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        tw, _, _ = tsize(draw, trial, font)
        if tw <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def rounded(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def grid(d, a=18):
    col = (168, 212, 238, a)
    for i in range(1, 6):
        y = int(H * i / 6)
        d.line((0, y, W, y), fill=col, width=1)
    for i in range(1, 8):
        x = int(W * i / 8)
        d.line((x, 0, x, H), fill=col, width=1)


def bloom(d, cx, cy, r, col, a):
    if r <= 4 or a <= 0:
        return
    for i in range(8, 0, -1):
        u = i / 8
        rr = int(r * u)
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=col + (int(a * 255 * (1 - u) * 0.5),))


def rings(d, cx, cy, t, col, s=160):
    for beat in (0.10, 0.42):
        if t < beat:
            continue
        age = clamp((t - beat) / 0.22)
        r = int(s * (0.28 + 1.45 * ease_out_cubic(age)))
        d.ellipse(
            (cx - r, cy - r, cx + r, cy + r),
            outline=col + (int((1 - age) * 150),),
            width=max(1, int(3.5 * (1 - age))),
        )


def captions(d, fonts, i, u, a):
    eye, title, lead = COPY[i]
    pad = 72
    # progress
    rounded(d, (pad, 58, W - pad, 64), 3, fill=(38, 50, 62, int(110 * a)))
    bar_w = int((W - pad * 2) * min(1.0, (i + ease_out_cubic(u)) / SCENES))
    rounded(d, (pad, 58, pad + max(10, bar_w), 64), 3, fill=A(ACCENT, a))

    draw_tracked(d, f"{eye}  /  08", (W * 0.5, 108), fonts["eye"], A(ACCENT, 0.92 * a), tracking=5.5)

    shown = max(1, int(len(title) * ease_out_cubic(min(1, u / 0.18))))
    tw = draw_tracked(d, title[:shown], (W * 0.5, 172), fonts["title"], A(INK, a), tracking=0.6)
    rule_w = max(56, min(240, tw * 0.42 if tw else 56))
    d.line((W * 0.5 - rule_w / 2, 218, W * 0.5 + rule_w / 2, 218), fill=A(ACCENT, 0.9 * a), width=3)

    lines = wrap_lines(d, lead, fonts["lead"], W - pad * 2 - 24)
    y0 = 272
    for n, line in enumerate(lines[:3]):
        draw_tracked(d, line, (W * 0.5, y0 + n * 42), fonts["lead"], A(LEAD, 0.98 * a), tracking=0.08)

    gap = 26
    start = W * 0.5 - (SCENES - 1) * gap / 2
    for k in range(SCENES):
        on = k == i
        r = 6 if on else 3.5
        d.ellipse(
            (start + k * gap - r, H * 0.918 - r, start + k * gap + r, H * 0.918 + r),
            fill=A(ACCENT if on else DIM, (1.0 if on else 0.42) * a),
        )
    draw_tracked(d, "APEX", (W * 0.5, H * 0.954), fonts["brand"], A(DIM, 0.85 * a), tracking=8)


def draw_car(base, cx, cy, ang, scale, stroke=ACCENT):
    car = Image.new("RGBA", (320, 168), (0, 0, 0, 0))
    d = ImageDraw.Draw(car)
    ox, oy = 160, 86
    d.ellipse((ox - 70, oy + 28, ox + 70, oy + 52), fill=(0, 0, 0, 90))
    # body
    rounded(d, (ox - 78, oy - 10, ox + 78, oy + 28), 14, fill=(248, 248, 252, 255), outline=stroke + (255,), width=3)
    # hood / trunk crease
    d.line((ox - 18, oy - 8, ox - 18, oy + 22), fill=stroke + (90,), width=2)
    d.line((ox + 22, oy - 8, ox + 22, oy + 22), fill=stroke + (90,), width=2)
    # cabin
    rounded(d, (ox - 18, oy - 46, ox + 48, oy - 6), 8, fill=(18, 28, 40, 255), outline=stroke + (200,), width=2)
    rounded(d, (ox - 8, oy - 40, ox + 16, oy - 14), 4, fill=ACCENT + (140,))
    rounded(d, (ox + 22, oy - 40, ox + 42, oy - 14), 4, fill=ACCENT + (90,))
    d.line((ox - 74, oy + 8, ox + 74, oy + 8), fill=stroke + (170,), width=2)
    # grille
    rounded(d, (ox + 62, oy - 4, ox + 76, oy + 16), 3, fill=(22, 28, 34, 255))
    d.ellipse((ox + 66, oy - 12, ox + 78, oy + 2), fill=GOLD + (255,))
    d.ellipse((ox + 66, oy + 10, ox + 78, oy + 22), fill=GOLD + (180,))
    d.ellipse((ox - 80, oy + 2, ox - 70, oy + 14), fill=(255, 72, 72, 255))
    # mirror
    rounded(d, (ox + 46, oy - 18, ox + 60, oy - 8), 3, fill=(230, 232, 236, 255), outline=stroke + (200,), width=1)
    for wx in (ox - 42, ox + 40):
        d.ellipse((wx - 18, oy + 10, wx + 18, oy + 46), fill=(12, 12, 16, 255), outline=stroke + (160,), width=2)
        d.ellipse((wx - 9, oy + 19, wx + 9, oy + 37), fill=(118, 158, 180, 255))
        d.line((wx - 8, oy + 28, wx + 8, oy + 28), fill=(20, 24, 28, 255), width=2)
        d.line((wx, oy + 20, wx, oy + 36), fill=(20, 24, 28, 255), width=2)
    car = car.resize((max(8, int(320 * scale)), max(8, int(168 * scale))), Image.Resampling.LANCZOS)
    car = car.rotate(-math.degrees(ang), resample=Image.Resampling.BICUBIC, expand=True)
    base.alpha_composite(car, (int(cx - car.width / 2), int(cy - car.height / 2)))


def flag_us(d, p, s=22):
    x, y = p
    rounded(d, (x - s, y - s * 0.64, x + s, y + s * 0.64), 3, fill=(178, 34, 52, 255))
    d.rectangle((x - s, y - s * 0.64, x - 2, y + 2), fill=(60, 59, 110, 255))
    for i in range(4):
        yy = y - s * 0.48 + i * 6
        d.line((x - 2, yy, x + s - 2, yy), fill=(255, 255, 255, 210), width=2)


def flag_ua(d, p, s=22):
    x, y = p
    rounded(d, (x - s, y - s * 0.64, x + s, y + s * 0.64), 3, fill=(0, 91, 187, 255))
    d.rectangle((x - s, y, x + s, y + s * 0.64), fill=(255, 213, 0, 255))


def bezier(p0, p1, p2, u):
    u = clamp(u)
    x = (1 - u) ** 2 * p0[0] + 2 * (1 - u) * u * p1[0] + u * u * p2[0]
    y = (1 - u) ** 2 * p0[1] + 2 * (1 - u) * u * p1[1] + u * u * p2[1]
    dx = 2 * (1 - u) * (p1[0] - p0[0]) + 2 * u * (p2[0] - p1[0])
    dy = 2 * (1 - u) * (p1[1] - p0[1]) + 2 * u * (p2[1] - p1[1])
    return x, y, math.atan2(dy, dx)


def phone(d, fonts, cx, cy, w, h, t, a, live=False, label=""):
    aa = int(255 * a)
    rounded(d, (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), 28, fill=(12, 20, 30, aa), outline=ACCENT + (aa,), width=3)
    d.rounded_rectangle((cx - 24, cy - h / 2 + 10, cx + 24, cy - h / 2 + 20), 5, fill=(6, 10, 14, aa))
    inner = (cx - w / 2 + 12, cy - h / 2 + 28, cx + w / 2 - 12, cy + h / 2 - 16)
    rounded(d, inner, 14, fill=(8, 14, 22, aa))
    # stories
    for i in range(4):
        sx = inner[0] + 28 + i * 42
        sy = inner[1] + 22
        d.ellipse((sx - 14, sy - 14, sx + 14, sy + 14), outline=ACCENT + (aa,), width=2)
        d.ellipse((sx - 8, sy - 8, sx + 8, sy + 8), fill=ACCENT + (int(aa * 0.35),))
    vy = inner[1] + 48
    vh = h * 0.42
    rounded(d, (inner[0] + 8, vy, inner[2] - 8, vy + vh), 12, fill=ACCENT + (int(aa * 0.16),), outline=ACCENT + (aa,), width=2)
    # play
    d.ellipse((cx - 20, vy + vh * 0.38, cx + 20, vy + vh * 0.38 + 40), outline=INK + (aa,), width=3)
    d.polygon(
        [(cx - 6, vy + vh * 0.40 + 8), (cx - 6, vy + vh * 0.40 + 28), (cx + 12, vy + vh * 0.40 + 18)],
        fill=INK + (aa,),
    )
    # actions
    ay = vy + vh + 18
    d.ellipse((inner[0] + 18, ay, inner[0] + 38, ay + 20), outline=RED + (aa,), width=2)
    d.ellipse((inner[0] + 48, ay, inner[0] + 68, ay + 20), outline=INK + (int(aa * 0.7),), width=2)
    if label:
        draw_tracked(d, label, (cx, ay + 36), fonts["tiny"], A(LEAD, a), tracking=1.4)
    rounded(d, (inner[0] + 16, inner[3] - 36, inner[2] - 16, inner[3] - 12), 8, fill=ACCENT + (int(aa * 0.85),))
    if live:
        rounded(d, (cx - 46, cy - h / 2 - 10, cx + 46, cy - h / 2 + 16), 13, fill=RED + (aa,))
        draw_tracked(d, "LIVE", (cx, cy - h / 2 + 3), fonts["tiny"], (255, 255, 255, aa), tracking=2.6)


def shop_crest(d, p, s, a):
    x, y = p
    aa = int(255 * a)
    rounded(d, (x - s * 0.52, y - s * 0.08, x + s * 0.52, y + s * 0.58), 5, fill=(16, 24, 34, aa), outline=ACCENT + (aa,), width=2)
    d.polygon([(x - s * 0.58, y - s * 0.06), (x, y - s * 0.68), (x + s * 0.58, y - s * 0.06)], outline=ACCENT + (aa,), width=2)
    d.rectangle((x - s * 0.16, y + 6, x + s * 0.16, y + s * 0.58), fill=(8, 12, 16, aa))
    d.ellipse((x - s * 0.38, y + 2, x - s * 0.24, y + 16), fill=GOLD + (aa,))
    d.ellipse((x + s * 0.24, y + 2, x + s * 0.38, y + 16), fill=GOLD + (aa,))


def camera_body(d, fonts, cx, cy, t, a):
    aa = int(255 * a)
    rounded(d, (cx - 240, cy - 168, cx + 240, cy + 148), 20, fill=(14, 22, 32, aa), outline=ACCENT + (aa,), width=3)
    # viewfinder corners
    for sx, sy in ((-226, -154), (226, -154), (-226, 134), (226, 134)):
        dx = 1 if sx > 0 else -1
        dy = 1 if sy > 0 else -1
        d.line((cx + sx, cy + sy, cx + sx - 32 * dx, cy + sy), fill=INK + (aa,), width=3)
        d.line((cx + sx, cy + sy, cx + sx, cy + sy - 32 * dy), fill=INK + (aa,), width=3)
    # inner bay
    rounded(d, (cx - 168, cy - 78, cx + 168, cy + 86), 12, fill=(10, 16, 24, aa))
    d.rectangle((cx - 132, cy - 4, cx - 120, cy + 72), fill=ACCENT + (int(aa * 0.55),))
    d.rectangle((cx + 120, cy - 4, cx + 132, cy + 72), fill=ACCENT + (int(aa * 0.55),))
    d.line((cx - 132, cy - 4, cx + 132, cy - 4), fill=ACCENT + (aa,), width=3)
    blink = 0.45 + 0.55 * math.sin(t * math.pi * 10)
    d.ellipse((cx + 196, cy - 144, cx + 218, cy - 122), fill=RED + (int(aa * blink),))
    draw_tracked(d, "REC  00:14", (cx - 132, cy - 132), fonts["tiny"], A(RED, a), tracking=2.0)
    sy = cy - 64 + ((t * 120) % 128)
    d.line((cx - 156, sy, cx + 156, sy), fill=ACCENT + (int(aa * 0.55),), width=2)


def shield(d, p, s, a, beat):
    x, y = p
    aa = int(255 * a)
    path = [
        (x, y - s),
        (x + s * 0.72, y - s * 0.48),
        (x + s * 0.58, y + s * 0.34),
        (x, y + s),
        (x - s * 0.58, y + s * 0.34),
        (x - s * 0.72, y - s * 0.48),
    ]
    d.polygon(path, outline=GOLD + (aa,), fill=(GOLD[0], GOLD[1], GOLD[2], int(40 + 80 * beat)), width=4)
    d.line([(x - s * 0.22, y + 8), (x - 2, y + s * 0.38), (x + s * 0.32, y - s * 0.28)], fill=INK + (aa,), width=7)


def coins(d, src, dst, t, a, n=8):
    aa = int(255 * a)
    for i in range(n):
        u = (t * 1.05 + i / n) % 1.0
        e = ease_in_out_cubic(u)
        x = lerp(src[0], dst[0], e)
        y = lerp(src[1], dst[1], e) - math.sin(e * math.pi) * 70
        r = 8 + 2 * math.sin(u * math.pi)
        d.ellipse(
            (x - r, y - r, x + r, y + r),
            fill=GOLD + (int(aa * (0.4 + 0.55 * (1 - abs(u - 0.5) * 2))),),
            outline=(170, 130, 40, aa),
            width=2,
        )


def map_pin(d, p, a, pulse=0.0):
    x, y = p
    aa = int(255 * a)
    r = 12 + pulse * 8
    d.ellipse((x - r, y - r - 6, x + r, y + r - 6), fill=ACCENT + (int(40 + 90 * pulse),))
    d.ellipse((x - 9, y - 16, x + 9, y + 2), fill=ACCENT + (aa,))
    d.polygon([(x, y + 18), (x - 9, y + 2), (x + 9, y + 2)], fill=ACCENT + (aa,))
    d.ellipse((x - 4, y - 11, x + 4, y - 3), fill=(8, 14, 22, aa))


def scene_index(t):
    raw = min(SCENES - 1e-6, t * SCENES)
    i = int(raw)
    u = raw - i
    appear = ease_out_cubic(min(1.0, u / 0.08))
    fade = 1.0 if u < 0.90 else 1 - ease_out_cubic((u - 0.90) / 0.10)
    return i, u, appear * fade


def paint(base, fonts, i, u, a):
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    grid(d, int(16 * a))
    cx, cy = W // 2, int(H * 0.52)
    ht = heart(u)
    aa = int(255 * a)

    if i == 0:
        bloom(d, cx, cy + 20, 340 + 90 * ht, ACCENT, 0.28 * a + 0.18 * ht * a)
        rings(d, cx, cy + 20, u, ACCENT, 230)
        fly = ease_out_cubic(min(1, u / 0.32))
        bubbles = [(-230, 70, "СТО"), (230, 64, "МАСТЕР"), (0, -168, "ЗАПИСЬ"), (-120, 150, "ЦЕНА"), (130, 150, "ОЧЕРЕДЬ")]
        for k, (dx, dy, lab) in enumerate(bubbles):
            ang = u * math.pi * 1.6 + k * 1.1
            hold = 0.42 + 0.58 * (1 - fly)
            px = cx + dx * hold + math.cos(ang) * 10
            py = cy + dy * hold + math.sin(ang) * 8
            d.ellipse((px - 38, py - 38, px + 38, py + 38), outline=ACCENT + (aa,), width=2)
            draw_tracked(d, lab, (px, py), fonts["tiny"], A(LEAD, a), tracking=1.2)
        grow = (0.82 + 0.18 * ease_out_back(min(1, u / 0.16))) * (1 + 0.06 * ht)
        draw_car(ov, cx, cy + 36, math.sin(u * math.pi * 2) * 0.04, 1.72 * grow)
        draw_tracked(d, "ВМЕСТО ЗВОНКОВ", (cx, cy + 210), fonts["sm"], A(ACCENT, a * fly), tracking=3.2)

    elif i == 1:
        bloom(d, cx, cy, 240, ACCENT, 0.16 * a)
        phone(d, fonts, cx, cy + 8, 340, 620, u, a, live=True, label="BOX · LIVE")
        phone(d, fonts, cx - 292, cy + 48, 230, 430, u + 0.2, a * 0.78, label="СТО")
        phone(d, fonts, cx + 292, cy + 48, 230, 430, u + 0.45, a * 0.78, label="ЛЕНТА")

    elif i == 2:
        bloom(d, cx, cy - 8, 220, ACCENT, 0.14 * a)
        rounded(d, (cx - 390, cy - 250, cx + 390, cy + 168), 24, fill=(11, 19, 29, aa), outline=ACCENT + (int(aa * 0.6),), width=2)
        # streets
        for k in range(-3, 4):
            d.line((cx - 360, cy + k * 52, cx + 360, cy + k * 52), fill=(168, 212, 238, int(34 * a)), width=2)
        for k in range(-4, 5):
            d.line((cx + k * 72, cy - 230, cx + k * 72, cy + 148), fill=(168, 212, 238, int(26 * a)), width=1)
        d.line((cx - 340, cy + 40, cx + 340, cy - 80), fill=ACCENT + (int(70 * a),), width=3)
        pins = [(cx - 200, cy - 30), (cx + 70, cy + 20), (cx + 220, cy - 90), (cx - 40, cy + 90)]
        names = ["AVTO+", "BOX 7", "LION", "SHIFT"]
        for n, p in enumerate(pins):
            map_pin(d, p, a, 0.45 + 0.55 * math.sin(u * math.pi * 5 + n))
            draw_tracked(d, names[n], (p[0], p[1] - 36), fonts["tiny"], A(INK, a), tracking=1.6)
        rounded(d, (cx - 210, cy + 196, cx + 210, cy + 278), 16, fill=(16, 26, 36, aa), outline=GOLD + (aa,), width=2)
        draw_tracked(d, "★  4.9     ·     ОКНО СЕГОДНЯ     ·     14:30", (cx, cy + 237), fonts["chip"], A(INK, a), tracking=0.8)

    elif i == 3:
        bloom(d, cx, cy, 260, ACCENT, 0.18 * a)
        draw_car(ov, cx, cy + 16, 0, 1.48)
        for n in range(11):
            uu = (u * 1.7 + n * 0.09) % 1
            x = cx - 80 + n * 16
            y = cy - 120 + uu * 150
            d.ellipse((x - 4, y - 6, x + 4, y + 6), fill=ACCENT + (int(aa * (1 - uu)),))
        gx, gy = cx + 230, cy - 8 + math.sin(u * math.pi * 6) * 12
        rounded(d, (gx, gy - 10, gx + 34, gy + 10), 5, fill=(176, 184, 192, aa))
        for n in range(14):
            uu = (u * 2.2 + n * 0.07) % 1
            d.ellipse(
                (gx - 10 - uu * 90 - 3, gy + math.sin(n * 1.4) * 16 - 3, gx - 10 - uu * 90 + 3, gy + math.sin(n * 1.4) * 16 + 3),
                fill=ACCENT + (int(aa * 0.7 * (1 - uu)),),
            )
        labels = [("МОЙКА", -1, -1), ("ДИАГНОСТИКА", 1, -1), ("ХОДОВАЯ", -1, 1), ("МАЛЯРКА", 1, 1)]
        for n, (lab, sx, sy) in enumerate(labels):
            pop = ease_out_back(clamp((u - 0.05 * n) / 0.16))
            x = cx + sx * 236 * pop
            y = cy + sy * 148 * pop
            rounded(d, (x - 122, y - 30, x + 122, y + 30), 14, fill=(14, 22, 32, aa), outline=ACCENT + (aa,), width=2)
            draw_tracked(d, lab, (x, y), fonts["chip"], A(INK, a), tracking=1.8)

    elif i == 4:
        bloom(d, cx, cy - 8, 240, ACCENT, 0.18 * a)
        camera_body(d, fonts, cx, cy + 18, u, a)
        draw_car(ov, cx, cy + 36, 0, 0.82)
        draw_tracked(d, "ПРЯМАЯ ТРАНСЛЯЦИЯ БОКСА", (cx, cy + 216), fonts["sm"], A(LEAD, a), tracking=2.4)

    elif i == 5:
        bloom(d, cx, cy - 20, 200, RED, 0.16 * a)
        p0, p2 = (W * 0.14, H * 0.60), (W * 0.86, H * 0.60)
        p1 = (W * 0.50, H * 0.38)
        travel = 0 if u < 0.04 else ease_in_out_cubic((u - 0.04) / 0.84)
        pts = [bezier(p0, p1, p2, k / 52)[:2] for k in range(53)]
        d.line(pts, fill=RED + (int(50 * a),), width=16, joint="curve")
        d.line(pts[: max(2, int(53 * travel))], fill=RED + (aa,), width=6, joint="curve")
        flag_us(d, (p0[0], p0[1] - 52), 26)
        flag_ua(d, (p2[0], p2[1] - 52), 26)
        draw_tracked(d, "США", (p0[0], p0[1] + 28), fonts["tiny"], A(LEAD, a), tracking=2.2)
        draw_tracked(d, "УКРАИНА", (p2[0], p2[1] + 28), fonts["tiny"], A(LEAD, a), tracking=2.2)
        x, y, ang = bezier(p0, p1, p2, travel)
        sea = 0.16 < travel < 0.82
        if sea:
            for w in range(5):
                wy = y + 28 + w * 10
                d.arc((x - 70 + w * 6, wy - 8, x + 70 - w * 6, wy + 8), 200, 340, fill=ACCENT + (int(aa * 0.45),), width=2)
            hx, hy = x, y + 8
            d.polygon(
                [(hx - 40, hy + 12), (hx + 42, hy + 10), (hx + 50, hy), (hx + 30, hy - 12), (hx - 30, hy - 8)],
                fill=(232, 232, 238, aa),
                outline=RED + (aa,),
            )
            d.rectangle((hx - 8, hy - 28, hx + 8, hy - 8), fill=RED + (aa,))
            draw_tracked(d, "ОКЕАН", (x, y - 52), fonts["tiny"], A(INK, a), tracking=2.4)
        draw_car(ov, x, y - (18 if sea else 4), ang * 0.28, 1.05, stroke=RED)
        draw_tracked(d, "ПОДБОР   →   ОКЕАН   →   ТАМОЖНЯ   →   КЛЮЧИ", (cx, H * 0.79), fonts["sm"], A(INK, a), tracking=1.6)

    elif i == 6:
        bloom(d, cx, cy, 260, GOLD, 0.18 * a)
        sh = ease_out_back(clamp(u / 0.24))
        shield(d, (cx, cy - 36), 128 * max(0.22, sh), a, ht)
        docs = [("КАСКО", -240), ("ОСАГО", 0), ("ПОЛИС", 240)]
        for n, (lab, dx) in enumerate(docs):
            uu = ease_out_cubic(clamp((u - 0.08 * n) / 0.32))
            x = cx + dx * uu
            y = cy + 196 - (1 - uu) * 70
            rounded(d, (x - 88, y - 52, x + 88, y + 52), 10, fill=(18, 26, 36, aa), outline=GOLD + (aa,), width=2)
            d.line((x - 52, y - 18, x + 52, y - 18), fill=INK + (aa,), width=3)
            d.line((x - 52, y + 2, x + 28, y + 2), fill=MUTED + (aa,), width=2)
            d.line((x - 52, y + 18, x + 40, y + 18), fill=MUTED + (aa,), width=2)
            draw_tracked(d, lab, (x, y + 36), fonts["tiny"], A(GOLD, a), tracking=2.0)
        draw_tracked(d, "ПОЛИС ЗА МИНУТЫ", (cx, cy + 318), fonts["sm"], A(GOLD, a), tracking=3.0)

    else:
        bloom(d, cx, cy + 10, 230, GOLD, 0.14 * a)
        nodes = [
            (cx - 290, cy - 110, "AVTO+"),
            (cx + 280, cy - 90, "BOX 7"),
            (cx - 250, cy + 150, "SHIFT"),
            (cx + 260, cy + 160, "LION"),
            (cx, cy - 210, "СТО"),
        ]
        for p in nodes:
            d.line((p[0], p[1], cx, cy), fill=ACCENT + (int(70 * a),), width=2)
            coins(d, (p[0], p[1]), (cx, cy), u + (p[0] % 13) * 0.02, a, n=6)
            shop_crest(d, (p[0], p[1]), 42, a)
            draw_tracked(d, p[2], (p[0], p[1] + 52), fonts["tiny"], A(LEAD, a), tracking=1.6)
        d.ellipse((cx - 88, cy - 88, cx + 88, cy + 88), fill=(16, 24, 34, aa), outline=GOLD + (aa,), width=4)
        draw_tracked(d, "ТЫ", (cx, cy - 14), fonts["lg"], A(INK, a), tracking=4)
        draw_tracked(d, "ДОЛЯ С ЗАПИСИ", (cx, cy + 28), fonts["chip"], A(GOLD, a), tracking=2.0)

    captions(d, fonts, i, u, a)
    base.alpha_composite(ov)


def make_frame(t, fonts, gradient):
    i, u, a = scene_index(t)
    img = gradient.copy().convert("RGBA")
    paint(img, fonts, i, u, a)
    return img.convert("RGB")


def ffmpeg_exe():
    import imageio_ffmpeg

    return imageio_ffmpeg.get_ffmpeg_exe()


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    fonts = load_fonts()
    gradient = make_gradient()
    cmd = [
        ffmpeg_exe(), "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
        "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "14",
        "-preset", "medium", "-movflags", "+faststart", "-an", OUT,
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
    assert proc.stdin is not None
    for n in range(FRAMES):
        t = n / (FRAMES - 1)
        proc.stdin.write(make_frame(t, fonts, gradient).tobytes())
        if n % 30 == 0:
            print(f"{n}/{FRAMES}", flush=True)
    proc.stdin.close()
    err = proc.stderr.read().decode("utf-8", errors="replace")
    code = proc.wait()
    if code != 0:
        sys.stderr.write(err)
        raise SystemExit(code)
    print(OUT)
    print(f"{os.path.getsize(OUT) / 1e6:.1f} MB · {DURATION:.1f}s · {SCENES} scenes")


if __name__ == "__main__":
    main()
