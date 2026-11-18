import * as THREE from 'three';

/** First-person cuffed / kazenka hands parented to the camera. */
export function makeHands() {
  const g = new THREE.Group();
  g.name = 'FPHands';
  const skin = new THREE.MeshStandardMaterial({ color: 0xc4a07a, roughness: 0.7 });
  const sleeve = stripedMat();
  for (const side of [-1, 1]) {
    const arm = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.08, 0.28), sleeve);
    arm.position.set(side * 0.22, -0.22, -0.38);
    arm.rotation.x = 0.35;
    g.add(arm);
    const hand = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.05, 0.1), skin);
    hand.position.set(side * 0.22, -0.28, -0.54);
    g.add(hand);
  }
  const cuff = new THREE.Mesh(
    new THREE.TorusGeometry(0.05, 0.012, 6, 12),
    new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.8, roughness: 0.3 }),
  );
  cuff.name = 'Cuffs';
  cuff.position.set(0, -0.26, -0.5);
  cuff.rotation.y = Math.PI / 2;
  g.add(cuff);
  return g;
}

function stripedMat() {
  const c = document.createElement('canvas');
  c.width = 64;
  c.height = 64;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#6a6a68';
  ctx.fillRect(0, 0, 64, 64);
  ctx.fillStyle = '#2e2e2c';
  for (let y = 0; y < 64; y += 8) ctx.fillRect(0, y, 64, 4);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  return new THREE.MeshStandardMaterial({ map: tex, roughness: 0.75 });
}
