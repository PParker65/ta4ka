#!/usr/bin/env python3
"""Record the in-app M2 view (model-viewer) to social-safe H.264 MP4s."""

from __future__ import annotations

import http.server
import shutil
import socketserver
import subprocess
import sys
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GLB = ROOT / "assets" / "models" / "2023_bmw_m2_m-performance_parts_g87.glb"
MV_JS = (
    ROOT
    / "build"
    / "web"
    / "assets"
    / "packages"
    / "model_viewer_plus"
    / "assets"
    / "model-viewer.min.js"
)
OUT_DIR = Path("/Users/anastasiia/Desktop/APEX-M2-pashalka")
TIKTOK_OUT = Path("/Users/anastasiia/Desktop/мм2")
STAGE = ROOT / "tools" / ".teaser_stage"
# Higher % = farther camera = smaller car. 72% → 108% ≈ 67% on-screen size.
ORBIT_PCT = 110
# Full M2 in 9:16: target the auto bbox (car center after 0.01 Sketchfab scale).
TIKTOK_ORBIT_PCT = 155
CAMERA_TARGET = "auto auto auto"
TIKTOK_YAW0 = 28.0
TIKTOK_YAW_SPAN = 26.0
TIKTOK_PITCH = 80.0
ORBIT_YAW0 = 32.0
ORBIT_YAW_SPAN = 58.0  # slower orbit, fewer reflection strobes

# Overlay is driven per captured frame via __APEX_SET_T (0..1 over 16s).
# CSS animations would finish in wall-clock time while we screenshot ~480 frames.
HTML = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<script type="module" src="/model-viewer.min.js"></script>
<style>
  html,body{margin:0;width:100%;height:100%;background:#0A0A0C;overflow:hidden}
  model-viewer{width:100%;height:100%;background:#0A0A0C;
    --progress-bar-color:#C4CAD2;--progress-bar-height:2px}
  model-viewer.apex-painted{opacity:1!important}
  model-viewer{opacity:0}
  #reel{
    position:fixed;inset:0;pointer-events:none;z-index:4;
    display:flex;flex-direction:column;align-items:center;
    padding:0;
  }
  .beat{
    position:absolute;left:0;right:0;
    display:flex;flex-direction:column;align-items:center;
    opacity:0;
    will-change:opacity;
  }
  .beat-top{top:__TOP__}
  .lockup{
    display:flex;align-items:center;justify-content:center;gap:10px;
  }
  .tick{
    width:2px;height:42px;border-radius:0;background:#D70200;
    flex:0 0 auto;
  }
  .super{
    margin:0 -0.28em 0 0;padding:0;border:0;
    font-family:"Helvetica Neue",Helvetica,Arial,sans-serif;
    font-weight:100;font-synthesis:none;
    font-size:84px;letter-spacing:0.22em;
    color:#E6E4DF;
    line-height:0.9;
  }
  .four{color:#D70200;font-weight:100;letter-spacing:0.22em}
  .soon{
    margin:8px -0.48em 0 0;padding:0;
    font-family:"Helvetica Neue",Helvetica,Arial,sans-serif;
    font-weight:100;font-synthesis:none;
    font-size:20px;letter-spacing:0.48em;
    color:#E6E4DF;
    line-height:1;
  }
</style>
</head>
<body>
<model-viewer
  id="car"
  src="/car.glb"
  alt=""
  loading="eager"
  reveal="manual"
  camera-controls
  disable-tap
  disable-pan
  interaction-prompt="none"
  shadow-intensity="0.22"
  shadow-softness="1"
  exposure="1.62"
  tone-mapping="aces"
  environment-image="legacy"
  interpolation-decay="0"
  camera-orbit="32deg 85deg __ORBIT__%"
  camera-target="__TARGET__"
  min-camera-orbit="auto 55deg 22%"
  max-camera-orbit="Infinity 105deg 260%"
  field-of-view="36deg"
  min-field-of-view="18deg"
  max-field-of-view="48deg"
></model-viewer>
<div id="reel" aria-hidden="true">
  <div class="beat beat-top" id="beat-mark">
    <div class="lockup">
      <span class="tick" id="tick"></span>
      <span class="super">Ta<span class="four">4</span>ka</span>
    </div>
    <div class="soon" id="soon">скоро.</div>
  </div>
</div>
<script>
(function () {
  function apply(mv) {
    // Keep baked Lion red + APEX? vinyl — do not overwrite film.
    return !!(mv.model && mv.model.materials);
  }
  function cl01(x) { return Math.max(0, Math.min(1, x)); }
  function smooth(x) { x = cl01(x); return x * x * (3 - 2 * x); }
  function gate(sec, t0, t1, fadeIn, fadeOut) {
    if (sec < t0 || sec > t1) return 0;
    return Math.min(smooth((sec - t0) / fadeIn), smooth((t1 - sec) / fadeOut));
  }
  var mark = document.getElementById('beat-mark');
  var soon = document.getElementById('soon');
  var tick = document.getElementById('tick');
  window.__APEX_SET_T = function (t01) {
    var s = t01 * 16;
    var apex = gate(s, 1.70, 7.55, 0.90, 0.85);
    var skoro = gate(s, 4.55, 7.55, 0.75, 0.85);
    mark.style.opacity = String(Math.max(apex, skoro));
    soon.style.opacity = String(skoro);
    tick.style.opacity = String(apex);
  };
  window.__APEX_SET_T(0);
  var mv = document.getElementById('car');
  function go() {
    apply(mv);
    mv.classList.add('apex-painted');
    mv.style.opacity = '1';
    try { if (mv.dismissPoster) mv.dismissPoster(); } catch (e) {}
    window.__APEX_READY = true;
  }
  mv.addEventListener('load', go);
  setTimeout(function () { if (!window.__APEX_READY) go(); }, 8000);
})();
</script>
</body>
</html>
"""


def build_html(
    orbit_pct: float,
    *,
    top: str,
    yaw: float = 32.0,
    pitch: float = 85.0,
) -> str:
    return (
        HTML.replace("32deg 85deg __ORBIT__%", f"{yaw:.0f}deg {pitch:.0f}deg {orbit_pct:.0f}%")
        .replace("__TARGET__", CAMERA_TARGET)
        .replace("__TOP__", top)
    )


def ffmpeg_exe() -> str:
    import imageio_ffmpeg

    return imageio_ffmpeg.get_ffmpeg_exe()


def serve(directory: Path) -> tuple[socketserver.TCPServer, int]:
    handler = http.server.SimpleHTTPRequestHandler
    class Quiet(handler):
        def log_message(self, *args):
            return

    httpd = socketserver.TCPServer(("127.0.0.1", 0), lambda *a: Quiet(*a, directory=str(directory)))
    port = httpd.server_address[1]
    t = threading.Thread(target=httpd.serve_forever, daemon=True)
    t.start()
    return httpd, port


# Master 1080×1920. 1:1 is a center square. 16:9 is pillarboxed (full frame).
CROP_1X1 = (0, 420, 1080, 1500)
VF_16X9 = (
    "scale=-2:1080:flags=lanczos,"
    "pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x0A0A0C,"
    "format=yuv420p"
)


def encode_mp4(
    src: list[str],
    dest: Path,
    *,
    fps: int,
    vf: str,
    crf: str | None = "16",
    bitrate: str | None = None,
    minrate: str | None = None,
    level: str = "4.1",
    maxrate: str | None = "10M",
    bufsize: str | None = "20M",
    preset: str = "medium",
) -> None:
    """Social-safe H.264 Progressive MP4 (not GIF / APNG / rgb24)."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        ffmpeg_exe(),
        "-y",
        *src,
        "-vf",
        vf,
        "-r",
        str(fps),
        "-fps_mode",
        "cfr",
        "-c:v",
        "libx264",
        "-profile:v",
        "high",
        "-level",
        level,
        "-pix_fmt",
        "yuv420p",
        "-tag:v",
        "avc1",
        "-preset",
        preset,
    ]
    if bitrate:
        cmd.extend(["-b:v", bitrate])
    elif crf:
        cmd.extend(["-crf", crf])
    if minrate:
        cmd.extend(["-minrate", minrate])
    if maxrate:
        cmd.extend(["-maxrate", maxrate])
    if bufsize:
        cmd.extend(["-bufsize", bufsize])
    cmd.extend(
        [
            "-g",
            str(fps),
            "-bf",
            "2",
            "-movflags",
            "+faststart",
            "-an",
            "-f",
            "mp4",
            str(dest),
        ]
    )
    subprocess.check_call(cmd)


def encode_frames(
    frames_dir: Path, w: int, h: int, fps: int, dest: Path, **enc
) -> None:
    encode_mp4(
        ["-framerate", str(fps), "-i", str(frames_dir / "f_%04d.png")],
        dest,
        fps=fps,
        vf=(
            f"scale={w}:{h}:flags=lanczos+accurate_rnd+full_chroma_int,"
            "format=yuv420p"
        ),
        **enc,
    )


def derive_crop(src: Path, dest: Path, *, fps: int, vf: str) -> None:
    encode_mp4(["-i", str(src)], dest, fps=fps, vf=vf)


def main() -> int:
    preview = "--preview" in sys.argv
    tiktok = "--tiktok" in sys.argv
    duration = 16.0
    fps = 30
    frames = 1 if preview else int(duration * fps)
    orbit_pct = TIKTOK_ORBIT_PCT if tiktok else ORBIT_PCT
    for arg in sys.argv[1:]:
        if arg.startswith("--orbit="):
            orbit_pct = float(arg.split("=", 1)[1])
    if not GLB.exists():
        print("missing GLB", GLB, file=sys.stderr)
        return 1
    if not MV_JS.exists():
        print("missing model-viewer", MV_JS, file=sys.stderr)
        return 1

    if STAGE.exists():
        shutil.rmtree(STAGE)
    STAGE.mkdir(parents=True)
    shutil.copy2(GLB, STAGE / "car.glb")
    sys.path.insert(0, str(ROOT / "tools"))
    print("teaser uses baked wrap as-is (Lion red + APEX? vinyl)", flush=True)
    shutil.copy2(MV_JS, STAGE / "model-viewer.min.js")
    if tiktok:
        yaw0, yaw_span, pitch = TIKTOK_YAW0, TIKTOK_YAW_SPAN, TIKTOK_PITCH
        html = build_html(orbit_pct, top="36vh", yaw=yaw0, pitch=pitch)
        dsf = 2
    else:
        yaw0, yaw_span, pitch = ORBIT_YAW0, ORBIT_YAW_SPAN, 85.0
        html = build_html(orbit_pct, top="28vh", yaw=yaw0, pitch=pitch)
        dsf = 1
    (STAGE / "index.html").write_text(html, encoding="utf-8")
    frames9 = STAGE / "f9"
    frames1 = STAGE / "f1"
    frames9.mkdir()
    if not tiktok:
        frames1.mkdir()

    httpd, port = serve(STAGE)
    url = f"http://127.0.0.1:{port}/index.html"
    print("serve", url, flush=True)

    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        chrome = ROOT / "tools" / ".pw-chrome" / "chromium-1223" / "chrome-mac-arm64" / (
            "Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
        )
        if not chrome.exists():
            raise SystemExit(f"missing chrome: {chrome}")
        browser = p.chromium.launch(
            headless=True,
            executable_path=str(chrome),
            args=[
                "--use-angle=metal",
                "--enable-webgl",
                "--ignore-gpu-blocklist",
                "--autoplay-policy=no-user-gesture-required",
            ],
        )
        page = browser.new_page(
            viewport={"width": 1080, "height": 1920},
            device_scale_factor=dsf,
        )
        page.goto(url, wait_until="domcontentloaded", timeout=120000)
        page.wait_for_function("window.__APEX_READY === true", timeout=90000)
        page.wait_for_timeout(700)

        def pose(t01: float, orbit: str | None = None) -> None:
            theta = yaw0 + yaw_span * t01
            cam = orbit or f"{theta:.3f}deg {pitch:.0f}deg {orbit_pct}%"
            page.evaluate(
                f"""() => {{
                  const mv = document.getElementById('car');
                  mv.cameraTarget = '{CAMERA_TARGET}';
                  mv.cameraOrbit = '{cam}';
                  mv.jumpCameraToGoal();
                  if (window.__APEX_SET_T) window.__APEX_SET_T({t01:.5f});
                }}"""
            )
            page.wait_for_timeout(90)

        # stills — overlay beats (door has no APEX vinyl)
        def shot(path):
            page.screenshot(path=str(path), type="png", timeout=120000, animations="disabled")

        pose(0.0)
        shot(STAGE / "preview_front.png")
        pose(3.20 / 16.0)
        shot(STAGE / "preview_apex.png")
        pose(6.20 / 16.0)
        shot(STAGE / "preview_soon.png")
        pose(12.00 / 16.0)
        shot(STAGE / "preview_crypt.png")
        pose(0.72, f"88deg 82deg {orbit_pct}%")
        shot(STAGE / "preview_side.png")
        pose(0.0)

        if preview:
            from PIL import Image

            if tiktok:
                soon = Image.open(STAGE / "preview_soon.png")
                print("tiktok preview", soon.size, "orbit", orbit_pct, flush=True)
                if not any(a.startswith("--orbit=") for a in sys.argv[1:]):
                    mid = 6.20 / 16.0
                    th = yaw0 + yaw_span * mid
                    for pct in (160, 190, 220):
                        pose(mid, f"{th:.3f}deg {pitch:.0f}deg {pct}%")
                        shot(STAGE / f"preview_orbit_{pct:.0f}.png")
            else:
                soon = Image.open(STAGE / "preview_soon.png")
                soon.crop(CROP_1X1).save(STAGE / "preview_soon_1x1.png")
                fitted = soon.resize((608, 1080), Image.Resampling.LANCZOS)
                letter = Image.new("RGB", (1920, 1080), (10, 10, 12))
                letter.paste(fitted, ((1920 - 608) // 2, 0))
                letter.save(STAGE / "preview_soon_16x9.png")
            browser.close()
            httpd.shutdown()
            for pth in sorted(STAGE.glob("preview_*.png")):
                print(pth)
            return 0

        for i in range(frames):
            t = i / max(1, frames - 1)
            pose(t)
            # 9:16
            png9 = frames9 / f"f_{i:04d}.png"
            page.screenshot(
                path=str(png9), type="png", timeout=120000, animations="disabled"
            )
            if not tiktok:
                from PIL import Image

                im = Image.open(png9)
                crop = im.crop(CROP_1X1)
                crop.save(frames1 / f"f_{i:04d}.png")
            if i % 30 == 0:
                print(f"{i}/{frames}", flush=True)

        browser.close()
    httpd.shutdown()

    if tiktok:
        TIKTOK_OUT.mkdir(parents=True, exist_ok=True)
        out_tt = TIKTOK_OUT / "мм2-tiktok-9x16.mp4"
        encode_frames(
            frames9,
            1080,
            1920,
            fps,
            out_tt,
            crf=None,
            bitrate="16M",
            minrate="14M",
            level="4.2",
            maxrate="20M",
            bufsize="32M",
            preset="slow",
        )
        (TIKTOK_OUT / "README.txt").write_text(
            "\n".join(
                [
                    "мм2 — TikTok, размер один в один.",
                    "",
                    "Файл: мм2-tiktok-9x16.mp4",
                    "Заливай в TikTok как есть. Не кропай и не pinch-zoom.",
                    "1080×1920, 9:16, H.264 High avc1, ~16 Mbps, 30 fps, без звука.",
                    "",
                    "Overlay: только сверху — Ta4ka 1.70–7.55 · скоро. 4.55–7.55",
                    "Нижнего текста нет.",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        print(out_tt, out_tt.stat().st_size)
        return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out9 = OUT_DIR / "m2-apex-9x16.mp4"
    out1 = OUT_DIR / "m2-apex-1x1.mp4"
    out16 = OUT_DIR / "m2-apex-16x9.mp4"
    encode_frames(frames9, 1080, 1920, fps, out9)
    encode_frames(frames1, 1080, 1080, fps, out1)
    derive_crop(out9, out16, fps=fps, vf=VF_16X9)
    (OUT_DIR / "README.txt").write_text(
        "\n".join(
            [
                "APEX M2 teaser — promo reel, not a product explainer.",
                "Door is clean: no APEX vinyl / door badge on the car in this video.",
                "Type lives only in the HTML overlay (top APEX → скоро.). No bottom copy.",
                "Letters: Helvetica Neue UltraLight, tracking 0.42em, #E6E4DF, thin red tick #D70200.",
                "Studio: #0A0A0C  ·  Lion red M2 #D70200  ·  black kidney + bumper grilles  ·  zoomed-out orbit  ·  silent",
                "",
                "Codec (all three files) — real H.264 MP4, not GIF/APNG:",
                "  container  MP4 (isom/iso2/avc1/mp41)  ·  +faststart",
                "  video      libx264  High@L4.1  yuv420p  avc1  CFR 30fps",
                "  audio      none (silent)",
                "",
                "Which file for which network:",
                "  m2-apex-9x16.mp4   1080×1920   TikTok · Reels · Shorts · Stories",
                "  m2-apex-1x1.mp4    1080×1080   Instagram / Facebook feed",
                "  m2-apex-16x9.mp4   1920×1080   YouTube · X · LinkedIn · Telegram landscape",
                "",
                "On-screen overlay (HTML/CSS over model-viewer, in the recording):",
                "  0.00–1.70s   —  no type",
                "  1.70–7.55s   —  TOP  APEX   (thin, wide tracking, micro red tick #D70200)",
                "  4.55–7.55s   —  TOP  скоро.  (under APEX; both leave together)",
                "  7.55–16.00s —  no type",
                "",
                "Copy used:",
                "  APEX",
                "  скоро.",
                "",
                "Nothing else is named. Fade in/out per beat — not held for the full 16s.",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(out9, out9.stat().st_size)
    print(out1, out1.stat().st_size)
    print(out16, out16.stat().st_size)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
