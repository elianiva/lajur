import * as THREE from "three";
import { box, mats, piece, signs, tarps, walls, type Shelf } from "./kit.ts";

/** Buildings face +x: the street side is at x = depth / 2. */

function roadSign(
  parent: THREE.Object3D,
  material: THREE.Material,
  width: number,
  height: number,
  y: number,
) {
  const board = new THREE.Mesh(box(0.16, height, width * 0.8), material);
  board.position.set(0.3, y, 0);
  parent.add(board);
}

/** A shop-house: two floors, a sign band and an awning over the pavement. */
export function ruko(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const wall = walls[Math.floor(seed * walls.length) % walls.length]!;
  const height = 6 + seed * 3;

  const roof = seed > 0.66 ? mats.tile : seed > 0.33 ? mats.tin : mats.roof;
  piece(group, [depth, height, width], wall, [0, height / 2, 0]);
  piece(group, [depth + 0.3, 0.3, width + 0.3], roof, [0, height + 0.15, 0]);
  roadSign(group, signs[Math.floor(seed * 97) % signs.length]!, width, 1.1, 3.6);
  piece(group, [1.3, 0.14, width * 0.8], mats.metal, [depth / 2 + 0.6, 3.0, 0]);

  const front = depth / 2 + 0.02;
  piece(group, [0.1, 2.6, width * 0.7], mats.glass, [front, 1.4, 0]);
  piece(group, [0.1, 0.09, width], mats.roof, [front + 0.05, 2.9, 0]);
  for (let floor = 0; floor < 2; floor += 1) {
    const y = 4.3 + floor * 1.9;
    if (y > height - 1) break;
    piece(group, [0.1, 1.1, width * 0.42], mats.glass, [front, y, -width * 0.2]);
    piece(group, [0.1, 1.1, width * 0.42], mats.glass, [-front, y, -width * 0.2]);
  }
  if (seed > 0.5) {
    piece(group, [0.5, 0.5, 0.5], mats.metal, [0, height + 0.6, width * 0.25]);
  }
  return group;
}

/** A warung: tarpaulin roof, counter, crates, and a banner. */
export function warung(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 3.4;

  piece(group, [2.4, 0.9, width * 0.8], mats.wood, [0, 0.45, 0]);
  piece(group, [2.8, 0.08, width], mats.wood, [0.1, 1.15, 0]);
  for (const z of [-width / 2, width / 2]) {
    piece(group, [0.1, 2.3, 0.1], mats.wood, [1.1, 1.15, z]);
  }
  const tarp = new THREE.Mesh(
    box(2.6, 0.1, width + 0.6),
    tarps[Math.floor(seed * 53) % tarps.length]!,
  );
  tarp.position.set(0.2, 2.45, 0);
  tarp.rotation.z = 0.12;
  group.add(tarp);

  piece(group, [0.9, 0.5, 0.9], mats.rust, [-1.2, 0.25, width * 0.32]);
  piece(group, [0.5, 0.35, 0.5], mats.rust, [-1.1, 0.85, width * 0.32]);
  for (let i = 0; i < 2; i += 1) {
    piece(group, [0.4, 0.32, 0.4], mats.metal, [-0.9 + i * 0.5, 0.16, -width * 0.3]);
  }
  return group;
}

/** A house behind the row: low, corrugated, with a porch. */
export function house(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const wall = walls[Math.floor(seed * 71) % walls.length]!;
  const height = 3.2 + seed * 1.4;

  piece(group, [depth, height, width], wall, [0, height / 2, 0]);
  const cover = seed > 0.6 ? mats.tile : seed > 0.25 ? mats.tin : mats.roof;
  const roof = new THREE.Mesh(box(depth + 0.8, 0.16, width + 0.8), cover);
  roof.position.set(0, height + 0.12, 0);
  group.add(roof);
  piece(group, [0.4, 0.5, width + 0.8], cover, [depth / 2 + 0.2, height + 0.3, 0]);
  piece(group, [0.1, 1.4, width * 0.3], mats.glass, [depth / 2 + 0.03, 1.1, 0]);
  return group;
}

export const shelf: Shelf = {
  title: "Buildings",
  assets: [
    { name: "Ruko", build: (seed) => ruko(seed, 4.5 + seed * 2.5, 7 + seed * 4) },
    { name: "Warung", build: (seed) => warung(seed) },
    { name: "House", build: (seed) => house(seed, 6 + seed * 6, 7 + seed * 4) },
  ],
};
