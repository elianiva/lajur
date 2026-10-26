/**
 * Layer 4: parcels. Each cell's roads and blocks become placements: a lot per
 * building asset, civic courts inside ring blocks, and big round canopies
 * (mangga, beringin, flamboyan, bambu) wherever land is left.
 *
 * The placements are `logic/parcels.bend`; this file reads them in world
 * metres, and keeps the geometry the plan check and the lab draw with.
 */
import P, { type List, type V } from "../parcels.mjs";
import { ART, COL, LOK, lerp, pt, type Block, type Cell, type Frame, type Pt } from "./cells.ts";

export type Use =
  | "rumah"
  | "petak"
  | "kos"
  | "warung"
  | "ruko"
  | "minimarket"
  | "bengkel"
  | "gudang"
  | "kantor"
  | "apartemen"
  | "rusun"
  | "mal"
  | "masjid"
  | "gereja"
  | "klenteng"
  | "sekolah"
  | "puskesmas"
  | "spbu";
export type CourtUse = "alun" | "pasar" | "sekolah" | "gudang" | "lapangan" | "masjid" | "pendopo";
export type Species = "mangga" | "beringin" | "flamboyan" | "bambu";

/** A building's footprint. The first edge, poly[0] to poly[1], faces its street. */
export interface Lot {
  use: Use;
  poly: Pt[];
}
/**
 * A civic court, as a frame rectangle of 8 points a side. A yard is only
 * ground: the courts inside it hold the buildings.
 */
export interface CourtArea {
  use: CourtUse;
  poly: Pt[];
  yard?: true;
}
export interface Tree {
  x: number;
  z: number;
  r: number;
  sp: Species;
}
export interface BlockArea {
  b: Block;
  poly: Pt[];
  box: Bounds;
}
export interface Plan {
  lots: Lot[];
  courts: CourtArea[];
  trees: Tree[];
  blocks: BlockArea[];
}

type Bounds = [number, number, number, number];

/** Half the carriageway, by road class; the river counts as a road 28 m wide. */
export const ROAD: Record<number, number> = { [ART]: 7, [COL]: 4.5, [LOK]: 2, 0: 14 };

// ---- Geometry ---------------------------------------------------------------

export function inPoly(p: Pt, poly: Pt[]): boolean {
  let inside = false;
  for (let a = 0, b = poly.length - 1; a < poly.length; b = a++) {
    const A = poly[a]!;
    const B = poly[b]!;
    if (A.z > p.z !== B.z > p.z && p.x < ((B.x - A.x) * (p.z - A.z)) / (B.z - A.z) + A.x)
      inside = !inside;
  }
  return inside;
}
export function pointSeg(p: Pt, a: Pt, b: Pt): number {
  const dx = b.x - a.x;
  const dz = b.z - a.z;
  const l = dx * dx + dz * dz;
  const t = l ? Math.max(0, Math.min(1, ((p.x - a.x) * dx + (p.z - a.z) * dz) / l)) : 0;
  return Math.hypot(p.x - a.x - t * dx, p.z - a.z - t * dz);
}
export function area(poly: Pt[]): number {
  let s = 0;
  for (let k = 0; k < poly.length; k++) {
    const p = poly[k]!;
    const q = poly[(k + 1) % poly.length]!;
    s += p.x * q.z - q.x * p.z;
  }
  return Math.abs(s) / 2;
}
export function bbox(poly: Pt[], pad = 0): Bounds {
  let x0 = Infinity;
  let z0 = Infinity;
  let x1 = -Infinity;
  let z1 = -Infinity;
  for (const p of poly) {
    x0 = Math.min(x0, p.x);
    z0 = Math.min(z0, p.z);
    x1 = Math.max(x1, p.x);
    z1 = Math.max(z1, p.z);
  }
  return [x0 - pad, z0 - pad, x1 + pad, z1 + pad];
}

/** A bucket grid, so each test looks only at what is near. */
export class Grid<T> {
  private m = new Map<number, T[]>();
  private s: number;
  constructor(size = 24) {
    this.s = size;
  }
  add(item: T, [x0, z0, x1, z1]: Bounds): void {
    for (let a = Math.floor(x0 / this.s); a <= Math.floor(x1 / this.s); a++)
      for (let b = Math.floor(z0 / this.s); b <= Math.floor(z1 / this.s); b++) {
        const k = a * 100003 + b;
        let bucket = this.m.get(k);
        if (!bucket) this.m.set(k, (bucket = []));
        bucket.push(item);
      }
  }
  near([x0, z0, x1, z1]: Bounds): Set<T> {
    const out = new Set<T>();
    for (let a = Math.floor(x0 / this.s); a <= Math.floor(x1 / this.s); a++)
      for (let b = Math.floor(z0 / this.s); b <= Math.floor(z1 / this.s); b++)
        for (const it of this.m.get(a * 100003 + b) ?? []) out.add(it);
    return out;
  }
}

/** A rectangle in the cell frame, as a world polygon, n points a side. */
export function framePoly(F: Frame, u0: number, u1: number, v0: number, v1: number, n = 12): Pt[] {
  const ring: Pt[] = [];
  for (let k = 0; k < n; k++) ring.push(F.at(lerp(u0, u1, k / n), v0));
  for (let k = 0; k < n; k++) ring.push(F.at(u1, lerp(v0, v1, k / n)));
  for (let k = 0; k < n; k++) ring.push(F.at(lerp(u1, u0, k / n), v1));
  for (let k = 0; k < n; k++) ring.push(F.at(u0, lerp(v1, v0, k / n)));
  return ring;
}

// ---- One cell's parcels -----------------------------------------------------

const USES: Use[] = [
  "rumah",
  "petak",
  "kos",
  "warung",
  "ruko",
  "minimarket",
  "bengkel",
  "gudang",
  "kantor",
  "apartemen",
  "rusun",
  "mal",
  "masjid",
  "gereja",
  "klenteng",
  "sekolah",
  "puskesmas",
  "spbu",
];
const COURT_USES: CourtUse[] = [
  "alun",
  "pasar",
  "sekolah",
  "gudang",
  "lapangan",
  "masjid",
  "pendopo",
];
const SPECIES: Species[] = ["mangga", "beringin", "flamboyan", "bambu"];

const list = <T>(l: List<T>): T[] => {
  const out: T[] = [];
  for (; l.$ === "Con"; l = l.tail) out.push(l.head);
  return out;
};

export function parcels(seed: number, c: Cell): Plan {
  const p = P.parcels_of(seed, c.i >>> 0, c.j >>> 0);
  // The model answers in metres from the cell's first corner.
  const ox = (p.ox | 0) / 100;
  const oz = (p.oz | 0) / 100;
  const poly = (ps: List<V>) => list(ps).map((v) => pt(ox + v.x, oz + v.z));
  const lots = list(p.lots).map((o) => ({ use: USES[o.use]!, poly: poly(o.pts) }));
  const courts = list(p.courts).map((o): CourtArea => {
    const court: CourtArea = { use: COURT_USES[o.use]!, poly: poly(o.pts) };
    if (o.yard) court.yard = true;
    return court;
  });
  const trees = list(p.trees).map((t) => ({
    x: ox + t.x,
    z: oz + t.z,
    r: t.r,
    sp: SPECIES[t.sp]!,
  }));
  const blocks = c.blocks.map((b) => {
    const outline = framePoly(c.frame, b.u0, b.u1, b.v0, b.v1, 12);
    return { b, poly: outline, box: bbox(outline) };
  });
  return { lots, courts, trees, blocks };
}
