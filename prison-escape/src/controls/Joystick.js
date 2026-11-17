/**
 * Left-half virtual analog stick.
 * Smooth -1..1 axes, deadzone, works with touch and mouse fallback.
 */
export class Joystick {
  constructor(root, knob) {
    this.root = root;
    this.knob = knob;
    this.pointerId = null;
    this.x = 0;
    this.y = 0;
    this._active = false;
    this.radius = 52;
    this.dead = 0.12;

    this._onDown = this.onDown.bind(this);
    this._onMove = this.onMove.bind(this);
    this._onUp = this.onUp.bind(this);

    window.addEventListener('pointerdown', this._onDown, { passive: false });
    window.addEventListener('pointermove', this._onMove, { passive: false });
    window.addEventListener('pointerup', this._onUp);
    window.addEventListener('pointercancel', this._onUp);
  }

  isLeftHalf(clientX) {
    return clientX < window.innerWidth * 0.5;
  }

  onDown(e) {
    if (e.target.closest('button')) return;
    if (this.pointerId !== null) return;
    if (!this.isLeftHalf(e.clientX)) return;
    this.pointerId = e.pointerId;
    this._active = true;
    this.root.setPointerCapture?.(e.pointerId);
    this.sample(e.clientX, e.clientY);
    e.preventDefault();
  }

  onMove(e) {
    if (e.pointerId !== this.pointerId) return;
    this.sample(e.clientX, e.clientY);
    e.preventDefault();
  }

  onUp(e) {
    if (e.pointerId !== this.pointerId) return;
    this.pointerId = null;
    this._active = false;
    this.x = 0;
    this.y = 0;
    this.knob.style.transform = 'translate(-50%, -50%)';
  }

  sample(cx, cy) {
    const rect = this.root.getBoundingClientRect();
    const ox = rect.left + rect.width / 2;
    const oy = rect.top + rect.height / 2;
    let dx = cx - ox;
    let dy = cy - oy;
    const len = Math.hypot(dx, dy) || 1;
    const clamped = Math.min(len, this.radius);
    dx = (dx / len) * clamped;
    dy = (dy / len) * clamped;
    this.knob.style.transform = `translate(calc(-50% + ${dx}px), calc(-50% + ${dy}px))`;
    let nx = dx / this.radius;
    let ny = dy / this.radius;
    const mag = Math.hypot(nx, ny);
    if (mag < this.dead) {
      this.x = 0;
      this.y = 0;
      return;
    }
    const scaled = (mag - this.dead) / (1 - this.dead);
    this.x = (nx / mag) * scaled;
    this.y = (ny / mag) * scaled;
  }

  /** Forward is negative Y on the stick (up). */
  get moveX() {
    return this.x;
  }

  get moveZ() {
    return this.y;
  }

  get magnitude() {
    return Math.min(1, Math.hypot(this.x, this.y));
  }

  dispose() {
    window.removeEventListener('pointerdown', this._onDown);
    window.removeEventListener('pointermove', this._onMove);
    window.removeEventListener('pointerup', this._onUp);
    window.removeEventListener('pointercancel', this._onUp);
  }
}
