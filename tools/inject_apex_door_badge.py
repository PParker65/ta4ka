#!/usr/bin/env python3
"""Bake black gloss paint and pin OEM APEX / скоро. door badges on every GLB."""

from __future__ import annotations

import io
import json
import math
import re
import struct
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_glb_black_paint import (
    LTRANS_RED,
    bake_file,
    bake_m2_grille_bumper_black,
    should_paint,
)

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "assets" / "models"
BADGE_PNG = Path(__file__).resolve().parent / "apex_door_badge.png"
BADGE_BLACK_PNG = Path(__file__).resolve().parent / "apex_door_badge_black.png"
M2_HINT = re.compile(r"bmw_m2|m2_m-performance|m-performance_parts_g87", re.I)

FONT_TTC = "/System/Library/Fonts/HelveticaNeue.ttc"
RED = (215, 2, 0, 255)  # Lion Trans #D70200
NODE_NAME = "apex_door_badge"
MAT_NAME = "apex_door_badge"

FRONT_HINT = (
    "grille",
    "grill",
    "headlight",
    "headlamp",
    "light_f",
    "frontlight",
    "bumper_f",
    "fender_f",
    "front l",
    "front r",
)
DRIVER_HINT = re.compile(
    r"front\s*l\b|frontleft|front_l|_fl\b|door.*\bleft\b|left.*door",
    re.I,
)


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    offset = 12
    js = None
    bin_chunk = b""
    while offset + 8 <= len(data):
        clen, ctype = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunk = data[offset : offset + clen]
        offset += clen
        if ctype.startswith(b"JSON"):
            js = json.loads(chunk.decode("utf-8"))
        elif ctype.startswith(b"BIN"):
            bin_chunk = chunk
    if js is None:
        raise ValueError(f"no JSON chunk: {path}")
    return js, bin_chunk


def write_glb(path: Path, js: dict, bin_chunk: bytes) -> None:
    raw = json.dumps(js, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_chunk = raw + (b" " * ((4 - (len(raw) % 4)) % 4))
    bin_out = bin_chunk + (b"\x00" * ((4 - (len(bin_chunk) % 4)) % 4))
    total = 12 + 8 + len(json_chunk) + 8 + len(bin_out)
    path.write_bytes(
        struct.pack("<4sII", b"glTF", 2, total)
        + struct.pack("<I4s", len(json_chunk), b"JSON")
        + json_chunk
        + struct.pack("<I4s", len(bin_out), b"BIN\x00")
        + bin_out
    )


def font(size: int, index: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_TTC, size, index=index)


def tsize(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont):
    b = draw.textbbox((0, 0), text, font=fnt)
    return b[2] - b[0], b[3] - b[1], b[1]


def draw_tracked(draw, text, xy, fnt, fill, tracking: float, align="center"):
    widths = []
    for ch in text:
        w, _, _ = tsize(draw, ch, fnt)
        widths.append(w)
    total = sum(widths) + tracking * max(0, len(text) - 1)
    x = xy[0] - total / 2 if align == "center" else xy[0]
    _, th, top = tsize(draw, text, fnt)
    y = xy[1] - th / 2 - top
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += w + tracking
    return total, th


# Wide door vinyl — overlay lockup (tick + APEX) fills the panel, no plaque.
BADGE_ASPECT = 480 / 2800
ULTRA_LIGHT = 5  # Helvetica Neue UltraLight (CSS weight 100)
CREAM = (0xE6, 0xE4, 0xDF, 255)  # overlay #E6E4DF


def make_badge(*, black: bool = False) -> bytes:
    """Ta4ka vinyl matching the HTML overlay: UltraLight, cream, red tick."""
    w, h = 2800, 480
    ink = (12, 10, 10, 255) if black else CREAM
    dummy = ImageDraw.Draw(Image.new("L", (8, 8)))

    def lockup(size: float):
        fnt = font(int(size), ULTRA_LIGHT)
        tracking = size * 0.22
        widths = []
        for ch in "Ta4ka":
            cw, _, _ = tsize(dummy, ch, fnt)
            widths.append(cw)
        apex_w = sum(widths) + tracking * 4
        _, apex_h, _ = tsize(dummy, "Ta4ka", fnt)
        # Overlay at 96px: tick 3×36, gap 16.
        tick_w = max(2.0, 3.0 * size / 96.0)
        tick_h = 36.0 * size / 96.0
        gap = 16.0 * size / 96.0
        total = tick_w + gap + apex_w
        return fnt, tracking, apex_w, apex_h, tick_w, tick_h, gap, total

    size = 80.0
    for trial in range(80, 700):
        rec = lockup(float(trial))
        apex_h, tick_h, total = rec[3], rec[5], rec[-1]
        if apex_h > h * 0.72 or tick_h > h * 0.78 or total > w * 0.92:
            break
        size = float(trial)
    fnt, tracking, apex_w, apex_h, tick_w, tick_h, gap, total = lockup(size)

    cx = w * 0.5
    cy = h * 0.50
    lock_left = cx - total / 2
    tick_x0 = lock_left
    apex_cx = lock_left + tick_w + gap + apex_w / 2

    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    draw_tracked(md, "Ta4ka", (apex_cx, cy), fnt, 255, tracking=tracking)

    fill = Image.new("RGBA", (w, h), (*ink[:3], 255))
    fill.putalpha(mask)

    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.alpha_composite(fill)

    tick = ImageDraw.Draw(out)
    ty0 = int(cy - tick_h * 0.50)
    tx0 = int(tick_x0)
    tick_fill = (10, 8, 8, 255) if black else RED
    tick.rounded_rectangle(
        (tx0, ty0, tx0 + max(2, int(round(tick_w))), ty0 + max(8, int(round(tick_h)))),
        radius=1,
        fill=tick_fill,
    )

    # Tight crop so UV maps the lockup across the full door quad (no empty plaque).
    alpha = out.split()[-1]
    bbox = alpha.getbbox()
    if bbox:
        pad_x = max(12, int(apex_h * 0.10))
        pad_y = max(10, int(apex_h * 0.16))
        x0 = max(0, bbox[0] - pad_x)
        y0 = max(0, bbox[1] - pad_y)
        x1 = min(w, bbox[2] + pad_x)
        y1 = min(h, bbox[3] + pad_y)
        out = out.crop((x0, y0, x1, y1))

    global BADGE_ASPECT
    BADGE_ASPECT = out.size[1] / max(1, out.size[0])

    buf = io.BytesIO()
    out.save(buf, format="PNG", optimize=True)
    raw = buf.getvalue()
    (BADGE_BLACK_PNG if black else BADGE_PNG).write_bytes(raw)
    return raw


def q_to_m(q):
    x, y, z, w = q
    xx, yy, zz = x * x, y * y, z * z
    xy, xz, yz = x * y, x * z, y * z
    wx, wy, wz = w * x, w * y, w * z
    return [
        [1 - 2 * (yy + zz), 2 * (xy - wz), 2 * (xz + wy), 0],
        [2 * (xy + wz), 1 - 2 * (xx + zz), 2 * (yz - wx), 0],
        [2 * (xz - wy), 2 * (yz + wx), 1 - 2 * (xx + yy), 0],
        [0, 0, 0, 1],
    ]


def ident():
    return [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]


def mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def node_local(n: dict):
    if "matrix" in n:
        m = n["matrix"]
        return [[m[c * 4 + r] for c in range(4)] for r in range(4)]
    out = ident()
    if "translation" in n:
        t = n["translation"]
        tm = ident()
        tm[0][3], tm[1][3], tm[2][3] = t
        out = mul(out, tm)
    if "rotation" in n:
        out = mul(out, q_to_m(n["rotation"]))
    if "scale" in n:
        s = n["scale"]
        sm = ident()
        sm[0][0], sm[1][1], sm[2][2] = s
        out = mul(out, sm)
    return out


def apply(m, x, y, z):
    return (
        m[0][0] * x + m[0][1] * y + m[0][2] * z + m[0][3],
        m[1][0] * x + m[1][1] * y + m[1][2] * z + m[1][3],
        m[2][0] * x + m[2][1] * y + m[2][2] * z + m[2][3],
    )


def apply_dir(m, x, y, z):
    return (
        m[0][0] * x + m[0][1] * y + m[0][2] * z,
        m[1][0] * x + m[1][1] * y + m[1][2] * z,
        m[2][0] * x + m[2][1] * y + m[2][2] * z,
    )


def world_mats(js: dict):
    nodes = js.get("nodes") or []
    parent = {i: None for i in range(len(nodes))}
    for i, n in enumerate(nodes):
        for c in n.get("children") or []:
            parent[c] = i
    cache: dict[int, list] = {}

    def world(i):
        if i in cache:
            return cache[i]
        loc = node_local(nodes[i])
        p = parent[i]
        cache[i] = loc if p is None else mul(world(p), loc)
        return cache[i]

    return [world(i) for i in range(len(nodes))]


def accessor_vec3(js, blob, acc_i):
    acc = js["accessors"][acc_i]
    if acc.get("type") != "VEC3" or "bufferView" not in acc:
        return []
    bv = js["bufferViews"][acc["bufferView"]]
    off = (bv.get("byteOffset") or 0) + (acc.get("byteOffset") or 0)
    count = acc["count"]
    stride = bv.get("byteStride") or 12
    ctype = acc["componentType"]
    out = []
    if ctype == 5126:
        for i in range(count):
            out.append(struct.unpack_from("<fff", blob, off + i * stride))
    return out


def already_injected(js: dict) -> bool:
    for n in js.get("nodes") or []:
        if str(n.get("name") or "").startswith(NODE_NAME):
            return True
    for m in js.get("materials") or []:
        if m.get("name") == MAT_NAME:
            return True
    return False


def body_mesh_indices(js: dict) -> set[int]:
    mats = js.get("materials") or []
    paint_ids = {i for i, m in enumerate(mats) if should_paint(m)}
    hits = set()
    for mi, mesh in enumerate(js.get("meshes") or []):
        for prim in mesh.get("primitives") or []:
            if prim.get("material") in paint_ids:
                hits.add(mi)
    return hits


def collect_body_points(js: dict, blob: bytes, worlds: list):
    body = body_mesh_indices(js)
    nodes = js.get("nodes") or []
    meshes = js.get("meshes") or []
    pts = []
    front_pts = []
    for ni, n in enumerate(nodes):
        mi = n.get("mesh")
        if mi is None:
            continue
        name = str(n.get("name") or "").lower()
        mesh = meshes[mi]
        W = worlds[ni]
        is_body = mi in body or any(
            k in name for k in ("paint", "body", "kuzov", "coloured", "carpaint")
        )
        is_front = any(h in name for h in FRONT_HINT)
        for prim in mesh.get("primitives") or []:
            attrs = prim.get("attributes") or {}
            if "POSITION" not in attrs:
                continue
            pos = accessor_vec3(js, blob, attrs["POSITION"])
            if not pos:
                continue
            step = max(1, len(pos) // 14000)
            for p in pos[::step]:
                wp = apply(W, *p)
                if is_body:
                    pts.append(wp)
                if is_front:
                    front_pts.append(wp)
    return pts, front_pts


def door_centers(pts, front_pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    zs = [p[2] for p in pts]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)
    minz, maxz = min(zs), max(zs)
    dx, dy, dz = maxx - minx, maxy - miny, maxz - minz
    # Y is up in glTF / model-viewer.
    if dz >= dx:
        length_axis, width_axis = 2, 0
        length, width = dz, dx
        lmin, lmax = minz, maxz
        wmin, wmax = minx, maxx
    else:
        length_axis, width_axis = 0, 2
        length, width = dx, dz
        lmin, lmax = minx, maxx
        wmin, wmax = minz, maxz

    front_is_min = True
    if front_pts:
        fl = sum(p[length_axis] for p in front_pts) / len(front_pts)
        front_is_min = abs(fl - lmin) <= abs(fl - lmax)

    def along(p):
        v = p[length_axis]
        t = (v - lmin) / length if length else 0.5
        return t if front_is_min else 1.0 - t

    mid_y0, mid_y1 = miny + dy * 0.34, miny + dy * 0.56
    door_t0, door_t1 = 0.20, 0.36
    side_cut = 0.78

    def side_cluster(sign: int):
        mid = (wmin + wmax) * 0.5
        picked = []
        for p in pts:
            if not (door_t0 <= along(p) <= door_t1):
                continue
            if not (mid_y0 <= p[1] <= mid_y1):
                continue
            w = p[width_axis]
            if sign < 0 and w > mid - width * 0.12:
                continue
            if sign > 0 and w < mid + width * 0.12:
                continue
            # keep outer skin
            edge = wmin if sign < 0 else wmax
            if abs(w - edge) > width * (1 - side_cut) * 0.55:
                if abs(w - edge) > width * 0.18:
                    continue
            picked.append(p)
        if len(picked) < 8:
            t = 0.28
            L = lmin + (t if front_is_min else 1.0 - t) * (lmax - lmin)
            Y = miny + dy * 0.44
            W = wmin if sign < 0 else wmax
            if length_axis == 2:
                return (W, Y, L)
            return (L, Y, W)
        # sit on the outer skin, not the average (average sinks into the door)
        if sign < 0:
            edge = min(p[width_axis] for p in picked)
            skin = [p for p in picked if p[width_axis] <= edge + width * 0.04]
        else:
            edge = max(p[width_axis] for p in picked)
            skin = [p for p in picked if p[width_axis] >= edge - width * 0.04]
        use = skin or picked
        sx = sum(p[0] for p in use) / len(use)
        sy = sum(p[1] for p in use) / len(use)
        sz = sum(p[2] for p in use) / len(use)
        return (sx, sy, sz)

    left = side_cluster(-1)
    right = side_cluster(1)
    # outward normals along width
    if width_axis == 0:
        ln, rn = (-1.0, 0.0, 0.0), (1.0, 0.0, 0.0)
        # +U is viewer's right when looking at the door from outside (LTR APEX).
        if front_is_min:
            lu, ru = (0.0, 0.0, -1.0), (0.0, 0.0, 1.0)
        else:
            lu, ru = (0.0, 0.0, 1.0), (0.0, 0.0, -1.0)
    else:
        ln, rn = (0.0, 0.0, -1.0), (0.0, 0.0, 1.0)
        if front_is_min:
            lu, ru = (-1.0, 0.0, 0.0), (1.0, 0.0, 0.0)
        else:
            lu, ru = (1.0, 0.0, 0.0), (-1.0, 0.0, 0.0)
    up = (0.0, 1.0, 0.0)
    return {
        "left": (left, ln, lu, up),
        "right": (right, rn, ru, up),
        "width": width,
        "length": length,
        "height": dy,
    }


def quad_verts(center, normal, u_axis, v_axis, bw, bh, lift):
    cx = center[0] + normal[0] * lift
    cy = center[1] + normal[1] * lift
    cz = center[2] + normal[2] * lift
    hx, hy, hz = (u_axis[0] * bw * 0.5, u_axis[1] * bw * 0.5, u_axis[2] * bw * 0.5)
    vx, vy, vz = (v_axis[0] * bh * 0.5, v_axis[1] * bh * 0.5, v_axis[2] * bh * 0.5)
    # UV: (0,0) top-left of artwork = -U +V
    corners = [
        (cx - hx + vx, cy - hy + vy, cz - hz + vz, 0.0, 0.0),  # top-left
        (cx + hx + vx, cy + hy + vy, cz + hz + vz, 1.0, 0.0),  # top-right
        (cx + hx - vx, cy + hy - vy, cz + hz - vz, 1.0, 1.0),  # bot-right
        (cx - hx - vx, cy - hy - vy, cz - hz - vz, 0.0, 1.0),  # bot-left
    ]
    n = normal
    verts = []
    uvs = []
    norms = []
    for x, y, z, u, v in corners:
        verts.extend([x, y, z])
        uvs.extend([u, v])
        norms.extend([n[0], n[1], n[2]])
    return verts, norms, uvs


def append_view(blob: bytearray, data: bytes, target: int) -> int:
    pad = (4 - (len(blob) % 4)) % 4
    blob.extend(b"\x00" * pad)
    off = len(blob)
    blob.extend(data)
    return off


def strip_apex_nodes(js: dict) -> None:
    apex = {
        i
        for i, n in enumerate(js.get("nodes") or [])
        if str(n.get("name") or "").startswith(NODE_NAME)
    }
    if not apex:
        return
    for n in js.get("nodes") or []:
        kids = n.get("children")
        if kids:
            n["children"] = [c for c in kids if c not in apex]
    for sc in js.get("scenes") or []:
        sc["nodes"] = [i for i in sc.get("nodes") or [] if i not in apex]


def collect_skin_points(js: dict, blob: bytes, worlds: list):
    """World-space samples from the large body meshes only (skip bolts / badges)."""
    nodes = js.get("nodes") or []
    meshes = js.get("meshes") or []
    per: list[tuple[float, list]] = []
    front_pts = []
    driver_pts = []
    for ni, n in enumerate(nodes):
        name = str(n.get("name") or "")
        if name.startswith(NODE_NAME):
            continue
        if DRIVER_HINT.search(name):
            W = worlds[ni]
            driver_pts.append((W[0][3], W[1][3], W[2][3]))
        mi = n.get("mesh")
        if mi is None:
            continue
        name = str(n.get("name") or "")
        W = worlds[ni]
        pts = []
        for prim in meshes[mi].get("primitives") or []:
            attrs = prim.get("attributes") or {}
            if "POSITION" not in attrs:
                continue
            pos = accessor_vec3(js, blob, attrs["POSITION"])
            if not pos:
                continue
            step = max(1, len(pos) // 12000)
            for p in pos[::step]:
                pts.append(apply(W, *p))
        if len(pts) < 8:
            continue
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        zs = [p[2] for p in pts]
        ext = max(max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
        per.append((ext, pts))
        low = name.lower()
        if any(h in low for h in FRONT_HINT):
            front_pts.extend(pts[:: max(1, len(pts) // 40)])
    if not per:
        raise RuntimeError("no mesh samples")
    max_ext = max(e for e, _ in per)
    pts = []
    for ext, p in per:
        if ext >= max_ext * 0.28:
            pts.extend(p)
    if len(pts) < 24:
        pts = [p for _, chunk in per for p in chunk]
    return pts, front_pts, driver_pts


def driver_door_pose(pts, front_pts, driver_pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    zs = [p[2] for p in pts]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)
    minz, maxz = min(zs), max(zs)
    dx, dy, dz = maxx - minx, maxy - miny, maxz - minz
    if dz >= dx:
        length_axis, width_axis = 2, 0
        length, width = dz, dx
        lmin, lmax = minz, maxz
        wmin, wmax = minx, maxx
    else:
        length_axis, width_axis = 0, 2
        length, width = dx, dz
        lmin, lmax = minx, maxx
        wmin, wmax = minz, maxz

    front_is_min = True
    if front_pts:
        fl = sum(p[length_axis] for p in front_pts) / len(front_pts)
        front_is_min = abs(fl - lmin) <= abs(fl - lmax)

    def along(p):
        v = p[length_axis]
        t = (v - lmin) / length if length else 0.5
        return t if front_is_min else 1.0 - t

    # Front door sheet: behind the wheel arch, below the glass, ahead of the B-pillar.
    # Parametric t (0=front) so the vinyl does not hug the fender.
    t_mid = 0.41
    y_frac = 0.40
    mid_y0, mid_y1 = miny + dy * 0.34, miny + dy * 0.46
    door_t0, door_t1 = 0.34, 0.48

    if driver_pts:
        mid_w = (wmin + wmax) * 0.5
        avg = sum(p[width_axis] for p in driver_pts) / len(driver_pts)
        sign = -1 if avg < mid_w else 1
    else:
        sign = -1  # LHD: negative width

    mid = (wmin + wmax) * 0.5
    picked = []
    for p in pts:
        if not (door_t0 <= along(p) <= door_t1):
            continue
        if not (mid_y0 <= p[1] <= mid_y1):
            continue
        w = p[width_axis]
        if sign < 0 and w > mid - width * 0.08:
            continue
        if sign > 0 and w < mid + width * 0.08:
            continue
        edge = wmin if sign < 0 else wmax
        if abs(w - edge) > width * 0.22:
            continue
        picked.append(p)

    L = lmin + (t_mid if front_is_min else 1.0 - t_mid) * (lmax - lmin)
    Y = miny + dy * y_frac
    if sign < 0:
        W = min(p[width_axis] for p in picked) if picked else wmin
        if picked:
            skin = [p for p in picked if p[width_axis] <= W + width * 0.03]
            W = sum(p[width_axis] for p in skin) / len(skin) if skin else W
    else:
        W = max(p[width_axis] for p in picked) if picked else wmax
        if picked:
            skin = [p for p in picked if p[width_axis] >= W - width * 0.03]
            W = sum(p[width_axis] for p in skin) / len(skin) if skin else W
    center = (W, Y, L) if length_axis == 2 else (L, Y, W)

    if width_axis == 0:
        normal = (-1.0, 0.0, 0.0) if sign < 0 else (1.0, 0.0, 0.0)
        # +U = viewer's right from outside the door (front of car is to the right
        # on an LHD driver door) so APEX reads left-to-right, not mirrored.
        if front_is_min:
            u_axis = (0.0, 0.0, -1.0) if sign < 0 else (0.0, 0.0, 1.0)
        else:
            u_axis = (0.0, 0.0, 1.0) if sign < 0 else (0.0, 0.0, -1.0)
    else:
        normal = (0.0, 0.0, -1.0) if sign < 0 else (0.0, 0.0, 1.0)
        if front_is_min:
            u_axis = (-1.0, 0.0, 0.0) if sign < 0 else (1.0, 0.0, 0.0)
        else:
            u_axis = (1.0, 0.0, 0.0) if sign < 0 else (-1.0, 0.0, 0.0)
    up = (0.0, 1.0, 0.0)
    return {
        "center": center,
        "normal": normal,
        "u": u_axis,
        "v": up,
        "width": width,
        "length": length,
        "height": dy,
        "sign": sign,
    }


def inject(js: dict, blob: bytes, png: bytes, *, black: bool = False) -> bytes:
    strip_apex_nodes(js)
    worlds = world_mats(js)
    pts, front_pts, driver_pts = collect_skin_points(js, blob, worlds)
    if len(pts) < 8:
        raise RuntimeError("not enough verts to place door")

    place = driver_door_pose(pts, front_pts, driver_pts)
    # Door-filling strip along the panel (not onto the fender).
    bw = place["length"] * 0.26
    bh = bw * BADGE_ASPECT
    lift = max(place["width"] * 0.011, place["length"] * 0.0026)

    bin_buf = bytearray(blob)
    views = js.setdefault("bufferViews", [])
    accs = js.setdefault("accessors", [])
    images = js.setdefault("images", [])
    textures = js.setdefault("textures", [])
    samplers = js.setdefault("samplers", [])
    materials = js.setdefault("materials", [])
    meshes = js.setdefault("meshes", [])
    nodes = js.setdefault("nodes", [])
    scenes = js.setdefault("scenes", [{"nodes": [js.get("scene", 0)]}])
    if not scenes:
        scenes.append({"nodes": [0]})
        js["scenes"] = scenes

    img_off = append_view(bin_buf, png, 0)
    img_view = len(views)
    views.append({"buffer": 0, "byteOffset": img_off, "byteLength": len(png)})
    img_i = len(images)
    images.append({"mimeType": "image/png", "bufferView": img_view, "name": "apex_door_badge"})
    samp_i = len(samplers)
    samplers.append({"magFilter": 9729, "minFilter": 9729, "wrapS": 33071, "wrapT": 33071})
    tex_i = len(textures)
    textures.append({"sampler": samp_i, "source": img_i, "name": "apex_door_badge"})
    mat_i = len(materials)
    mat = {
        "name": MAT_NAME,
        "alphaMode": "MASK",
        "alphaCutoff": 0.04,
        "doubleSided": True,
        "pbrMetallicRoughness": {
            "baseColorFactor": [1, 1, 1, 1],
            "baseColorTexture": {"index": tex_i},
            "metallicFactor": 0.08 if black else 0.0,
            "roughnessFactor": 0.46 if black else 0.62,
        },
    }
    if not black:
        # Unlit cream — same #E6E4DF as the HTML overlay, no metal sparkle.
        mat["extensions"] = {"KHR_materials_unlit": {}}
        used = js.setdefault("extensionsUsed", [])
        if "KHR_materials_unlit" not in used:
            used.append("KHR_materials_unlit")
    materials.append(mat)

    center, normal, u_axis, v_axis = (
        place["center"],
        place["normal"],
        place["u"],
        place["v"],
    )
    verts, norms, uvs = quad_verts(center, normal, u_axis, v_axis, bw, bh, lift)
    idx = struct.pack("<6H", 0, 1, 2, 0, 2, 3)
    vbytes = struct.pack("<" + "f" * 12, *verts)
    nbytes = struct.pack("<" + "f" * 12, *norms)
    ubytes = struct.pack("<" + "f" * 8, *uvs)

    def acc_f(data, ncomp, typ, mins=None, maxs=None):
        off = append_view(bin_buf, data, 34962)
        vi = len(views)
        views.append({"buffer": 0, "byteOffset": off, "byteLength": len(data), "target": 34962})
        ai = len(accs)
        rec = {"bufferView": vi, "componentType": 5126, "count": ncomp, "type": typ}
        if mins is not None:
            rec["min"] = mins
            rec["max"] = maxs
        accs.append(rec)
        return ai

    xs, ys, zs = verts[0::3], verts[1::3], verts[2::3]
    pos_i = acc_f(vbytes, 4, "VEC3", [min(xs), min(ys), min(zs)], [max(xs), max(ys), max(zs)])
    nor_i = acc_f(nbytes, 4, "VEC3")
    uv_i = acc_f(ubytes, 4, "VEC2")
    ioff = append_view(bin_buf, idx, 34963)
    ivi = len(views)
    views.append({"buffer": 0, "byteOffset": ioff, "byteLength": len(idx), "target": 34963})
    ii = len(accs)
    accs.append({"bufferView": ivi, "componentType": 5123, "count": 6, "type": "SCALAR"})
    mesh_i = len(meshes)
    meshes.append(
        {
            "name": f"{NODE_NAME}_driver",
            "primitives": [
                {
                    "attributes": {"POSITION": pos_i, "NORMAL": nor_i, "TEXCOORD_0": uv_i},
                    "indices": ii,
                    "material": mat_i,
                    "mode": 4,
                }
            ],
        }
    )
    ni = len(nodes)
    nodes.append({"name": f"{NODE_NAME}_driver", "mesh": mesh_i})

    scene = scenes[js.get("scene") or 0]
    scene.setdefault("nodes", []).append(ni)

    buffers = js.setdefault("buffers", [{"byteLength": 0}])
    buffers[0]["byteLength"] = len(bin_buf)
    cx, cy, cz = center
    print(
        f"  door xyz=({cx:.3f},{cy:.3f},{cz:.3f}) "
        f"size={bw:.3f}x{bh:.3f} sign={place['sign']}",
        flush=True,
    )
    return bytes(bin_buf)


def is_m2(path: Path) -> bool:
    return bool(M2_HINT.search(path.name))


def process(path: Path, png: bytes, *, black: bool = False, bake_red: bool = False) -> str:
    if bake_red:
        n = bake_file(path, color=LTRANS_RED)
        print(f"  baked red {n} material(s)", flush=True)
    js, blob = read_glb(path)
    blob = inject(js, blob, png, black=black)
    write_glb(path, js, blob)
    kind = "cream" if not black else "black"
    return f"{path.name}: driver door ({kind})"


def main() -> int:
    metal = make_badge(black=False)
    files = sorted(MODELS.glob("*.glb"))
    if len(sys.argv) > 1:
        files = [Path(a) for a in sys.argv[1:]]
    files = [p for p in files if not is_m2(p)]
    if not files:
        print("no glbs", file=sys.stderr)
        return 1
    failed = 0
    for path in files:
        try:
            print(process(path, metal, black=False, bake_red=False), flush=True)
        except Exception as e:
            failed += 1
            print(f"{path.name}: FAIL {e}", file=sys.stderr)
    print(f"done · {len(files)} files · badge {BADGE_PNG} · fail {failed}")
    return 1 if failed == len(files) else 0


if __name__ == "__main__":
    raise SystemExit(main())
