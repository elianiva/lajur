import * as THREE from "three";
import { bake, box, mats } from "../assets/kit.ts";
import { house, kos, petak, ruko, warung } from "../assets/buildings.ts";
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

export function townView(options: { buildings?: boolean } = {}): TownView {
  const group = new THREE.Group();
  const asphalt = new Batch();
  const paint = new Batch();
  const walk = new Batch();
  const kerb = new Batch();
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
        const samples = T.samples(i, j, d);
        const half = halfAt(i, j, d);

        strip(asphalt, samples, -half, half, ASPHALT);
        for (const side of [-1, 1] as const) {
          strip(
            walk,
            samples,
            side * half,
            side * (half + T.PAVEMENT_CM),
            WALK,
            1,
            samples.length - 1,
          );
          // The kerb face, one quad per segment from the road up to the walk.
          for (let k = 1; k + 1 < samples.length; k += 1) {
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
          const stop = alongStreet(samples, approach.line);
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
            const crossing = alongStreet(samples, approach.zebra);
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

  // --- junction discs -------------------------------------------------------

  for (let i = 0; i < T.COLS; i += 1) {
    for (let j = 0; j < T.ROWS; j += 1) {
      const at = T.site(i, j);
      let radius = 0;
      for (const approach of T.approaches(i, j)) {
        if (approach.present) radius = Math.max(radius, approach.half);
      }
      if (radius === 0) continue;
      const sides = 20;
      for (let k = 0; k < sides; k += 1) {
        const a = (k / sides) * Math.PI * 2;
        const b = ((k + 1) / sides) * Math.PI * 2;
        asphalt.quad(
          [at.x * CM, ASPHALT, at.z * CM],
          [(at.x + Math.cos(a) * radius) * CM, ASPHALT, (at.z + Math.sin(a) * radius) * CM],
          [(at.x + Math.cos(b) * radius) * CM, ASPHALT, (at.z + Math.sin(b) * radius) * CM],
          [(at.x + Math.cos(b) * radius) * CM, ASPHALT, (at.z + Math.sin(b) * radius) * CM],
        );
      }
    }
  }

  // --- buildings ------------------------------------------------------------

  const kinds = { Ruko: ruko, Warung: warung, House: house, Kos: kos, Petak: petak };
  for (let i = 0; i + 1 < T.COLS; i += 1) {
    for (let j = 0; j + 1 < T.ROWS; j += 1) {
      if (!T.blockExists(i, j)) continue;
      const rows = T.rowsIn(i, j);
      const lots = T.lotsIn(i, j);
      for (let row = 0; row < rows; row += 1) {
        for (let k = 0; k < lots; k += 1) {
          const lot = T.lotAt(i, j, row, k);
          const seed = hash(i * 31 + k, j * 17 + row, lot.kind.length);
          const width = lot.w * CM;
          const depth = lot.d * CM;
          const kind = lot.kind;
          const mesh =
            kind === "Ruko" || kind === "House"
              ? kinds[kind](seed, width, depth)
              : kinds[kind](seed);
          mesh.position.set(lot.x * CM, 0, lot.z * CM);
          mesh.rotation.y = Math.atan2(-lot.fz, lot.fx);
          buildings.add(mesh);
        }
      }
    }
  }

  // --- signals --------------------------------------------------------------

  for (let i = 0; i < T.COLS; i += 1) {
    for (let j = 0; j < T.ROWS; j += 1) {
      if (T.control(i, j) !== "Signal") continue;
      const at = T.site(i, j);
      for (const approach of T.approaches(i, j)) {
        if (!approach.present || !approach.head) continue;
        const angle = { North: -Math.PI / 2, South: Math.PI / 2, East: 0, West: Math.PI }[
          approach.d
        ];
        const reach = (approach.half + 90) * CM;
        const x = at.x * CM + Math.cos(angle) * reach;
        const z = at.z * CM + Math.sin(angle) * reach;
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
