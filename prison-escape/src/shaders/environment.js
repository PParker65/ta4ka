import * as THREE from 'three';

function canvas(size) {
  const c = document.createElement('canvas');
  c.width = c.height = size;
  return { c, ctx: c.getContext('2d') };
}

function toTex(c, repeatX = 1, repeatY = 1) {
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(repeatX, repeatY);
  tex.anisotropy = 8;
  tex.minFilter = THREE.LinearMipmapLinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.generateMipmaps = true;
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.needsUpdate = true;
  return tex;
}

function noise(ctx, size, alpha = 0.12) {
  const img = ctx.getImageData(0, 0, size, size);
  for (let i = 0; i < img.data.length; i += 4) {
    const n = (Math.random() - 0.5) * 40 * alpha * 8;
    img.data[i] = Math.max(0, Math.min(255, img.data[i] + n));
    img.data[i + 1] = Math.max(0, Math.min(255, img.data[i + 1] + n));
    img.data[i + 2] = Math.max(0, Math.min(255, img.data[i + 2] + n));
  }
  ctx.putImageData(img, 0, 0);
}

/** Peeling beige/ochre plaster — cells & vault upper walls. */
export function plasterTex(size = 256) {
  const { c, ctx } = canvas(size);
  ctx.fillStyle = '#cbb89a';
  ctx.fillRect(0, 0, size, size);
  for (let i = 0; i < 70; i++) {
    const x = Math.random() * size;
    const y = Math.random() * size;
    const g = ctx.createRadialGradient(x, y, 1, x, y, 6 + Math.random() * 18);
    g.addColorStop(0, `rgba(${90 + Math.random() * 40},${70 + Math.random() * 30},50,0.28)`);
    g.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, size, size);
  }
  ctx.fillStyle = 'rgba(90,70,50,0.18)';
  for (let i = 0; i < 28; i++) {
    ctx.beginPath();
    const x = Math.random() * size;
    const y = Math.random() * size;
    ctx.ellipse(x, y, 4 + Math.random() * 10, 3 + Math.random() * 8, Math.random(), 0, 6.28);
    ctx.fill();
  }
  ctx.strokeStyle = 'rgba(70,55,40,0.25)';
  ctx.lineWidth = 1;
  for (let i = 0; i < 12; i++) {
    ctx.beginPath();
    ctx.moveTo(Math.random() * size, Math.random() * size);
    ctx.lineTo(Math.random() * size, Math.random() * size);
    ctx.stroke();
  }
  noise(ctx, size, 0.2);
  return toTex(c, 3, 2);
}

/** Dark-blue peeling paint (occupied cell). */
export function occupiedBlueTex(size = 256) {
  const { c, ctx } = canvas(size);
  ctx.fillStyle = '#1d3d62';
  ctx.fillRect(0, 0, size, size);
  ctx.fillStyle = '#c4b496';
  for (let i = 0; i < 22; i++) {
    ctx.globalAlpha = 0.55 + Math.random() * 0.4;
    ctx.beginPath();
    const x = Math.random() * size;
    const y = Math.random() * size;
    ctx.ellipse(x, y, 8 + Math.random() * 28, 6 + Math.random() * 18, Math.random(), 0, 6.28);
    ctx.fill();
  }
  ctx.globalAlpha = 1;
  noise(ctx, size, 0.15);
  return toTex(c, 2, 1.4);
}

/** Corridor white plaster with dirt streaks. */
export function corridorPlasterTex(size = 256) {
  const { c, ctx } = canvas(size);
  ctx.fillStyle = '#e8e4d8';
  ctx.fillRect(0, 0, size, size);
  ctx.fillStyle = 'rgba(160,150,130,0.35)';
  for (let i = 0; i < 16; i++) {
    ctx.fillRect(Math.random() * size, Math.random() * size, 30 + Math.random() * 80, 8 + Math.random() * 40);
  }
  noise(ctx, size, 0.12);
  return toTex(c, 2, 1.5);
}

function tileGrid(ctx, size, cols, rows, light, dark, grout) {
  const tw = size / cols;
  const th = size / rows;
  ctx.fillStyle = grout;
  ctx.fillRect(0, 0, size, size);
  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < cols; x++) {
      const jitter = (Math.random() - 0.5) * 10;
      ctx.fillStyle = shade(light, jitter);
      ctx.fillRect(x * tw + 1, y * th + 1, tw - 2, th - 2);
      if (Math.random() < 0.08) {
        ctx.fillStyle = dark;
        ctx.globalAlpha = 0.35;
        ctx.fillRect(x * tw + 1, y * th + 1, tw - 2, th - 2);
        ctx.globalAlpha = 1;
      }
    }
  }
}

function shade(hex, d) {
  const n = parseInt(hex.slice(1), 16);
  const r = Math.max(0, Math.min(255, ((n >> 16) & 255) + d));
  const g = Math.max(0, Math.min(255, ((n >> 8) & 255) + d));
  const b = Math.max(0, Math.min(255, (n & 255) + d));
  return `rgb(${r|0},${g|0},${b|0})`;
}

/** Cyan-blue square wainscot tiles (vaulted corridor). */
export function blueTileTex() {
  const { c, ctx } = canvas(256);
  tileGrid(ctx, 256, 8, 8, '#2f8aa0', '#1a5c6c', '#1c3d46');
  noise(ctx, 256, 0.1);
  return toTex(c, 2.2, 1.1);
}

/** Mint/teal cell tile band + white tiles. */
export function tealBandTex() {
  const { c, ctx } = canvas(256);
  tileGrid(ctx, 256, 10, 10, '#8fd4c6', '#6aaea4', '#cfd8d4');
  return toTex(c, 4, 0.35);
}

export function whiteTileTex() {
  const { c, ctx } = canvas(256);
  tileGrid(ctx, 256, 8, 8, '#efebe3', '#c8c0b4', '#b9b3a8');
  for (let i = 0; i < 10; i++) {
    ctx.fillStyle = 'rgba(80,70,60,0.25)';
    ctx.fillRect(Math.random() * 256, Math.random() * 256, 20, 14);
  }
  return toTex(c, 3, 3);
}

/** Terracotta corridor floor — painted, not a high-frequency checker (that swam). */
export function redFloorTex() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#a24a34';
  ctx.fillRect(0, 0, 256, 256);
  ctx.fillStyle = 'rgba(70,25,16,0.18)';
  for (let i = 0; i < 10; i++) ctx.fillRect(0, Math.random() * 256, 256, 10 + Math.random() * 18);
  noise(ctx, 256, 0.08);
  return toTex(c, 1.6, 4);
}

/** Broken beige cell floor with missing tiles → grey screed. */
export function brokenFloorTex() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#6a6864';
  ctx.fillRect(0, 0, 256, 256);
  const tw = 32;
  for (let y = 0; y < 8; y++) {
    for (let x = 0; x < 8; x++) {
      if (Math.random() < 0.62) {
        ctx.fillStyle = shade('#d8c9a6', (Math.random() - 0.5) * 18);
        ctx.fillRect(x * tw + 1, y * tw + 1, tw - 2, tw - 2);
      }
    }
  }
  noise(ctx, 256, 0.08);
  return toTex(c, 2.2, 2.2);
}

/** Rusty lattice for bunk decks (photo 02 / 10). */
export function latticeTex() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#1a1512';
  ctx.fillRect(0, 0, 256, 256);
  ctx.strokeStyle = '#5a4036';
  ctx.lineWidth = 5;
  for (let y = 8; y < 256; y += 18) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(256, y);
    ctx.stroke();
  }
  ctx.strokeStyle = '#3a2a24';
  ctx.lineWidth = 3;
  for (let x = 10; x < 256; x += 22) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, 256);
    ctx.stroke();
  }
  ctx.strokeStyle = '#8a4530';
  ctx.lineWidth = 2;
  for (let y = 8; y < 256; y += 18) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(256, y);
    ctx.stroke();
  }
  const tex = toTex(c, 2, 3);
  return tex;
}

export function brickTex() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#6a5346';
  ctx.fillRect(0, 0, 256, 256);
  const bh = 28;
  const bw = 56;
  for (let y = 0, row = 0; y < 256; y += bh, row++) {
    const off = row % 2 ? bw / 2 : 0;
    for (let x = -bw; x < 256; x += bw) {
      ctx.fillStyle = shade('#8a6a58', (Math.random() - 0.5) * 28);
      ctx.fillRect(x + off + 2, y + 2, bw - 4, bh - 4);
    }
  }
  return toTex(c, 2, 2);
}

export function ceilingTex() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#d9d2c6';
  ctx.fillRect(0, 0, 256, 256);
  ctx.fillStyle = 'rgba(120,110,90,0.2)';
  for (let i = 0; i < 20; i++) ctx.fillRect(Math.random() * 256, Math.random() * 256, 50, 18);
  noise(ctx, 256, 0.1);
  return toTex(c, 4, 8);
}

export function diamondCeilingTex() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#dfe8ee';
  ctx.fillRect(0, 0, 256, 256);
  ctx.fillStyle = '#3d6ea8';
  const drawD = (x, y, col) => {
    ctx.fillStyle = col;
    ctx.beginPath();
    ctx.moveTo(x, y - 14);
    ctx.lineTo(x + 10, y);
    ctx.lineTo(x, y + 14);
    ctx.lineTo(x - 10, y);
    ctx.closePath();
    ctx.fill();
  };
  for (let x = 20; x < 256; x += 36) {
    drawD(x, 40, '#3d6ea8');
    drawD(x + 18, 40, '#c9899a');
  }
  ctx.fillStyle = '#3a7aa0';
  ctx.fillRect(0, 0, 256, 18);
  noise(ctx, 256, 0.08);
  return toTex(c, 8, 1);
}

export function greenMetalTex() {
  const { c, ctx } = canvas(128);
  ctx.fillStyle = '#1f8a3a';
  ctx.fillRect(0, 0, 128, 128);
  ctx.fillStyle = 'rgba(0,0,0,0.15)';
  for (let i = 0; i < 20; i++) ctx.fillRect(0, Math.random() * 128, 128, 3);
  noise(ctx, 128, 0.12);
  return toTex(c, 1, 2);
}

export const FlickerLampShader = {
  uniforms: {
    uTime: { value: 0 },
    uAlarm: { value: 0 },
    uColor: { value: new THREE.Color(0xf2f0dc) },
    uId: { value: 0 },
  },
  vertexShader: /* glsl */ `
    varying vec3 vN;
    void main() {
      vN = normalize(normalMatrix * normal);
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: /* glsl */ `
    uniform float uTime;
    uniform float uAlarm;
    uniform vec3 uColor;
    uniform float uId;
    varying vec3 vN;
    void main() {
      float t = uTime * mix(1.1, 10.0, uAlarm) + uId * 13.7;
      float f = 0.94 + 0.06 * sin(t) * sin(t * 0.73 + 0.4);
      f *= 0.82 + 0.18 * abs(vN.y);
      vec3 col = uColor;
      if (uAlarm > 0.5) {
        float strobe = step(0.42, fract(uTime * 7.5 + uId));
        f *= mix(0.22, 1.2, strobe);
        col = mix(uColor, vec3(1.0, 0.12, 0.08), 0.7);
      }
      gl_FragColor = vec4(col * f * 1.35, 1.0);
    }
  `,
};

/** Cream plaster facade with barred windows — Лукʼянівка blocks. */
export function facadeTex() {
  const { c, ctx } = canvas(512);
  ctx.fillStyle = '#d4cec0';
  ctx.fillRect(0, 0, 512, 512);
  ctx.fillStyle = '#c4b8a6';
  ctx.fillRect(0, 0, 512, 28);
  ctx.fillRect(0, 490, 512, 22);
  const floors = 5;
  const bays = 9;
  const ww = 28;
  const wh = 42;
  for (let f = 0; f < floors; f++) {
    for (let b = 0; b < bays; b++) {
      const x = 28 + b * 54;
      const y = 48 + f * 86;
      ctx.fillStyle = '#1a222c';
      ctx.fillRect(x, y, ww, wh);
      ctx.fillStyle = 'rgba(180, 200, 210, 0.12)';
      ctx.fillRect(x + 2, y + 2, ww - 4, 8);
      ctx.strokeStyle = 'rgba(20,20,22,0.7)';
      ctx.lineWidth = 1;
      for (let i = 1; i < 4; i++) {
        ctx.beginPath();
        ctx.moveTo(x + (ww * i) / 4, y);
        ctx.lineTo(x + (ww * i) / 4, y + wh);
        ctx.stroke();
      }
    }
  }
  noise(ctx, 512, 0.06);
  return toTex(c, 1, 1);
}

export function asphaltTex() {
  const { c, ctx } = canvas(256);
  ctx.fillStyle = '#3a3c40';
  ctx.fillRect(0, 0, 256, 256);
  ctx.fillStyle = '#2e3034';
  for (let i = 0; i < 18; i++) ctx.fillRect(Math.random() * 256, Math.random() * 256, 40, 3);
  noise(ctx, 256, 0.1);
  return toTex(c, 1, 1);
}

export function skyTex() {
  const { c, ctx } = canvas(256);
  const g = ctx.createLinearGradient(0, 0, 0, 256);
  g.addColorStop(0, '#8ea8bc');
  g.addColorStop(0.45, '#b7c4ce');
  g.addColorStop(0.72, '#c9c2b4');
  g.addColorStop(1, '#d8cbb8');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 256, 256);
  ctx.fillStyle = 'rgba(255,255,255,0.18)';
  for (let i = 0; i < 6; i++) {
    ctx.beginPath();
    ctx.ellipse(40 + i * 40, 70 + (i % 3) * 12, 50, 10, 0, 0, 6.28);
    ctx.fill();
  }
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.needsUpdate = true;
  return tex;
}

export function createFlickerMaterial(id = 0) {
  const mat = new THREE.ShaderMaterial({
    uniforms: THREE.UniformsUtils.clone(FlickerLampShader.uniforms),
    vertexShader: FlickerLampShader.vertexShader,
    fragmentShader: FlickerLampShader.fragmentShader,
  });
  mat.uniforms.uId.value = id;
  mat.toneMapped = false;
  return mat;
}

export function updateFlickerMaterials(materials, time, alarm) {
  for (const m of materials) {
    m.uniforms.uTime.value = time;
    m.uniforms.uAlarm.value = alarm ? 1 : 0;
  }
}
