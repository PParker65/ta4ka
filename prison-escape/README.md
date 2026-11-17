# Побег / Prison Escape

Mobile-first third-person 3D prison escape. Visuals follow a post-Soviet SIZO (green numbered cell doors, blue tile wainscot, terracotta floors, rusted lattice bunks, peeling plaster) — not a Hollywood orange-block prison.

Stack: **Three.js + Vite + Tailwind CSS**. Isolated from the rest of this repository (`prison-escape/` only).

## Run

```bash
cd prison-escape
npm install && npm run dev
```

Then open the printed local URL (default `http://localhost:5173`). Touch on a phone, or WASD + mouse on desktop.

## Controls

| Input | Action |
| --- | --- |
| Left half / virtual stick | Move |
| Right half swipe / mouse drag | Look (orbital third-person) |
| **Действие** / `E` | Open door 4, rattle locked doors, switch CCTV |
| **Присесть** / `C` | Crouch / stealth (harder for guards and cameras to see) |
| Shift | Run (desktop) |

Goal: leave cell **4**, sneak the corridor, reach the **дворик для прогулок**.

## Mixamo / GLB stubs

Placeholder orange-robe prisoner + `AnimationMixer` clips ship by default. Drop files to replace:

- `public/models/prisoner.glb`
- `public/models/mixamo/Idle.fbx`
- `public/models/mixamo/Walking.fbx`
- `public/models/mixamo/Running.fbx`

See `src/game/Character.js`.

## Quality

Desktop: SSAO + Bloom. Mobile / low-end: skipped automatically, pixel ratio capped, few real lights (fluorescent flicker is a shader).
