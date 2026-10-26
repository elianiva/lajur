/**
 * The world's roads, one cell at a time.
 *
 * Every cell is a function of (seed, i, j) alone, so cells can be generated
 * in any order, ahead of the driver, and still meet their neighbours exactly.
 *
 *   Layer 1  a jittered lattice of main roads, 650 m apart: every third line
 *            an arterial, the rest collectors. Some segments are dropped, by a
 *            rule that never leaves a crossing with fewer than two roads.
 *            Rivers run through every fourth row of cells.
 *   Layer 2  each cell has a curved frame (a Coons patch of its four roads) and
 *            is cut into blocks by up to two collectors.
 *   Layer 3  each block is filled by the density field: sawah and kebun stay
 *            open; a tree of lokal streets, a comb, a grid, or a ring lane
 *            round a civic court. Lokal streets reach a main road only at
 *            entrance slots both sides of it share.
 *
 * All three layers are `logic/world.bend`, with their laws in
 * `logic/PROOF_WORLD.bend`. This file reads the model in metres and frames.
 */
import W, { type List } from "../world.mjs";

export interface Pt {
  x: number;
  z: number;
}

/** A lattice segment runs east from its node, or south. */
export type Dir = "E" | "S";
/** A side of a cell or block, in the frame: v = 0 is south, u = 0 is west. */
export type Side = "S" | "N" | "W" | "E";

/** Road classes. A line of kind 0 is a river. */
export const ART = 1;
export const COL = 2;
export const LOK = 3;

export interface Line {
  kind: number;
  pts: Pt[];
  /** The lattice segment this road is: "i,j,E". */
  seg?: string;
  river?: boolean;
  /** Where a tree street ends in a turning circle. */
  bulb?: Pt;
  tree?: boolean;
  ring?: boolean;
  mouth?: boolean;
  cut?: "u" | "v";
  cross?: boolean;
}

export interface Frame {
  at(u: number, v: number): Pt;
  /** Metres per unit of u, and of v. */
  mu: number;
  mv: number;
}

export type BlockType = "sawah" | "kebun" | "tree" | "comb" | "grid" | "ring" | "shops";
export type Court = "alun" | "pasar" | "sekolah" | "gudang";

export interface Block {
  u0: number;
  u1: number;
  v0: number;
  v1: number;
  /** Whether a road runs along each side. */
  roads: Record<Side, boolean>;
  type: BlockType;
  /** The density at the block's middle. */
  d: number;
  /** A ring block's lane, in the frame, and the civic court inside it. */
  inner?: { ru0: number; ru1: number; rv0: number; rv1: number };
  court?: Court;
  tips?: { linked: number; bulb: number; through: number };
}

export interface Cell {
  i: number;
  j: number;
  lines: Line[];
  blocks: Block[];
  frame: Frame;
}

// ---- The model --------------------------------------------------------------
// All three layers are logic/world.bend: the lattice, the roads, the frames,
// the collectors, the entrance slots, what each block becomes and the streets
// inside it. This file reads them in metres and fractions. The model answers in signed centimetres,
// positions along a road or across a frame in 65536ths, densities in 1024ths.

const u32 = (n: number) => n >>> 0;
const metres = (cm: number) => (cm | 0) / 100;
const cm = (m: number) => u32(Math.round(m * 100));
const q16 = (t: number) => Math.min(65536, Math.max(0, Math.round(t * 65536)));
const toPt = (p: Pt) => pt(metres(p.x), metres(p.z));
const east = (dir: Dir) => dir === "E";

// ---- Determinism, for the parcels -----------------------------------------------

const mix32 = (a: number, b: number): number => {
  let h = Math.imul(a ^ Math.imul(b, 0x9e3779b1), 0x85ebca6b) >>> 0;
  h ^= h >>> 13;
  h = Math.imul(h, 0xc2b2ae35) >>> 0;
  return (h ^ (h >>> 16)) >>> 0;
};
/** A number in [0, 1) from the seed and any integers: the model's own mix. */
export const hash = (seed: number, ...xs: number[]): number =>
  xs.reduce((h, x) => mix32(h, (x | 0) >>> 0), seed >>> 0) / 4294967296;
export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
export const pt = (x: number, z: number): Pt => ({ x, z });

/** The density field, in [0, 1). */
export const density = (seed: number, x: number, z: number): number =>
  W.density(seed, cm(x), cm(z)) / 1024;

// ---- Layer 1: the lattice -----------------------------------------------------

export const node = (seed: number, i: number, j: number): Pt => toPt(W.node(seed, u32(i), u32(j)));

/** The segment from (i, j) east to (i + 1, j), or south to (i, j + 1). */
export const segExists = (seed: number, i: number, j: number, dir: Dir): boolean =>
  W.has_road(seed, u32(i), u32(j), east(dir));

export const segKind = (i: number, j: number, dir: Dir): number =>
  W.road_code(u32(i), u32(j), east(dir));

/** A Catmull-Rom segment through the lattice. */
export function segCurve(seed: number, i: number, j: number, dir: Dir): (t: number) => Pt {
  const curve = W.curve_of(seed, u32(i), u32(j), east(dir));
  return (t) => toPt(W.curve_at(curve, q16(t)));
}

/** `n + 1` points along `f`, from t = 0 to t = 1. */
export const along = (f: (t: number) => Pt, n: number): Pt[] =>
  Array.from({ length: n + 1 }, (_, k) => f(k / n));

// ---- The cell's frame ---------------------------------------------------------

export function frame(seed: number, i: number, j: number): Frame {
  const f = W.frame_of(seed, u32(i), u32(j));
  return {
    at: (u, v) => toPt(W.frame_at(f, q16(u), q16(v))),
    mu: f.mu / 100,
    mv: f.mv / 100,
  };
}

// ---- One cell ---------------------------------------------------------------
// The model's cell, in world metres. A line's tag says what it is: 0 the
// lattice road east from the corner and 9 the one south, 1 and 2 a collector
// across u and across v, 3 the river, 4 and 5 a tree street, the second ending
// in a turning circle, 6 a ring lane, 7 a mouth, 8 a cross street.

const LANDS: BlockType[] = ["sawah", "kebun", "tree", "comb", "grid", "ring", "shops"];
const COURTS: Court[] = ["alun", "pasar", "sekolah", "gudang"];

const list = <T>(l: List<T>): T[] => {
  const out: T[] = [];
  for (; l.$ === "Con"; l = l.tail) out.push(l.head);
  return out;
};

function lineOf(kind: number, tag: number, pts: Pt[], i: number, j: number): Line {
  switch (tag) {
    case 0:
      return { kind, pts, seg: `${i},${j},E` };
    case 9:
      return { kind, pts, seg: `${i},${j},S` };
    case 1:
      return { kind, pts, cut: "u" };
    case 2:
      return { kind, pts, cut: "v" };
    case 3:
      return { kind: 0, pts, river: true };
    case 4:
      return { kind, pts, tree: true };
    case 5:
      return { kind, pts, tree: true, bulb: pts[pts.length - 1]! };
    case 6:
      return { kind, pts, ring: true };
    case 7:
      return { kind, pts, mouth: true };
    default:
      return { kind, pts, cross: true };
  }
}

/** Everything returned is in world metres. */
export function cell(seed: number, i: number, j: number): Cell {
  const F = frame(seed, i, j);
  const c = W.cell_of(seed, u32(i), u32(j));
  const lines = list(c.lines).map((l) => lineOf(l.kind, l.tag, list(l.pts).map(toPt), i, j));
  const blocks = list(c.blocks).map((b): Block => {
    const r = b.fill;
    const blk: Block = {
      u0: b.u0 / 65536,
      u1: b.u1 / 65536,
      v0: b.v0 / 65536,
      v1: b.v1 / 65536,
      roads: { S: b.s_road, N: b.n_road, W: b.w_road, E: b.e_road },
      type: LANDS[r.land]!,
      d: b.d / 1024,
    };
    if (r.court < 4) {
      blk.court = COURTS[r.court]!;
      blk.inner = {
        ru0: metres(r.ring.x0) / F.mu,
        ru1: metres(r.ring.x1) / F.mu,
        rv0: metres(r.ring.z0) / F.mv,
        rv1: metres(r.ring.z1) / F.mv,
      };
    }
    if (blk.type === "tree" || blk.type === "ring")
      blk.tips = { linked: r.linked, bulb: r.bulb, through: r.thru };
    return blk;
  });
  return { i, j, lines, blocks, frame: F };
}
