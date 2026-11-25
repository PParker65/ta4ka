import * as THREE from 'three';

/** First-person cuffed / kazenka hands parented to the camera. */
export function makeHands() {
  const g = new THREE.Group();
  g.name = 'FPHands';
  const skin = new THREE.MeshStandardMaterial({
    color: 0xd4b08a,
    roughness: 0.55,
    emissive: 0x5a3018,
    emissiveIntensity: 0.28,
  });
  const sleeve = streetMat();
  g.userData.street = sleeve;
  g.userData.kaz = stripedMat();
  const arms = [];
  for (const side of [-1, 1]) {
    const arm = new THREE.Group();
    arm.position.set(side * 0.22, -0.1, -0.22);
    g.add(arm);
    const sleeveM = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.06, 0.16), sleeve);
    sleeveM.position.set(0, 0.01, 0.04);
    arm.add(sleeveM);
    const wrist = new THREE.Mesh(new THREE.CylinderGeometry(0.022, 0.026, 0.05, 8), skin);
    wrist.rotation.x = Math.PI / 2;
    wrist.position.set(0, -0.01, -0.06);
    arm.add(wrist);
    const hand = new THREE.Mesh(new THREE.BoxGeometry(0.068, 0.034, 0.085), skin);
    hand.position.set(0, -0.02, -0.1);
    arm.add(hand);
    const thumb = new THREE.Mesh(new THREE.BoxGeometry(0.016, 0.016, 0.04), skin);
    thumb.position.set(side * 0.04, -0.01, -0.1);
    thumb.rotation.y = side * 0.55;
    arm.add(thumb);
    for (let f = 0; f < 4; f++) {
      const finger = new THREE.Mesh(new THREE.BoxGeometry(0.013, 0.012, 0.042), skin);
      finger.position.set(-0.024 + f * 0.016, -0.03, -0.15);
      finger.rotation.x = 0.18;
      arm.add(finger);
    }
    arms.push(arm);
  }
  const note = new THREE.Mesh(
    new THREE.BoxGeometry(0.052, 0.005, 0.034),
    new THREE.MeshStandardMaterial({
      color: 0xe8d9b0,
      roughness: 0.82,
      emissive: 0x4a3a12,
      emissiveIntensity: 0.18,
    }),
  );
  note.position.set(0.012, 0.018, -0.072);
  note.rotation.set(-0.85, 0.18, 0.28);
  const fold = new THREE.Mesh(
    new THREE.BoxGeometry(0.024, 0.004, 0.03),
    new THREE.MeshBasicMaterial({ color: 0xc8b890 }),
  );
  fold.position.set(0.012, 0.003, 0);
  note.add(fold);
  const ink = new THREE.MeshBasicMaterial({ color: 0x2a2418 });
  for (const [ix, iz, iw] of [
    [-0.006, 0.008, 0.028],
    [-0.004, 0.001, 0.022],
    [0.002, -0.007, 0.016],
  ]) {
    const line = new THREE.Mesh(new THREE.BoxGeometry(iw, 0.0015, 0.002), ink);
    line.position.set(ix, 0.003, iz);
    note.add(line);
  }
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
      const s = i === 0 ? -1 : 1;
      const swing = Math.sin(t * freq) * amp * (cuffed ? 0.35 : 1) * s;
      arm.rotation.x = 0.18 + swing;
      arm.position.y = -0.1 + Math.abs(Math.sin(t * freq)) * mag * 0.01;
      if (cuffed) {
        arm.position.x = s * 0.12;
        arm.rotation.z = -s * 0.18;
      } else {
        arm.position.x = s * 0.22;
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
  ctx.fillStyle = '#c8c8be';
  ctx.fillRect(0, 0, 32, 32);
  ctx.fillStyle = '#2c2c28';
  for (let y = 0; y < 32; y += 8) ctx.fillRect(0, y, 32, 4);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return new THREE.MeshStandardMaterial({ map: tex, roughness: 0.75 });
}
