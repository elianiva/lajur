import * as THREE from "three";
import { ball, cyl, mats, piece, pick, tarps, walls, type Shelf } from "./kit.ts";

/** Chunky toy people, about 1.6 m, facing +x. Read at a glance from the sky. */

const CLOTH = [...tarps, mats.white, mats.black, ...walls.slice(0, 4)];

function figure(seed: number, scale = 1): THREE.Group {
  const group = new THREE.Group();
  const shirt = pick(CLOTH, seed, 3);
  const trousers = pick([mats.black, tarps[0]!, mats.woodDark, mats.concrete], seed, 5);
  const skin = (seed * 7) % 1 > 0.5 ? mats.skin : mats.skinDark;
  for (const z of [-0.11, 0.11]) piece(group, [0.18, 0.75, 0.16], trousers, [0, 0.38, z]);
  piece(group, [0.3, 0.62, 0.48], shirt, [0, 1.06, 0]);
  for (const z of [-0.3, 0.3]) piece(group, [0.14, 0.55, 0.12], shirt, [0, 1.05, z]);
  ball(group, 0.2, skin, [0, 1.56, 0], 1);
  group.scale.setScalar(scale);
  return group;
}

/** A passer-by in a bright shirt. */
export function pejalan(seed: number): THREE.Group {
  const group = figure(seed);
  ball(group, 0.21, mats.hair, [-0.03, 1.62, 0], 1).scale.set(1, 0.6, 1);
  return group;
}

/** An ibu in a jilbab and a long skirt, carrying a basket. */
export function ibu(seed: number): THREE.Group {
  const group = figure(seed);
  const cloth = pick([tarps[4]!, tarps[5]!, mats.white, mats.green, walls[6]!], seed, 7);
  piece(group, [0.42, 0.8, 0.5], pick(CLOTH, seed, 11), [0, 0.4, 0]);
  ball(group, 0.24, cloth, [-0.02, 1.6, 0], 1).scale.set(1, 1.05, 1);
  cyl(group, 0.32, 0.2, 0.3, cloth, [0, 1.3, 0], 8);
  cyl(group, 0.22, 0.18, 0.25, mats.wood, [0.05, 0.85, 0.42], 8);
  return group;
}

/** A pedagang under a caping, a pikulan across the shoulders. */
export function pedagang(seed: number): THREE.Group {
  const group = figure(seed);
  const hat = new THREE.Mesh(new THREE.ConeGeometry(0.45, 0.28, 10), mats.yellow);
  hat.position.set(0, 1.78, 0);
  group.add(hat);
  piece(group, [0.06, 0.06, 2.0], mats.wood, [0, 1.4, 0]);
  for (const z of [-0.95, 0.95]) {
    cyl(group, 0.02, 0.02, 0.6, mats.wire, [0, 1.1, z], 3);
    cyl(group, 0.3, 0.24, 0.35, mats.wood, [0, 0.65, z], 8);
    ball(group, 0.18, pick([mats.red, mats.leafLight, mats.yellow], seed + z, 3), [0, 0.88, z]);
  }
  return group;
}

/** A schoolkid in the red-and-white uniform. */
export function anak(seed: number): THREE.Group {
  const group = new THREE.Group();
  const skin = seed > 0.5 ? mats.skin : mats.skinDark;
  for (const z of [-0.09, 0.09]) piece(group, [0.14, 0.5, 0.12], skin, [0, 0.25, z]);
  piece(group, [0.26, 0.3, 0.38], mats.red, [0, 0.6, 0]);
  piece(group, [0.26, 0.42, 0.38], mats.white, [0, 0.95, 0]);
  piece(group, [0.22, 0.4, 0.34], pick(tarps, seed, 9), [-0.22, 0.95, 0]);
  ball(group, 0.18, skin, [0, 1.32, 0], 1);
  ball(group, 0.19, mats.hair, [-0.03, 1.37, 0], 1).scale.set(1, 0.6, 1);
  return group;
}

export const shelf: Shelf = {
  title: "People",
  assets: [
    { name: "Pejalan", build: pejalan },
    { name: "Ibu", build: ibu },
    { name: "Pedagang", build: pedagang },
    { name: "Anak", build: anak },
  ],
};
