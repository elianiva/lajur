import * as THREE from "three";
import { ball, board, cyl, mats, piece, pick, span, tarps, wheel, type Shelf } from "./kit.ts";

/** Street furniture: what parks on, stands on, or hangs over the pavement. */

export function motorbike(seed: number): THREE.Group {
  const group = new THREE.Group();
  const paint = pick([...tarps, mats.black, mats.white, mats.red], seed, 31);
  piece(group, [0.3, 0.34, 1.1], paint, [0, 0.62, 0]);
  piece(group, [0.32, 0.18, 0.6], mats.black, [0, 0.86, 0.15]);
  piece(group, [0.34, 0.55, 0.22], paint, [0, 0.85, -0.42]);
  piece(group, [0.66, 0.06, 0.06], mats.metal, [0, 1.15, -0.48]);
  piece(group, [0.16, 0.12, 0.06], mats.lamp, [0, 1.0, -0.55]);
  for (const z of [-0.55, 0.55]) {
    const rim = wheel(0.27, 0.12, mats.rubber);
    rim.position.set(0, 0.27, z);
    group.add(rim);
  }
  return group;
}

/** A pushcart: wooden box, one wheel, a parasol. */
export function cart(seed: number): THREE.Group {
  const group = new THREE.Group();
  piece(group, [1.2, 0.7, 1.8], mats.wood, [0, 0.75, 0]);
  piece(group, [1.3, 0.1, 1.9], mats.woodDark, [0, 1.15, 0]);
  const rim = wheel(0.4, 0.12, mats.rubber);
  rim.position.set(0.55, 0.4, 0);
  group.add(rim);
  cyl(group, 0.04, 0.04, 2.4, mats.metal, [0, 1.9, 0.6], 4);
  const shade = new THREE.Mesh(new THREE.ConeGeometry(1.3, 0.7, 8), pick(tarps, seed, 17));
  shade.position.set(0, 3.1, 0.6);
  group.add(shade);
  return group;
}

/** A gerobak bakso: glass case on wheels, a pot steaming, the name painted on. */
export function gerobak(seed: number): THREE.Group {
  const group = new THREE.Group();
  const words = ["BAKSO", "SIOMAY", "ES DAWET", "NASGOR", "SATE", "CILOK"];
  piece(group, [1.0, 0.8, 1.9], mats.white, [0, 0.9, 0]);
  piece(
    group,
    [0.04, 0.6, 1.9],
    board(pick(words, seed, 5), pick(["#e8382f", "#2f7fe0", "#23a35a"], seed)),
    [0.52, 0.95, 0],
  );
  piece(group, [0.9, 0.6, 1.2], mats.mirror, [0, 1.6, -0.3]);
  piece(group, [1.05, 0.08, 2.0], pick(tarps, seed, 9), [0, 2.4, 0]);
  for (const z of [-0.9, 0.9]) piece(group, [0.06, 0.9, 0.06], mats.metal, [0.45, 1.95, z]);
  cyl(group, 0.3, 0.3, 0.5, mats.steel, [0, 1.55, 0.6], 8);
  for (const z of [-0.6, 0.6]) {
    const rim = wheel(0.35, 0.1, mats.rubber);
    rim.position.set(-0.55, 0.35, z);
    rim.rotation.y = Math.PI / 2;
    group.add(rim);
  }
  return group;
}

/** A tenda: the evening food tent, its banner painted with dishes. */
export function tenda(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 5;
  const words = ["PECEL LELE", "SEAFOOD", "NASI UDUK", "LALAPAN", "AYAM BAKAR"];
  for (const x of [-1.5, 1.5])
    for (const z of [-width / 2, width / 2])
      piece(group, [0.08, 2.4, 0.08], mats.metal, [x, 1.2, z]);
  piece(group, [3.4, 0.1, width + 0.2], pick(tarps, seed, 2), [0, 2.45, 0]);
  piece(
    group,
    [0.06, 1.2, width],
    board(pick(words, seed, 3), "#fffdf2", "#e8382f"),
    [1.55, 1.8, 0],
  );
  piece(group, [1.0, 0.75, width * 0.7], mats.wood, [-0.2, 0.38, 0]);
  for (let k = 0; k < 4; k += 1) piece(group, [0.4, 0.45, 0.4], mats.red, [0.8, 0.22, -1.5 + k]);
  return group;
}

/** A beach umbrella over a plastic table: the pinggir jalan stall. */
export function payung(seed: number): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.05, 0.05, 2.4, mats.white, [0, 1.2, 0], 4);
  const top = new THREE.Mesh(new THREE.ConeGeometry(1.6, 0.6, 8), pick(tarps, seed, 7));
  top.position.y = 2.5;
  group.add(top);
  piece(group, [0.9, 0.7, 0.9], mats.white, [0.4, 0.35, 0]);
  for (let k = 0; k < 3; k += 1)
    piece(group, [0.35, 0.4, 0.35], pick(tarps, seed + k * 0.2, 5), [-0.6 + k * 0.4, 0.2, 0.9]);
  return group;
}

export function powerPole(): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.12, 0.16, 7.5, mats.concrete, [0, 3.75, 0], 6);
  piece(group, [0.1, 0.1, 1.6], mats.metal, [0, 6.9, 0]);
  piece(group, [0.1, 0.1, 1.1], mats.metal, [0, 7.3, 0]);
  cyl(group, 0.25, 0.25, 0.6, mats.steel, [0.25, 6.3, 0], 6);
  return group;
}

/** A street lamp: a curved arm over the road. */
export function lampu(): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.08, 0.12, 8, mats.steel, [0, 4, 0], 6);
  piece(group, [2.2, 0.1, 0.1], mats.steel, [1.1, 8, 0]);
  piece(group, [0.7, 0.18, 0.35], mats.steel, [2.1, 7.9, 0]);
  piece(group, [0.6, 0.06, 0.3], mats.lamp, [2.1, 7.8, 0]);
  return group;
}

/** A traffic light on an arm, the three lamps facing +x. */
export function lampuMerah(seed: number): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.1, 0.12, 5.5, mats.black, [0, 2.75, 0], 6);
  piece(group, [0.1, 0.1, 3], mats.black, [0, 5.4, -1.5]);
  piece(group, [0.4, 1.2, 0.45], mats.black, [0, 4.8, -2.8]);
  const lit = Math.floor(seed * 3);
  [mats.red, mats.yellow, mats.green].forEach((lamp, k) => {
    ball(group, 0.15, k === lit ? mats.lamp : lamp, [0.22, 5.2 - k * 0.38, -2.8]);
  });
  piece(group, [0.3, 0.9, 0.35], mats.black, [0, 2.4, 0.2]);
  return group;
}

/** A halte: a bus shelter with a bench and a route board. */
export function halte(seed: number): THREE.Group {
  const group = new THREE.Group();
  for (const z of [-2.2, 2.2]) piece(group, [0.12, 2.7, 0.12], mats.steel, [-0.6, 1.35, z]);
  piece(group, [1.8, 0.12, 5.2], seed > 0.5 ? tarps[0]! : mats.red, [0, 2.75, 0]);
  piece(group, [0.08, 1.8, 4.4], mats.mirror, [-0.7, 1.4, 0]);
  piece(group, [0.5, 0.1, 3.6], mats.steel, [-0.3, 0.5, 0]);
  piece(group, [0.08, 0.5, 2.4], board("HALTE", "#2f7fe0"), [0.5, 2.5, 0]);
  return group;
}

/** A baliho: the big roadside billboard on a steel post. */
export function baliho(seed: number): THREE.Group {
  const group = new THREE.Group();
  const words = [
    "KOPI SUSU",
    "PILIH NOMOR 2",
    "SIMPATI",
    "PROMO GAJIAN",
    "MIE PEDAS",
    "KREDIT MOTOR",
  ];
  cyl(group, 0.3, 0.3, 9, mats.steel, [0, 4.5, 0], 6);
  piece(group, [0.3, 4, 9], mats.steel, [0, 10.5, 0]);
  piece(
    group,
    [0.1, 3.6, 8.6],
    board(pick(words, seed, 4), pick(["#ff7a2f", "#d2489a", "#2f7fe0", "#23a35a"], seed, 2)),
    [0.18, 10.5, 0],
  );
  piece(group, [0.8, 0.1, 9], mats.steel, [0.4, 8.4, 0]);
  return group;
}

/** Umbul-umbul: tall bamboo poles with long curved banners. */
export function umbul(seed: number): THREE.Group {
  const group = new THREE.Group();
  for (let k = 0; k < 3; k += 1) {
    const z = (k - 1) * 1.6;
    const pole = cyl(group, 0.05, 0.08, 9, mats.wood, [0, 4.5, z], 4);
    pole.rotation.x = (k - 1) * 0.04;
    const banner = pick(tarps, seed + k * 0.17, 3);
    for (let s = 0; s < 6; s += 1) {
      piece(group, [0.04, 1, 0.5], s % 2 ? banner : mats.white, [0.3 + s * 0.04, 8.2 - s, z + 0.3]);
    }
  }
  return group;
}

/** Merah-putih bunting between two posts: Agustusan all year. */
export function bunting(length = 8): THREE.Group {
  const group = new THREE.Group();
  for (const z of [-length / 2, length / 2]) cyl(group, 0.05, 0.05, 4, mats.white, [0, 2, z], 4);
  addBunting(group, new THREE.Vector3(0, 3.8, -length / 2), new THREE.Vector3(0, 3.8, length / 2));
  return group;
}

/** Hang a string of red and white pennants from `from` to `to`, sagging. */
export function addBunting(parent: THREE.Object3D, from: THREE.Vector3, to: THREE.Vector3) {
  const count = Math.max(2, Math.floor(from.distanceTo(to) / 0.7));
  let previous = from.clone();
  for (let k = 1; k <= count; k += 1) {
    const t = k / count;
    const at = from.clone().lerp(to, t);
    at.y -= Math.sin(t * Math.PI) * 0.6;
    span(parent, previous, at, 0.03, mats.wire);
    const pennant = new THREE.Mesh(PENNANT, k % 2 ? mats.red : mats.white);
    pennant.position.copy(at);
    pennant.lookAt(at.clone().add(to.clone().sub(from).normalize()));
    parent.add(pennant);
    previous = at;
  }
}

const PENNANT = (() => {
  const geometry = new THREE.ConeGeometry(0.2, 0.45, 3);
  geometry.rotateX(Math.PI);
  geometry.translate(0, -0.25, 0);
  geometry.scale(1, 1, 0.2);
  return geometry;
})();

/** A tong: the blue water drum and a green bin. */
export function tong(seed: number): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.35, 0.35, 0.9, seed > 0.5 ? tarps[0]! : mats.green, [0, 0.45, 0], 10);
  cyl(group, 0.37, 0.37, 0.08, mats.black, [0, 0.92, 0], 10);
  piece(group, [0.5, 0.7, 0.5], mats.yellow, [0, 0.35, 0.8]);
  return group;
}

/** Pots of plants by a door: the kampung's front garden. */
export function pot(seed: number): THREE.Group {
  const group = new THREE.Group();
  for (let k = 0; k < 3; k += 1) {
    const size = 0.2 + ((seed * 7 + k * 0.3) % 1) * 0.2;
    cyl(
      group,
      size,
      size * 0.7,
      size * 1.6,
      k % 2 ? mats.rust : mats.white,
      [0, size * 0.8, k * 0.6],
      6,
    );
    ball(group, size * 1.4, k % 2 ? mats.leaf : mats.leafLight, [0, size * 2.2, k * 0.6]);
    if ((seed * 13 + k) % 2 > 1) ball(group, size * 0.5, mats.red, [0.1, size * 3, k * 0.6]);
  }
  return group;
}

/** A road sign on a post: no parking, no stopping, or a speed limit. */
export function rambu(seed: number): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 0.05, 0.05, 2.6, mats.steel, [0, 1.3, 0], 4);
  const face = cyl(group, 0.4, 0.4, 0.06, seed > 0.5 ? mats.red : tarps[0]!, [0.04, 2.6, 0], 12);
  face.rotation.z = Math.PI / 2;
  piece(group, [0.08, 0.1, 0.6], mats.white, [0.08, 2.6, 0]);
  return group;
}

export const shelf: Shelf = {
  title: "Street",
  assets: [
    { name: "Motor", build: motorbike },
    { name: "Gerobak", build: gerobak },
    { name: "Cart", build: cart },
    { name: "Tenda", build: tenda },
    { name: "Payung", build: payung },
    { name: "Halte", build: halte },
    { name: "Baliho", build: baliho },
    { name: "Umbul-umbul", build: umbul },
    { name: "Bendera", build: () => bunting() },
    { name: "Power pole", build: powerPole },
    { name: "Lampu", build: lampu },
    { name: "Lampu merah", build: lampuMerah },
    { name: "Rambu", build: rambu },
    { name: "Tong", build: tong },
    { name: "Pot", build: pot },
  ],
};
