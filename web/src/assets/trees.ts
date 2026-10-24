import * as THREE from "three";
import { box, mats, type Shelf } from "./kit.ts";

export function palm(seed: number): THREE.Group {
  const group = new THREE.Group();
  const height = 3.6 + seed * 2.2;
  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.24, height, 5), mats.trunk);
  trunk.position.y = height / 2;
  group.add(trunk);
  for (let leaf = 0; leaf < 5; leaf += 1) {
    const frond = new THREE.Mesh(box(0.16, 0.1, 1.9), mats.leaf);
    frond.position.set(0, height, 0);
    frond.rotation.y = (leaf / 5) * Math.PI * 2;
    frond.rotation.x = -0.5;
    frond.translateZ(0.9);
    group.add(frond);
  }
  return group;
}

export function banana(seed: number): THREE.Group {
  const group = new THREE.Group();
  const height = 1.8 + seed;
  const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.16, height, 5), mats.trunk);
  trunk.position.y = height / 2;
  group.add(trunk);
  for (let leaf = 0; leaf < 4; leaf += 1) {
    const frond = new THREE.Mesh(box(0.5, 0.06, 1.5), leaf % 2 ? mats.leaf : mats.leafDeep);
    frond.position.set(0, height, 0);
    frond.rotation.y = (leaf / 4) * Math.PI * 2 + 0.4;
    frond.rotation.x = -0.35;
    frond.translateZ(0.7);
    group.add(frond);
  }
  return group;
}

export const shelf: Shelf = {
  title: "Trees",
  assets: [
    { name: "Palm", build: palm },
    { name: "Banana", build: banana },
  ],
};
