import * as THREE from "three";
import { bake, box, mats, roofs, walls } from "../assets/kit.ts";
import {
  bengkel,
  filler,
  gudang,
  house,
  kos,
  minimarket,
  petak,
  ruko,
  warung,
} from "../assets/buildings.ts";
import { powerPole, pot } from "../assets/street.ts";
import { kamboja, mangga, palm, semak } from "../assets/trees.ts";
import * as T from "./model.ts";

/**
 * The town, drawn.
 *
 * Everything here comes from `model.ts`: street centrelines as samples, each
 * approach's carriageway width, its line and its crossing, and every lot with
 * the way its front looks. The file turns those numbers into triangles and
 * nothing else — no placement is decided here.
 *
 * Roads, kerbs and markings go straight into one merged mesh per material. The
 * buildings are built from the asset kit and baked once, because a bird's-eye
 * view of the whole town has to be one scene, not eighty.
 */

const CM = 0.01;
const ASPHALT = 0;
const PAINT = 0.02;
const WALK = 0.16;
/** Steps a kerb return is drawn in. */
const FILLET = 6;

type V3 = [number, number, number];

function cross(a: V3, b: V3): V3 {
  return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
}

/** Triangles with one material, wound so they face the way they should. */
class Batch {
  private positions: number[] = [];
  private indices: number[] = [];
  private count = 0;

  quad(a: V3, b: V3, c: V3, d: V3, hint: V3 = [0, 1, 0]): void {
    const normal = cross(
      [b[0] - a[0], b[1] - a[1], b[2] - a[2]],
      [c[0] - a[0], c[1] - a[1], c[2] - a[2]],
    );
    if (normal[0] * hint[0] + normal[1] * hint[1] + normal[2] * hint[2] < 0) {
      this.triangle(a, c, b);
      this.triangle(a, d, c);
    } else {
      this.triangle(a, b, c);
      this.triangle(a, c, d);
    }
  }

  private triangle(a: V3, b: V3, c: V3): void {
    this.positions.push(...a, ...b, ...c);
    this.indices.push(this.count, this.count + 1, this.count + 2);
    this.count += 3;
  }

  get empty(): boolean {
    return this.count === 0;
  }

  mesh(material: THREE.Material): THREE.Mesh {
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.Float32BufferAttribute(this.positions, 3));
    geometry.setIndex(this.indices);
    geometry.computeVertexNormals();
    const mesh = new THREE.Mesh(geometry, material);
    mesh.receiveShadow = true;
    return mesh;
  }
}

/** A point on a street's polyline, `distance` centimetres from its start. */
function alongStreet(samples: T.Sample[], distance: number): T.Sample {
  let walked = 0;
  for (let k = 0; k + 1 < samples.length; k += 1) {
    const a = samples[k]!;
    const b = samples[k + 1]!;
    const step = Math.hypot(b.x - a.x, b.z - a.z);
    if (walked + step >= distance && step > 0) {
      const t = (distance - walked) / step;
      return {
        x: a.x + (b.x - a.x) * t,
        z: a.z + (b.z - a.z) * t,
        dx: b.dx,
        dz: b.dz,
      };
    }
    walked += step;
  }
  return samples[samples.length - 1]!;
}

function normalAt(s: T.Sample): [number, number] {
  const length = Math.hypot(s.dx, s.dz) || 1;
  return [-s.dz / length, s.dx / length];
}

/** The street as drawn: from its mouth at one junction to its mouth at the
 * other, so no ribbon reaches into the junction box. A sample the mouth has
 * already passed is dropped, or the ribbon would double back on itself. */
function trimmed(
  samples: T.Sample[],
  from: T.Pt,
  to: T.Pt,
  start: number,
  end: number,
): T.Sample[] {
  const at = (k: number) =>
    k === 0 ? 0 : Math.hypot(samples[k]!.x - samples[k - 1]!.x, samples[k]!.z - samples[k - 1]!.z);
  let total = 0;
  for (let k = 1; k < samples.length; k += 1) total += at(k);
  const inside: T.Sample[] = [];
  let walked = 0;
  for (let k = 0; k < samples.length; k += 1) {
    walked += at(k);
    if (walked > start && walked < total - end) inside.push(samples[k]!);
  }
  const head: T.Sample = { ...samples[0]!, x: from.x, z: from.z };
  const tail: T.Sample = { ...samples[samples.length - 1]!, x: to.x, z: to.z };
  return [head, ...inside, tail];
}

/** A quadratic fillet from `a` to `b` bending towards `c`, the square corner. */
function fillet(a: V3, c: V3, b: V3, t: number): V3 {
  const u = 1 - t;
  return [
    u * u * a[0] + 2 * u * t * c[0] + t * t * b[0],
    a[1],
    u * u * a[2] + 2 * u * t * c[2] + t * t * b[2],
  ];
}

/** The way an edge of the junction boundary faces at `k`: the side away from
 * the node, which is where the pavement goes. */
function edgeNormal(edge: V3[], k: number, centre: V3): [number, number] {
  const a = edge[Math.max(0, k - 1)]!;
  const b = edge[Math.min(edge.length - 1, k + 1)]!;
  const dx = b[0] - a[0];
  const dz = b[2] - a[2];
  const length = Math.hypot(dx, dz) || 1;
  const nx = -dz / length;
  const nz = dx / length;
  const p = edge[k]!;
  const out = nx * (p[0] - centre[0]) + nz * (p[2] - centre[2]) > 0 ? 1 : -1;
  return [nx * out, nz * out];
}

/** A strip along a street between two lateral offsets, in centimetres. */
function strip(
  batch: Batch,
  samples: T.Sample[],
  inner: number,
  outer: number,
  y: number,
  from = 0,
  to = samples.length - 1,
): void {
  for (let k = from; k < to; k += 1) {
    const a = samples[k]!;
    const b = samples[k + 1]!;
    const na = normalAt(a);
    const nb = normalAt(b);
    const point = (s: T.Sample, n: [number, number], offset: number): V3 => [
      (s.x + n[0] * offset) * CM,
      y,
      (s.z + n[1] * offset) * CM,
    ];
    batch.quad(point(a, na, inner), point(a, na, outer), point(b, nb, outer), point(b, nb, inner));
  }
}

function hash(a: number, b: number, c: number): number {
  let h = Math.imul(a ^ 0x9e3779b9, 0x85ebca6b) >>> 0;
  h = (h ^ Math.imul(b + 1, 0xc2b2ae35)) >>> 0;
  h = (h ^ Math.imul(c + 7, 0x27d4eb2f)) >>> 0;
  return ((h >>> 0) % 1000) / 1000;
}

export interface TownView {
  group: THREE.Group;
  bounds: THREE.Box3;
}

export function townView(options: { buildings?: boolean; splits?: boolean } = {}): TownView {
  const group = new THREE.Group();
  const asphalt = new Batch();
  const paint = new Batch();
  const walk = new Batch();
  const kerb = new Batch();
  const yard = new Batch();
  const buildings = new THREE.Group();

  const halves = new Map<string, number>();
  for (let i = 0; i < T.COLS; i += 1) {
    for (let j = 0; j < T.ROWS; j += 1) {
      for (const approach of T.approaches(i, j)) {
        if (approach.present) halves.set(`${i},${j},${approach.d}`, approach.half);
      }
    }
  }
  const halfAt = (i: number, j: number, d: T.DirName): number =>
    halves.get(`${i},${j},${d}`) ?? 300;

  // --- streets, pavements and markings ------------------------------------

  const opposite: Record<T.DirName, T.DirName> = {
    North: "South",
    South: "North",
    East: "West",
    West: "East",
  };
  const step: Record<T.DirName, [number, number]> = {
    North: [0, -1],
    South: [0, 1],
    East: [1, 0],
    West: [-1, 0],
  };

  for (let i = 0; i < T.COLS; i += 1) {
    for (let j = 0; j < T.ROWS; j += 1) {
      for (const d of ["East", "South"] as T.DirName[]) {
        if (!T.has(i, j, d)) continue;
        const raw = T.samples(i, j, d);
        const farI = i + step[d][0];
        const farJ = j + step[d][1];
        const samples = trimmed(
          raw,
          T.mouthMid(i, j, d),
          T.mouthMid(farI, farJ, opposite[d]),
          T.mouthCm(i, j, d),
          T.mouthCm(farI, farJ, opposite[d]),
        );
        const half = halfAt(i, j, d);

        strip(asphalt, samples, -half, half, ASPHALT);
        for (const side of [-1, 1] as const) {
          strip(walk, samples, side * half, side * (half + T.PAVEMENT_CM), WALK);
          // The kerb face, one quad per segment from the road up to the walk.
          for (let k = 0; k + 1 < samples.length; k += 1) {
            const a = samples[k]!;
            const b = samples[k + 1]!;
            const na = normalAt(a);
            const nb = normalAt(b);
            const at = (s: T.Sample, n: [number, number]): V3 => [
              (s.x + n[0] * half * side) * CM,
              WALK,
              (s.z + n[1] * half * side) * CM,
            ];
            const at0 = (s: T.Sample, n: [number, number]): V3 => [
              (s.x + n[0] * half * side) * CM,
              0,
              (s.z + n[1] * half * side) * CM,
            ];
            kerb.quad(at0(a, na), at0(b, nb), at(a, na), at(b, nb), [
              na[0] * side,
              0,
              na[1] * side,
            ]);
          }
        }

        // A broken centre line, and a solid edge line each side.
        for (let k = 0; k + 1 < samples.length; k += 1) {
          const marked = k % 3 !== 2;
          if (marked) strip(paint, samples, -9, 9, PAINT, k, k + 1);
        }
        strip(paint, samples, -half + 20, -half + 35, PAINT, 1, samples.length - 1);
        strip(paint, samples, half - 35, half - 20, PAINT, 1, samples.length - 1);

        // The approach at each end stops short and marks its line.
        for (const [nodeI, nodeJ, towards] of [
          [i, j, d],
          [i + step[d][0], j + step[d][1], opposite[d]],
        ] as const) {
          const approach = T.approaches(nodeI, nodeJ).find((a) => a.d === towards);
          if (!approach || !approach.present) continue;
          const stop = alongStreet(raw, approach.line);
          const n = normalAt(stop);
          const width = approach.half - 30;
          const at = (offset: number): V3 => [
            (stop.x + n[0] * offset) * CM,
            PAINT,
            (stop.z + n[1] * offset) * CM,
          ];
          if (approach.mark !== "NoLine") {
            const thickness = approach.mark === "StopLine" ? 40 : 30;
            const push = (offset: number, along: number): V3 => [
              (stop.x + n[0] * offset + (stop.dx / 1024) * along) * CM,
              PAINT,
              (stop.z + n[1] * offset + (stop.dz / 1024) * along) * CM,
            ];
            paint.quad(at(-width), at(width), push(width, thickness), push(-width, thickness));
          }
          if (approach.zebra > 0) {
            const crossing = alongStreet(raw, approach.zebra);
            const cn = normalAt(crossing);
            const dirx = crossing.dx / 1024;
            const dirz = crossing.dz / 1024;
            for (let stripe = -half + 60; stripe < half - 60; stripe += 110) {
              const at2 = (offset: number, along: number): V3 => [
                (crossing.x + cn[0] * offset + dirx * along) * CM,
                PAINT,
                (crossing.z + cn[1] * offset + dirz * along) * CM,
              ];
              paint.quad(
                at2(stripe, -160),
                at2(stripe, 160),
                at2(stripe + 60, 160),
                at2(stripe + 60, -160),
              );
            }
          }
        }
      }
    }
  }

  // --- junctions ------------------------------------------------------------
  //
  // A junction is the ground the streets leave between their mouths, and its
  // kerb is a fillet at each corner, tangent to both streets. The hub is one
  // polygon: each approach's mouth from its right kerb to its left, then the
  // fillet into the next mouth. The ribbons stop on the same segments, so the
  // carriageway is continuous and nothing is drawn twice.

  const around: T.DirName[] = ["North", "East", "South", "West"];
  const point = (p: T.Pt): V3 => [p.x * CM, ASPHALT, p.z * CM];

  for (let i = 0; i < T.COLS; i += 1) {
    for (let j = 0; j < T.ROWS; j += 1) {
      const centre = point(T.site(i, j));
      const hub: V3[] = [];
      for (let q = 0; q < 4; q += 1) {
        const d = around[q]!;
        if (!T.has(i, j, d)) continue;
        // Clockwise round the node a mouth runs from its left kerb to its
        // right, and the edge that follows joins that right kerb to the next
        // approach's left one.
        const left = point(T.mouthSide(i, j, d, true));
        const right = point(T.mouthSide(i, j, d, false));
        hub.push(left, right);
        let step = 1;
        while (step < 4 && !T.has(i, j, around[(q + step) % 4]!)) step += 1;
        const next = around[(q + step) % 4]!;
        const far = point(T.mouthSide(i, j, next, true));

        // A corner is a fillet round the square corner. Where the leg between
        // two approaches is missing, the two kerbs are one straight kerb
        // through the junction, and the pavement crosses with it.
        const edge: V3[] = [];
        if (step === 1) {
          const corner = point(T.cornerBetween(i, j, d, next));
          for (let s = 0; s <= FILLET; s += 1) edge.push(fillet(right, corner, far, s / FILLET));
        } else {
          edge.push(right, far);
        }
        for (let s = 1; s < edge.length; s += 1) hub.push(edge[s]!);

        // The pavement follows the same edge, out to the walk's width, with
        // the kerb face beneath it.
        for (let s = 0; s + 1 < edge.length; s += 1) {
          const p0 = edge[s]!;
          const p1 = edge[s + 1]!;
          const n0 = edgeNormal(edge, s, centre);
          const n1 = edgeNormal(edge, s + 1, centre);
          const out = (p: V3, n: [number, number], reach: number, y: number): V3 => [
            p[0] + n[0] * reach * CM,
            y,
            p[2] + n[1] * reach * CM,
          ];
          walk.quad(
            out(p0, n0, 0, WALK),
            out(p0, n0, T.PAVEMENT_CM, WALK),
            out(p1, n1, T.PAVEMENT_CM, WALK),
            out(p1, n1, 0, WALK),
          );
          kerb.quad(
            out(p0, n0, 0, 0),
            out(p1, n1, 0, 0),
            out(p1, n1, 0, WALK),
            out(p0, n0, 0, WALK),
            [n0[0], 0, n0[1]],
          );
        }
      }
      for (let k = 0; k < hub.length; k += 1) {
        const a = hub[k]!;
        const b = hub[(k + 1) % hub.length]!;
        asphalt.quad(centre, a, b, b);
      }
    }
  }

  // --- buildings ------------------------------------------------------------

  const AIR = 0.16;
  // The catalogue builds some of its assets to a footprint and some to their
  // own size. A kind with a size of its own is fitted to the lot it stands in,
  // uniformly, so the workshop under a cell is the workshop the catalogue draws
  // and never a stretched one.
  const fitted =
    (build: (seed: number) => THREE.Group) =>
    (seed: number, width: number, depth: number): THREE.Group => {
      const group = build(seed);
      const box = new THREE.Box3().setFromObject(group);
      const size = box.getSize(new THREE.Vector3());
      const scale = Math.min(width / Math.max(size.x, 0.1), depth / Math.max(size.z, 0.1));
      if (Number.isFinite(scale) && scale > 0) group.scale.setScalar(scale);
      return group;
    };

  const kinds = {
    Ruko: ruko,
    Warung: warung,
    House: house,
    Kos: kos,
    Petak: petak,
    Filler: filler,
    Minimarket: fitted(minimarket),
    Bengkel: fitted(bengkel),
    Gudang: fitted(gudang),
  };
  // A lot is a cell of its band, so its back edge can be shorter than its
  // front. When it is square enough the detailed asset stands in it; when the
  // band bends the footprint into a trapezoid, the footprint itself is
  // extruded, walls and a flat roof, so the wedge is built instead of left
  // empty. That is the shape an offset subdivision gives and a box cannot.
  const heights: Record<T.LotKind, number> = {
    Ruko: 7.2,
    Warung: 3.1,
    House: 4.6,
    Kos: 8.2,
    Petak: 4.2,
    Filler: 5.2,
    Minimarket: 5.4,
    Bengkel: 4.8,
    Gudang: 6.4,
  };
  const footprint = (lot: T.Lot): [number, number][] => [
    [lot.ax * CM, lot.az * CM],
    [lot.bx * CM, lot.bz * CM],
    [lot.cx * CM, lot.cz * CM],
    [lot.dx * CM, lot.dz * CM],
  ];
  const prism = (lot: T.Lot, seed: number): THREE.Group => {
    const quad = footprint(lot);
    const height = heights[lot.kind] * (0.82 + 0.42 * seed);
    const wall = walls[Math.floor(seed * walls.length) % walls.length]!;
    const roof = roofs[Math.floor(seed * 7.3) % roofs.length]!;
    const sides: number[] = [];
    for (let k = 0; k < 4; k += 1) {
      const p = quad[k]!;
      const q = quad[(k + 1) % 4]!;
      sides.push(p[0], 0, p[1], q[0], 0, q[1], q[0], height, q[1]);
      sides.push(p[0], 0, p[1], q[0], height, q[1], p[0], height, p[1]);
    }
    const body = new THREE.BufferGeometry();
    body.setAttribute("position", new THREE.Float32BufferAttribute(sides, 3));
    body.computeVertexNormals();
    const cap = new THREE.BufferGeometry();
    cap.setAttribute(
      "position",
      new THREE.Float32BufferAttribute(
        [
          quad[0]![0],
          height,
          quad[0]![1],
          quad[1]![0],
          height,
          quad[1]![1],
          quad[2]![0],
          height,
          quad[2]![1],
          quad[0]![0],
          height,
          quad[0]![1],
          quad[2]![0],
          height,
          quad[2]![1],
          quad[3]![0],
          height,
          quad[3]![1],
        ],
        3,
      ),
    );
    cap.computeVertexNormals();
    const group = new THREE.Group();
    group.add(new THREE.Mesh(body, wall));
    group.add(new THREE.Mesh(cap, roof));
    return group;
  };
  const place = (lot: T.Lot, seed: number): void => {
    const front = Math.hypot(lot.bx - lot.ax, lot.bz - lot.az);
    const back = Math.hypot(lot.cx - lot.dx, lot.cz - lot.dz);
    const square = front <= 0 || back / front > 0.92;
    const mesh = square
      ? kinds[lot.kind](seed, lot.w * CM - AIR, lot.d * CM - AIR)
      : prism(lot, seed);
    mesh.position.set(lot.x * CM, 0, lot.z * CM);
    mesh.rotation.y = Math.atan2(-lot.fz, lot.fx);
    buildings.add(mesh);
  };
  for (let i = 0; i + 1 < T.COLS; i += 1) {
    for (let j = 0; j + 1 < T.ROWS; j += 1) {
      if (!T.blockExists(i, j)) continue;
      // The ground the block's own lots stand on: the core and the lanes
      // between them. Without it the gaps read as lawn instead of yard.
      const [nw, nd] = T.coreLots(i, j);
      if (nw > 0 && nd > 0) {
        const c0 = T.coreAt(i, j, 0, 0);
        const c1 = T.coreAt(i, j, 1024, 0);
        const c2 = T.coreAt(i, j, 1024, 1024);
        const c3 = T.coreAt(i, j, 0, 1024);
        yard.quad(
          [c0.x * CM, 0.02, c0.z * CM],
          [c1.x * CM, 0.02, c1.z * CM],
          [c2.x * CM, 0.02, c2.z * CM],
          [c3.x * CM, 0.02, c3.z * CM],
        );
      }
      const rings = T.ringsIn(i, j);
      for (let side = 0; side < 4; side += 1) {
        for (let ring = 0; ring < rings; ring += 1) {
          const lots = T.lotsOn(i, j, side, ring);
          for (let k = 0; k < lots; k += 1) {
            const lot = T.lotAt(i, j, side, ring, k);
            place(lot, hash(i * 31 + k, j * 17 + side * 7 + ring, lot.kind.length));
          }
        }
      }
      const [across, deep] = T.coreLots(i, j);
      for (let a = 0; a < across; a += 1) {
        for (let b = 0; b < deep; b += 1) {
          // A yard block's square stands open in the middle of its grid.
          if (T.coreOpen(i, j, a, b)) continue;
          const lot = T.coreLotAt(i, j, a, b);
          place(lot, hash(i * 13 + a, j * 11 + b, lot.kind.length));
        }
      }
    }
  }

  // --- street furniture -----------------------------------------------------
  //
  // One prop in front of every frontage lot, on the lot's own centre line. A
  // tree is scaled to the radius the model gave it, so the drawn crown is the
  // crown the law bounds.

  const trees = { Mangga: mangga, Palm: palm, Kamboja: kamboja };
  for (let i = 0; i + 1 < T.COLS; i += 1) {
    for (let j = 0; j + 1 < T.ROWS; j += 1) {
      if (!T.blockExists(i, j)) continue;
      for (let side = 0; side < 4; side += 1) {
        const lots = T.lotsOn(i, j, side, 0);
        for (let k = 0; k < lots; k += 1) {
          const prop = T.propAt(i, j, side, k);
          const seed = hash(i * 13 + k, j * 7 + side, prop.r);
          let mesh: THREE.Object3D;
          if (prop.kind === "Pole") {
            mesh = powerPole();
          } else if (prop.kind === "Pot") {
            mesh = pot(seed);
          } else if (prop.kind === "Semak") {
            mesh = semak(seed, Math.min(prop.r * 2 * CM, 3));
          } else {
            const tree = trees[prop.kind](seed);
            const box = new THREE.Box3().setFromObject(tree);
            const reach = Math.max(-box.min.x, box.max.x, -box.min.z, box.max.z);
            if (reach > 0) tree.scale.setScalar((prop.r * CM) / reach);
            mesh = tree;
          }
          mesh.position.set(prop.x * CM, WALK, prop.z * CM);
          mesh.rotation.y = (seed - 0.5) * 0.6;
          buildings.add(mesh);
        }
      }
      // An open core cell is a kebun: the tree it holds stands in the middle
      // of it, and the same crown the model declares is what is drawn.
      const [across, deep] = T.coreLots(i, j);
      for (let a = 0; a < across; a += 1) {
        for (let b = 0; b < deep; b += 1) {
          if (!T.coreOpen(i, j, a, b)) continue;
          const prop = T.coreTree(i, j, a, b);
          const seed = hash(i * 17 + a, j * 19 + b, prop.r);
          const tree = trees[prop.kind](seed);
          const box = new THREE.Box3().setFromObject(tree);
          const reach = Math.max(-box.min.x, box.max.x, -box.min.z, box.max.z);
          if (reach > 0) tree.scale.setScalar((prop.r * CM) / reach);
          tree.position.set(prop.x * CM, WALK, prop.z * CM);
          tree.rotation.y = (seed - 0.5) * 6.3;
          buildings.add(tree);
        }
      }
    }
  }

  // --- signals --------------------------------------------------------------

  for (let i = 0; i < T.COLS; i += 1) {
    for (let j = 0; j < T.ROWS; j += 1) {
      if (T.control(i, j) !== "Signal") continue;
      for (const approach of T.approaches(i, j)) {
        if (!approach.present || !approach.head) continue;
        // The head stands on the kerb at the stop line, where a driver waits.
        const raw = T.samples(i, j, approach.d);
        const stop = alongStreet(raw, approach.line);
        const n = normalAt(stop);
        const side = approach.d === "North" || approach.d === "East" ? -1 : 1;
        const x = (stop.x + n[0] * (approach.half + 60) * side) * CM;
        const z = (stop.z + n[1] * (approach.half + 60) * side) * CM;
        const angle = { North: -Math.PI / 2, South: Math.PI / 2, East: 0, West: Math.PI }[
          approach.d
        ];
        const pole = new THREE.Mesh(box(0.12, 5.4, 0.12), mats.metal);
        pole.position.set(x, WALK + 2.7, z);
        const head = new THREE.Mesh(box(0.34, 0.9, 0.3), mats.metal);
        head.position.set(x, WALK + 5.1, z);
        head.rotation.y = angle;
        buildings.add(pole, head);
      }
    }
  }

  // --- the river ------------------------------------------------------------
  //
  // The model leaves a gap between two columns and only the bridges cross it.
  // The water fills that gap, half way between the two banks, and takes its
  // width from the same pavement the streets use.

  const river = new Batch();
  {
    const gap = T.riverGap();
    const path: T.Pt[] = [];
    for (let j = 0; j < T.ROWS; j += 1) {
      const west = T.site(gap, j);
      const east = T.site(gap + 1, j);
      path.push({ x: (west.x + east.x) / 2, z: (west.z + east.z) / 2 });
    }
    for (let k = 0; k + 1 < path.length; k += 1) {
      const a = path[k]!;
      const b = path[k + 1]!;
      const dx = b.x - a.x;
      const dz = b.z - a.z;
      const span = Math.hypot(dx, dz) || 1;
      const nx = -dz / span;
      const nz = dx / span;
      const wide = 1300;
      const grow = 900 / span;
      const at = (p: T.Pt, s: number, back: number): V3 => [
        (p.x + nx * wide * s + (dx / span) * back) * CM,
        -0.02,
        (p.z + nz * wide * s + (dz / span) * back) * CM,
      ];
      river.quad(at(a, -1, -grow), at(a, 1, -grow), at(b, 1, grow), at(b, -1, grow));
    }
  }

  // The streets cut inside each block. Drawn over the lots for now: the lots
  // still follow the coarse block, so this shows the street layer on its own.
  if (options.splits) {
    for (let i = 0; i + 1 < T.COLS; i += 1) {
      for (let j = 0; j + 1 < T.ROWS; j += 1) {
        if (!T.blockExists(i, j)) continue;
        for (const p of T.SPLIT_PATHS) {
          const cut = T.splitAt(i, j, p);
          if (!cut) continue;
          const dx = cut.b.x - cut.a.x;
          const dz = cut.b.z - cut.a.z;
          const length = Math.hypot(dx, dz) || 1;
          const nx = (-dz / length) * cut.half;
          const nz = (dx / length) * cut.half;
          const at = (q: T.Pt, side: number): V3 => [
            (q.x + nx * side) * CM,
            0.06,
            (q.z + nz * side) * CM,
          ];
          asphalt.quad(at(cut.a, -1), at(cut.a, 1), at(cut.b, 1), at(cut.b, -1));
        }
      }
    }
  }

  // The land the town sits on, so a street reads as a street and not a hole.
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(2000, 2000), mats.ground);
  ground.rotation.x = -Math.PI / 2;
  ground.position.set(400, -0.04, 400);
  ground.receiveShadow = true;
  group.add(ground);

  for (const [batch, material] of [
    [asphalt, mats.asphalt],
    [paint, mats.paint],
    [walk, mats.walk],
    [kerb, mats.kerb],
    [yard, mats.dirt],
    [river, mats.water],
  ] as const) {
    if (!batch.empty) group.add(batch.mesh(material));
  }

  if (options.buildings !== false) group.add(bake(buildings));

  group.traverse((node) => {
    if (node instanceof THREE.Mesh) node.receiveShadow = true;
  });

  // Frame the town itself, not the box it was laid out in.
  const bounds = new THREE.Box3();
  for (let i = 0; i < T.COLS; i += 1) {
    for (let j = 0; j < T.ROWS; j += 1) {
      const at = T.site(i, j);
      bounds.expandByPoint(new THREE.Vector3(at.x * CM, 0, at.z * CM));
      bounds.expandByPoint(new THREE.Vector3(at.x * CM, 26, at.z * CM));
    }
  }
  bounds.expandByScalar(40);
  return { group, bounds };
}
