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
    arm.position.set(side * 0.2, -0.2, -0.34);
    g.add(arm);
    const sleeveM = new THREE.Mesh(new THREE.BoxGeometry(0.075, 0.075, 0.3), sleeve);
    sleeveM.position.z = -0.04;
    arm.add(sleeveM);
    const hand = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.045, 0.09), skin);
    hand.position.set(0, -0.04, -0.22);
    arm.add(hand);
    for (let f = 0; f < 4; f++) {
      const finger = new THREE.Mesh(new THREE.BoxGeometry(0.012, 0.012, 0.045), skin);
      finger.position.set(-0.024 + f * 0.016, -0.05, -0.28);
      arm.add(finger);
    }
    arms.push(arm);
  }
  const cuff = new THREE.Mesh(
    new THREE.TorusGeometry(0.048, 0.01, 8, 14),
    new THREE.MeshStandardMaterial({ color: 0x8a9094, metalness: 0.82, roughness: 0.28 }),
  );
  cuff.name = 'Cuffs';
  cuff.position.set(0, -0.24, -0.52);
  cuff.rotation.y = Math.PI / 2;
  g.add(cuff);
  const chain = new THREE.Mesh(
    new THREE.CylinderGeometry(0.008, 0.008, 0.16, 6),
    new THREE.MeshStandardMaterial({ color: 0x6a7074, metalness: 0.7, roughness: 0.35 }),
  );
  chain.name = 'Cuffs';
  chain.position.set(0, -0.24, -0.52);
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
    const amp = mag * (run ? 0.055 : 0.032);
    arms.forEach((arm, i) => {
      const s = i === 0 ? 1 : -1;
      const swing = Math.sin(t * freq) * amp * (cuffed ? 0.35 : 1) * s;
      arm.rotation.x = 0.28 + swing;
      arm.position.y = -0.2 + Math.abs(Math.sin(t * freq)) * mag * 0.012;
      if (cuffed) {
        arm.position.x = s * 0.1;
        arm.rotation.z = -s * 0.25;
      } else {
        arm.position.x = s * 0.2;
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
