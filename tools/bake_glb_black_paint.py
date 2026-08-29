#!/usr/bin/env python3
"""Bake black gloss metallic body paint into GLB materials (stdlib only)."""

from __future__ import annotations

import json
import re
import struct
import sys
from pathlib import Path

PAINT = re.compile(
    r"paint|pintura|carpaint|car_paint|car_body|kuzov|new_color|astral_paint|"
    r"coloured|smallspecmap|\bprimary\b|paintsecondary|car_paint_bai|"
    r"gaolianghei|gloss_black|default1",
    re.I,
)
SKIP = re.compile(
    r"glass|window|windo|vidro|light|lamp|lens|tire|tyre|pneu|rubber|interior|"
    r"leather|seat|chrome|mirror|wheel|\brim\b|caliper|calliper|grille|grill|"
    r"carbon|engine|badge|plate|chassis|fabric|carpet|wood|display|speaker|"
    r"brake|cabin|dash|int_|neishi|luntai|reflector|indicator|signal|glow|"
    r"emiss|deng|plastic|plas_",
    re.I,
)

# #0A0A0A
COLOR = [10 / 255, 10 / 255, 10 / 255, 1.0]
# Lion Trans / APEX red #D70200
LTRANS_RED = [215 / 255, 2 / 255, 0 / 255, 1.0]
METALLIC = 0.95
ROUGHNESS = 0.22


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    if data[:4] != b"glTF":
        raise ValueError(f"not a GLB: {path}")
    offset = 12
    js = None
    bin_chunk = b""
    while offset + 8 <= len(data):
        clen, ctype = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunk = data[offset : offset + clen]
        offset += clen + ((4 - (clen % 4)) % 4)
        # chunk length already excludes padding in some writers; use raw clen
        offset = offset  # kept for clarity
        if ctype.startswith(b"JSON"):
            js = json.loads(chunk[:clen].decode("utf-8"))
        elif ctype.startswith(b"BIN"):
            bin_chunk = chunk[:clen]
    if js is None:
        raise ValueError(f"no JSON chunk: {path}")
    return js, bin_chunk


def write_glb(path: Path, js: dict, bin_chunk: bytes) -> None:
    raw = json.dumps(js, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_pad = (4 - (len(raw) % 4)) % 4
    json_chunk = raw + (b" " * json_pad)
    bin_pad = (4 - (len(bin_chunk) % 4)) % 4
    bin_out = bin_chunk + (b"\x00" * bin_pad)
    total = 12 + 8 + len(json_chunk) + 8 + len(bin_out)
    header = struct.pack("<4sII", b"glTF", 2, total)
    json_hdr = struct.pack("<I4s", len(json_chunk), b"JSON")
    bin_hdr = struct.pack("<I4s", len(bin_out), b"BIN\x00")
    path.write_bytes(header + json_hdr + json_chunk + bin_hdr + bin_out)


def skip_name(name: str) -> bool:
    return bool(SKIP.search(name)) and "paint" not in name


def chromatic(mat: dict) -> bool:
    pbr = mat.get("pbrMetallicRoughness") or {}
    f = pbr.get("baseColorFactor")
    if not f or len(f) < 3:
        return False
    a = f[3] if len(f) > 3 else 1
    if a < 0.95:
        return False
    r, g, b = float(f[0]), float(f[1]), float(f[2])
    mx, mn = max(r, g, b), min(r, g, b)
    return mx > 0.08 and (mx - mn) > 0.08


def should_paint(mat: dict) -> bool:
    name = str(mat.get("name") or "").lower()
    if skip_name(name):
        return False
    if str(mat.get("alphaMode") or "").upper() == "BLEND":
        return False
    return bool(PAINT.search(name)) or chromatic(mat)


def paint_mat(mat: dict, color: list[float] | None = None) -> None:
    pbr = mat.setdefault("pbrMetallicRoughness", {})
    pbr["baseColorFactor"] = list(color or COLOR)
    pbr["metallicFactor"] = METALLIC
    pbr["roughnessFactor"] = ROUGHNESS
    pbr.pop("baseColorTexture", None)
    pbr.pop("metallicRoughnessTexture", None)


M2_TRIM_BLACK = re.compile(r"grille|grill|coloured", re.I)


def bake_m2_grille_bumper_black(path: Path) -> int:
    """Keep M2 body Lion red; force kidney grille + Coloured bumper kit to black."""
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
    n = 0
    for mat in js.get("materials") or []:
        name = str(mat.get("name") or "")
        if str(mat.get("alphaMode") or "").upper() == "BLEND":
            continue
        if "apex" in name.lower():
            continue
        if M2_TRIM_BLACK.search(name):
            paint_mat(mat, COLOR)
            n += 1
    if n:
        write_glb(path, js, bin_chunk)
    return n


def hide_apex_door_badge(path: Path) -> int:
    """Teaser-only: omit apex_door_badge nodes so the door is clean. Overlay stays HTML."""
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

    def is_badge(name: str) -> bool:
        return "apex_door_badge" in str(name or "").lower()

    n = 0
    nodes = js.get("nodes") or []
    hide = {i for i, node in enumerate(nodes) if is_badge(node.get("name") or "")}
    meshes = js.get("meshes") or []
    hide |= {
        i
        for i, node in enumerate(nodes)
        if isinstance(node.get("mesh"), int)
        and 0 <= node["mesh"] < len(meshes)
        and is_badge((meshes[node["mesh"]] or {}).get("name") or "")
    }
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
    for mat in js.get("materials") or []:
        if not is_badge(mat.get("name") or ""):
            continue
        pbr = mat.setdefault("pbrMetallicRoughness", {})
        f = list(pbr.get("baseColorFactor") or [1, 1, 1, 1])
        while len(f) < 4:
            f.append(1.0)
        f[3] = 0.0
        pbr["baseColorFactor"] = f
        pbr.pop("baseColorTexture", None)
        mat["alphaMode"] = "BLEND"
        mat["alphaCutoff"] = 1.0
        n += 1
    if n:
        write_glb(path, js, bin_chunk)
    return n


def soften_m2_teaser_body(path: Path) -> int:
    """Teaser-only: keep Lion red #D70200, kill orbit sparkle on metal/clearcoat."""
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
    n = 0
    for mat in js.get("materials") or []:
        name = str(mat.get("name") or "")
        low = name.lower()
        if "apex" in low:
            continue
        pbr = mat.setdefault("pbrMetallicRoughness", {})
        if "paint_material" in low:
            pbr["baseColorFactor"] = list(LTRANS_RED)
            pbr["metallicFactor"] = 0.55
            pbr["roughnessFactor"] = 0.46
            pbr.pop("baseColorTexture", None)
            pbr.pop("metallicRoughnessTexture", None)
            n += 1
        elif M2_TRIM_BLACK.search(name) and str(mat.get("alphaMode") or "").upper() != "BLEND":
            pbr["baseColorFactor"] = list(COLOR)
            pbr["metallicFactor"] = 0.28
            pbr["roughnessFactor"] = 0.50
            pbr.pop("baseColorTexture", None)
            pbr.pop("metallicRoughnessTexture", None)
            n += 1
        ext = mat.get("extensions") or {}
        cc = ext.get("KHR_materials_clearcoat")
        if cc:
            cc["clearcoatFactor"] = min(float(cc.get("clearcoatFactor") or 0.34), 0.12)
            cc["clearcoatRoughnessFactor"] = max(
                float(cc.get("clearcoatRoughnessFactor") or 0.04), 0.36
            )
            n += 1
    if n:
        write_glb(path, js, bin_chunk)
    return n


def bake_file(path: Path, color: list[float] | None = None) -> int:
    # Re-read with correct chunk walking (no extra pad skip)
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
    n = 0
    for mat in js.get("materials") or []:
        if should_paint(mat):
            paint_mat(mat, color)
            n += 1
    if n:
        write_glb(path, js, bin_chunk)
    return n


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/models")
    files = sorted(root.glob("*.glb"))
    if not files:
        print(f"no glbs in {root}", file=sys.stderr)
        return 1
    total = 0
    for path in files:
        n = bake_file(path)
        total += n
        print(f"{path.name}: painted {n} material(s)")
    print(f"done · {len(files)} files · {total} materials")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
