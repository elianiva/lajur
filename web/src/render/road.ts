import * as THREE from "three";
import { mergeGeometries } from "three/addons/utils/BufferGeometryUtils.js";
import type { RoadPath } from "./path.ts";

/**
 * The street, streamed a chunk at a time.
 *
 * The model generates the road as a pure function of distance, so each 50 m
 * chunk can be built once, baked into one mesh per material, kept in a map and
 * dropped when it falls behind. Everything here is dressing: the lanes, the
 * traffic and the verdict live in the model.
 *
 * The street is an Indonesian arterial: undivided, two lanes each way, white
 * markings, a narrow pavement, and warungs, ruko, parked motorbikes, carts and
 * power lines packed right up to the kerb.
 */

const LANE = 3.25;
const ROAD_HALF = LANE * 2; // 6.5
const SHOULDER = 0.6;
const WALK = 1.4;
const WALK_TOP = 0.16;
const BEHIND = 2;
const AHEAD = 8;
const SAMPLE = 2.5;

const mats = {
  asphalt: new THREE.MeshStandardMaterial({ color: 0x33343a, roughness: 0.97 }),
  patch: new THREE.MeshStandardMaterial({ color: 0x3b3c43, roughness: 0.97 }),
  paint: new THREE.MeshStandardMaterial({ color: 0xece5d2, roughness: 0.85 }),
  concrete: new THREE.MeshStandardMaterial({ color: 0xb9b2a1, roughness: 0.96 }),
  kerb: new THREE.MeshStandardMaterial({ color: 0xcdc6b2, roughness: 0.95 }),
  walk: new THREE.MeshStandardMaterial({ color: 0xd3cbb4, roughness: 0.95 }),
  ground: new THREE.MeshStandardMaterial({ color: 0x8c946f, roughness: 1 }),
  grass: new THREE.MeshStandardMaterial({ color: 0x71934a, roughness: 1 }),
  glass: new THREE.MeshStandardMaterial({ color: 0x44555e, roughness: 0.35, metalness: 0.1 }),
  roof: new THREE.MeshStandardMaterial({ color: 0x8b8478, roughness: 0.9 }),
  tile: new THREE.MeshStandardMaterial({ color: 0xa65a3f, roughness: 0.9 }),
  tin: new THREE.MeshStandardMaterial({ color: 0x9aa0a2, roughness: 0.85 }),
  rust: new THREE.MeshStandardMaterial({ color: 0x9a6b4f, roughness: 0.95 }),
  wood: new THREE.MeshStandardMaterial({ color: 0x8a6a45, roughness: 0.95 }),
  metal: new THREE.MeshStandardMaterial({ color: 0x6f7378, roughness: 0.8 }),
  trunk: new THREE.MeshStandardMaterial({ color: 0x6a5139, roughness: 1 }),
  leaf: new THREE.MeshStandardMaterial({ color: 0x5f9a3c, roughness: 0.95, flatShading: true }),
  leafDeep: new THREE.MeshStandardMaterial({ color: 0x487a2d, roughness: 0.95, flatShading: true }),
  wire: new THREE.MeshStandardMaterial({ color: 0x2a2b2e, roughness: 0.9 }),
};

// Faded paint and corrugated roofs: the palette of every ruko row.
const walls = [
  0xd9c7a4, 0xe3d6b6, 0xc9a184, 0xa9b6a5, 0xd8b98d, 0xb98a6a, 0xe0d3bd, 0x9fb3b5, 0xcaa88e,
].map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.93 }));
const tarps = [0x2f6fb5, 0xd8543f, 0xe0a63c, 0x3f8f6a, 0xb84b8c].map(
  (color) => new THREE.MeshStandardMaterial({ color, roughness: 0.9, side: THREE.DoubleSide }),
);
const signs = [0xd23f34, 0x2f7ec4, 0xe0a63c, 0x2f8f5f].map(
  (color) => new THREE.MeshStandardMaterial({ color, roughness: 0.8 }),
);

interface Sample {
  x: number;
  z: number;
  rx: number;
  rz: number;
  s: number;
}

const boxes = new Map<string, THREE.BoxGeometry>();

function box(width: number, height: number, depth: number): THREE.BoxGeometry {
  const key = `${width}:${height}:${depth}`;
  const cached = boxes.get(key);
  if (cached) return cached;
  const geometry = new THREE.BoxGeometry(width, height, depth);
  boxes.set(key, geometry);
  return geometry;
}

function hash(i: number): number {
  let h = Math.imul(i ^ 0x9e3779b9, 0x85ebca6b) >>> 0;
  h ^= h >>> 13;
  h = Math.imul(h, 0xc2b2ae35) >>> 0;
  return ((h ^ (h >>> 16)) >>> 0) / 0x100000000;
}

function ribbon(
  samples: Sample[],
  latA: number,
  latB: number,
  yA: number,
  yB: number,
  dash?: { on: number; period: number },
): THREE.BufferGeometry {
  const position: number[] = [];
  const indices: number[] = [];
  let vertex = 0;

  for (let i = 0; i < samples.length - 1; i += 1) {
    const a = samples[i]!;
    const b = samples[i + 1]!;
    if (dash && a.s % dash.period >= dash.on) continue;

    position.push(
      a.x + a.rx * latA,
      yA,
      a.z + a.rz * latA,
      a.x + a.rx * latB,
      yB,
      a.z + a.rz * latB,
      b.x + b.rx * latA,
      yA,
      b.z + b.rz * latA,
      b.x + b.rx * latB,
      yB,
      b.z + b.rz * latB,
    );
    indices.push(vertex, vertex + 1, vertex + 2, vertex + 1, vertex + 3, vertex + 2);
    vertex += 4;
  }

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute("position", new THREE.Float32BufferAttribute(position, 3));
  geometry.setIndex(indices);
  geometry.computeVertexNormals();
  geometry.computeBoundingSphere();
  return geometry;
}

function piece(
  parent: THREE.Object3D,
  size: [number, number, number],
  material: THREE.Material,
  at: [number, number, number],
): THREE.Mesh {
  const mesh = new THREE.Mesh(box(...size), material);
  mesh.position.set(...at);
  parent.add(mesh);
  return mesh;
}

// --- props -----------------------------------------------------------------

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
function ruko(seed: number, width: number, depth: number): THREE.Group {
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
function warung(seed: number): THREE.Group {
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
function house(seed: number, width: number, depth: number): THREE.Group {
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

function motorbike(seed: number): THREE.Group {
  const group = new THREE.Group();
  const paint = tarps[Math.floor(seed * 31) % tarps.length]!;
  piece(group, [0.28, 0.32, 1.1], paint, [0, 0.62, 0]);
  piece(group, [0.3, 0.5, 0.5], paint, [0, 0.95, 0.28]);
  piece(group, [0.62, 0.06, 0.06], mats.metal, [0, 1.08, -0.45]);
  for (const z of [-0.55, 0.55]) {
    const wheel = new THREE.Mesh(new THREE.CylinderGeometry(0.27, 0.27, 0.1, 8), mats.wire);
    wheel.rotation.z = Math.PI / 2;
    wheel.position.set(0, 0.27, z);
    group.add(wheel);
  }
  return group;
}

function cart(seed: number): THREE.Group {
  const group = new THREE.Group();
  piece(group, [1.2, 0.7, 1.8], mats.wood, [0, 0.75, 0]);
  piece(group, [1.3, 0.1, 1.9], mats.wood, [0, 1.15, 0]);
  const wheel = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.4, 0.12, 8), mats.wire);
  wheel.rotation.z = Math.PI / 2;
  wheel.position.set(0.55, 0.4, 0);
  group.add(wheel);
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

function palm(seed: number): THREE.Group {
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

function banana(seed: number): THREE.Group {
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

function powerPole(): THREE.Group {
  const group = new THREE.Group();
  const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.16, 7.5, 6), mats.concrete);
  pole.position.y = 3.75;
  group.add(pole);
  piece(group, [0.1, 0.1, 1.6], mats.metal, [0, 6.9, 0]);
  piece(group, [0.1, 0.1, 1.1], mats.metal, [0, 7.3, 0]);
  return group;
}

// --- baking ----------------------------------------------------------------

/**
 * Merges a chunk's meshes into one mesh per material. A busy street is a
 * thousand little boxes; without this the draw calls, not the geometry, are
 * what the frame time goes to.
 */
function bake(group: THREE.Group): THREE.Group {
  group.updateMatrixWorld(true);
  const buckets = new Map<THREE.Material, THREE.BufferGeometry[]>();

  group.traverse((node) => {
    if (!(node instanceof THREE.Mesh)) return;
    const geometry = node.geometry.clone();
    geometry.applyMatrix4(node.matrixWorld);
    // A ribbon carries position and normal; a box also carries uv. Merging
    // demands one attribute set per bucket, so drop everything but the two.
    for (const name of Object.keys(geometry.attributes)) {
      if (name !== "position" && name !== "normal") geometry.deleteAttribute(name);
    }
    if (!geometry.getAttribute("normal")) geometry.computeVertexNormals();
    const bucket = buckets.get(node.material as THREE.Material) ?? [];
    bucket.push(geometry);
    buckets.set(node.material as THREE.Material, bucket);
  });

  const baked = new THREE.Group();
  for (const [material, geometries] of buckets) {
    const merged = mergeGeometries(geometries, false);
    for (const geometry of geometries) geometry.dispose();
    if (!merged) continue;
    const mesh = new THREE.Mesh(merged, material);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    baked.add(mesh);
  }
  return baked;
}

// --- the view --------------------------------------------------------------

export class RoadView {
  readonly group = new THREE.Group();
  private path: RoadPath;
  private built = Number.NaN;
  private chunks = new Map<number, THREE.Group>();

  constructor(path: RoadPath) {
    this.path = path;
  }

  update(index: number): void {
    const from = Math.max(0, index - BEHIND);
    const to = index + AHEAD;

    if (this.built !== index) {
      this.built = index;
      for (const [at, chunk] of this.chunks) {
        if (at < from || at >= to) {
          dispose(chunk);
          this.group.remove(chunk);
          this.chunks.delete(at);
        }
      }
    }

    // A chunk costs more than one frame's budget to bake, so the queue drains a
    // little each frame: ahead first, then behind. This runs even when the car
    // is stopped, or a crash would leave a hole in the street.
    const order: number[] = [];
    for (let at = index; at < to; at += 1) order.push(at);
    for (let at = index - 1; at >= from; at -= 1) order.push(at);

    if (this.chunks.size === 0) {
      for (const at of order) this.fill(at);
      return;
    }

    const budget = performance.now() + 5;
    for (const at of order) {
      if (this.chunks.has(at)) continue;
      this.fill(at);
      if (performance.now() > budget) break;
    }
  }

  private fill(at: number): void {
    if (at < 0 || this.chunks.has(at)) return;
    const chunk = bake(this.chunk(at));
    this.chunks.set(at, chunk);
    this.group.add(chunk);
  }

  private samples(index: number): Sample[] {
    const length = this.path.chunkLength;
    const count = Math.max(1, Math.ceil(length / SAMPLE));
    const out: Sample[] = [];

    for (let part = 0; part <= count; part += 1) {
      const along = (length * part) / count;
      const at = this.path.point(index, along);
      out.push({ x: at.x, z: at.z, rx: Math.cos(at.heading), rz: Math.sin(at.heading), s: along });
    }
    return out;
  }

  private chunk(index: number): THREE.Group {
    const group = new THREE.Group();
    const samples = this.samples(index);

    const paint = (geometry: THREE.BufferGeometry, material: THREE.Material) => {
      group.add(new THREE.Mesh(geometry, material));
    };

    paint(ribbon(samples, -60, 60, -0.15, -0.15), mats.ground);
    paint(ribbon(samples, -ROAD_HALF, ROAD_HALF, 0, 0), mats.asphalt);

    // Shoulder, gutter and the narrow pavement, both sides.
    for (const side of [-1, 1] as const) {
      const edge = side * ROAD_HALF;
      const shoulder = side * (ROAD_HALF + SHOULDER);
      const walk = side * (ROAD_HALF + SHOULDER + WALK);

      paint(ribbon(samples, edge, shoulder, 0.01, 0.01), mats.concrete);
      paint(ribbon(samples, shoulder, walk, WALK_TOP, WALK_TOP), mats.walk);
      paint(ribbon(samples, shoulder, shoulder, WALK_TOP, 0), mats.kerb);
    }

    // White markings: solid edges, dashed centre and lane dividers.
    paint(ribbon(samples, -ROAD_HALF + 0.2, -ROAD_HALF + 0.35, 0.02, 0.02), mats.paint);
    paint(ribbon(samples, ROAD_HALF - 0.35, ROAD_HALF - 0.2, 0.02, 0.02), mats.paint);
    const dash = { on: 3, period: 9 };
    paint(ribbon(samples, -0.09, 0.09, 0.02, 0.02, dash), mats.paint);
    paint(ribbon(samples, -LANE - 0.075, -LANE + 0.075, 0.02, 0.02, dash), mats.paint);
    paint(ribbon(samples, LANE - 0.075, LANE + 0.075, 0.02, 0.02, dash), mats.paint);

    this.scenery(group, index);
    return group;
  }

  private scenery(group: THREE.Group, index: number): void {
    const length = this.path.chunkLength;

    for (const side of [-1, 1] as const) {
      const frontage = side * (ROAD_HALF + SHOULDER + WALK);

      // The row: ruko, warung and houses shoulder to shoulder.
      let cursor = 0.5;
      let unit = 0;
      while (cursor < length - 4) {
        const noise = hash(index * 19 + side * 137 + unit * 11);
        const kind = hash(index + side * 41 + unit * 7);
        const width = kind < 0.35 ? 3.6 : 4.5 + noise * 2.5;
        const depth = 7 + hash(index + unit * 3 + side * 23) * 4;
        const at = this.path.point(index, Math.min(cursor + width / 2, length));
        const offset = frontage + side * (depth / 2 + 1.6);

        const size = kind < 0.28 ? 0 : kind < 0.72 ? 1 : 2;
        const cue = hash(index * 3 + unit + side * 29);
        const building =
          size === 0
            ? warung(cue)
            : size === 1
              ? ruko(cue, width, depth)
              : house(cue, width, depth);

        if (size !== 0) {
          building.position.set(
            at.x + Math.cos(at.heading) * offset,
            0,
            at.z + Math.sin(at.heading) * offset,
          );
          building.rotation.y = -at.heading + (side > 0 ? Math.PI : 0);
          group.add(building);
        } else {
          building.position.set(
            at.x + Math.cos(at.heading) * offset,
            0,
            at.z + Math.sin(at.heading) * offset,
          );
          building.rotation.y = -at.heading + (side > 0 ? Math.PI : 0);
          group.add(building);
        }

        // Parked motorbikes and crates on the shoulder.
        if (noise > 0.35) {
          const bikes = 1 + Math.floor(hash(index + unit * 13) * 3);
          for (let n = 0; n < bikes; n += 1) {
            const bike = motorbike(hash(index + unit * 4 + n));
            const along = Math.min(cursor + 0.9 + n * 0.85, length);
            const spot = this.path.point(index, along);
            const park = frontage + side * 0.9;
            bike.position.set(
              spot.x + Math.cos(spot.heading) * park,
              WALK_TOP,
              spot.z + Math.sin(spot.heading) * park,
            );
            bike.rotation.y = -spot.heading + Math.PI / 2 + 0.2;
            group.add(bike);
          }
        }

        if (noise > 0.8) {
          const trolley = cart(hash(index + unit * 3 + side));
          const spot = this.path.point(index, Math.min(cursor + width + 1, length));
          const park = frontage + side * 1.9;
          trolley.position.set(
            spot.x + Math.cos(spot.heading) * park,
            WALK_TOP,
            spot.z + Math.sin(spot.heading) * park,
          );
          trolley.rotation.y = -spot.heading;
          group.add(trolley);
        }

        cursor += width + 0.8 + hash(index + unit * 9) * 2.4;
        unit += 1;
      }

      // A second row behind the first, so the skyline is not one wall deep.
      let behind = 2;
      while (behind < length - 6) {
        const noise = hash(index * 31 + side * 77 + behind * 5);
        const width = 8 + noise * 8;
        const depth = 8 + hash(index + behind * 3 + side * 13) * 6;
        const at = this.path.point(index, Math.min(behind, length));
        const offset = frontage + side * (12 + depth / 2 + noise * 4);
        const blockOut = house(noise, width, depth);
        blockOut.position.set(
          at.x + Math.cos(at.heading) * offset,
          0.4,
          at.z + Math.sin(at.heading) * offset,
        );
        blockOut.rotation.y = -at.heading + (side > 0 ? Math.PI : 0) + noise * 0.2;
        group.add(blockOut);
        behind += width + 2 + noise * 4;
      }

      // Trees behind the row, and a pole at the kerb.
      for (let planted = 0; planted < 2; planted += 1) {
        const spot = hash(index + side * 31 + planted * 23);
        if (spot < 0.45) continue;
        const at = this.path.point(index, length * (0.25 + planted * 0.45));
        const offset = frontage + side * 2.4;
        const tree = spot > 0.75 ? palm(spot) : banana(spot);
        tree.position.set(
          at.x + Math.cos(at.heading) * offset,
          WALK_TOP,
          at.z + Math.sin(at.heading) * offset,
        );
        group.add(tree);
      }
    }

    // Power poles down the left kerb, wires strung between them.
    const poles: THREE.Vector3[] = [];
    for (let at = 4; at < length; at += 16) {
      const spot = this.path.point(index, at);
      const offset = -(ROAD_HALF + SHOULDER - 0.15);
      const pole = powerPole();
      pole.position.set(
        spot.x + Math.cos(spot.heading) * offset,
        0,
        spot.z + Math.sin(spot.heading) * offset,
      );
      pole.rotation.y = -spot.heading;
      group.add(pole);
      poles.push(pole.position.clone());

      const wire = new THREE.Mesh(box(0.05, 0.05, 0.05), mats.wire);
      wire.position.copy(pole.position).setY(7.2);
      group.add(wire);
    }

    for (let i = 0; i + 1 < poles.length; i += 1) {
      const a = poles[i]!;
      const b = poles[i + 1]!;
      for (const height of [6.85, 7.25]) {
        const from = a.clone().setY(height);
        const to = b.clone().setY(height);
        const span = from.distanceTo(to);
        const wire = new THREE.Mesh(new THREE.BoxGeometry(0.035, 0.035, span), mats.wire);
        wire.position.copy(from).lerp(to, 0.5);
        wire.lookAt(to);
        group.add(wire);
      }
    }

    // Zebra stripes every fourth chunk, and a patched surface.
    if (index % 4 === 0) {
      const band: Sample[] = [];
      const at = length * 0.5;
      for (let step = -1.8; step <= 1.8; step += 0.9) {
        const point = this.path.point(index, at + step);
        band.push({
          x: point.x,
          z: point.z,
          rx: Math.cos(point.heading),
          rz: Math.sin(point.heading),
          s: at + step,
        });
      }
      for (let lateral = -ROAD_HALF + 0.7; lateral < ROAD_HALF - 0.7; lateral += 1.2) {
        group.add(new THREE.Mesh(ribbon(band, lateral, lateral + 0.6, 0.025, 0.025), mats.paint));
      }
    }
  }
}

function dispose(group: THREE.Object3D): void {
  group.traverse((node) => {
    if (node instanceof THREE.Mesh) node.geometry.dispose();
  });
  group.removeFromParent();
}
