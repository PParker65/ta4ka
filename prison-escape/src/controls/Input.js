import { Joystick } from './Joystick.js';

/**
 * Desktop: pointer-lock look. WASD walk relative to the camera, Shift run.
 * Mobile: left stick move, right-half swipe look.
 */
export class Input {
  constructor({ mobile, canvas }) {
    this.mobile = mobile;
    this.canvas = canvas;
    this.joystick = new Joystick(
      document.getElementById('stick-root'),
      document.getElementById('stick-knob'),
    );
    this.joystick.enabled = !!mobile;

    this.yaw = 0;
    this.pitch = 0;
    this.lookPointer = null;
    this._lx = 0;
    this._ly = 0;
    this.keys = new Set();
    this.crouchHeld = false;
    this.sprintHeld = false;
    this.interactPulse = false;
    this.talkPulse = false;
    this.locked = false;
    this.sensitivity = mobile ? 0.012 : 0.0024;
    this.dragSensitivity = 0.008;

    this._down = this.onPointerDown.bind(this);
    this._move = this.onPointerMove.bind(this);
    this._up = this.onPointerUp.bind(this);
    this._keyDown = this.onKeyDown.bind(this);
    this._keyUp = this.onKeyUp.bind(this);
    this._mouse = this.onMouseMove.bind(this);
    this._lock = this.onLock.bind(this);

    window.addEventListener('pointerdown', this._down, { passive: false });
    window.addEventListener('pointermove', this._move, { passive: false });
    window.addEventListener('pointerup', this._up);
    window.addEventListener('pointercancel', this._up);
    window.addEventListener('keydown', this._keyDown);
    window.addEventListener('keyup', this._keyUp);
    window.addEventListener('contextmenu', (e) => e.preventDefault());
    document.addEventListener('mousemove', this._mouse);
    document.addEventListener('pointerlockchange', this._lock);

    document.getElementById('btn-interact').addEventListener('pointerdown', (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.interactPulse = true;
    });
    document.getElementById('btn-crouch').addEventListener('pointerdown', (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.crouchHeld = !this.crouchHeld;
      this.syncCrouchButton();
    });
    const runBtn = document.getElementById('btn-run');
    if (runBtn) {
      const down = (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.sprintHeld = true;
        runBtn.classList.add('bg-amber-700/70');
      };
      const up = () => {
        this.sprintHeld = false;
        runBtn.classList.remove('bg-amber-700/70');
      };
      runBtn.addEventListener('pointerdown', down);
      runBtn.addEventListener('pointerup', up);
      runBtn.addEventListener('pointercancel', up);
      runBtn.addEventListener('pointerleave', up);
    }
    this.syncCrouchButton();
  }

  syncCrouchButton() {
    const btn = document.getElementById('btn-crouch');
    btn.classList.toggle('bg-amber-700/70', this.crouchHeld);
    btn.textContent = this.crouchHeld ? 'Стоя' : 'Присесть';
  }

  overlay(e) {
    return e.target.closest('button, input, textarea, #dialog, #shop, #shmon-ui, #cards, #rope, #boot, #chat');
  }

  onLock() {
    this.locked = document.pointerLockElement === this.canvas;
    const hint = document.getElementById('look-hint');
    if (hint) hint.classList.toggle('hidden', this.locked || this.mobile);
  }

  tryLock() {
    if (this.mobile || this.locked) return;
    this.canvas.requestPointerLock?.();
  }

  onPointerDown(e) {
    this.onUnlockAudio?.();
    if (this.overlay(e)) return;
    if (!this.mobile && e.button === 0) this.tryLock();
    if (this.locked) return;
    if (this.mobile && e.clientX < window.innerWidth * 0.5) return;
    if (this.lookPointer !== null) return;
    this.lookPointer = e.pointerId;
    this._lx = e.clientX;
    this._ly = e.clientY;
    e.preventDefault();
  }

  onPointerMove(e) {
    if (this.locked || e.pointerId !== this.lookPointer) return;
    const dx = e.clientX - this._lx;
    const dy = e.clientY - this._ly;
    this._lx = e.clientX;
    this._ly = e.clientY;
    this.applyLook(dx, dy, this.dragSensitivity);
    e.preventDefault();
  }

  onMouseMove(e) {
    if (!this.locked) return;
    this.applyLook(e.movementX || 0, e.movementY || 0, this.sensitivity);
  }

  applyLook(dx, dy, sens) {
    this.yaw -= dx * sens;
    this.pitch = clamp(this.pitch - dy * sens, -0.72, 0.42);
  }

  onPointerUp(e) {
    if (e.pointerId === this.lookPointer) this.lookPointer = null;
  }

  onKeyDown(e) {
    this.onUnlockAudio?.();
    const tag = (e.target && e.target.tagName) || '';
    if (tag === 'INPUT' || tag === 'TEXTAREA') return;
    this.keys.add(e.code);
    this.keys.add((e.key || '').toLowerCase());
    if (e.code === 'KeyC') {
      this.crouchHeld = !this.crouchHeld;
      this.syncCrouchButton();
    }
    if ((e.code === 'KeyE' || e.code === 'Space' || e.code === 'KeyF') && !e.repeat) this.interactPulse = true;
    if (e.code === 'KeyT' && !e.repeat) this.talkPulse = true;
    if (e.code === 'Escape' && this.locked) document.exitPointerLock?.();
  }

  onKeyUp(e) {
    this.keys.delete(e.code);
    this.keys.delete((e.key || '').toLowerCase());
  }

  /** Look is mouse only. WASD never turns the camera. */
  turnRate() {
    return 0;
  }

  consumeInteract() {
    const v = this.interactPulse;
    this.interactPulse = false;
    return v;
  }

  consumeTalk() {
    const v = this.talkPulse;
    this.talkPulse = false;
    return v;
  }

  moveVector() {
    let x = this.joystick.enabled ? -this.joystick.moveX : 0;
    let z = this.joystick.enabled ? this.joystick.moveZ : 0;
    if (this.keys.has('KeyA') || this.keys.has('a')) x += 1;
    if (this.keys.has('KeyD') || this.keys.has('d')) x -= 1;
    if (this.keys.has('KeyW') || this.keys.has('ArrowUp') || this.keys.has('w') || this.keys.has('arrowup')) z -= 1;
    if (this.keys.has('KeyS') || this.keys.has('ArrowDown') || this.keys.has('s') || this.keys.has('arrowdown')) z += 1;
    const mag = Math.hypot(x, z);
    if (mag > 1) {
      x /= mag;
      z /= mag;
    }
    const run =
      this.sprintHeld || this.keys.has('ShiftLeft') || this.keys.has('ShiftRight') || this.keys.has('shift');
    return { x, z, mag: Math.min(1, mag), run };
  }

  dispose() {
    this.joystick.dispose();
    window.removeEventListener('pointerdown', this._down);
    window.removeEventListener('pointermove', this._move);
    window.removeEventListener('pointerup', this._up);
    window.removeEventListener('pointercancel', this._up);
    window.removeEventListener('keydown', this._keyDown);
    window.removeEventListener('keyup', this._keyUp);
    document.removeEventListener('mousemove', this._mouse);
    document.removeEventListener('pointerlockchange', this._lock);
  }
}

function clamp(v, a, b) {
  return Math.max(a, Math.min(b, v));
}
