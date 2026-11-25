# Mixamo clips (stubs)

The game loads a styled placeholder prisoner if these files are missing.
Drop Mixamo FBX exports here to swap in real locomotion:

- `Idle.fbx`
- `Walking.fbx`
- `Running.fbx`  (run clip)

Optional crouch:

- `CrouchIdle.fbx`
- `Crouching.fbx`

Character GLB (optional):

- `../prisoner.glb` — orange jumpsuit character; `GLTFLoader` tries this first.

See `src/game/Character.js` for the loader stubs.
