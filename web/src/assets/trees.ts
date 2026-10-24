import * as THREE from "three";
import { ball, box, cyl, mats, piece, tarps, type Shelf } from "./kit.ts";

/** Coconut palm: a leaning trunk, drooping fronds, a cluster of nuts. */
export function palm(seed: number): THREE.Group {
  const group = new THREE.Group();
  const height = 4.5 + seed * 3;
  const lean = (seed - 0.5) * 0.25;
  const trunk = cyl(group, 0.16, 0.26, height, mats.trunk, [0, height / 2, 0], 6);
  trunk.rotation.z = lean;
  const top = new THREE.Vector3(-Math.sin(lean) * height, height, 0);
  for (let leaf = 0; leaf < 7; leaf += 1) {
    const frond = new THREE.Mesh(box(0.5, 0.08, 2.4), leaf % 2 ? mats.leaf : mats.leafDeep);
    frond.position.copy(top);
    frond.rotation.y = (leaf / 7) * Math.PI * 2 + seed;
    frond.rotation.x = -0.45;
    frond.translateZ(1.1);
    group.add(frond);
  }
  for (let k = 0; k < 3; k += 1)
    ball(group, 0.18, mats.green, [top.x + (k - 1) * 0.25, height - 0.25, 0.15]);
  return group;
}

export function banana(seed: number): THREE.Group {
  const group = new THREE.Group();
  const height = 1.8 + seed;
  cyl(group, 0.12, 0.18, height, mats.leafDeep, [0, height / 2, 0], 6);
  for (let leaf = 0; leaf < 5; leaf += 1) {
    const frond = new THREE.Mesh(box(0.6, 0.06, 1.6), leaf % 2 ? mats.leafLight : mats.leaf);
    frond.position.set(0, height, 0);
    frond.rotation.y = (leaf / 5) * Math.PI * 2 + 0.4;
    frond.rotation.x = -0.3;
    frond.translateZ(0.75);
    group.add(frond);
  }
  return group;
}

/** A canopy of lumpy balls on a trunk: the shape most street trees share. */
function crown(
  group: THREE.Group,
  seed: number,
  height: number,
  spread: number,
  lumps: number,
  materials: THREE.Material[],
) {
  for (let k = 0; k < lumps; k += 1) {
    const angle = (k / lumps) * Math.PI * 2 + seed * 3;
    const out = k === 0 ? 0 : spread * (0.45 + ((seed * 31 + k * 0.37) % 1) * 0.3);
    const size = spread * (k === 0 ? 0.75 : 0.5 + ((seed * 17 + k * 0.21) % 1) * 0.15);
    ball(group, size, materials[k % materials.length]!, [
      Math.cos(angle) * out,
      height + (k === 0 ? spread * 0.25 : ((k * 0.7) % 1) * spread * 0.35),
      Math.sin(angle) * out,
    ]);
  }
}

/** Mangga: the mango in every front yard, dense and dark. */
export function mangga(seed: number): THREE.Group {
  const group = new THREE.Group();
  const height = 2.6 + seed * 1.2;
  cyl(group, 0.2, 0.3, height, mats.trunk, [0, height / 2, 0], 6);
  crown(group, seed, height + 0.6, 2.2 + seed * 0.8, 6, [mats.leafDeep, mats.leaf]);
  return group;
}

/** Beringin: the banyan of the alun-alun, wide and heavy, roots hanging. */
export function beringin(seed: number): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.7, 1.1, 4, mats.trunk, [0, 2, 0], 8);
  for (let k = 0; k < 10; k += 1) {
    const angle = (k / 10) * Math.PI * 2 + seed;
    const reach = 2.5 + (k % 3);
    cyl(
      group,
      0.06,
      0.06,
      4.5,
      mats.trunk,
      [Math.cos(angle) * reach, 2.6, Math.sin(angle) * reach],
      4,
    );
  }
  crown(group, seed, 6, 5.5, 9, [mats.leafDeep, mats.leaf, mats.leafDeep]);
  return group;
}

/** Kamboja: frangipani, a crooked crown dotted with white and pink flowers. */
export function kamboja(seed: number): THREE.Group {
  const group = new THREE.Group();
  const bloom = seed > 0.5 ? mats.white : tarps[4]!;
  cyl(group, 0.15, 0.22, 2.2, mats.trunk, [0, 1.1, 0], 6);
  for (let k = 0; k < 4; k += 1) {
    const angle = (k / 4) * Math.PI * 2 + seed * 2;
    const branch = cyl(
      group,
      0.08,
      0.1,
      1.6,
      mats.trunk,
      [Math.cos(angle) * 0.5, 2.6, Math.sin(angle) * 0.5],
      5,
    );
    branch.rotation.set(Math.sin(angle) * 0.6, 0, -Math.cos(angle) * 0.6);
    const tip: [number, number, number] = [Math.cos(angle) * 1.0, 3.3, Math.sin(angle) * 1.0];
    ball(group, 0.6, mats.leaf, tip);
    for (let f = 0; f < 3; f += 1) {
      ball(group, 0.18, bloom, [
        tip[0] + (f - 1) * 0.3,
        tip[1] + 0.5,
        tip[2] + ((f * 0.37) % 0.4) - 0.2,
      ]);
    }
  }
  return group;
}

/** Bambu: a clump of tall culms, leaning out, leaves at the tips. */
export function bambu(seed: number): THREE.Group {
  const group = new THREE.Group();
  for (let k = 0; k < 9; k += 1) {
    const angle = k * 2.4 + seed * 5;
    const height = 6 + ((seed * 13 + k * 0.31) % 1) * 4;
    const culm = cyl(
      group,
      0.07,
      0.09,
      height,
      k % 3 ? mats.leafDeep : mats.yellow,
      [Math.cos(angle) * 0.5, height / 2, Math.sin(angle) * 0.5],
      5,
    );
    const tilt = 0.12 + (k % 3) * 0.06;
    culm.rotation.set(Math.sin(angle) * tilt, 0, -Math.cos(angle) * tilt);
    ball(group, 0.9, mats.leafLight, [
      Math.cos(angle) * (0.5 + height * tilt),
      height - 0.6,
      Math.sin(angle) * (0.5 + height * tilt),
    ]).scale.set(1, 0.5, 1);
  }
  return group;
}

/** Pepaya: a bare trunk, an umbrella of leaves, fruit under them. */
export function pepaya(seed: number): THREE.Group {
  const group = new THREE.Group();
  const height = 3 + seed * 1.5;
  cyl(group, 0.1, 0.16, height, mats.concrete, [0, height / 2, 0], 6);
  for (let leaf = 0; leaf < 6; leaf += 1) {
    const frond = new THREE.Mesh(box(0.9, 0.05, 0.9), mats.leafLight);
    frond.position.set(0, height, 0);
    frond.rotation.y = (leaf / 6) * Math.PI * 2;
    frond.rotation.x = -0.3;
    frond.translateZ(0.75);
    group.add(frond);
  }
  for (let k = 0; k < 4; k += 1) {
    const angle = k * 1.6;
    ball(group, 0.16, k % 2 ? mats.yellow : mats.green, [
      Math.cos(angle) * 0.2,
      height - 0.4,
      Math.sin(angle) * 0.2,
    ]).scale.set(1, 1.5, 1);
  }
  return group;
}

const flame = new THREE.MeshStandardMaterial({
  color: 0xff5a36,
  roughness: 0.95,
  flatShading: true,
});
flame.name = "leaf";

/** Flamboyan: the flame tree, a flat wide crown of red. */
export function flamboyan(seed: number): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.2, 0.32, 3.4, mats.trunk, [0, 1.7, 0], 6);
  for (let k = 0; k < 7; k += 1) {
    const angle = (k / 7) * Math.PI * 2 + seed;
    const out = k === 0 ? 0 : 2.4;
    ball(group, 1.7, k % 3 === 2 ? mats.leaf : flame, [
      Math.cos(angle) * out,
      4.2 + (k % 2) * 0.3,
      Math.sin(angle) * out,
    ]).scale.set(1, 0.55, 1);
  }
  return group;
}

/** Semak: a hedge of bougainvillea or pucuk merah, trimmed square. */
export function semak(seed: number, length = 3): THREE.Group {
  const group = new THREE.Group();
  const flowering = seed > 0.5;
  piece(group, [0.9, 0.9, length], mats.leafDeep, [0, 0.45, 0]);
  for (let k = 0; k < length * 2; k += 1) {
    ball(
      group,
      0.32,
      flowering ? (k % 2 ? tarps[4]! : mats.leaf) : k % 2 ? mats.red : mats.leafLight,
      [0.1, 0.9, -length / 2 + 0.25 + k * 0.5],
    );
  }
  return group;
}

export const shelf: Shelf = {
  title: "Trees",
  assets: [
    { name: "Kelapa", build: palm },
    { name: "Pisang", build: banana },
    { name: "Mangga", build: mangga },
    { name: "Beringin", build: beringin },
    { name: "Kamboja", build: kamboja },
    { name: "Bambu", build: bambu },
    { name: "Pepaya", build: pepaya },
    { name: "Flamboyan", build: flamboyan },
    { name: "Semak", build: (seed) => semak(seed) },
  ],
};
