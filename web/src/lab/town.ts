import * as THREE from "three";
import { bodyLength } from "../bend.ts";
import {
  bengkel,
  gudang,
  house,
  kos,
  minimarket,
  mal,
  petak,
  ruko,
  rusun,
  apartemen,
  kantor,
  warung,
} from "../assets/buildings.ts";
import { buildCar, trafficColour } from "../assets/cars.ts";
import {
  flag,
  gapura,
  gereja,
  klenteng,
  lapangan,
  masjid,
  masjidJawa,
  pasar,
  pendopo,
  posRonda,
  puskesmas,
  sekolah,
  spbu,
  tugu,
} from "../assets/civic.ts";
import { bake, mats, piece, roofs, span, tarps } from "../assets/kit.ts";
import { anak, ibu, pedagang, pejalan } from "../assets/people.ts";
import { angkot, bajaj, becak, metromini, ojek, pickup } from "../assets/rides.ts";
import {
  addBunting,
  baliho,
  cart,
  gerobak,
  halte,
  lampu,
  lampuMerah,
  motorbike,
  payung,
  pot,
  powerPole,
  tenda,
  tong,
  umbul,
} from "../assets/street.ts";
import {
  bambu,
  banana,
  beringin,
  flamboyan,
  kamboja,
  mangga,
  palm,
  pepaya,
  semak,
} from "../assets/trees.ts";
import type { Body } from "../game.mjs";
import { random, type View } from "./view.ts";

/**
 * A kota, packed: a boulevard with a planted median, side streets, a river
 * with painted kampung on its banks, an alun-alun with its mosque, a pasar, a
 * school field, towers and a mall, and gangs between rows of houses. Traffic
 * keeps left and queues at the lights; people walk the pavements.
 *
 * This is a showroom for the assets and the looks, not the game: nothing here
 * is a rule. Everything that stands still is baked into one mesh per
 * material; everything that moves is instanced.
 */

const HX = 170;
const HZ = 120;
const UP = new THREE.Vector3(0, 1, 0);

type Kind = "raya" | "jalan" | "lokal";

interface Road {
  axis: "x" | "z";
  at: number;
  kind: Kind;
  half: number;
  walk: number;
  /** Lane centres from the road's middle, one direction's worth. */
  lanes: number[];
}

const ROADS: Road[] = [
  { axis: "x", at: -70, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
  { axis: "x", at: 0, kind: "raya", half: 7.4, walk: 3, lanes: [2.5, 5.75] },
  { axis: "x", at: 75, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
  { axis: "z", at: -105, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
  { axis: "z", at: -40, kind: "lokal", half: 2.9, walk: 1.5, lanes: [1.4] },
  { axis: "z", at: 65, kind: "lokal", half: 2.9, walk: 1.5, lanes: [1.4] },
  { axis: "z", at: 100, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
];
const ALONG_X = ROADS.filter((road) => road.axis === "x");
const ALONG_Z = ROADS.filter((road) => road.axis === "z");

// --- the river ------------------------------------------------------------------

const WATER = 7;
const WALL = 8.5;
const BANK = 12;

function riverX(z: number): number {
  return 26 + 13 * Math.sin(z / 34) + 5 * Math.sin(z / 13 + 1);
}

/** A quad strip along z between two x functions, at height y, facing up. */
function stripZ(left: (z: number) => number, right: (z: number) => number, y: number) {
  const position: number[] = [];
  for (let z = -HZ; z < HZ; z += 2) {
    const z1 = Math.min(z + 2, HZ);
    const a = [left(z), y, z];
    const b = [right(z), y, z];
    const c = [right(z1), y, z1];
    const d = [left(z1), y, z1];
    position.push(...a, ...d, ...b, ...b, ...d, ...c);
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute("position", new THREE.Float32BufferAttribute(position, 3));
  geometry.computeVertexNormals();
  return geometry;
}

/** An upright wall along z at x = at(z), from y0 to y1. */
function wallZ(at: (z: number) => number, y0: number, y1: number) {
  const position: number[] = [];
  for (let z = -HZ; z < HZ; z += 2) {
    const z1 = Math.min(z + 2, HZ);
    const a = [at(z), y0, z];
    const b = [at(z), y1, z];
    const c = [at(z1), y1, z1];
    const d = [at(z1), y0, z1];
    position.push(...a, ...b, ...d, ...d, ...b, ...c);
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute("position", new THREE.Float32BufferAttribute(position, 3));
  geometry.computeVertexNormals();
  return geometry;
}

/** Whether a riverside z falls under one of the road bridges. */
function onBridge(z: number): boolean {
  return ALONG_X.some((road) => Math.abs(z - road.at) < road.half + road.walk + 0.6);
}

const bankWall = mats.concrete.clone();
bankWall.side = THREE.DoubleSide;
const skirt = mats.earth;

// --- placement ------------------------------------------------------------------

interface Rect {
  x0: number;
  x1: number;
  z0: number;
  z1: number;
}

/** The yaw that points a model's local +x (a building's front) along (fx, fz). */
function front(fx: number, fz: number): number {
  return Math.atan2(-fz, fx);
}

/** The yaw that points a model's local -z (a vehicle's nose) along (tx, tz). */
function nose(tx: number, tz: number): number {
  return Math.atan2(-tx, -tz);
}

function overlaps(a: Rect, b: Rect): boolean {
  return a.x0 < b.x1 && a.x1 > b.x0 && a.z0 < b.z1 && a.z1 > b.z0;
}

function wet(rect: Rect, margin = 0): boolean {
  for (const z of [rect.z0, (rect.z0 + rect.z1) / 2, rect.z1]) {
    const river = riverX(z);
    if (rect.x1 > river - BANK - margin && rect.x0 < river + BANK + margin) return true;
  }
  return false;
}

interface Built {
  object: THREE.Object3D;
  /** Pavement life in front of it: parked bikes, a cart, a customer. */
  busy: number;
}

type Pick = (roll: () => number, depth: number) => Built;

const shop = (object: THREE.Object3D, busy: number): Built => ({ object, busy });

/** What lines each kind of frontage, by weight. */
const FRONTAGE: Record<Kind | "gang", [number, Pick][]> = {
  raya: [
    [
      6,
      (roll, depth) =>
        shop(ruko(roll() * 0.3 + 0.7, 5 + roll() * 2, Math.min(depth - 1.8, 12)), 0.9),
    ],
    [1.2, (roll) => shop(minimarket(roll()), 1)],
    [1, (roll) => shop(warung(roll()), 1)],
    [0.8, (roll) => shop(bengkel(roll()), 0.6)],
    [0.6, (roll, depth) => shop(house(roll(), 8 + roll() * 3, depth - 1), 0.2)],
  ],
  jalan: [
    [4, (roll, depth) => shop(ruko(roll(), 4.5 + roll() * 2, Math.min(depth - 1.8, 11)), 0.8)],
    [2, (roll) => shop(warung(roll()), 1)],
    [3, (roll, depth) => shop(house(roll(), 7 + roll() * 4, depth - 0.8), 0.25)],
    [1, (roll) => shop(kos(roll()), 0.4)],
    [0.5, (roll) => shop(minimarket(roll()), 1)],
    [0.5, (roll) => shop(bengkel(roll()), 0.6)],
  ],
  lokal: [
    [4, (roll, depth) => shop(house(roll(), 6.5 + roll() * 4, depth - 0.6), 0.3)],
    [2, (roll) => shop(warung(roll()), 1)],
    [1.5, (roll) => shop(kos(roll()), 0.4)],
    [1.2, (roll) => shop(petak(roll()), 0.3)],
    [1.2, (roll, depth) => shop(ruko(roll(), 4.5 + roll() * 2, Math.min(depth - 1.8, 9)), 0.7)],
  ],
  gang: [
    [5, (roll, depth) => shop(house(roll(), 6 + roll() * 3.5, depth - 0.5), 0.2)],
    [2.6, (roll) => shop(petak(roll()), 0.25)],
    [0.8, (roll) => shop(kos(roll()), 0.3)],
    [0.6, (roll) => shop(warung(roll()), 0.8)],
  ],
};

function choose<T>(roll: () => number, table: [number, T][]): T {
  const total = table.reduce((sum, [weight]) => sum + weight, 0);
  let at = roll() * total;
  for (const [weight, value] of table) {
    at -= weight;
    if (at <= 0) return value;
  }
  return table[table.length - 1]![1];
}

const STREET_TREES = [palm, mangga, kamboja, flamboyan, pepaya, banana];
const BANK_TREES = [palm, bambu, banana, mangga, palm];

// --- vehicles and people --------------------------------------------------------

interface Variant {
  meshes: THREE.InstancedMesh[];
  length: number;
  count: number;
}

/** One model, baked once, drawn as many times as there are movers using it. */
function variant(object: THREE.Object3D, capacity: number): Variant {
  const length = new THREE.Box3().setFromObject(object).getSize(new THREE.Vector3()).z;
  const baked = bake(object);
  const meshes = baked.children.map((child) => {
    const mesh = child as THREE.Mesh;
    const instanced = new THREE.InstancedMesh(mesh.geometry, mesh.material, capacity);
    instanced.castShadow = true;
    instanced.receiveShadow = true;
    instanced.frustumCulled = false;
    instanced.count = 0;
    return instanced;
  });
  return { meshes, length, count: 0 };
}

interface Lane {
  axis: "x" | "z";
  fixed: number;
  dir: 1 | -1;
  /** Stop lines, in metres along the lane. */
  stops: number[];
  movers: Mover[];
  people: boolean;
}

interface Mover {
  lane: Lane;
  variant: Variant;
  slot: number;
  s: number;
  v: number;
  top: number;
  length: number;
  jitter: number;
  phase: number;
}

const SPAN = { x: 2 * HX, z: 2 * HZ };

function lanePoint(lane: Lane, s: number, jitter: number): [number, number] {
  const from = lane.axis === "x" ? -HX : -HZ;
  const to = -from;
  const along = lane.dir > 0 ? from + s : to - s;
  return lane.axis === "x" ? [along, lane.fixed + jitter] : [lane.fixed + jitter, along];
}

// --- the town -------------------------------------------------------------------

const BODIES: Body["$"][] = ["Sedan", "Sedan", "Hatch", "Hatch", "Taxi", "Van", "Bus", "Truck"];

export function townView(seed: number): View {
  const group = new THREE.Group();
  const still = new THREE.Group();
  const roll = random(seed);
  const reserved: Rect[] = [];

  const add = (object: THREE.Object3D, x: number, y: number, z: number, yaw = 0) => {
    object.position.set(x, y, z);
    object.rotation.y = yaw;
    still.add(object);
    return object;
  };

  /** Place a landmark and keep the ground under it for itself. */
  const landmark = (object: THREE.Object3D, x: number, z: number, yaw: number, margin = 1.5) => {
    add(object, x, 0, z, yaw);
    object.updateMatrixWorld(true);
    const bounds = new THREE.Box3().setFromObject(object);
    reserved.push({
      x0: bounds.min.x - margin,
      x1: bounds.max.x + margin,
      z0: bounds.min.z - margin,
      z1: bounds.max.z + margin,
    });
  };

  const free = (rect: Rect) => !wet(rect) && !reserved.some((other) => overlaps(rect, other));
  const tree = (x: number, z: number, kinds = STREET_TREES) => {
    const kind = kinds[Math.floor(roll() * kinds.length)]!;
    add(kind(roll()), x, 0, z, roll() * 6);
  };

  // --- ground, river and the diorama's edge ------------------------------------

  const west = (z: number) => riverX(z) - WALL;
  const east = (z: number) => riverX(z) + WALL;
  still.add(
    new THREE.Mesh(
      stripZ(() => -HX, west, 0),
      mats.ground,
    ),
  );
  still.add(
    new THREE.Mesh(
      stripZ(east, () => HX, 0),
      mats.ground,
    ),
  );
  still.add(
    new THREE.Mesh(
      stripZ(
        (z) => riverX(z) - WATER,
        (z) => riverX(z) + WATER,
        -1.4,
      ),
      mats.water,
    ),
  );
  still.add(
    new THREE.Mesh(
      stripZ(west, (z) => riverX(z) - WATER, -0.6),
      mats.concrete,
    ),
  );
  still.add(
    new THREE.Mesh(
      stripZ((z) => riverX(z) + WATER, east, -0.6),
      mats.concrete,
    ),
  );
  still.add(new THREE.Mesh(wallZ(west, -0.6, 0), bankWall));
  still.add(new THREE.Mesh(wallZ(east, -0.6, 0), bankWall));
  still.add(
    new THREE.Mesh(
      wallZ((z) => riverX(z) - WATER, -1.6, -0.6),
      bankWall,
    ),
  );
  still.add(
    new THREE.Mesh(
      wallZ((z) => riverX(z) + WATER, -1.6, -0.6),
      bankWall,
    ),
  );
  // Riverside paths, painted in bands like Jodipan.
  still.add(
    new THREE.Mesh(
      stripZ((z) => west(z) - 3.2, west, 0.04),
      mats.paving,
    ),
  );
  still.add(
    new THREE.Mesh(
      stripZ(east, (z) => east(z) + 3.2, 0.04),
      mats.paving,
    ),
  );
  for (const side of [-1, 1]) {
    for (let z = -HZ + 2; z < HZ; z += 2.5) {
      if (onBridge(z)) continue;
      const x = riverX(z) + side * (WALL - 0.2);
      piece(still, [0.2, 0.9, 0.2], tarps[Math.floor(Math.abs(z) / 2.5) % tarps.length]!, [
        x,
        0.45,
        z,
      ]);
    }
    const rail: THREE.Vector3[] = [];
    for (let z = -HZ; z <= HZ; z += 4)
      rail.push(new THREE.Vector3(riverX(z) + side * (WALL - 0.2), 0.9, z));
    for (let k = 0; k + 1 < rail.length; k += 1) {
      if (onBridge(rail[k]!.z) || onBridge(rail[k + 1]!.z)) continue;
      span(still, rail[k]!, rail[k + 1]!, 0.12, mats.white);
    }
  }

  // The base: a slab of earth under everything, cut where the river runs out.
  for (const z of [-HZ, HZ]) {
    const river = riverX(z);
    const out = z > 0 ? 0.6 : -0.6;
    piece(still, [river - WALL + HX, 8, 1.2], skirt, [(-HX + river - WALL) / 2, -4, z + out]);
    piece(still, [HX - river - WALL, 8, 1.2], skirt, [(HX + river + WALL) / 2, -4, z + out]);
    piece(still, [WALL * 2, 6.6, 1.2], skirt, [river, -4.7, z + out]);
  }
  for (const x of [-HX, HX])
    piece(still, [1.2, 8, 2 * HZ + 2.4], skirt, [x + (x > 0 ? 0.6 : -0.6), -4, 0]);

  // --- roads ---------------------------------------------------------------------

  const crossings = (road: Road) => (road.axis === "x" ? ALONG_Z : ALONG_X);
  /** The stretches of a road between the junctions on it. */
  const stretches = (road: Road): [number, number][] => {
    const limit = road.axis === "x" ? HX : HZ;
    const cuts = crossings(road)
      .map(
        (other) =>
          [other.at - other.half - other.walk, other.at + other.half + other.walk] as const,
      )
      .sort((a, b) => a[0] - b[0]);
    const out: [number, number][] = [];
    let start = -limit;
    for (const [a, b] of cuts) {
      out.push([start, a]);
      start = b;
    }
    out.push([start, limit]);
    return out;
  };
  /** A box laid along a road: `from`..`to` along it, `l0`..`l1` across it. */
  const along = (
    road: Road,
    from: number,
    to: number,
    l0: number,
    l1: number,
    y0: number,
    y1: number,
    material: THREE.Material,
  ) => {
    const length = to - from;
    const across = l1 - l0;
    const mid = (from + to) / 2;
    const lateral = road.at + (l0 + l1) / 2;
    const size: [number, number, number] =
      road.axis === "x" ? [length, y1 - y0, across] : [across, y1 - y0, length];
    const at: [number, number, number] =
      road.axis === "x" ? [mid, (y0 + y1) / 2, lateral] : [lateral, (y0 + y1) / 2, mid];
    return piece(still, size, material, at);
  };

  for (const road of ROADS) {
    const limit = road.axis === "x" ? HX : HZ;
    const top = road.axis === "x" ? 0.06 : 0.068;
    along(road, -limit, limit, -road.half, road.half, -0.3, top, mats.asphalt);
    for (const [a, b] of stretches(road)) {
      for (const side of [-1, 1]) {
        const inner = side * road.half;
        const outer = side * (road.half + road.walk);
        along(road, a, b, Math.min(inner, outer), Math.max(inner, outer), -0.3, 0.2, mats.walk);
        along(
          road,
          a,
          b,
          Math.min(inner, inner + side * 0.25),
          Math.max(inner, inner + side * 0.25),
          -0.3,
          0.22,
          mats.kerb,
        );
        // A solid edge line.
        const edge = side * (road.half - 0.35);
        along(road, a + 0.5, b - 0.5, edge - 0.08, edge + 0.08, top, top + 0.012, mats.paint);
      }
      // Dashes: the centre of a two-way road, the dividers on the boulevard.
      const dashes = road.kind === "raya" ? [-4.1, 4.1] : [0];
      for (const lateral of dashes) {
        for (let s = a + 2; s + 3 < b - 1; s += 8)
          along(road, s, s + 3, lateral - 0.08, lateral + 0.08, top, top + 0.012, mats.paint);
      }
      // The boulevard's median: a kerbed strip of grass with palms and lamps.
      if (road.kind === "raya") {
        along(road, a + 1, b - 1, -0.9, 0.9, 0, 0.3, mats.kerb);
        along(road, a + 1.3, b - 1.3, -0.65, 0.65, 0, 0.36, mats.grass);
        for (let s = a + 6; s < b - 4; s += 10) {
          const [x, z] = road.axis === "x" ? [s, road.at] : [road.at, s];
          if (Math.abs(x - riverX(z)) < WALL + 2) continue;
          if (Math.floor(s / 10) % 2) add(palm(roll()), x, 0.36, z, roll() * 6);
          else {
            add(lampu(), x, 0.36, z, Math.PI / 2);
            add(lampu(), x, 0.36, z, -Math.PI / 2);
          }
        }
      }
      // Zebra crossings at both ends of each stretch.
      if (road.kind !== "lokal") {
        for (const s of [a + 2.2, b - 2.2]) {
          if (Math.abs(s) >= limit - 3) continue;
          for (let l = -road.half + 0.6; l < road.half - 0.4; l += 1.1)
            along(road, s - 1.6, s + 1.6, l, l + 0.55, top, top + 0.014, mats.paint);
        }
      }
    }

    // Bridge parapets where an x road crosses the river.
    if (road.axis === "x") {
      const river = riverX(road.at);
      for (const side of [-1, 1]) {
        const l = side * (road.half + road.walk + 0.2);
        along(road, river - WALL - 1, river + WALL + 1, l - 0.25, l + 0.25, 0, 1.1, mats.white);
        for (let x = river - WALL; x <= river + WALL; x += 2) {
          along(
            road,
            x - 0.3,
            x + 0.3,
            l - 0.3,
            l + 0.3,
            1.1,
            1.4,
            tarps[Math.floor(x) % tarps.length]!,
          );
        }
      }
      along(
        road,
        river - WALL - 0.5,
        river + WALL + 0.5,
        -road.half - road.walk,
        road.half + road.walk,
        -1.4,
        -0.3,
        mats.concrete,
      );
    }
  }

  // Footbridges over the river, painted.
  for (const z of [-38, 38, 100]) {
    const river = riverX(z);
    piece(still, [WALL * 2 + 2, 0.3, 2.4], tarps[(z + 200) % tarps.length]!, [river, 0.4, z]);
    for (const side of [-1, 1])
      piece(still, [WALL * 2 + 2, 0.9, 0.12], mats.yellow, [river, 0.95, z + side * 1.15]);
  }

  // Lights and umbul-umbul at every junction.
  for (const a of ALONG_X) {
    for (const b of ALONG_Z) {
      const x = b.at;
      const z = a.at;
      const ox = b.half + b.walk - 0.6;
      const oz = a.half + a.walk - 0.6;
      add(lampuMerah(roll()), x - ox, 0.2, z - oz, front(0, 1));
      add(lampuMerah(roll()), x + ox, 0.2, z + oz, front(0, -1));
      add(lampuMerah(roll()), x + ox, 0.2, z - oz, front(-1, 0));
      add(lampuMerah(roll()), x - ox, 0.2, z + oz, front(1, 0));
      reserved.push({ x0: x - ox - 4, x1: x + ox + 4, z0: z - oz - 4, z1: z + oz + 4 });
    }
  }

  // --- landmarks -------------------------------------------------------------------

  // The alun-alun: a square of grass with two fenced banyans, the masjid agung
  // on its west side.
  landmark(masjid(0.3 + roll() * 0.2), -88, -37, front(1, 0));
  {
    const square = { x0: -70, x1: -47, z0: -62, z1: -13 };
    const cx = (square.x0 + square.x1) / 2;
    const cz = (square.z0 + square.z1) / 2;
    piece(still, [square.x1 - square.x0, 0.12, square.z1 - square.z0], mats.field, [cx, 0.06, cz]);
    piece(still, [square.x1 - square.x0, 0.14, 2.4], mats.paving, [cx, 0.07, cz]);
    piece(still, [2.4, 0.14, square.z1 - square.z0], mats.paving, [cx, 0.07, cz]);
    for (const dz of [-12, 12]) {
      add(beringin(roll()), cx, 0, cz + dz);
      for (let k = 0; k < 16; k += 1) {
        const angle = (k / 16) * Math.PI * 2;
        piece(still, [0.15, 1, 0.15], mats.white, [
          cx + Math.cos(angle) * 4,
          0.5,
          cz + dz + Math.sin(angle) * 4,
        ]);
      }
    }
    flag(still, [cx, 0, cz], 12);
    for (let k = 0; k < 3; k += 1)
      add(tenda(roll()), square.x0 + 5 + k * 7, 0, square.z0 + 3, front(0, -1));
    for (let k = 0; k < 14; k += 1) {
      const z = square.z0 + 2 + k * 3.5;
      add(k % 3 ? gerobak(roll()) : payung(roll()), square.x1 - 1, 0, z, front(-1, 0));
      add(k % 2 ? kamboja(roll()) : flamboyan(roll()), square.x0 + 1.5, 0, z);
    }
    for (let k = 0; k < 40; k += 1) {
      const person = [pejalan, ibu, anak, pedagang][k % 4]!(roll());
      add(
        person,
        square.x0 + 3 + roll() * (square.x1 - square.x0 - 6),
        0.12,
        square.z0 + 2 + roll() * (square.z1 - square.z0 - 4),
        roll() * 6,
      );
    }
    reserved.push({ x0: square.x0 - 2, x1: square.x1 + 2, z0: square.z0 - 2, z1: square.z1 + 2 });
  }

  landmark(pasar(roll()), -72, 27, front(0, -1));
  for (let k = 0; k < 6; k += 1) add(angkot(roll()), -86 + k * 5.2, 0.2, 8.9, nose(1, 0));
  for (let k = 0; k < 18; k += 1) {
    add(
      [pejalan, ibu, pedagang][k % 3]!(roll()),
      -88 + roll() * 32,
      0.3,
      15 + roll() * 22,
      roll() * 6,
    );
  }
  landmark(klenteng(roll()), -55, 53, front(1, 0));
  landmark(sekolah(roll()), -129, 40, front(1, 0));
  for (let k = 0; k < 16; k += 1)
    add(anak(roll()), -119 + roll() * 6, 0, 26 + roll() * 28, roll() * 6);
  landmark(lapangan(), -140, -37, 0);
  for (let k = 0; k < 14; k += 1)
    add(anak(roll()), -160 + roll() * 40, 0.1, -50 + roll() * 26, roll() * 6);
  landmark(puskesmas(), -24, -52, front(-1, 0));
  landmark(spbu(), 136, 26, front(0, -1));
  landmark(mal(roll()), 138, -38, front(0, 1));
  landmark(kantor(0.2 + roll() * 0.3), 82, -50, front(-1, 0));
  landmark(kantor(0.6 + roll() * 0.4), 82, -24, front(-1, 0));
  landmark(apartemen(roll()), 124, -98, front(0, 1));
  landmark(apartemen(roll()), 153, -98, front(0, 1));
  landmark(rusun(roll()), 77, 25, front(1, 0));
  landmark(rusun(roll()), 77, 55, front(1, 0));
  landmark(gereja(roll()), 136, 100, front(0, -1));
  landmark(tugu(), 82, 100, 0);
  landmark(masjidJawa(roll()), 51, -98, front(-1, 0));
  landmark(pendopo(roll()), -142, 100, front(0, -1));
  landmark(gudang(roll()), -152, -97, front(0, 1));
  landmark(gudang(roll()), -128, -97, front(0, 1), 0.5);

  // --- blocks ------------------------------------------------------------------

  const sideOf = (roads: Road[], limit: number) => {
    const cuts: { at: number; road: Road | null }[] = [
      { at: -limit, road: null },
      ...roads.map((road) => ({ at: road.at, road })),
      { at: limit, road: null },
    ];
    return cuts;
  };
  const xCuts = sideOf(ALONG_Z, HX);
  const zCuts = sideOf(ALONG_X, HZ);
  const edge = (cut: { at: number; road: Road | null }, sign: number) =>
    cut.road ? cut.at + sign * (cut.road.half + cut.road.walk) : cut.at + sign * 1;

  /** One row of lots facing (fx, fz), its depth across, filled along t. */
  const row = (band: Rect, fx: number, fz: number, kind: Kind | "gang", road: Road | null) => {
    const alongX = fz !== 0;
    const start = alongX ? band.x0 : band.z0;
    const end = alongX ? band.x1 : band.z1;
    const depth = alongX ? band.z1 - band.z0 : band.x1 - band.x0;
    const yaw = front(fx, fz);
    let cursor = start + roll() * 0.6;

    while (cursor < end - 3) {
      let built = choose(roll, FRONTAGE[kind])(roll, depth);
      let bounds = new THREE.Box3().setFromObject(built.object);
      let width = bounds.max.z - bounds.min.z;
      const lotAt = (w: number): Rect =>
        alongX
          ? { x0: cursor, x1: cursor + w, z0: band.z0, z1: band.z1 }
          : { x0: band.x0, x1: band.x1, z0: cursor, z1: cursor + w };
      const fits = () =>
        cursor + width <= end && bounds.max.x - bounds.min.x <= depth + 0.4 && free(lotAt(width));

      // Too big for what is left: squeeze in a narrow house instead.
      if (!fits() && end - cursor > 5) {
        built = shop(house(roll(), Math.min(5 + roll() * 2, end - cursor - 1), depth - 0.6), 0.2);
        bounds = new THREE.Box3().setFromObject(built.object);
        width = bounds.max.z - bounds.min.z;
      }

      if (!fits()) {
        // Leave a gap: a tree in the yard, or the riverbank's own planting.
        const [x, z] = alongX
          ? [cursor + 1.5, (band.z0 + band.z1) / 2]
          : [(band.x0 + band.x1) / 2, cursor + 1.5];
        const spot = { x0: x - 1, x1: x + 1, z0: z - 1, z1: z + 1 };
        if (!reserved.some((other) => overlaps(spot, other))) {
          const river = Math.abs(x - riverX(z));
          if (river > BANK + 0.5) tree(x, z);
          else if (river > WALL + 3.6 && roll() > 0.4) tree(x, z, BANK_TREES);
        }
        cursor += 3;
        continue;
      }

      // Front of the lot: the band's edge on the facing side.
      const frontEdge = alongX ? (fz < 0 ? band.z0 : band.z1) : fx < 0 ? band.x0 : band.x1;
      const middle = cursor + width / 2;
      const q = alongX
        ? new THREE.Vector3(middle, 0, frontEdge - fz * 0.2)
        : new THREE.Vector3(frontEdge - fx * 0.2, 0, middle);
      const offset = new THREE.Vector3(
        bounds.max.x,
        0,
        (bounds.min.z + bounds.max.z) / 2,
      ).applyAxisAngle(UP, yaw);
      add(built.object, q.x - offset.x, 0, q.z - offset.z, yaw);

      // Painted roofs on the riverbank kampung.
      const river = Math.abs(q.x - riverX(q.z));
      if (river < 32 && roll() > 0.35) {
        const paint = tarps[Math.floor(roll() * tarps.length)]!;
        built.object.traverse((node) => {
          if (node instanceof THREE.Mesh && roofs.includes(node.material)) node.material = paint;
        });
      }

      // The pavement in front of a shop fills up.
      if (road && roll() < built.busy) {
        const out = road.walk * 0.55;
        const bikes = 1 + Math.floor(roll() * 4);
        for (let n = 0; n < bikes; n += 1) {
          const t = cursor + 0.8 + n * 0.9;
          if (t > cursor + width) break;
          const [x, z] = alongX ? [t, frontEdge + fz * out] : [frontEdge + fx * out, t];
          add(motorbike(roll()), x, 0.2, z, nose(fx, fz) + (roll() - 0.5) * 0.4);
        }
        if (roll() < 0.35) {
          const t = cursor + width - 1;
          const [x, z] = alongX ? [t, frontEdge + fz * out] : [frontEdge + fx * out, t];
          const stall = [gerobak, payung, cart, tong, pot][Math.floor(roll() * 5)]!;
          add(stall(roll()), x, 0.2, z, yaw + Math.PI);
        }
        if (roll() < 0.5) {
          const t = cursor + roll() * width;
          const [x, z] = alongX ? [t, frontEdge + fz * out * 0.6] : [frontEdge + fx * out * 0.6, t];
          add(
            [pejalan, ibu, anak][Math.floor(roll() * 3)]!(roll()),
            x,
            0.2,
            z,
            yaw + Math.PI + (roll() - 0.5),
          );
        }
      } else if (!road && roll() < 0.3) {
        const t = cursor + 0.6 + roll() * (width - 1.2);
        const [x, z] = alongX ? [t, frontEdge + fz * 1.2] : [frontEdge + fx * 1.2, t];
        add(roll() > 0.5 ? motorbike(roll()) : pot(roll()), x, 0, z, yaw + Math.PI / 2);
      }

      // Leave the roofs' overhangs room, so neighbours meet without overlapping.
      cursor += width + 0.5 + roll() * 0.5;
    }
  };

  for (let i = 0; i + 1 < xCuts.length; i += 1) {
    for (let j = 0; j + 1 < zCuts.length; j += 1) {
      const westCut = xCuts[i]!;
      const eastCut = xCuts[i + 1]!;
      const northCut = zCuts[j]!;
      const southCut = zCuts[j + 1]!;
      const block: Rect = {
        x0: edge(westCut, 1),
        x1: edge(eastCut, -1),
        z0: edge(northCut, 1),
        z1: edge(southCut, -1),
      };
      const depthOf = (road: Road | null) =>
        road?.kind === "raya" ? 14 : road?.kind === "jalan" ? 12 : road ? 10.5 : 9.5;
      const nD = depthOf(northCut.road);
      const sD = depthOf(southCut.road);
      const wD = westCut.road ? depthOf(westCut.road) : 0;
      const eD = eastCut.road ? depthOf(eastCut.road) : 0;

      row({ ...block, z1: block.z0 + nD }, 0, -1, northCut.road?.kind ?? "gang", northCut.road);
      row({ ...block, z0: block.z1 - sD }, 0, 1, southCut.road?.kind ?? "gang", southCut.road);

      // Inside: rows back to back, a gang between each facing pair.
      const inner = { x0: block.x0 + wD, x1: block.x1 - eD };
      const gangs: number[] = [];
      let z = block.z0 + nD;
      const zEnd = block.z1 - sD;
      while (z + 21 <= zEnd) {
        row({ ...inner, z0: z, z1: z + 9 }, 0, 1, "gang", null);
        z += 9;
        gangs.push(z + 1.5);
        z += 3;
        row({ ...inner, z0: z, z1: z + 9 }, 0, -1, "gang", null);
        z += 9;
      }
      if (zEnd - z >= 5) row({ ...inner, z0: z, z1: zEnd }, 0, 1, "gang", null);

      // Gangs: a paved strip, bunting overhead, a gapura where it meets a road.
      for (const gz of gangs) {
        const gang = { x0: inner.x0, x1: inner.x1, z0: gz - 1.5, z1: gz + 1.5 };
        let x = gang.x0;
        while (x < gang.x1) {
          const next = Math.min(x + 6, gang.x1);
          const cell = { ...gang, x0: x, x1: next };
          if (!wet(cell, -BANK + WALL) && !reserved.some((other) => overlaps(cell, other))) {
            piece(still, [next - x, 0.06, 2.6], mats.concrete, [(x + next) / 2, 0.03, gz]);
            if (roll() > 0.55)
              addBunting(
                still,
                new THREE.Vector3(x, 3.6, gz - 1.3),
                new THREE.Vector3(next, 3.6, gz + 1.3),
              );
            if (roll() > 0.82)
              add(
                [motorbike, pot, tong][Math.floor(roll() * 3)]!(roll()),
                (x + next) / 2,
                0.06,
                gz + (roll() - 0.5) * 1.2,
                roll() * 6,
              );
            if (roll() > 0.75)
              add(
                [pejalan, ibu, anak][Math.floor(roll() * 3)]!(roll()),
                (x + next) / 2,
                0.06,
                gz,
                roll() * 6,
              );
          }
          x = next;
        }
        for (const [cut, sign] of [
          [westCut, 1],
          [eastCut, -1],
        ] as const) {
          if (!cut.road) continue;
          const gx = edge(cut, sign) + sign * 0.6;
          const spot = { x0: gx - 1, x1: gx + 1, z0: gz - 4, z1: gz + 4 };
          if (wet(spot) || reserved.some((other) => overlaps(spot, other))) continue;
          add(gapura(roll(), 3.6), gx, 0, gz, front(-sign, 0));
          if (roll() > 0.5) add(posRonda(roll()), gx + sign * 2.4, 0, gz + 3.6, front(-sign, 0));
        }
      }

      // Columns along side roads, open where each gang comes out.
      for (const [cut, sign, d] of [
        [westCut, 1, wD],
        [eastCut, -1, eD],
      ] as const) {
        if (!cut.road) continue;
        const x0 = sign > 0 ? block.x0 : block.x1 - d;
        const stops = [
          block.z0 + nD,
          ...gangs.flatMap((gz) => [gz - 1.5 - 0.6, gz + 1.5 + 0.6]),
          zEnd,
        ];
        for (let k = 0; k + 1 < stops.length; k += 2) {
          row(
            { x0, x1: x0 + d, z0: stops[k]!, z1: stops[k + 1]! },
            -sign,
            0,
            cut.road.kind,
            cut.road,
          );
        }
      }
    }
  }

  // Power poles down every non-boulevard road, wires between them; baliho and
  // halte along the boulevard.
  for (const road of ROADS) {
    const limit = road.axis === "x" ? HX : HZ;
    if (road.kind === "raya") {
      for (let s = -limit + 20; s < limit - 10; s += 46) {
        for (const side of [-1, 1]) {
          const l = road.at + side * (road.half + road.walk - 0.9);
          const spot = { x0: s - 4, x1: s + 4, z0: l - 1, z1: l + 1 };
          if (wet(spot) || reserved.some((other) => overlaps(spot, other))) continue;
          if ((s / 46 + side) % 2) add(halte(roll()), s, 0.2, l, front(0, -side));
          else add(umbul(roll()), s, 0.2, l, front(0, -side));
        }
      }
      for (let s = -limit + 40; s < limit; s += 70) {
        const l = road.at + (road.half + road.walk + 3);
        add(baliho(roll()), s, 0, l + 4, front(0, -1));
      }
      continue;
    }
    const lateral = road.half + 0.3;
    const poles: THREE.Vector3[] = [];
    for (let s = -limit + 4; s < limit; s += 15) {
      const [x, z] = road.axis === "x" ? [s, road.at - lateral] : [road.at - lateral, s];
      const near = crossings(road).some(
        (other) => Math.abs(s - other.at) < other.half + other.walk + 2,
      );
      if (near || Math.abs(x - riverX(z)) < WALL + 1) {
        poles.push(new THREE.Vector3(Number.NaN, 0, 0));
        continue;
      }
      add(powerPole(), x, 0.2, z, road.axis === "x" ? 0 : Math.PI / 2);
      poles.push(new THREE.Vector3(x, 0, z));
    }
    for (let k = 0; k + 1 < poles.length; k += 1) {
      const a = poles[k]!;
      const b = poles[k + 1]!;
      if (Number.isNaN(a.x) || Number.isNaN(b.x)) continue;
      for (const [height, offset] of [
        [7.0, 0.6],
        [7.4, -0.4],
        [6.5, 0.2],
      ] as const) {
        const shift =
          road.axis === "x" ? new THREE.Vector3(0, 0, offset) : new THREE.Vector3(offset, 0, 0);
        span(
          still,
          a.clone().add(shift).setY(height),
          b
            .clone()
            .add(shift)
            .setY(height - 0.05),
          0.04,
          mats.wire,
        );
      }
      if (road.kind === "lokal" && roll() > 0.5) {
        const across =
          road.axis === "x"
            ? new THREE.Vector3(0, 0, 2 * lateral)
            : new THREE.Vector3(2 * lateral, 0, 0);
        addBunting(still, a.clone().setY(5.2), b.clone().add(across).setY(5.2));
      }
    }
  }

  // Hedges and flowers along the riverside paths.
  for (let z = -HZ + 4; z < HZ - 4; z += 6 + roll() * 6) {
    for (const side of [-1, 1]) {
      const x = riverX(z) + side * (WALL + 4.2);
      const spot = { x0: x - 1, x1: x + 1, z0: z - 2, z1: z + 2 };
      if (
        reserved.some((other) => overlaps(spot, other)) ||
        ROADS.some((road) => road.axis === "x" && Math.abs(z - road.at) < road.half + road.walk + 2)
      )
        continue;
      if (roll() > 0.5)
        add(semak(roll(), 2.5), x, 0, z, Math.PI / 2 + Math.atan2(1, (13 * Math.cos(z / 34)) / 34));
      else add(pejalan(roll()), riverX(z) + side * (WALL + 1.5), 0.04, z, roll() * 6);
    }
  }

  still.traverse((node) => {
    if (node instanceof THREE.Mesh) {
      node.castShadow = true;
      node.receiveShadow = true;
    }
  });
  const baked = bake(still);
  group.add(baked);

  // --- traffic -------------------------------------------------------------------

  const lanes: Lane[] = [];
  for (const road of ROADS) {
    for (const dir of [1, -1] as const) {
      for (const offset of road.lanes) {
        // Keep left: eastbound and southbound run on the -z and +x sides.
        const lateral = road.axis === "x" ? -dir * offset : dir * offset;
        const from = road.axis === "x" ? -HX : -HZ;
        const to = -from;
        const stops = crossings(road).map((other) => {
          const line =
            dir > 0
              ? other.at - other.half - other.walk - 0.6
              : other.at + other.half + other.walk + 0.6;
          return dir > 0 ? line - from : to - line;
        });
        lanes.push({
          axis: road.axis,
          fixed: road.at + lateral,
          dir,
          stops,
          movers: [],
          people: false,
        });
      }
      // People on the pavements, both ways.
      const walk = road.half + road.walk / 2;
      lanes.push({
        axis: road.axis,
        fixed: road.at + dir * walk,
        dir: roll() > 0.5 ? 1 : -1,
        stops: [],
        movers: [],
        people: true,
      });
    }
  }

  // Vehicle kinds by road, by weight. Each entry builds a variant lazily.
  const variants = new Map<string, Variant>();
  const CAPACITY = 160;
  const make = (key: string, build: () => THREE.Object3D) => {
    let found = variants.get(key);
    if (!found) {
      found = variant(build(), CAPACITY);
      variants.set(key, found);
      for (const mesh of found.meshes) group.add(mesh);
    }
    return found;
  };
  const car = () => {
    const body = BODIES[Math.floor(roll() * BODIES.length)]!;
    const colour = Math.floor(roll() * 5);
    return make(
      `car:${body}:${colour}`,
      () => buildCar(body, trafficColour(colour * 2 + 1), bodyLength(body)).group,
    );
  };
  const ride = (name: string, build: (seed: number) => THREE.Object3D, kinds = 3) => {
    const which = Math.floor(roll() * kinds);
    return make(`${name}:${which}`, () => build((which + 0.5) / kinds));
  };
  const MIX: Record<Kind, [number, () => Variant][]> = {
    raya: [
      [5, car],
      [3, () => ride("ojek", ojek, 4)],
      [1.6, () => ride("motor", motorbike, 4)],
      [0.9, () => ride("angkot", angkot, 4)],
      [0.4, () => ride("metromini", metromini, 2)],
      [0.4, () => ride("pickup", pickup, 2)],
    ],
    jalan: [
      [3, car],
      [3, () => ride("ojek", ojek, 4)],
      [2, () => ride("motor", motorbike, 4)],
      [1.2, () => ride("angkot", angkot, 4)],
      [0.5, () => ride("bajaj", bajaj, 2)],
      [0.4, () => ride("pickup", pickup, 2)],
    ],
    lokal: [
      [4, () => ride("motor", motorbike, 4)],
      [2, () => ride("ojek", ojek, 4)],
      [1, () => ride("becak", becak, 3)],
      [0.7, () => ride("bajaj", bajaj, 2)],
      [0.6, () => ride("angkot", angkot, 4)],
      [0.5, car],
    ],
  };
  const WALKERS: [number, () => Variant][] = [
    [3, () => ride("pejalan", pejalan, 6)],
    [2, () => ride("ibu", ibu, 4)],
    [1.2, () => ride("anak", anak, 3)],
    [0.6, () => ride("pedagang", pedagang, 2)],
  ];

  const movers: Mover[] = [];
  for (const lane of lanes) {
    const road = ROADS.find(
      (r) => r.axis === lane.axis && Math.abs(lane.fixed - r.at) <= r.half + r.walk,
    )!;
    const length = SPAN[lane.axis];
    let s = roll() * 6;
    while (s < length - 6) {
      const chosen = choose(roll, lane.people ? WALKERS : MIX[road.kind])();
      if (chosen.count >= CAPACITY) break;
      const slot = chosen.count;
      chosen.count += 1;
      const small = chosen.length < 2.6;
      const top = lane.people ? 1.1 + roll() * 0.5 : small ? 9 + roll() * 3 : 7.5 + roll() * 3;
      const mover: Mover = {
        lane,
        variant: chosen,
        slot,
        s,
        v: top,
        top,
        length: chosen.length,
        jitter: lane.people ? (roll() - 0.5) * (road.walk - 0.8) : small ? (roll() - 0.5) * 1.6 : 0,
        phase: roll() * 10,
      };
      lane.movers.push(mover);
      movers.push(mover);
      s +=
        chosen.length + (lane.people ? 2 + roll() * 9 : small ? 1.5 + roll() * 6 : 4 + roll() * 12);
    }
  }

  const matrix = new THREE.Matrix4();
  const rotation = new THREE.Quaternion();
  const scale = new THREE.Vector3(1, 1, 1);
  const position = new THREE.Vector3();
  const place = (mover: Mover, time: number) => {
    const [x, z] = lanePoint(mover.lane, mover.s, mover.jitter);
    const lane = mover.lane;
    const yaw = lane.axis === "x" ? nose(lane.dir, 0) : nose(0, lane.dir);
    const bob =
      lane.people && mover.v > 0.2 ? Math.abs(Math.sin(time * 9 + mover.phase)) * 0.08 : 0;
    const height = lane.people ? 0.2 : 0.07;
    position.set(x, height + bob, z);
    // People face +x by default; turn them a quarter more than vehicles.
    rotation.setFromAxisAngle(UP, lane.people ? yaw - Math.PI / 2 : yaw);
    matrix.compose(position, rotation, scale);
    for (const mesh of mover.variant.meshes) mesh.setMatrixAt(mover.slot, matrix);
  };

  for (const found of variants.values()) for (const mesh of found.meshes) mesh.count = found.count;
  let time = 0;
  movers.forEach((mover) => place(mover, 0));

  // Signals: the x roads go, all red, the z roads go, all red.
  const CYCLE = 26;
  const green = (axis: "x" | "z") => {
    const phase = time % CYCLE;
    return axis === "x" ? phase < 11 : phase >= 13 && phase < 24;
  };

  return {
    group,
    bounds: new THREE.Box3(new THREE.Vector3(-HX, -8, -HZ), new THREE.Vector3(HX, 30, HZ)),
    update(dt) {
      time += dt;
      for (const lane of lanes) {
        const length = SPAN[lane.axis];
        const list = lane.movers;
        list.sort((a, b) => a.s - b.s);
        const go = lane.people || green(lane.axis);
        for (let k = 0; k < list.length; k += 1) {
          const mover = list[k]!;
          const leader = list[(k + 1) % list.length]!;
          let gap = leader === mover ? Infinity : leader.s - mover.s;
          if (gap <= 0) gap += length;
          gap -= (leader.length + mover.length) / 2 + (lane.people ? 0.6 : 1.4);
          if (!go) {
            const nose = mover.s + mover.length / 2;
            for (const stop of lane.stops) {
              const ahead = stop - nose;
              if (ahead > -0.4) gap = Math.min(gap, ahead);
            }
          }
          const want = Math.max(0, Math.min(mover.top, gap * 1.1));
          mover.v += (want - mover.v) * Math.min(1, dt * (want < mover.v ? 6 : 1.5));
        }
        for (const mover of list) {
          mover.s += mover.v * dt;
          if (mover.s > length) mover.s -= length;
          place(mover, time);
        }
      }
      for (const found of variants.values())
        for (const mesh of found.meshes) mesh.instanceMatrix.needsUpdate = true;
    },
  };
}
