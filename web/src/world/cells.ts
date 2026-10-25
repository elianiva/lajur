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
import W, { type Edge as BendEdge, type List } from "../world.mjs";

export interface Pt {
  x: number;
  z: number;
}

/** A lattice segment runs east from its node, or south. */
export type Dir = "E" | "S";
/** A side of a cell or block, in the frame: v = 0 is south, u = 0 is west. */
export type Side = "S" | "N" | "W" | "E";

export const RIVER_HALF = 14;

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
  /** The length of the line across the frame at a fixed u (or v), metres. */
  line(axis: "u" | "v", at: number): number;
}

/** A road along one edge of a block, and the stretch of it the block owns. */
export interface Edge {
  road: boolean;
  key: number[];
  len: number;
  /** Junctions already on it, as parameters along it. */
  avoid: number[];
  t0: number;
  t1: number;
}

export type BlockType = "sawah" | "kebun" | "tree" | "comb" | "grid" | "ring" | "shops";
export type Court = "alun" | "pasar" | "sekolah" | "gudang";

export interface Block {
  u0: number;
  u1: number;
  v0: number;
  v1: number;
  edges: Record<Side, Edge>;
  type: BlockType;
  /** The density at the block's middle. */
  d: number;
  /** A ring block's lane, in the frame, and the civic court inside it. */
  inner?: { ru0: number; ru1: number; rv0: number; rv1: number };
  court?: Court;
  tips?: { linked: number; bulb: number; through: number };
}

export interface Mouth {
  side: Side;
  key: string;
  t: number;
  at: Pt;
}

export interface Cell {
  i: number;
  j: number;
  lines: Line[];
  blocks: Block[];
  mouths: Mouth[];
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

export const riverRow = (j: number) => W.river_row(u32(j));
export const riverV = (seed: number, i: number, j: number, u: number): number =>
  W.river_v(seed, u32(i), u32(j), q16(u)) / 65536;

// Where a collector meets a lattice road. Side 0 is the cell south (or west)
// of it, side 1 north (or east).
const sideMouth = (seed: number, i: number, j: number, dir: Dir, side: 0 | 1): number =>
  W.side_mouth(seed, u32(i), u32(j), east(dir), side) / 65536;

export function cellCuts(seed: number, i: number, j: number) {
  const c = W.cell_cuts(seed, u32(i), u32(j));
  return { uc: c.uc ? c.uc / 65536 : null, vc: c.vc ? c.vc / 65536 : null };
}

export const segLength = (seed: number, i: number, j: number, dir: Dir) =>
  W.road_length(seed, u32(i), u32(j), east(dir)) / 100;

// ---- The cell's frame ---------------------------------------------------------

export function frame(seed: number, i: number, j: number): Frame {
  const f = W.frame_of(seed, u32(i), u32(j));
  return {
    at: (u, v) => toPt(W.frame_at(f, q16(u), q16(v))),
    mu: f.mu / 100,
    mv: f.mv / 100,
    line: (axis, at) => W.frame_line_length(f, axis === "u", q16(at)) / 100,
  };
}

const NONE: Edge = { road: false, key: [], len: 0, avoid: [], t0: 0, t1: 0 };

// ---- One cell ---------------------------------------------------------------

type AddLine = (kind: number, pts: Pt[], extra?: Partial<Line>) => void;

/** Everything returned is in world metres. */
export function cell(seed: number, i: number, j: number): Cell {
  const F = frame(seed, i, j);
  const lines: Line[] = [];
  const blocks: Block[] = [];
  const mouths: Mouth[] = [];
  const line: AddLine = (kind, pts, extra = {}) => {
    lines.push({ kind, pts, ...extra });
  };
  const { uc, vc } = cellCuts(seed, i, j);
  const river = riverRow(j);

  // The cell's own roads: its south and west segments, so every segment of the
  // world belongs to exactly one cell.
  for (const dir of ["E", "S"] as const) {
    if (!segExists(seed, i, j, dir)) continue;
    line(segKind(i, j, dir), along(segCurve(seed, i, j, dir), 64), { seg: `${i},${j},${dir}` });
  }
  if (uc !== null)
    line(
      COL,
      along((v) => F.at(uc, v), 64),
      { cut: "u" },
    );
  if (vc !== null)
    line(
      COL,
      along((u) => F.at(u, vc), 64),
      { cut: "v" },
    );
  if (river)
    line(
      0,
      along((u) => F.at(u, riverV(seed, i, j, u)), 24),
      { river: true },
    );

  // What lies on each of the four sides, and the junctions already on it: the
  // collectors' mouths, from either side. A lattice side's length is the
  // road's own arc length, which both cells beside it measure alike; their
  // frames differ.
  const seg = (si: number, sj: number, dir: Dir): Edge => ({
    road: segExists(seed, si, sj, dir),
    key: [si, sj, dir === "E" ? 0 : 1],
    len: segLength(seed, si, sj, dir),
    avoid: [sideMouth(seed, si, sj, dir, 0), sideMouth(seed, si, sj, dir, 1)],
    t0: 0,
    t1: 1,
  });
  const sides: Record<Side, Edge> = {
    S: seg(i, j, "E"),
    N: seg(i, j + 1, "E"),
    W: seg(i, j, "S"),
    E: seg(i + 1, j, "S"),
  };

  // Blocks: the cell cut by uc and vc, in the frame. River cells are split by
  // the water instead, which leaves a green bank on each side of it.
  const lenU = uc === null ? 0 : F.line("u", uc);
  const lenV = vc === null ? 0 : F.line("v", vc);
  const us = uc === null ? [0, 1] : [0, uc, 1];
  const vs = vc === null ? [0, 1] : [0, vc, 1];
  for (let a = 0; a + 1 < us.length; a++)
    for (let b = 0; b + 1 < vs.length; b++) {
      const r = { u0: us[a]!, u1: us[a + 1]!, v0: vs[b]!, v1: vs[b + 1]! };
      // Each edge of the block: the road on it, or nothing.
      const cutU: Edge = {
        road: true,
        key: [i, j, 3],
        len: lenU,
        avoid: [vc ?? -1],
        t0: r.v0,
        t1: r.v1,
      };
      const cutV: Edge = {
        road: true,
        key: [i, j, 2],
        len: lenV,
        avoid: [uc ?? -1],
        t0: r.u0,
        t1: r.u1,
      };
      const edges: Record<Side, Edge> = {
        S: r.v0 === 0 ? { ...sides.S, t0: r.u0, t1: r.u1 } : cutV,
        N: r.v1 === 1 ? { ...sides.N, t0: r.u0, t1: r.u1 } : cutV,
        W: r.u0 === 0 ? { ...sides.W, t0: r.v0, t1: r.v1 } : cutU,
        E: r.u1 === 1 ? { ...sides.E, t0: r.v0, t1: r.v1 } : cutU,
      };
      const block = (
        u0: number,
        u1: number,
        v0: number,
        v1: number,
        e: Record<Side, Edge>,
      ): Block => ({
        u0,
        u1,
        v0,
        v1,
        edges: e,
        type: "sawah",
        d: 0,
      });
      if (river) {
        // The water's v-range over this block, and a bank of 15 m each side.
        let lo = 1;
        let hi = 0;
        for (let k = 0; k <= 16; k++) {
          const v = riverV(seed, i, j, lerp(r.u0, r.u1, k / 16));
          lo = Math.min(lo, v);
          hi = Math.max(hi, v);
        }
        const bank = (RIVER_HALF + 15) / F.mv;
        blocks.push(block(r.u0, r.u1, r.v0, lo - bank, { ...edges, N: NONE }));
        blocks.push(block(r.u0, r.u1, hi + bank, r.v1, { ...edges, S: NONE }));
      } else blocks.push(block(r.u0, r.u1, r.v0, r.v1, edges));
    }

  for (const blk of blocks) fill(seed, i, j, F, blk, line, mouths);
  return { i, j, lines, blocks, mouths, frame: F };
}

const LANDS: BlockType[] = ["sawah", "kebun", "tree", "comb", "grid", "ring", "shops"];
const COURTS: Court[] = ["alun", "pasar", "sekolah", "gudang"];
const SIDES: Side[] = ["S", "N", "W", "E"];

// ---- Layer 3: fill a block ----------------------------------------------------
// The model answers in the block's metric frame, centimetres from the frame's
// first corner along u and v. A point maps back through the frame, and a
// straight run in the frame is drawn every 10 m or so, so it bends with it.

const list = <T>(l: List<T>): T[] => {
  const out: T[] = [];
  for (; l.$ === "Con"; l = l.tail) out.push(l.head);
  return out;
};

const far = 0xffffffff;
const toEdge = (e: Edge): BendEdge => ({
  $: "Edge",
  road: e.road,
  k0: u32(e.key[0] ?? 0),
  k1: u32(e.key[1] ?? 0),
  k2: u32(e.key[2] ?? 0),
  len: cm(e.len),
  a0: e.avoid[0] === undefined || e.avoid[0] < 0 ? far : q16(e.avoid[0]),
  a1: e.avoid[1] === undefined || e.avoid[1] < 0 ? far : q16(e.avoid[1]),
  t0: q16(e.t0),
  t1: q16(e.t1),
});

function fill(
  seed: number,
  i: number,
  j: number,
  F: Frame,
  blk: Block,
  line: AddLine,
  mouths: Mouth[],
) {
  const c = F.at((blk.u0 + blk.u1) / 2, (blk.v0 + blk.v1) / 2);
  blk.d = density(seed, c.x, c.z);
  const e = blk.edges;
  const r = W.block_fill(
    seed,
    u32(i),
    u32(j),
    q16(blk.u0),
    q16(blk.u1),
    q16(blk.v0),
    q16(blk.v1),
    toEdge(e.S),
    toEdge(e.N),
    toEdge(e.W),
    toEdge(e.E),
  );
  blk.type = LANDS[r.land]!;
  const fu = (x: number) => metres(x) / F.mu;
  const fv = (z: number) => metres(z) / F.mv;
  if (r.court < 4) {
    blk.court = COURTS[r.court]!;
    blk.inner = { ru0: fu(r.ring.x0), ru1: fu(r.ring.x1), rv0: fv(r.ring.z0), rv1: fv(r.ring.z1) };
  }
  if (blk.type === "tree" || blk.type === "ring")
    blk.tips = { linked: r.linked, bulb: r.bulb, through: r.thru };
  for (const st of list(r.streets)) {
    const uv = list(st.pts).map((p) => [fu(p.x), fv(p.z)] as const);
    const pts: Pt[] = [F.at(uv[0]![0], uv[0]![1])];
    for (let k = 1; k < uv.length; k++) {
      const [u0, v0] = uv[k - 1]!;
      const [u1, v1] = uv[k]!;
      const n = Math.max(1, Math.ceil(Math.hypot((u1 - u0) * F.mu, (v1 - v0) * F.mv) / 10));
      for (let s = 1; s <= n; s++) pts.push(F.at(lerp(u0, u1, s / n), lerp(v0, v1, s / n)));
    }
    line(
      LOK,
      pts,
      st.tag === 0
        ? { tree: true, ...(st.bulb ? { bulb: pts[pts.length - 1]! } : {}) }
        : st.tag === 1
          ? { ring: true }
          : st.tag === 2
            ? { mouth: true }
            : { cross: true },
    );
  }
  for (const m of list(r.mouths)) {
    const side = SIDES[m.side]!;
    const t = m.t / 65536;
    const at =
      side === "S"
        ? F.at(t, blk.v0)
        : side === "N"
          ? F.at(t, blk.v1)
          : side === "W"
            ? F.at(blk.u0, t)
            : F.at(blk.u1, t);
    mouths.push({ side, key: e[side].key.join(","), t, at });
  }
}
