import * as THREE from 'three';

/** First-person cuffed / kazenka hands parented to the camera. */
export function makeHands() {
  const g = new THREE.Group();
  g.name = 'FPHands';
  const skin = new THREE.MeshStandardMaterial({ color: 0xc4a07a, roughness: 0.62 });
  const sleeve = streetMat();
  g.userData.street = sleeve;
  g.userData.kaz = stripedMat();
  const arms = [];
  for (const side of [-1, 1]) {
    const arm = new THREE.Group();
    arm.position.set(side * 0.16, -0.22, -0.28);
    g.add(arm);
    const sleeveM = new THREE.Mesh(new THREE.BoxGeometry(0.055, 0.05, 0.11), sleeve);
    sleeveM.position.set(0, 0, 0.02);
    arm.add(sleeveM);
    const hand = new THREE.Mesh(new THREE.BoxGeometry(0.055, 0.03, 0.07), skin);
    hand.position.set(0, -0.02, -0.08);
    arm.add(hand);
    for (let f = 0; f < 4; f++) {
      const finger = new THREE.Mesh(new THREE.BoxGeometry(0.01, 0.01, 0.03), skin);
      finger.position.set(-0.018 + f * 0.012, -0.028, -0.12);
      arm.add(finger);
    }
    arms.push(arm);
  }
  const note = new THREE.Mesh(
    new THREE.BoxGeometry(0.16, 0.022, 0.11),
    new THREE.MeshStandardMaterial({
      color: 0xf4e6b0,
      roughness: 0.78,
      emissive: 0x6a5420,
      emissiveIntensity: 0.55,
    }),
  );
  note.position.set(0.02, 0.02, -0.1);
  note.rotation.set(-1.05, 0.15, 0.35);
  note.visible = false;
  arms[0].add(note);
  g.userData.holdNote = note;
  const cuff = new THREE.Mesh(
    new THREE.TorusGeometry(0.04, 0.008, 8, 12),
    new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.82, roughness: 0.28 }),
  );
  cuff.name = 'Cuffs';
  cuff.position.set(0, -0.24, -0.34);
  cuff.rotation.y = Math.PI / 2;
  g.add(cuff);
  const chain = new THREE.Mesh(
    new THREE.CylinderGeometry(0.006, 0.006, 0.12, 6),
    new THREE.MeshStandardMaterial({ color: 0x6a7074, metalness: 0.7, roughness: 0.35 }),
  );
  chain.name = 'Cuffs';
  chain.position.set(0, -0.24, -0.34);
  chain.rotation.z = Math.PI / 2;
  g.add(chain);

  g.userData.setKazenka = () => {
    g.traverse((c) => {
      if (c.isMesh && c.material === g.userData.street) c.material = g.userData.kaz;
    });
  };
  g.userData.step = (t, mag, run, cuffed) => {
    cuff.visible = cuffed;
    chain.visible = cuffed;
    const freq = run ? 11 : 7;
    const amp = mag * (run ? 0.04 : 0.022);
    arms.forEach((arm, i) => {
      const s = i === 0 ? 1 : -1;
      const swing = Math.sin(t * freq) * amp * (cuffed ? 0.35 : 1) * s;
      arm.rotation.x = 0.12 + swing;
      arm.position.y = -0.22 + Math.abs(Math.sin(t * freq)) * mag * 0.01;
      if (cuffed) {
        arm.position.x = s * 0.09;
        arm.rotation.z = -s * 0.18;
      } else {
        arm.position.x = s * 0.16;
        arm.rotation.z = 0;
      }
    });
  };
  return g;
}

function streetMat() {
  return new THREE.MeshStandardMaterial({ color: 0x2a2e34, roughness: 0.78 });
}

function stripedMat() {
  const c = document.createElement('canvas');
  c.width = 32;
  c.height = 32;
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#6a6a68';
  ctx.fillRect(0, 0, 32, 32);
  ctx.fillStyle = '#2e2e2c';
  for (let y = 0; y < 32; y += 8) ctx.fillRect(0, y, 32, 3);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return new THREE.MeshStandardMaterial({ map: tex, roughness: 0.75 });
}
