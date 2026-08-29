#!/usr/bin/env python3
"""Bake Lion red M2 body + APEX? cut-vinyl wrap that sits on the door skin."""

from __future__ import annotations

import io
import json
import math
import struct
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_glb_black_paint import LTRANS_RED, write_glb

ROOT = Path(__file__).resolve().parents[1]
GLB = ROOT / "assets" / "models" / "2023_bmw_m2_m-performance_parts_g87.glb"
FONT_TTC = "/System/Library/Fonts/HelveticaNeue.ttc"
BOLD = 1

# Vinyl thickness on the paint (~0.9 mm). Follows the panel, not a hovering plaque.
FILM_LIFT = 0.00092
RED_METAL = 0.95
RED_ROUGH = 0.22
RED_CLEAR = 0.34
RED_CLEAR_ROUGH = 0.12


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


def norm3(v):
    x, y, z = v
    n = math.sqrt(x * x + y * y + z * z) or 1.0
    return (x / n, y / n, z / n)


def add3(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def scale3(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def accessor_vec3(js, blob, acc_i):
    acc = js["accessors"][acc_i]
    bv = js["bufferViews"][acc["bufferView"]]
    off = (bv.get("byteOffset") or 0) + (acc.get("byteOffset") or 0)
    count = acc["count"]
    stride = bv.get("byteStride") or 12
    return [struct.unpack_from("<fff", blob, off + i * stride) for i in range(count)]


def accessor_indices(js, blob, acc_i):
    acc = js["accessors"][acc_i]
    bv = js["bufferViews"][acc["bufferView"]]
    off = (bv.get("byteOffset") or 0) + (acc.get("byteOffset") or 0)
    count = acc["count"]
    ctype = acc["componentType"]
    fmt, size = {5121: ("B", 1), 5123: ("H", 2), 5125: ("I", 4)}[ctype]
    stride = bv.get("byteStride") or size
    return [struct.unpack_from("<" + fmt, blob, off + i * stride)[0] for i in range(count)]


def append_view(blob: bytearray, data: bytes, target: int | None = None) -> int:
    pad = (4 - (len(blob) % 4)) % 4
    blob.extend(b"\x00" * pad)
    off = len(blob)
    blob.extend(data)
    return off


def is_apex_name(name: str) -> bool:
    n = str(name or "").lower()
    return n.startswith("apex_door_badge") or n.startswith("apex_wrap")


def strip_apex(js: dict, *, keep_carbon_fill: bool = True) -> int:
    """Hide old plaques / orange-carbon overlays. Keep carbon mesh if it plugs body holes."""
    nodes = js.get("nodes") or []
    hide = set()
    for i, n in enumerate(nodes):
        name = str(n.get("name") or "").lower()
        if not is_apex_name(name):
            continue
        if keep_carbon_fill and name == "apex_wrap_carbon":
            continue
        hide.add(i)
    meshes = js.get("meshes") or []
    for i, n in enumerate(nodes):
        if i in hide:
            continue
        if not isinstance(n.get("mesh"), int):
            continue
        mi = n["mesh"]
        if 0 <= mi < len(meshes) and is_apex_name((meshes[mi] or {}).get("name") or ""):
            mname = str((meshes[mi] or {}).get("name") or "").lower()
            if keep_carbon_fill and mname == "apex_wrap_carbon":
                continue
            hide.add(i)
    n = 0
    for i in hide:
        nodes[i]["scale"] = [0.0, 0.0, 0.0]
        n += 1
    for node in nodes:
        kids = node.get("children")
        if kids:
            kept = [c for c in kids if c not in hide]
            if len(kept) != len(kids):
                node["children"] = kept
                n += 1
    for scene in js.get("scenes") or []:
        roots = scene.get("nodes")
        if roots:
            kept = [c for c in roots if c not in hide]
            if len(kept) != len(roots):
                scene["nodes"] = kept
                n += 1
    return n


def paint_lion_red(js: dict) -> int:
    n = 0
    used = js.setdefault("extensionsUsed", [])
    if "KHR_materials_clearcoat" not in used:
        used.append("KHR_materials_clearcoat")
    for mat in js.get("materials") or []:
        name = str(mat.get("name") or "").lower()
        if "paint_material" not in name and name not in ("apex_wrap_carbon", "apex_wrap_roof"):
            continue
        pbr = mat.setdefault("pbrMetallicRoughness", {})
        pbr["baseColorFactor"] = list(LTRANS_RED)
        pbr["metallicFactor"] = RED_METAL
        pbr["roughnessFactor"] = RED_ROUGH
        pbr.pop("baseColorTexture", None)
        pbr.pop("metallicRoughnessTexture", None)
        ext = mat.setdefault("extensions", {})
        cc = ext.setdefault("KHR_materials_clearcoat", {})
        cc["clearcoatFactor"] = RED_CLEAR
        cc["clearcoatRoughnessFactor"] = RED_CLEAR_ROUGH
        n += 1
    return n


def find_paint(js: dict) -> tuple[int, int, dict]:
    for mi, mesh in enumerate(js.get("meshes") or []):
        if "kit1_paint_geo" in str(mesh.get("name") or "").lower():
            return mi, (mesh.get("primitives") or [{}])[0].get("material", 14), mesh
    raise RuntimeError("paint mesh not found")


def restore_full_paint_mesh(js: dict, paint_mat: int) -> int:
    """The orange-job split replaced paint indices; prim0 then failed to draw,
    so only the rear carbon fill was visible. Put the original full-body
    index buffer back (accessor after POSITION/NORMAL/UV of kit1_paint)."""
    _, _, mesh = find_paint(js)
    prim0 = (mesh.get("primitives") or [{}])[0]
    attrs = prim0.get("attributes") or {}
    pos_i = attrs.get("POSITION")
    if not isinstance(pos_i, int):
        raise RuntimeError("paint POSITION missing")
    vert_n = js["accessors"][pos_i]["count"]
    orig = None
    # Sketchfab layout: POSITION, NORMAL, UV, then the full index buffer.
    guess = pos_i + 3
    accs = js.get("accessors") or []
    if guess < len(accs):
        acc = accs[guess]
        n = acc.get("count") or 0
        if (
            acc.get("type") == "SCALAR"
            and acc.get("componentType") == 5125
            and n >= vert_n
            and n % 3 == 0
        ):
            orig = guess
    if orig is None:
        raise RuntimeError("original paint indices not found")
    mesh["primitives"] = [
        {
            "attributes": {
                "NORMAL": attrs.get("NORMAL", pos_i + 1),
                "POSITION": pos_i,
                "TEXCOORD_0": attrs.get("TEXCOORD_0", pos_i + 2),
            },
            "indices": orig,
            "material": paint_mat,
            "mode": 4,
        }
    ]
    print(f"  restored paint indices acc={orig} tris={js['accessors'][orig]['count']//3}", flush=True)
    return orig


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_TTC, size, index=BOLD)


def tsize(draw, text, fnt):
    b = draw.textbbox((0, 0), text, font=fnt)
    return b[2] - b[0], b[3] - b[1], b[1]


def make_vinyl_png() -> tuple[bytes, float]:
    """Cut-vinyl / plotter film: TA4KA as one piece, dark film, slight cut edge."""
    text = "TA4KA"
    w, h = 3200, 900
    dummy = ImageDraw.Draw(Image.new("L", (8, 8)))
    size = 80
    tracking = 0
    for trial in range(80, 980):
        fnt = font(trial)
        tw, th, _ = tsize(dummy, text, fnt)
        # Slight positive tracking — wrap wordmark, not overlay UltraLight.
        tr = trial * 0.04
        if tw + tr * 4 > w * 0.90 or th > h * 0.72:
            break
        size, tracking = trial, tr
    fnt = font(size)
    tw, th, top = tsize(dummy, text, fnt)
    total = tw + tracking * 4
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    x = (w - total) / 2
    y = (h - th) / 2 - top
    # Draw per-glyph so tracking stays even (including the ?).
    cursor = x
    for ch in text:
        md.text((cursor, y), ch, font=fnt, fill=255)
        cw, _, _ = tsize(dummy, ch, fnt)
        cursor += cw + tracking

    # Plotter lip: dilate, then a thin inner sheen.
    edge = mask.filter(ImageFilter.MaxFilter(5))
    edge = ImageChops.subtract(edge, mask)
    sheen = mask.filter(ImageFilter.MinFilter(3))

    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # Dark satin film with a soft top-to-bottom falloff.
    film = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = film.load()
    mpx = mask.load()
    for yy in range(h):
        t = yy / max(1, h - 1)
        r = int(22 + 14 * (1.0 - t))
        g = int(22 + 12 * (1.0 - t))
        b = int(24 + 11 * (1.0 - t))
        for xx in range(w):
            a = mpx[xx, yy]
            if a:
                px[xx, yy] = (r, g, b, a)
    img.alpha_composite(film)

    lip = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    lpx = lip.load()
    epx = edge.load()
    for yy in range(h):
        for xx in range(w):
            a = epx[xx, yy]
            if a:
                lpx[xx, yy] = (6, 6, 7, min(255, int(a * 0.92)))
    img.alpha_composite(lip)

    shine = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    spx = shine.load()
    shpx = sheen.load()
    for yy in range(h):
        for xx in range(w):
            a = shpx[xx, yy]
            if a and yy < h * 0.42:
                spx[xx, yy] = (38, 38, 42, min(70, a // 4))
    img.alpha_composite(shine)

    alpha = img.split()[-1]
    bbox = alpha.getbbox()
    if bbox:
        pad_x = max(14, int(th * 0.06))
        pad_y = max(12, int(th * 0.10))
        img = img.crop(
            (
                max(0, bbox[0] - pad_x),
                max(0, bbox[1] - pad_y),
                min(w, bbox[2] + pad_x),
                min(h, bbox[3] + pad_y),
            )
        )
    aspect = img.size[1] / max(1, img.size[0])
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue(), aspect


def add_accessor(
    js,
    blob: bytearray,
    data: bytes,
    count: int,
    typ: str,
    target: int,
    mins=None,
    maxs=None,
    ctype=5126,
):
    views = js.setdefault("bufferViews", [])
    accs = js.setdefault("accessors", [])
    off = append_view(blob, data, target)
    vi = len(views)
    views.append({"buffer": 0, "byteOffset": off, "byteLength": len(data), "target": target})
    ai = len(accs)
    rec = {"bufferView": vi, "componentType": ctype, "count": count, "type": typ}
    if mins is not None:
        rec["min"] = mins
        rec["max"] = maxs
    accs.append(rec)
    return ai


def pack_f(vals) -> bytes:
    return struct.pack("<" + "f" * len(vals), *vals)


def inject_film(
    js,
    blob: bytearray,
    png: bytes,
    name: str,
    verts: list,
    norms: list,
    uvs: list,
    indices: list[int],
) -> None:
    views = js.setdefault("bufferViews", [])
    images = js.setdefault("images", [])
    textures = js.setdefault("textures", [])
    samplers = js.setdefault("samplers", [])
    materials = js.setdefault("materials", [])
    meshes = js.setdefault("meshes", [])
    nodes = js.setdefault("nodes", [])
    scenes = js.setdefault("scenes", [{"nodes": [0]}])

    img_off = append_view(blob, png)
    img_view = len(views)
    views.append({"buffer": 0, "byteOffset": img_off, "byteLength": len(png)})
    img_i = len(images)
    images.append({"mimeType": "image/png", "bufferView": img_view, "name": name})
    samp_i = len(samplers)
    samplers.append({"magFilter": 9729, "minFilter": 9729, "wrapS": 33071, "wrapT": 33071})
    tex_i = len(textures)
    textures.append({"sampler": samp_i, "source": img_i, "name": name})
    mat_i = len(materials)
    materials.append(
        {
            "name": name,
            "alphaMode": "MASK",
            "alphaCutoff": 0.32,
            "doubleSided": False,
            "pbrMetallicRoughness": {
                "baseColorFactor": [1, 1, 1, 1],
                "baseColorTexture": {"index": tex_i},
                "metallicFactor": 0.12,
                "roughnessFactor": 0.38,
            },
            "extensions": {
                "KHR_materials_clearcoat": {
                    "clearcoatFactor": 0.10,
                    "clearcoatRoughnessFactor": 0.34,
                }
            },
        }
    )
    used = js.setdefault("extensionsUsed", [])
    if "KHR_materials_clearcoat" not in used:
        used.append("KHR_materials_clearcoat")

    xs, ys, zs = [p[0] for p in verts], [p[1] for p in verts], [p[2] for p in verts]
    flat_p = [c for p in verts for c in p]
    flat_n = [c for p in norms for c in p]
    flat_u = [c for p in uvs for c in p]
    pos_i = add_accessor(
        js,
        blob,
        pack_f(flat_p),
        len(verts),
        "VEC3",
        34962,
        [min(xs), min(ys), min(zs)],
        [max(xs), max(ys), max(zs)],
    )
    nor_i = add_accessor(js, blob, pack_f(flat_n), len(norms), "VEC3", 34962)
    uv_i = add_accessor(js, blob, pack_f(flat_u), len(uvs), "VEC2", 34962)
    raw_i = struct.pack("<" + "I" * len(indices), *indices)
    ii = add_accessor(js, blob, raw_i, len(indices), "SCALAR", 34963, ctype=5125)
    mesh_i = len(meshes)
    meshes.append(
        {
            "name": name,
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
    nodes.append({"name": name, "mesh": mesh_i})
    # Must live under the Sketchfab 0.01-scale root. Scene-root wraps were
    # 100× the car and stole the camera bounding box (rear-quarter crop).
    root_i = next(
        (i for i, n in enumerate(nodes) if str(n.get("name") or "") == "RootNode"),
        None,
    )
    if root_i is None:
        scenes = js.setdefault("scenes", [{"nodes": [0]}])
        scenes[js.get("scene") or 0].setdefault("nodes", []).append(ni)
    else:
        nodes[root_i].setdefault("children", []).append(ni)
    print(f"  film {name} tris={len(indices)//3} verts={len(verts)} parent={root_i}", flush=True)


def door_uv(p, *, cz: float, cy: float, bw: float, bh: float):
    # A at the front (+Z), ? toward the rear. Same on both sides.
    u = (cz + bw * 0.5 - p[2]) / bw
    v = (cy + bh * 0.5 - p[1]) / bh
    return u, v


def hood_uv(p, *, cx: float, cz: float, bw: float, bh: float, cy: float):
    u = (p[0] - (cx - bw * 0.5)) / bw
    v = (cz + bh * 0.5 - p[2]) / bh
    return u, v


def build_conforming(
    sources: list[tuple[list, list, list]],
    *,
    uv_fn,
    keep_pt,
    lift: float,
) -> tuple[list, list, list, list[int]] | None:
    verts, norms, uvs, indices = [], [], [], []
    remap: dict[tuple, int] = {}

    def push(p, n):
        key = (round(p[0], 5), round(p[1], 5), round(p[2], 5))
        i = remap.get(key)
        if i is not None:
            return i
        nn = norm3(n)
        i = len(verts)
        remap[key] = i
        verts.append(add3(p, scale3(nn, lift)))
        norms.append(nn)
        uvs.append(uv_fn(p))
        return i

    n_keep = 0
    for pos, nor, idx in sources:
        for t in range(0, len(idx), 3):
            ia, ib, ic = idx[t], idx[t + 1], idx[t + 2]
            pts = [pos[ia], pos[ib], pos[ic]]
            ns = [nor[ia], nor[ib], nor[ic]]
            if not keep_pt(pts, ns):
                continue
            n_keep += 1
            indices.extend((push(pts[0], ns[0]), push(pts[1], ns[1]), push(pts[2], ns[2])))
    if n_keep < 12 or len(verts) < 8:
        return None
    return verts, norms, uvs, indices


def paint_sources(js, blob, mesh) -> list[tuple[list, list, list]]:
    out = []
    for prim in mesh.get("primitives") or []:
        attrs = prim.get("attributes") or {}
        if "POSITION" not in attrs or "NORMAL" not in attrs or "indices" not in prim:
            continue
        out.append(
            (
                accessor_vec3(js, blob, attrs["POSITION"]),
                accessor_vec3(js, blob, attrs["NORMAL"]),
                accessor_indices(js, blob, prim["indices"]),
            )
        )
    return out


def door_keep(sign: int, bw: float, bh: float, cz: float, cy: float):
    def keep(pts, ns):
        mx = sum(p[0] for p in pts) / 3
        my = sum(p[1] for p in pts) / 3
        mz = sum(p[2] for p in pts) / 3
        nx = sum(n[0] for n in ns) / 3
        ny = sum(n[1] for n in ns) / 3
        if sign < 0:
            if mx > -0.84 or nx > -0.42:
                return False
        else:
            if mx < 0.84 or nx < 0.42:
                return False
        if ny < -0.45:
            return False
        # Stay on the door skin — do not jump the B-pillar onto the quarter.
        if mz < 0.08 or mz > 1.18:
            return False
        u, v = door_uv((mx, my, mz), cz=cz, cy=cy, bw=bw, bh=bh)
        return -0.04 <= u <= 1.04 and -0.10 <= v <= 1.10

    return keep


def hood_keep(bw: float, bh: float, cx: float, cy: float, cz: float):
    def keep(pts, ns):
        mx = sum(p[0] for p in pts) / 3
        my = sum(p[1] for p in pts) / 3
        mz = sum(p[2] for p in pts) / 3
        ny = sum(n[1] for n in ns) / 3
        if abs(mx) > 0.52 or my < 0.84 or mz < 1.22 or mz > 1.90:
            return False
        if ny < 0.20:
            return False
        u, v = hood_uv((mx, my, mz), cx=cx, cz=cz, bw=bw, bh=bh, cy=cy)
        return -0.08 <= u <= 1.08 and -0.12 <= v <= 1.12

    return keep


def process(path: Path) -> None:
    js, raw = read_glb(path)
    n_strip = strip_apex(js, keep_carbon_fill=False)
    mesh_i, paint_mat, mesh = find_paint(js)
    restore_full_paint_mesh(js, paint_mat)
    n_paint = paint_lion_red(js)
    blob = bytearray(raw)
    sources = paint_sources(js, blob, mesh)

    png, aspect = make_vinyl_png()
    # Large mid-door plotter wordmark. Height from the cut artwork.
    door_bw = 1.05
    door_bh = door_bw * aspect
    door_cz, door_cy = 0.60, 0.568
    for sign, side in ((-1, "driver"), (1, "passenger")):
        built = build_conforming(
            sources,
            uv_fn=lambda p, cz=door_cz, cy=door_cy, bw=door_bw, bh=door_bh: door_uv(
                p, cz=cz, cy=cy, bw=bw, bh=bh
            ),
            keep_pt=door_keep(sign, door_bw, door_bh, door_cz, door_cy),
            lift=FILM_LIFT,
        )
        if not built:
            print(f"  skip door {side}: no skin", flush=True)
            continue
        inject_film(js, blob, png, f"apex_wrap_film_{side}", *built)

    # Hood skin here is a thin nose strip — skip so it does not read as a sticker.
    print("  skip hood: not enough wrap-quality skin", flush=True)

    js.setdefault("buffers", [{"byteLength": 0}])[0]["byteLength"] = len(blob)
    write_glb(path, js, bytes(blob))
    print(
        f"{path.name}: strip={n_strip} red_mats={n_paint} bytes={path.stat().st_size}",
        flush=True,
    )


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else GLB
    if not path.exists():
        print("missing", path, file=sys.stderr)
        return 1
    process(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
