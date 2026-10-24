import * as THREE from "three";
import {
  ball,
  board,
  cyl,
  dome,
  mats,
  piece,
  pick,
  roof,
  span,
  tarps,
  walls,
  type Shelf,
} from "./kit.ts";

/** Landmarks: the buildings a kota is navigated by. Each faces +x like the rest. */

/** A red-and-white flag on a pole. */
export function flag(parent: THREE.Object3D, at: [number, number, number], height = 8) {
  const [x, y, z] = at;
  cyl(parent, 0.08, 0.1, height, mats.white, [x, y + height / 2, z], 6);
  piece(parent, [0.04, 0.5, 1.4], mats.red, [x, y + height - 0.3, z + 0.72]);
  piece(parent, [0.04, 0.5, 1.4], mats.white, [x, y + height - 0.8, z + 0.72]);
}

/** A tiered pyramid roof: the tajug of a Javanese mosque, the joglo of a pendopo. */
function tajug(
  parent: THREE.Object3D,
  size: number,
  tiers: number,
  material: THREE.Material,
  y: number,
) {
  let s = size;
  let at = y;
  for (let tier = 0; tier < tiers; tier += 1) {
    const height = s * (tier === tiers - 1 ? 0.55 : 0.28);
    roof(parent, s, s, height, true, material, [0, at, 0]);
    at += height * 0.62;
    if (tier < tiers - 1) piece(parent, [s * 0.5, height * 0.5, s * 0.5], mats.white, [0, at, 0]);
    at += height * 0.3;
    s *= 0.58;
  }
  ball(parent, 0.4, mats.gold, [0, at + 0.2, 0]);
}

/** A domed mosque with a minaret and a crescent. */
export function masjid(seed: number): THREE.Group {
  const group = new THREE.Group();
  const wall = seed > 0.5 ? mats.white : pick(walls, seed, 11);
  const dress = seed > 0.5 ? mats.green : mats.gold;
  piece(group, [18, 7, 18], wall, [0, 3.5, 0]);
  piece(group, [18.4, 0.6, 18.4], dress, [0, 7.3, 0]);
  // Serambi: the open porch on the street side, arches as dark panels.
  piece(group, [5, 0.4, 16], mats.white, [11.5, 4.8, 0]);
  for (let k = 0; k < 5; k += 1) {
    piece(group, [0.5, 4.6, 0.5], mats.white, [13.6, 2.3, -7 + k * 3.5]);
    piece(group, [0.12, 3.2, 2.2], mats.glass, [9.02, 2.0, -7 + k * 3.5]);
  }
  piece(group, [6, 0.25, 18], mats.paving, [11.5, 0.12, 0]);
  piece(group, [7, 2.5, 7], wall, [0, 8.6, 0]);
  dome(group, 5.5, dress, [0, 9.8, 0]);
  cyl(group, 0.1, 0.1, 1.8, mats.gold, [0, 16.1, 0], 4);
  const crescent = new THREE.Mesh(
    new THREE.TorusGeometry(0.5, 0.12, 4, 10, Math.PI * 1.4),
    mats.gold,
  );
  crescent.position.set(0, 17.3, 0);
  crescent.rotation.z = 0.8;
  group.add(crescent);
  for (const [x, z] of [
    [6, 6],
    [6, -6],
    [-6, 6],
    [-6, -6],
  ] as const)
    dome(group, 1.4, dress, [x, 7.6, z]);
  // The minaret: tall, banded, a balcony and a small dome.
  const m: [number, number] = [9, 11];
  cyl(group, 1.1, 1.3, 26, mats.white, [m[0], 13, m[1]], 8);
  for (const y of [8, 16]) cyl(group, 1.35, 1.35, 0.5, dress, [m[0], y, m[1]], 8);
  cyl(group, 1.8, 1.8, 0.5, mats.white, [m[0], 22, m[1]], 8);
  cyl(group, 0.8, 0.8, 2.5, mats.white, [m[0], 27.2, m[1]], 8);
  dome(group, 1, dress, [m[0], 28.4, m[1]]);
  piece(group, [0.25, 1.1, 8], board("MASJID", "#23a35a"), [14.15, 5.6, 0]);
  return group;
}

/** A Javanese mosque: a square hall under a three-tier tajug roof. */
export function masjidJawa(seed: number): THREE.Group {
  const group = new THREE.Group();
  piece(group, [16, 1, 16], mats.white, [0, 0.5, 0]);
  piece(group, [13, 4.5, 13], pick(walls, seed, 12), [0, 3.25, 0]);
  for (let k = 0; k < 4; k += 1)
    piece(group, [0.12, 2.6, 1.6], mats.woodDark, [6.52, 2.6, -4.5 + k * 3]);
  tajug(group, 18, 3, seed > 0.5 ? mats.tileDark : mats.greenRoof, 5.5);
  // The bedug drum and a well, on the porch.
  const drum = cyl(group, 0.7, 0.7, 1.4, mats.wood, [7.4, 2.0, 5.5], 10);
  drum.rotation.z = Math.PI / 2;
  piece(group, [0.8, 1.3, 1.8], mats.woodDark, [7.4, 1.1, 5.5]);
  return group;
}

/** A church: a nave, a bell tower and a cross. */
export function gereja(seed: number): THREE.Group {
  const group = new THREE.Group();
  const wall = seed > 0.5 ? mats.white : pick(walls, seed, 13);
  piece(group, [22, 8, 11], wall, [-2, 4, 0]);
  roof(group, 11.6, 22.6, 5, false, mats.tileDark, [-2, 8, 0]).rotation.y = Math.PI / 2;
  for (let k = 0; k < 4; k += 1)
    piece(group, [1.2, 3.4, 0.12], mats.mirror, [-10 + k * 5, 4, 5.52]);
  piece(group, [5, 16, 5], wall, [9, 8, 0]);
  roof(group, 5.6, 5.6, 6, true, mats.tileDark, [9, 16, 0]);
  piece(group, [0.4, 3, 0.4], mats.gold, [9, 23.5, 0]);
  piece(group, [0.4, 0.4, 1.8], mats.gold, [9, 24.2, 0]);
  piece(group, [0.12, 3.6, 2.2], mats.woodDark, [11.52, 1.8, 0]);
  ball(group, 1.2, mats.glow, [11.4, 12, 0]).scale.set(0.15, 1, 1);
  return group;
}

/** A klenteng: red walls, a sweeping tile roof, lanterns and a gold ridge. */
export function klenteng(seed: number): THREE.Group {
  const group = new THREE.Group();
  piece(group, [14, 0.8, 14], mats.white, [0, 0.4, 0]);
  piece(group, [11, 5, 12], mats.red, [0, 3.3, 0]);
  roof(group, 13.5, 15, 3.6, false, seed > 0.5 ? mats.tile : mats.greenRoof, [0, 5.8, 0]);
  piece(group, [0.5, 0.5, 15.6], mats.gold, [0, 9.5, 0]);
  for (const z of [-7.8, 7.8]) piece(group, [0.6, 1.4, 0.6], mats.gold, [0, 10.1, z]);
  piece(group, [3.4, 0.3, 12.5], mats.tile, [6.8, 4.6, 0]);
  for (const z of [-5, -1.7, 1.7, 5]) {
    cyl(group, 0.3, 0.3, 4, mats.red, [7.8, 2.8, z], 8);
    ball(group, 0.45, mats.red, [7.8, 3.9, z]).scale.set(1, 0.75, 1);
    piece(group, [0.1, 0.12, 0.5], mats.gold, [7.8, 3.5, z]);
  }
  piece(group, [0.12, 3.2, 3.4], mats.woodDark, [5.52, 2.4, 0]);
  cyl(group, 0.9, 1.1, 1.2, mats.gold, [9, 1.4, 0], 8);
  return group;
}

/** A pasar: an open hall of stalls under one long roof, sacks and crates. */
export function pasar(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 36;
  const depth = 24;
  piece(group, [depth, 0.3, width], mats.concrete, [0, 0.15, 0]);
  for (let x = -depth / 2 + 1; x <= depth / 2 - 1; x += (depth - 2) / 3) {
    for (let z = -width / 2 + 1; z <= width / 2 - 1; z += (width - 2) / 5) {
      piece(group, [0.5, 6.5, 0.5], mats.steel, [x, 3.4, z]);
    }
  }
  roof(group, depth + 3, width + 3, 5.5, true, seed > 0.5 ? mats.spandek : mats.tin, [0, 6.6, 0]);
  roof(group, depth * 0.5, width * 0.7, 2.4, false, mats.white, [0, 9.6, 0]);
  piece(group, [0.4, 2.2, 14], board("PASAR RAKYAT", "#2f7fe0"), [depth / 2 + 1.7, 7.4, 0]);
  // Stalls in rows: a counter, goods in colours, a tarp.
  for (let row = 0; row < 3; row += 1) {
    for (let k = 0; k < 6; k += 1) {
      const x = -depth / 2 + 4 + row * 7.5;
      const z = -width / 2 + 3.5 + k * 5.8;
      piece(group, [2.4, 0.9, 4.4], mats.wood, [x, 0.75, z]);
      for (let g = 0; g < 4; g += 1) {
        const goods = [mats.red, mats.leafLight, mats.yellow, tarps[5]!, mats.rust][
          (row + k + g) % 5
        ]!;
        ball(group, 0.38, goods, [x - 0.6 + (g % 2) * 1.2, 1.45, z - 1 + Math.floor(g / 2) * 2]);
      }
      const tarp = piece(group, [3, 0.08, 4.6], pick(tarps, seed + row * 0.3 + k * 0.1, 3), [
        x + 0.3,
        2.6,
        z,
      ]);
      tarp.rotation.z = -0.15;
    }
  }
  return group;
}

/** A primary school: a long block with a corridor, a flag and a sign. */
export function sekolah(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 32;
  const depth = 9;
  const wall = seed > 0.5 ? mats.white : pick(walls, seed, 14);
  piece(group, [depth - 2.4, 3.6, width], wall, [-1.2, 1.8, 0]);
  roof(group, depth + 0.6, width + 0.6, 2.6, true, mats.tileDark, [0, 3.6, 0]);
  for (let k = 0; k < 8; k += 1) {
    const z = -width / 2 + 2 + k * 4;
    piece(group, [0.25, 3.6, 0.25], mats.white, [depth / 2 - 0.2, 1.8, z]);
    piece(group, [0.1, 1.1, 1.8], mats.glass, [depth / 2 - 2.38, 2.0, z + 1.6]);
    piece(group, [0.1, 2.2, 0.9], tarps[0]!, [depth / 2 - 2.38, 1.1, z + 0.2]);
  }
  piece(group, [2.4, 0.15, width], mats.paving, [depth / 2 - 1.2, 0.08, 0]);
  piece(group, [0.2, 1.2, 8], board("SD NEGERI 1", "#e8382f"), [depth / 2 + 0.3, 4.4, 0]);
  piece(group, [3, 0.5, 3], mats.white, [depth / 2 + 6, 0.25, 0]);
  flag(group, [depth / 2 + 6, 0.5, 0], 9);
  return group;
}

/** A puskesmas: a white clinic with a green band, a canopy and an ambulance bay. */
export function puskesmas(): THREE.Group {
  const group = new THREE.Group();
  piece(group, [12, 7, 20], mats.white, [0, 3.5, 0]);
  piece(group, [12.2, 0.7, 20.2], mats.green, [0, 6.4, 0]);
  for (const y of [1.8, 5]) {
    for (let k = 0; k < 5; k += 1) piece(group, [0.12, 1.4, 2], mats.mirror, [6.02, y, -8 + k * 4]);
  }
  piece(group, [4, 0.3, 7], mats.white, [8, 3.4, 0]);
  for (const z of [-3, 3]) piece(group, [0.3, 3.4, 0.3], mats.white, [9.8, 1.7, z]);
  piece(group, [0.2, 1.1, 8], board("PUSKESMAS", "#23a35a"), [6.2, 7.6, 0]);
  piece(group, [0.3, 1.4, 0.4], mats.red, [10.1, 4.4, -2.6]);
  piece(group, [0.3, 0.4, 1.4], mats.red, [10.1, 4.4, -2.6]);
  return group;
}

/** An SPBU: a red-and-white canopy over pump islands, a price tower, a shop. */
export function spbu(): THREE.Group {
  const group = new THREE.Group();
  piece(group, [26, 0.12, 30], mats.concrete, [0, 0.06, 0]);
  for (const x of [-4, 4]) {
    for (const z of [-8, 0, 8]) {
      piece(group, [1.2, 0.3, 4], mats.white, [x, 0.25, z]);
      piece(group, [0.8, 1.8, 1.2], mats.white, [x, 1.2, z]);
      piece(group, [0.82, 0.5, 1.22], mats.red, [x, 1.9, z]);
      cyl(group, 0.2, 0.2, 5.5, mats.white, [x, 2.85, z + 1.6], 6);
    }
  }
  piece(group, [14, 1.2, 24], mats.white, [0, 6.2, 0]);
  piece(group, [14.1, 0.5, 24.1], mats.red, [0, 6.6, 0]);
  piece(group, [14.12, 0.2, 24.12], tarps[0]!, [0, 6.0, 0]);
  piece(group, [8, 4, 10], mats.white, [-10, 2, 6]);
  piece(group, [0.12, 2.6, 8], mats.mirror, [-5.98, 1.5, 6]);
  // The price tower out front.
  piece(group, [0.8, 9, 2.6], mats.white, [11, 4.5, -12]);
  piece(group, [0.9, 2, 2.7], board("SPBU", "#e8382f"), [11, 8, -12]);
  for (let k = 0; k < 3; k += 1)
    piece(group, [0.85, 0.8, 2.3], pick([tarps[0]!, mats.green, mats.yellow], k), [
      11,
      2 + k * 1.2,
      -12,
    ]);
  return group;
}

/** A pos ronda: the neighbourhood watch hut on stilts, a kentongan hanging. */
export function posRonda(seed: number): THREE.Group {
  const group = new THREE.Group();
  for (const x of [-1.2, 1.2])
    for (const z of [-1.4, 1.4]) piece(group, [0.18, 2.6, 0.18], mats.wood, [x, 1.3, z]);
  piece(group, [2.8, 0.15, 3.2], mats.wood, [0, 0.6, 0]);
  piece(group, [0.1, 0.9, 3.2], pick(walls, seed, 15), [-1.3, 1.1, 0]);
  roof(group, 3.4, 3.8, 1, false, seed > 0.5 ? mats.tin : mats.tile, [0, 2.6, 0]);
  const kentongan = cyl(group, 0.12, 0.12, 0.9, mats.woodDark, [1.4, 1.8, 1.2], 6);
  kentongan.rotation.z = 0.1;
  piece(group, [0.1, 0.4, 1.8], board("POS RONDA", "#1f2a44"), [1.4, 2.9, 0]);
  return group;
}

/** A gapura: the painted gate at a kampung's entrance, flags on top. */
export function gapura(seed: number, width = 6): THREE.Group {
  const group = new THREE.Group();
  for (const z of [-width / 2, width / 2]) {
    piece(group, [0.9, 4.5, 0.9], mats.white, [0, 2.25, z]);
    piece(group, [0.95, 0.5, 0.95], mats.red, [0, 1.2, z]);
    piece(group, [0.95, 0.5, 0.95], mats.red, [0, 3.2, z]);
    roof(group, 1.3, 1.3, 1, true, mats.red, [0, 4.5, z]);
  }
  piece(
    group,
    [0.5, 1.1, width],
    seed > 0.5 ? board("SELAMAT DATANG", "#e8382f") : board("RT 05 RW 03", "#2f7fe0"),
    [0, 4.0, 0],
  );
  piece(group, [0.4, 0.2, width + 1], mats.white, [0, 4.6, 0]);
  return group;
}

/** A tugu: an obelisk on a stepped plinth in a round pool, flowers around it. */
export function tugu(): THREE.Group {
  const group = new THREE.Group();
  cyl(group, 11, 11, 0.4, mats.grass, [0, 0.2, 0], 24);
  cyl(group, 8, 8, 0.6, mats.white, [0, 0.3, 0], 24);
  cyl(group, 7.4, 7.4, 0.62, mats.water, [0, 0.32, 0], 24);
  for (let k = 0; k < 14; k += 1) {
    const angle = (k / 14) * Math.PI * 2;
    ball(group, 0.6, k % 2 ? mats.red : tarps[4]!, [
      Math.cos(angle) * 9.5,
      0.7,
      Math.sin(angle) * 9.5,
    ]);
  }
  piece(group, [4, 1.2, 4], mats.white, [0, 1.2, 0]);
  piece(group, [3, 1, 3], mats.white, [0, 2.3, 0]);
  cyl(group, 0.5, 1.2, 14, mats.white, [0, 9.8, 0], 4);
  cyl(group, 0, 0.5, 1.4, mats.gold, [0, 17.5, 0], 4);
  piece(group, [3.1, 0.3, 3.1], mats.gold, [0, 2.85, 0]);
  return group;
}

/** A pendopo: an open joglo pavilion on a stone floor. */
export function pendopo(seed: number): THREE.Group {
  const group = new THREE.Group();
  piece(group, [14, 0.8, 14], mats.white, [0, 0.4, 0]);
  for (let i = -1; i <= 1; i += 2) {
    for (let j = -1; j <= 1; j += 2) {
      piece(group, [0.4, 5, 0.4], mats.woodDark, [i * 2.2, 3.2, j * 2.2]);
      piece(group, [0.3, 3.4, 0.3], mats.wood, [i * 5.6, 2.5, j * 5.6]);
    }
  }
  tajug(group, 15, 3, seed > 0.5 ? mats.tileDark : mats.tile, 4.2);
  return group;
}

/** A lapangan: a football pitch with goals, the kampung's one open space. */
export function lapangan(): THREE.Group {
  const group = new THREE.Group();
  const length = 50;
  const width = 32;
  piece(group, [length + 4, 0.1, width + 4], mats.field, [0, 0.05, 0]);
  for (let k = 0; k < 6; k += 1)
    piece(group, [length / 6, 0.11, width], k % 2 ? mats.field : mats.grass, [
      -length / 2 + length / 12 + (k * length) / 6,
      0.06,
      0,
    ]);
  const line = (size: [number, number], at: [number, number]) =>
    piece(group, [size[0], 0.12, size[1]], mats.paint, [at[0], 0.07, at[1]]);
  line([length, 0.2], [0, -width / 2]);
  line([length, 0.2], [0, width / 2]);
  line([0.2, width], [-length / 2, 0]);
  line([0.2, width], [length / 2, 0]);
  line([0.2, width], [0, 0]);
  for (const side of [-1, 1]) {
    line([0.2, 14], [side * (length / 2 - 7), 0]);
    line([7, 0.2], [side * (length / 2 - 3.5), -7]);
    line([7, 0.2], [side * (length / 2 - 3.5), 7]);
    for (const z of [-3.6, 3.6])
      piece(group, [0.15, 2.4, 0.15], mats.white, [side * (length / 2 + 0.1), 1.2, z]);
    piece(group, [0.15, 0.15, 7.4], mats.white, [side * (length / 2 + 0.1), 2.4, 0]);
    span(
      group,
      new THREE.Vector3(side * (length / 2 + 1.2), 0.1, -3.6),
      new THREE.Vector3(side * (length / 2 + 0.1), 2.4, -3.6),
      0.05,
      mats.white,
    );
    span(
      group,
      new THREE.Vector3(side * (length / 2 + 1.2), 0.1, 3.6),
      new THREE.Vector3(side * (length / 2 + 0.1), 2.4, 3.6),
      0.05,
      mats.white,
    );
  }
  return group;
}

export const shelf: Shelf = {
  title: "Landmarks",
  assets: [
    { name: "Masjid", build: masjid },
    { name: "Masjid Jawa", build: masjidJawa },
    { name: "Gereja", build: gereja },
    { name: "Klenteng", build: klenteng },
    { name: "Pasar", build: pasar },
    { name: "Sekolah", build: sekolah },
    { name: "Puskesmas", build: puskesmas },
    { name: "SPBU", build: spbu },
    { name: "Pendopo", build: pendopo },
    { name: "Pos ronda", build: posRonda },
    { name: "Gapura", build: (seed) => gapura(seed) },
    { name: "Tugu", build: tugu },
    { name: "Lapangan", build: lapangan },
  ],
};
