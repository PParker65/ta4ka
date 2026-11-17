import * as THREE from 'three';

export class Guards {
  constructor(scene, prison) {
    this.scene = scene;
    this.prison = prison;
    this.list = [];
    this.spotLights = [];
  }

  spawn() {
    this.list.push(
      this.makeGuard(
        [
          new THREE.Vector3(0, 0, 6.2),
          new THREE.Vector3(0, 0, 12),
          new THREE.Vector3(0, 0, 18),
          new THREE.Vector3(0, 0, 12),
        ],
        1.15,
      ),
      this.makeGuard(
        [
          new THREE.Vector3(0, 0, 26),
          new THREE.Vector3(0, 0, 34),
          new THREE.Vector3(0.4, 0, 30),
        ],
        0.95,
      ),
    );
  }

  makeGuard(waypoints, speed) {
    const root = new THREE.Group();
    const coat = new THREE.MeshStandardMaterial({ color: 0x1a1c1e, roughness: 0.7 });
    const skin = new THREE.MeshStandardMaterial({ color: 0xb08a68, roughness: 0.75 });
    const body = new THREE.Mesh(new THREE.BoxGeometry(0.42, 0.7, 0.28), coat);
    body.position.y = 1.15;
    body.castShadow = true;
    root.add(body);
    const legs = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.7, 0.22), coat);
    legs.position.y = 0.42;
    root.add(legs);
    const head = new THREE.Mesh(new THREE.SphereGeometry(0.13, 10, 8), skin);
    head.position.y = 1.62;
    root.add(head);
    const cap = new THREE.Mesh(
      new THREE.CylinderGeometry(0.14, 0.15, 0.1, 10),
      new THREE.MeshStandardMaterial({ color: 0x111214 }),
    );
    cap.position.y = 1.74;
    root.add(cap);
    const brim = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 0.02, 0.16),
      new THREE.MeshStandardMaterial({ color: 0x111214 }),
    );
    brim.position.set(0, 1.7, 0.1);
    root.add(brim);

    const torch = new THREE.Group();
    torch.position.set(0.18, 1.28, 0.12);
    const handle = new THREE.Mesh(
      new THREE.CylinderGeometry(0.03, 0.03, 0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0x2a2a2c, metalness: 0.5 }),
    );
    handle.rotation.x = Math.PI / 2;
    torch.add(handle);
    const cone = new THREE.Mesh(
      new THREE.ConeGeometry(0.55, 2.4, 16, 1, true),
      new THREE.MeshBasicMaterial({
        color: 0xfff2c4,
        transparent: true,
        opacity: 0.2,
        depthWrite: false,
        side: THREE.DoubleSide,
      }),
    );
    cone.rotation.x = Math.PI / 2;
    cone.position.z = 1.25;
    torch.add(cone);
    root.add(torch);

    const light = new THREE.SpotLight(0xfff1c2, 2.2, 11, 0.38, 0.45, 1.1);
    light.position.set(0.18, 1.28, 0.2);
    light.target.position.set(0.18, 0.9, 3.2);
    root.add(light);
    root.add(light.target);
    this.spotLights.push(light);

    root.position.copy(waypoints[0]);
    this.scene.add(root);

    return {
      root,
      torch,
      light,
      waypoints,
      index: 0,
      speed,
      wait: 0,
      facing: new THREE.Vector3(0, 0, 1),
      range: 10.5,
      angle: 0.48,
    };
  }

  update(dt) {
    for (const g of this.list) {
      if (g.wait > 0) {
        g.wait -= dt;
        g.root.rotation.y += dt * 0.4;
        this.syncFacing(g);
        continue;
      }
      const target = g.waypoints[g.index];
      const pos = g.root.position;
      const dx = target.x - pos.x;
      const dz = target.z - pos.z;
      const dist = Math.hypot(dx, dz);
      if (dist < 0.12) {
        g.index = (g.index + 1) % g.waypoints.length;
        g.wait = 1.1;
        continue;
      }
      const step = Math.min(g.speed * dt, dist);
      pos.x += (dx / dist) * step;
      pos.z += (dz / dist) * step;
      g.root.rotation.y = Math.atan2(dx, dz);
      this.syncFacing(g);
      const t = performance.now() * 0.004;
      g.root.children[1].rotation.x = Math.sin(t * g.speed * 4) * 0.15;
    }
  }

  syncFacing(g) {
    g.facing.set(Math.sin(g.root.rotation.y), 0, Math.cos(g.root.rotation.y));
  }

  sees(playerPos, crouching) {
    for (const g of this.list) {
      const origin = g.root.position.clone();
      origin.y = 1.35;
      const to = playerPos.clone();
      to.y = crouching ? 0.7 : 1.2;
      const delta = to.sub(origin);
      const dist = delta.length();
      const range = crouching ? g.range * 0.58 : g.range;
      if (dist > range) continue;
      delta.normalize();
      const ang = crouching ? g.angle * 0.85 : g.angle;
      if (delta.dot(g.facing) > Math.cos(ang)) return g;
    }
    return null;
  }

  setAlarm(on) {
    for (const g of this.list) {
      g.light.color.set(on ? 0xff2222 : 0xfff1c2);
      g.light.intensity = on ? 3.4 : 2.2;
      g.speed = on ? 2.1 : 1.0;
    }
  }
}
