import { Joystick } from './Joystick.js';

/**
 * Touch + keyboard/mouse fallback.
 * Left half: joystick. Right half: swipe look (orbital yaw/pitch).
 */
export class Input {
  constructor() {
    this.joystick = new Joystick(
      document.getElementById('stick-root'),
      document.getElementById('stick-knob'),
    );

    this.yaw = 0;
    this.pitch = 0.18;
    this.lookPointer = null;
    this._lx = 0;
    this._ly = 0;
    this.keys = new Set();
    this.crouchHeld = false;
    this.interactPulse = false;
    this.sensitivity = 0.012;

    this._down = this.onPointerDown.bind(this);
    this._move = this.onPointerMove.bind(this);
    this._up = this.onPointerUp.bind(this);
    this._keyDown = this.onKeyDown.bind(this);
    this._keyUp = this.onKeyUp.bind(this);

    window.addEventListener('pointerdown', this._down, { passive: false });
    window.addEventListener('pointermove', this._move, { passive: false });
    window.addEventListener('pointerup', this._up);
    window.addEventListener('pointercancel', this._up);
    window.addEventListener('keydown', this._keyDown);
    window.addEventListener('keyup', this._keyUp);
    window.addEventListener('contextmenu', (e) => e.preventDefault());

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
    this.syncCrouchButton();
  }

  syncCrouchButton() {
    const btn = document.getElementById('btn-crouch');
    btn.classList.toggle('bg-amber-700/70', this.crouchHeld);
    btn.textContent = this.crouchHeld ? 'Стоя' : 'Присесть';
  }

  onPointerDown(e) {
    if (e.target.closest('button')) return;
    if (e.clientX >= window.innerWidth * 0.5 && this.lookPointer === null) {
      this.lookPointer = e.pointerId;
      this._lx = e.clientX;
      this._ly = e.clientY;
      e.preventDefault();
    }
  }

  onPointerMove(e) {
    if (e.pointerId !== this.lookPointer) return;
    const dx = e.clientX - this._lx;
    const dy = e.clientY - this._ly;
    this._lx = e.clientX;
    this._ly = e.clientY;
    this.yaw -= dx * this.sensitivity;
    this.pitch = THREE_CLAMP(this.pitch + dy * this.sensitivity, 0.02, 0.72);
    e.preventDefault();
  }

  onPointerUp(e) {
    if (e.pointerId === this.lookPointer) this.lookPointer = null;
  }

  onKeyDown(e) {
    this.keys.add(e.code);
    if (e.code === 'KeyC') {
      this.crouchHeld = !this.crouchHeld;
      this.syncCrouchButton();
    }
    if (e.code === 'KeyE' || e.code === 'Space') this.interactPulse = true;
  }

  onKeyUp(e) {
    this.keys.delete(e.code);
  }

  consumeInteract() {
    const v = this.interactPulse;
    this.interactPulse = false;
    return v;
  }

  /** Camera-relative move vector on XZ, magnitude 0..1. */
  moveVector() {
    let x = this.joystick.moveX;
    let z = this.joystick.moveZ;
    if (this.keys.has('KeyA') || this.keys.has('ArrowLeft')) x -= 1;
    if (this.keys.has('KeyD') || this.keys.has('ArrowRight')) x += 1;
    if (this.keys.has('KeyW') || this.keys.has('ArrowUp')) z -= 1;
    if (this.keys.has('KeyS') || this.keys.has('ArrowDown')) z += 1;
    const mag = Math.hypot(x, z);
    if (mag > 1) {
      x /= mag;
      z /= mag;
    }
    const run = this.keys.has('ShiftLeft') || this.keys.has('ShiftRight') || mag > 0.72;
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
  }
}

function THREE_CLAMP(v, a, b) {
  return Math.max(a, Math.min(b, v));
}
