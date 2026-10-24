import * as THREE from "three";
import { mats, piece, tarps, wheel, type Shelf } from "./kit.ts";

/** Street furniture: what parks on, stands on, or hangs over the pavement. */

export function motorbike(seed: number): THREE.Group {
  const group = new THREE.Group();
  const paint = tarps[Math.floor(seed * 31) % tarps.length]!;
  piece(group, [0.28, 0.32, 1.1], paint, [0, 0.62, 0]);
  piece(group, [0.3, 0.5, 0.5], paint, [0, 0.95, 0.28]);
  piece(group, [0.62, 0.06, 0.06], mats.metal, [0, 1.08, -0.45]);
  for (const z of [-0.55, 0.55]) {
    const rim = wheel(0.27, 0.1, mats.wire);
    rim.position.set(0, 0.27, z);
    group.add(rim);
  }
  return group;
}

export function cart(seed: number): THREE.Group {
  const group = new THREE.Group();
  piece(group, [1.2, 0.7, 1.8], mats.wood, [0, 0.75, 0]);
  piece(group, [1.3, 0.1, 1.9], mats.wood, [0, 1.15, 0]);
  const rim = wheel(0.4, 0.12, mats.wire);
  rim.position.set(0.55, 0.4, 0);
  group.add(rim);
  const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 2.4, 4), mats.metal);
  pole.position.set(0, 1.9, 0.6);
  group.add(pole);
  const shade = new THREE.Mesh(
    new THREE.ConeGeometry(1.3, 0.7, 6),
    tarps[Math.floor(seed * 17) % tarps.length]!,
  );
  shade.position.set(0, 3.1, 0.6);
  group.add(shade);
  return group;
}

export function powerPole(): THREE.Group {
  const group = new THREE.Group();
  const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.16, 7.5, 6), mats.concrete);
  pole.position.y = 3.75;
  group.add(pole);
  piece(group, [0.1, 0.1, 1.6], mats.metal, [0, 6.9, 0]);
  piece(group, [0.1, 0.1, 1.1], mats.metal, [0, 7.3, 0]);
  return group;
}

export const shelf: Shelf = {
  title: "Street",
  assets: [
    { name: "Motorbike", build: motorbike },
    { name: "Cart", build: cart },
    { name: "Power pole", build: powerPole },
  ],
};
