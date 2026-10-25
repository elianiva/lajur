import * as THREE from "three";
import {
  board,
  cyl,
  mats,
  piece,
  pick,
  roof,
  roofs,
  signs,
  span,
  tarps,
  walls,
  type Shelf,
} from "./kit.ts";

/** Buildings face +x: the street side is at x = depth / 2, width runs along z. */

const SHOP_WORDS = [
  "TOKO",
  "APOTEK",
  "BAKSO",
  "SALON",
  "FOTOKOPI",
  "PULSA",
  "SOTO",
  "KOPI",
  "MIE AYAM",
  "LAUNDRY",
  "ES TEH",
  "SEMBAKO",
  "BENGKEL",
  "MARTABAK",
  "BATIK",
  "EMAS",
];
const SIGN_COLOURS = ["#e8382f", "#2f7fe0", "#f4b42e", "#23a35a", "#8a4fd8", "#ff7a2f", "#1f2a44"];

function shopSign(seed: number): THREE.Material {
  const background = pick(SIGN_COLOURS, seed, 7);
  return board(
    pick(SHOP_WORDS, seed, 3),
    background,
    background === "#f4b42e" ? "#1f2a44" : "#fffdf2",
  );
}

/** A row of window panes across the front at one floor. */
function panes(
  group: THREE.Object3D,
  x: number,
  y: number,
  width: number,
  count: number,
  size: [number, number],
  seed: number,
) {
  const step = width / count;
  for (let k = 0; k < count; k += 1) {
    const lit = (Math.floor(seed * 977) + k * 7) % 3 === 0;
    piece(group, [0.12, size[1], size[0]], lit ? mats.glow : mats.glass, [
      x,
      y,
      -width / 2 + step * (k + 0.5),
    ]);
  }
}

/** A water tank on legs: the orange toren on every roof. */
export function toren(parent: THREE.Object3D, at: [number, number, number], seed: number) {
  const [x, y, z] = at;
  for (const dx of [-0.35, 0.35]) {
    for (const dz of [-0.35, 0.35])
      piece(parent, [0.08, 1.2, 0.08], mats.metal, [x + dx, y + 0.6, z + dz]);
  }
  cyl(parent, 0.55, 0.55, 1.1, seed > 0.5 ? mats.rust : tarps[0]!, [x, y + 1.75, z], 10);
  cyl(parent, 0.2, 0.55, 0.25, seed > 0.5 ? mats.rust : tarps[0]!, [x, y + 2.42, z], 10);
}

function dish(parent: THREE.Object3D, at: [number, number, number]) {
  const [x, y, z] = at;
  piece(parent, [0.08, 0.7, 0.08], mats.metal, [x, y + 0.35, z]);
  const plate = cyl(parent, 0.5, 0.15, 0.18, mats.white, [x + 0.15, y + 0.85, z], 8);
  plate.rotation.z = -0.9;
}

function laundry(
  parent: THREE.Object3D,
  x: number,
  y: number,
  z: number,
  length: number,
  seed: number,
) {
  span(
    parent,
    new THREE.Vector3(x, y, z - length / 2),
    new THREE.Vector3(x, y, z + length / 2),
    0.03,
    mats.wire,
  );
  for (let k = 0; k < 5; k += 1) {
    const cloth = tarps[(Math.floor(seed * 13) + k) % tarps.length]!;
    piece(parent, [0.05, 0.5, 0.35], cloth, [
      x,
      y - 0.27,
      z - length / 2 + (k + 0.6) * (length / 5.4),
    ]);
  }
}

/** A shop-house: two or three floors, rolling shutters, a sign band, an awning. */
export function ruko(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const wall = pick(walls, seed, 1);
  const floors = seed > 0.7 ? 3 : 2;
  const height = floors * 3.3;
  const front = depth / 2;

  piece(group, [depth, height, width], wall, [0, height / 2, 0]);
  // Parapet with a cornice: the flat-topped ruko silhouette.
  piece(group, [depth - 0.1, 0.25, width - 0.1], mats.concrete, [0, height + 0.12, 0]);
  piece(group, [0.3, 0.9, width - 0.2], wall, [front - 0.15, height + 0.6, 0]);

  // Ground floor: shutter or open shop with goods, then the sign and awning.
  const open = (seed * 7) % 1 > 0.35;
  piece(group, [0.1, 2.7, width * 0.86], open ? mats.glass : mats.steel, [front - 0.05, 1.4, 0]);
  if (!open) {
    for (let y = 0.3; y < 2.7; y += 0.3)
      piece(group, [0.04, 0.04, width * 0.86], mats.metal, [front - 0.1, y, 0]);
  }
  piece(group, [0.16, 1.0, width * 0.92], shopSign(seed), [front - 0.08, 3.3, 0]);
  // The awning hangs inside the front line, over the shop's own forecourt: a
  // building fills its lot and never reaches past it.
  const awning = piece(group, [1.6, 0.1, width * 0.96], pick(tarps, seed, 5), [
    front - 0.85,
    2.85,
    0,
  ]);
  awning.rotation.z = -0.12;

  // Upper floors: windows, a balcony rail, a split AC unit.
  for (let floor = 1; floor < floors; floor += 1) {
    const y = floor * 3.3 + 1.6;
    panes(group, front - 0.05, y, width * 0.8, 2, [width * 0.3, 1.4], seed + floor);
    piece(group, [0.8, 0.1, width * 0.9], mats.white, [front - 0.4, floor * 3.3 + 0.2, 0]);
    piece(group, [0.05, 0.8, width * 0.9], mats.metal, [front - 0.78, floor * 3.3 + 0.6, 0]);
    piece(group, [0.5, 0.5, 0.8], mats.white, [front - 0.25, y + 1.1, width * 0.35]);
  }
  if (seed > 0.4) toren(group, [-depth * 0.2, height + 0.25, -width * 0.2], seed);
  if (seed > 0.8) dish(group, [depth * 0.1, height + 0.25, width * 0.25]);
  return group;
}

/** A warung: tarpaulin roof, counter, benches, crates, and a painted name. */
export function warung(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const wall = pick(walls, seed, 2);
  const front = depth / 2;

  // The back half is a shed; the front half is the counter under the tarp.
  piece(group, [depth * 0.5, 2.5, width * 0.94], wall, [-depth * 0.22, 1.25, 0]);
  piece(group, [0.6, 0.95, width * 0.8], mats.wood, [front - 0.5, 0.48, 0]);
  piece(group, [0.8, 0.08, width * 0.85], mats.woodDark, [front - 0.5, 0.98, 0]);
  // Snacks hung in strips and jars on the counter.
  for (let k = 0; k < 4; k += 1) {
    const z = -width * 0.3 + k * width * 0.2;
    piece(group, [0.08, 0.7, 0.2], pick(tarps, seed + k * 0.1, 3), [front - 0.85, 1.9, z]);
    cyl(group, 0.13, 0.13, 0.3, mats.mirror, [front - 0.5, 1.17, z], 6);
  }
  for (const z of [-width * 0.45, width * 0.45])
    piece(group, [0.1, 2.4, 0.1], mats.wood, [front - 0.1, 1.2, z]);
  piece(group, [depth * 0.94, 0.1, width * 0.96], pick(tarps, seed, 4), [0, 2.55, 0]);
  piece(
    group,
    [0.12, 0.7, width * 0.9],
    board(seed > 0.5 ? "WARUNG" : "WARTEG", "#fffdf2", "#e8382f"),
    [front - 0.1, 3.05, 0],
  );
  // A long bench out front, crates and a gas bottle.
  piece(group, [0.4, 0.45, width * 0.7], mats.wood, [front - 1.1, 0.23, 0]);
  piece(group, [0.5, 0.4, 0.6], mats.red, [front - 1.6, 0.2, width * 0.3]);
  cyl(group, 0.18, 0.18, 0.5, mats.green, [front - 1.6, 0.25, -width * 0.3], 8);
  return group;
}

/** A kampung house: hipped tile roof, a teras with two posts, a fence. */
export function house(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const wall = pick(walls, seed, 3);
  const height = 3.2 + ((seed * 3.7) % 1) * 0.8;
  const cover = pick(roofs, seed, 2);
  const hipped = (seed * 5) % 1 > 0.35;
  const inner = depth - 2;

  piece(group, [inner, height, width * 0.92], wall, [-1, height / 2, 0]);
  roof(group, depth - 0.2, width * 0.92, Math.min(width, depth) * 0.32, hipped, cover, [
    0,
    height,
    0,
  ]);
  if (!hipped) piece(group, [depth - 0.2, 0.1, 0.1], mats.white, [0, height, width * 0.46 + 0.3]);
  // Teras: posts, a door, two windows with white frames.
  for (const z of [-width * 0.36, width * 0.36])
    piece(group, [0.2, height, 0.2], mats.white, [depth / 2 - 0.2, height / 2, z]);
  piece(group, [0.12, 2.1, 0.95], mats.woodDark, [inner / 2 - 0.94, 1.05, -width * 0.15]);
  for (const z of [width * 0.22, -width * 0.38]) {
    if (Math.abs(z) > width / 2 - 0.4) continue;
    piece(group, [0.14, 1.2, 1.0], mats.white, [inner / 2 - 0.95, 1.7, z]);
    piece(group, [0.18, 1.0, 0.8], mats.glass, [inner / 2 - 0.94, 1.7, z]);
  }
  piece(group, [2.0, 0.12, width * 0.9], mats.paving, [depth / 2 - 1, 0.06, 0]);
  // A low fence with a gate gap, and a pot or two.
  if (seed > 0.3) {
    piece(group, [0.15, 0.9, width * 0.32], mats.white, [depth / 2 - 0.1, 0.45, -width * 0.32]);
    piece(group, [0.15, 0.9, width * 0.32], mats.white, [depth / 2 - 0.1, 0.45, width * 0.32]);
  }
  cyl(group, 0.25, 0.18, 0.4, mats.rust, [depth / 2 - 0.3, 0.2, width * 0.3], 6);
  cyl(group, 0.35, 0.35, 0.5, mats.leaf, [depth / 2 - 0.3, 0.6, width * 0.3], 6);
  if (seed > 0.55) toren(group, [-depth * 0.3, height - 0.3, width * 0.32], seed);
  return group;
}

/** Kos-kosan: two floors of rented rooms, a corridor, a row of doors and slippers. */
export function kos(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const wall = pick(walls, seed, 4);
  // Rooms line the width; the corridor runs the depth in front of them.
  const units = Math.min(Math.max(Math.floor(width / 2.8), 1), 6);
  const unit = width / units;
  const body = depth - 1.6;
  piece(group, [body, 6.4, width * 0.96], wall, [-0.8, 3.2, 0]);
  piece(group, [1.6, 0.2, width * 0.96], mats.concrete, [depth / 2 - 0.8, 3.2, 0]);
  piece(group, [0.08, 1.0, width * 0.96], mats.metal, [depth / 2 - 0.06, 3.8, 0]);
  for (let k = 0; k < units; k += 1) {
    const z = -width / 2 + unit * (k + 0.5);
    for (const y of [1.05, 4.25]) {
      piece(group, [0.1, 2.1, unit * 0.7], pick(signs, seed + k, 2), [depth / 2 - 1.58, y, z]);
      piece(group, [0.1, 0.8, unit * 0.6], mats.glass, [depth / 2 - 1.58, y + 0.3, z + unit * 0.1]);
    }
  }
  roof(group, depth - 0.2, width * 0.96, 2.2, false, pick(roofs, seed, 3), [0, 6.4, 0]);
  piece(group, [0.16, 0.8, Math.min(3.2, width * 0.5)], board("KOS PUTRI", "#d2489a"), [
    depth / 2 - 0.05,
    3.0,
    0,
  ]);
  laundry(group, depth / 2 - 0.4, 6.0, 0, width * 0.8, seed);
  return group;
}

/** Rumah petak: a terrace of tiny kampung homes under one long roof. */
export function petak(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const units = Math.min(Math.max(Math.floor(width / 3.4), 1), 6);
  const unit = width / units;
  for (let k = 0; k < units; k += 1) {
    const z = -width / 2 + unit * (k + 0.5);
    const wall = pick(walls, seed + k * 0.13, 5);
    piece(group, [depth - 0.2, 3, unit - 0.06], wall, [0, 1.5, z]);
    piece(group, [0.1, 1.9, unit * 0.28], mats.woodDark, [depth / 2 - 0.06, 0.95, z - unit * 0.2]);
    piece(group, [0.1, 0.8, unit * 0.3], mats.glass, [depth / 2 - 0.06, 1.6, z + unit * 0.18]);
    if ((k + Math.floor(seed * 10)) % 2 === 0) {
      cyl(group, 0.22, 0.16, 0.35, mats.rust, [depth / 2 - 0.5, 0.18, z + unit * 0.3], 6);
      cyl(group, 0.3, 0.3, 0.4, mats.leafLight, [depth / 2 - 0.5, 0.55, z + unit * 0.3], 6);
    }
  }
  roof(group, depth - 0.2, width * 0.98, 1.8, false, seed > 0.5 ? mats.tile : mats.tin, [0, 3, 0]);
  laundry(group, depth / 2 - 0.6, 2.2, 0, width * 0.5, seed);
  return group;
}

/**
 * A filler block: a terrace with two floors of windows on every side, a broken
 * roofline and clutter on all four corners of the roof.
 *
 * Every other building here has one face, the one that looks at the road, and
 * blank walls elsewhere. A lot in the middle of a block has no road to look at,
 * so it takes this instead: nothing on it is a back.
 */
export function filler(seed: number, width: number, depth: number): THREE.Group {
  const group = new THREE.Group();
  const wall = pick(walls, seed, 11);
  const height = 6.2;
  piece(group, [depth, height, width], wall, [0, height / 2, 0]);
  piece(group, [depth - 0.1, 0.25, width - 0.1], mats.concrete, [0, height + 0.1, 0]);

  // A row of gables across the width: the roofline of a terrace, not a box.
  const units = Math.max(2, Math.min(5, Math.round(width / 3.2)));
  const unit = width / units;
  for (let k = 0; k < units; k += 1) {
    const z = -width / 2 + unit * (k + 0.5);
    const hipped = (k + Math.floor(seed * 9)) % 3 === 0;
    roof(
      group,
      depth - 0.2,
      unit - 0.04,
      Math.min(unit, depth) * 0.3,
      hipped,
      k % 2 ? mats.tileDark : mats.tile,
      [0, height, z],
    );
  }

  // Two floors of windows on all four sides, and a door on the long ones.
  for (let k = 0; k < 4; k += 1) {
    const long = k < 2;
    const sign = k % 2 === 0 ? 1 : -1;
    const span = long ? width : depth;
    const count = Math.max(2, Math.round(span / 2.6));
    for (const y of [1.6, 4.4]) {
      for (let w = 0; w < count; w += 1) {
        const t = -span / 2 + (span / count) * (w + 0.5);
        const lit = (Math.floor(seed * 977) + w + k * 3) % 4 === 0;
        const mat = lit ? mats.glow : mats.glass;
        if (long) piece(group, [0.1, 1.2, 1.1], mat, [sign * (depth / 2 - 0.04), y, t]);
        else piece(group, [1.1, 1.2, 0.1], mat, [t, y, sign * (width / 2 - 0.04)]);
      }
    }
    if (long && (k + Math.floor(seed * 5)) % 2 === 0)
      piece(group, [0.12, 2.0, 0.9], mats.woodDark, [sign * (depth / 2 - 0.05), 1.0, span * 0.3]);
  }

  // Clutter on every side of the roof, so no view of it is blank.
  if (seed > 0.25) toren(group, [-depth * 0.22, height + 0.2, -width * 0.22], seed);
  if (seed > 0.55) toren(group, [depth * 0.2, height + 0.2, width * 0.18], seed);
  if (seed > 0.45) dish(group, [depth * 0.15, height + 0.2, -width * 0.3]);
  laundry(group, depth / 2 - 0.5, height - 1.2, -width * 0.15, Math.min(width * 0.5, 6), seed);
  return group;
}

/** Rumah susun: five floors of flats, laundry on every balcony. */
export function rusun(seed: number): THREE.Group {
  const group = new THREE.Group();
  const floors = 5;
  const width = 26;
  const depth = 11;
  const wall = pick(walls, seed, 6);
  const height = floors * 3;
  piece(group, [depth, height, width], wall, [0, height / 2, 0]);
  for (let floor = 0; floor < floors; floor += 1) {
    const y = floor * 3;
    piece(group, [1.4, 0.2, width], mats.white, [depth / 2 + 0.7, y + 0.1, 0]);
    piece(group, [0.08, 1.0, width], mats.white, [depth / 2 + 1.36, y + 0.6, 0]);
    panes(group, depth / 2 + 0.02, y + 1.6, width - 2, 8, [1.2, 1.4], seed + floor * 0.3);
    if (floor > 0)
      laundry(group, depth / 2 + 1.0, y + 2.6, -width * 0.2 + (floor % 2) * 6, 6, seed + floor);
  }
  // A stair core in a contrasting colour, the name on top.
  piece(group, [depth + 0.4, height + 2, 4], mats.white, [0, (height + 2) / 2, width / 2 - 2]);
  piece(group, [depth + 0.4, 0.4, width + 0.4], mats.white, [0, height + 0.2, 0]);
  piece(group, [0.2, 1.4, 6], board("RUSUNAWA", "#2f7fe0"), [depth / 2 + 0.2, height + 1.2, -4]);
  toren(group, [-2, height + 0.4, -6], seed);
  toren(group, [-2, height + 0.4, -2], seed);
  return group;
}

/** An apartment tower: a podium, a slab of balconies, a crown. */
export function apartemen(seed: number): THREE.Group {
  const group = new THREE.Group();
  const floors = 14 + Math.floor(seed * 10);
  const height = floors * 3.1;
  const wall = seed > 0.5 ? mats.white : pick(walls, seed, 7);
  piece(group, [22, 6, 22], mats.concrete, [0, 3, 0]);
  piece(group, [0.2, 3.5, 18], mats.mirror, [11.02, 2.3, 0]);
  piece(group, [16, height, 14], wall, [0, 6 + height / 2, 0]);
  for (let floor = 0; floor < floors; floor += 2) {
    const y = 6 + floor * 3.1;
    piece(group, [1.2, 0.25, 14.4], mats.white, [8.6, y + 0.1, 0]);
    panes(group, 8.02, y + 1.6, 12, 4, [2.2, 1.8], seed + floor * 0.11);
    panes(group, 8.02, y + 4.7, 12, 4, [2.2, 1.8], seed + floor * 0.17);
  }
  for (const z of [-7.02, 7.02])
    piece(group, [12, height, 0.12], mats.glass, [0, 6 + height / 2, z]);
  piece(group, [17, 3, 15], pick(signs, seed, 4), [0, 6 + height + 1.5, 0]);
  return group;
}

/** A glass office tower with a stepped crown and a logo band. */
export function kantor(seed: number): THREE.Group {
  const group = new THREE.Group();
  const height = 40 + seed * 40;
  const glass = seed > 0.5 ? mats.curtain : mats.glass;
  piece(group, [18, height, 18], glass, [0, height / 2, 0]);
  for (let y = 4; y < height; y += 4) piece(group, [18.3, 0.35, 18.3], mats.white, [0, y, 0]);
  for (const x of [-9, 9])
    for (const z of [-9, 9]) piece(group, [1, height, 1], mats.white, [x, height / 2, z]);
  piece(group, [12, 6, 12], glass, [0, height + 3, 0]);
  piece(group, [12.3, 0.4, 12.3], mats.white, [0, height + 6, 0]);
  cyl(group, 0.15, 0.15, 8, mats.metal, [0, height + 10, 0], 4);
  piece(group, [0.3, 2.2, 10], board(pick(["BANK", "MENARA", "PLAZA", "GRAHA"], seed), "#1f2a44"), [
    9.2,
    height - 2,
    0,
  ]);
  piece(group, [4, 0.4, 10], mats.white, [11, 4, 0]);
  return group;
}

/** A minimarket: glass front, a striped band, a sign, motorbikes outside. */
export function minimarket(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 10;
  const depth = 9;
  const blue = seed > 0.5;
  piece(group, [depth, 4.4, width], mats.white, [0, 2.2, 0]);
  piece(group, [0.12, 2.8, width * 0.9], mats.mirror, [depth / 2 + 0.01, 1.5, 0]);
  piece(group, [0.4, 0.4, width + 0.2], mats.red, [depth / 2 + 0.1, 3.2, 0]);
  piece(group, [0.4, 0.4, width + 0.2], blue ? tarps[0]! : mats.yellow, [depth / 2 + 0.1, 3.6, 0]);
  piece(group, [0.4, 0.5, width + 0.2], blue ? mats.yellow : tarps[0]!, [depth / 2 + 0.1, 4.05, 0]);
  piece(
    group,
    [0.3, 1.2, 6],
    board(blue ? "MINIMART" : "SERBAMART", blue ? "#2f7fe0" : "#e8382f"),
    [depth / 2 + 0.2, 5.0, 0],
  );
  piece(group, [2, 0.2, width], mats.concrete, [depth / 2 + 1, 0.1, 0]);
  cyl(group, 0.35, 0.35, 0.9, mats.red, [depth / 2 + 0.6, 0.65, width / 2 - 0.6], 8);
  return group;
}

/** A bengkel: an open workshop bay, stacked tyres, a lift and an oil sign. */
export function bengkel(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 7;
  const depth = 8;
  piece(group, [depth, 3.8, 0.3], pick(walls, seed, 8), [0, 1.9, -width / 2]);
  piece(group, [depth, 3.8, 0.3], pick(walls, seed, 8), [0, 1.9, width / 2]);
  piece(group, [0.3, 3.8, width], pick(walls, seed, 8), [-depth / 2, 1.9, 0]);
  const top = piece(group, [depth + 1.4, 0.15, width + 0.6], mats.tin, [0.6, 3.9, 0]);
  top.rotation.z = -0.06;
  piece(group, [depth, 0.1, width], mats.concrete, [0, 0.05, 0]);
  piece(group, [0.16, 0.9, width * 0.9], board("BENGKEL", "#1f2a44", "#f4b42e"), [
    depth / 2 + 0.5,
    4.5,
    0,
  ]);
  for (let k = 0; k < 5; k += 1) {
    const tyre = cyl(
      group,
      0.4,
      0.4,
      0.25,
      mats.rubber,
      [depth / 2 - 0.6, 0.15 + k * 0.26, width / 2 - 0.8],
      10,
    );
    tyre.rotation.y = k;
  }
  piece(group, [3.6, 0.15, 1.6], mats.red, [-0.5, 1.1, -0.8]);
  piece(group, [0.3, 1.1, 0.3], mats.metal, [-0.5, 0.55, -0.8]);
  return group;
}

/** A gudang: an arched tin warehouse with a loading dock. */
export function gudang(seed: number): THREE.Group {
  const group = new THREE.Group();
  const width = 18;
  const depth = 24;
  piece(group, [depth, 5, width], pick(walls, seed, 9), [0, 2.5, 0]);
  const vault = new THREE.Mesh(
    new THREE.CylinderGeometry(width / 2, width / 2, depth, 12, 1, false, 0, Math.PI),
    seed > 0.5 ? mats.spandek : mats.tin,
  );
  vault.rotation.z = Math.PI / 2;
  vault.scale.set(0.35, 1, 1);
  vault.position.set(0, 5, 0);
  group.add(vault);
  piece(group, [0.12, 4, 6], mats.steel, [depth / 2 + 0.01, 2, 0]);
  piece(group, [3, 1.1, width], mats.concrete, [depth / 2 + 1.5, 0.55, 0]);
  return group;
}

/** A mall: a big box, a glass atrium, a giant sign. */
export function mal(seed: number): THREE.Group {
  const group = new THREE.Group();
  piece(group, [40, 14, 50], seed > 0.5 ? mats.white : pick(walls, seed, 10), [0, 7, 0]);
  piece(group, [8, 16, 20], mats.mirror, [18, 8, 0]);
  piece(group, [0.4, 4, 18], board("MAL KOTA", "#d2489a"), [22.3, 18, 0]);
  piece(group, [30, 2, 40], mats.concrete, [-2, 15, 0]);
  for (let k = 0; k < 4; k += 1) piece(group, [4, 2, 4], mats.steel, [-10 + k * 6, 17, -12]);
  return group;
}

export const shelf: Shelf = {
  title: "Homes and shops",
  assets: [
    { name: "Rumah", build: (seed) => house(seed, 7 + seed * 4, 9 + seed * 3) },
    { name: "Rumah petak", build: (seed) => petak(seed, 11, 8) },
    { name: "Kos", build: (seed) => kos(seed, 11, 10) },
    { name: "Pengisi", build: (seed) => filler(seed, 11, 10) },
    { name: "Ruko", build: (seed) => ruko(seed, 4.5 + seed * 2, 12) },
    { name: "Warung", build: (seed) => warung(seed, 5.5, 5) },
    { name: "Minimarket", build: minimarket },
    { name: "Bengkel", build: bengkel },
    { name: "Gudang", build: gudang },
    { name: "Rusun", build: rusun },
    { name: "Apartemen", build: apartemen },
    { name: "Kantor", build: kantor },
    { name: "Mal", build: mal },
  ],
};
