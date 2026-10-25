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
 * Layers 1 and 2, and the choice of what each block becomes, are
 * `logic/world.bend`, with their laws in `logic/PROOF.bend`. The streets inside
 * a block are still TypeScript, until they are ported too.
 */
import W from "../world.mjs";

export interface Pt {
  x: number;
  z: number;
}

/** A lattice segment runs east from its node, or south. */
export type Dir = "E" | "S";
/** A side of a cell or block, in the frame: v = 0 is south, u = 0 is west. */
export type Side = "S" | "N" | "W" | "E";

const SHOPS = 35; // depth of the frontage row on a main road
const LOK_FLOOR = 20; // nearest two junctions on a lokal street
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
  cross?: "u" | "v";
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
  /** A big ring's street across the middle. */
  mid?: { axis: "u" | "v"; t: number };
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
// Layers 1 and 2 are logic/world.bend: the lattice, the roads, the frames, the
// collectors, the entrance slots and what each block becomes. This file reads
// them in metres and fractions. The model answers in signed centimetres,
// positions along a road or across a frame in 65536ths, densities in 1024ths.

const u32 = (n: number) => n >>> 0;
const metres = (cm: number) => (cm | 0) / 100;
const cm = (m: number) => u32(Math.round(m * 100));
const q16 = (t: number) => Math.min(65536, Math.max(0, Math.round(t * 65536)));
const toPt = (p: Pt) => pt(metres(p.x), metres(p.z));
const east = (dir: Dir) => dir === "E";

// ---- Determinism, for the layers still in TypeScript --------------------------

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
const mixp = (p: Pt, q: Pt, t: number) => pt(lerp(p.x, q.x, t), lerp(p.z, q.z, t));
export const dist = (p: Pt, q: Pt) => Math.hypot(p.x - q.x, p.z - q.z);

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

// ---- Entrance slots -----------------------------------------------------------

function slots(seed: number, key: number[], len: number, avoid: number[]): number[] {
  const far = 0xffffffff;
  const [a0 = -1, a1 = -1] = avoid;
  const at = (a: number) => (a < 0 ? far : q16(a));
  const out: number[] = [];
  for (
    let l = W.slots(seed, u32(key[0]!), u32(key[1]!), u32(key[2]!), cm(len), at(a0), at(a1));
    l.$ === "Con";
    l = l.tail
  )
    out.push(l.head / 65536);
  return out;
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

const LAND: BlockType[] = ["sawah", "kebun", "tree", "comb", "grid", "ring"];
const COURTS: Court[] = ["alun", "pasar", "sekolah", "gudang"];

// ---- Layer 3: fill a block ----------------------------------------------------

interface Slot {
  name: Side;
  t: number;
  use: number;
  shared: number;
  own: number;
}
interface Box {
  ru0: number;
  ru1: number;
  rv0: number;
  rv1: number;
}
type Straight = (u0: number, v0: number, u1: number, v1: number) => Pt[];

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
  const d = density(seed, c.x, c.z);
  blk.d = d;
  const roll = hash(seed, 11, i, j, Math.round(blk.u0 * 1000), Math.round(blk.v0 * 1000));
  // Sawah alternates with kebun and kampung; a ring is a civic court.
  blk.type = LAND[W.land(Math.round(d * 1024), Math.floor(roll * 1024))]!;
  // The ring sits behind the shops on a road side, and 12 m in from a side
  // without one.
  const inset = (e: Edge) => (e.road ? SHOPS : 12);
  const ru0 = blk.u0 + inset(blk.edges.W) / F.mu;
  const ru1 = blk.u1 - inset(blk.edges.E) / F.mu;
  const rv0 = blk.v0 + inset(blk.edges.S) / F.mv;
  const rv1 = blk.v1 - inset(blk.edges.N) / F.mv;
  const open = blk.type === "sawah" || blk.type === "kebun";
  if (open || (ru1 - ru0) * F.mu < 70 || (rv1 - rv0) * F.mv < 70) {
    if (!open) blk.type = "shops";
    return;
  }
  // The entrances: slots on each road side that fall inside the ring's span,
  // each used by this side with its own roll, and at least one in all.
  const cand: Slot[] = [];
  for (const name of Object.keys(blk.edges) as Side[]) {
    const e = blk.edges[name];
    if (!e.road) continue;
    const span = name === "S" || name === "N" ? [ru0, ru1] : [rv0, rv1];
    for (const t of slots(seed, e.key, e.len, e.avoid)) {
      if (
        t < e.t0 ||
        t > e.t1 ||
        t < span[0]! + LOK_FLOOR / e.len ||
        t > span[1]! - LOK_FLOOR / e.len
      )
        continue;
      const shared = hash(seed, 13, ...e.key, Math.round(t * 1e4));
      const own = hash(
        seed,
        12,
        ...e.key,
        Math.round(t * 1e4),
        name === "S" || name === "W" ? 1 : 0,
      );
      cand.push({ name, t, use: Math.min(shared, own), shared, own });
    }
  }
  if (!cand.length) {
    blk.type = "shops";
    return;
  }
  cand.sort((a, b) => a.use - b.use);
  // A slot both sides like (the shared roll) becomes a crossing of the road.
  const used = cand.filter((s, k) => k === 0 || s.shared < 0.3 || s.own < 0.22);
  // A straight line in the frame, drawn every 10 m or so on the ground.
  const seg: Straight = (u0, v0, u1, v1) => {
    const n = Math.max(4, Math.ceil(Math.hypot((u1 - u0) * F.mu, (v1 - v0) * F.mv) / 10));
    return Array.from({ length: n + 1 }, (_, k) => F.at(lerp(u0, u1, k / n), lerp(v0, v1, k / n)));
  };
  if (blk.type === "tree")
    return growTree(seed, i, j, F, blk, line, mouths, used, d, { ru0, ru1, rv0, rv1 }, seg, cand);
  const ringPts = [
    ...seg(ru0, rv0, ru1, rv0),
    ...seg(ru1, rv0, ru1, rv1).slice(1),
    ...seg(ru1, rv1, ru0, rv1).slice(1),
    ...seg(ru0, rv1, ru0, rv0).slice(1),
  ];
  line(LOK, ringPts, { ring: true });
  const onRing: { axis: "u" | "v"; t: number }[] = []; // where streets meet the ring
  for (const m of used) {
    const t = m.t;
    const [a, b] =
      m.name === "S"
        ? [
            [t, blk.v0],
            [t, rv0],
          ]
        : m.name === "N"
          ? [
              [t, blk.v1],
              [t, rv1],
            ]
          : m.name === "W"
            ? [
                [blk.u0, t],
                [ru0, t],
              ]
            : [
                [blk.u1, t],
                [ru1, t],
              ];
    line(LOK, seg(a[0]!, a[1]!, b[0]!, b[1]!), { mouth: true });
    mouths.push({ side: m.name, key: blk.edges[m.name].key.join(","), t, at: F.at(a[0]!, a[1]!) });
    onRing.push({ axis: m.name === "S" || m.name === "N" ? "u" : "v", t });
  }
  // Streets across the ring: a comb one way, a grid both. They keep the lokal
  // floor from every entrance on the ring. A comb's teeth lean, up to 25
  // degrees, so the estate is not square to its frame; `lean` is how far a
  // tooth's far end moves, in the frame.
  const across = (
    axis: "u" | "v",
    lo: number,
    hi: number,
    metres: number,
    gap: number,
    lean = 0,
  ) => {
    const n = Math.floor(((hi - lo) * metres) / gap);
    for (let k = 1; k < n; k++) {
      const t = lerp(lo, hi, k / n);
      const a = t - lean / 2;
      const b = t + lean / 2;
      if (Math.min(a, b) < lo + LOK_FLOOR / metres || Math.max(a, b) > hi - LOK_FLOOR / metres)
        continue;
      if (
        onRing.some(
          (o) =>
            o.axis === axis &&
            Math.min(Math.abs(o.t - a), Math.abs(o.t - b)) * metres < 1.5 * LOK_FLOOR,
        )
      )
        continue;
      line(LOK, axis === "u" ? seg(a, rv0, b, rv1) : seg(ru0, a, ru1, b), { cross: axis });
    }
  };
  const gap = lerp(85, 55, d);
  const longU = (ru1 - ru0) * F.mu >= (rv1 - rv0) * F.mv;
  if (blk.type === "comb") {
    const span = longU ? (rv1 - rv0) * F.mv : (ru1 - ru0) * F.mu;
    const lean = (Math.tan((roll * 2 - 1) * 0.44) * span) / (longU ? F.mu : F.mv);
    across(longU ? "u" : "v", longU ? ru0 : rv0, longU ? ru1 : rv1, longU ? F.mu : F.mv, gap, lean);
  }
  if (blk.type === "grid") {
    across("u", ru0, ru1, F.mu, gap * 1.2);
    across("v", rv0, rv1, F.mv, gap * 1.4);
  }
  if (blk.type === "ring") {
    // A big ring keeps one street across its middle; the court takes one half.
    if (Math.min((ru1 - ru0) * F.mu, (rv1 - rv0) * F.mv) > 120) {
      const lo = longU ? ru0 : rv0;
      const hi = longU ? ru1 : rv1;
      const metres = longU ? F.mu : F.mv;
      across(longU ? "u" : "v", lo, hi, metres, ((hi - lo) * metres) / 2 - 0.5);
      blk.mid = { axis: longU ? "u" : "v", t: (lo + hi) / 2 };
    }
    const r2 = hash(seed, 14, i, j, Math.round(blk.u0 * 1000), Math.round(blk.v0 * 1000));
    blk.inner = { ru0, ru1, rv0, rv1 };
    blk.court = COURTS[W.court(Math.round(d * 1024), Math.floor(r2 * 1024))]!;
  }
}

// ---- A tree -----------------------------------------------------------------
// A trunk from each entrance, and branches that leave it at an angle, wander,
// and branch again. Growth stops where a street would come within two lot
// depths of another, or leave the block's inner rectangle. A tip that stops
// near another street links to it, a T, when the link is short; otherwise it
// ends in a turning circle, so a car can always turn round. Everything is a
// function of the block, so the cell stays independent of its neighbours.
const CLEAR = 26; // two rows of lots between streets
const STEP = 6;
const OPP: Record<Side, Side> = { S: "N", N: "S", W: "E", E: "W" };

interface Placed {
  u: number;
  v: number;
  p: Pt;
  id: number;
}

function growTree(
  seed: number,
  i: number,
  j: number,
  F: Frame,
  blk: Block,
  line: AddLine,
  mouths: Mouth[],
  used: Slot[],
  d: number,
  box: Box,
  seg: Straight,
  cand: Slot[],
) {
  let state =
    (hash(seed, 20, i, j, Math.round(blk.u0 * 1e4), Math.round(blk.v0 * 1e4)) * 4294967296) >>> 0;
  const R = () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  const between = (a: number, b: number) => a + (b - a) * R();
  const placed: Placed[] = [];
  const inBox = (u: number, v: number) => u > box.ru0 && u < box.ru1 && v > box.rv0 && v < box.rv1;
  // The nearest other street point, ignoring the branch itself and the
  // stretch of its parent it left from.
  const nearest = (p: Pt, id: number, skip: (q: Placed) => boolean) => {
    let best: { d: number; q: Placed } | null = null;
    for (const q of placed) {
      if (q.id === id || skip(q)) continue;
      const dd = dist(p, q.p);
      if (!best || dd < best.d) best = { d: dd, q };
    }
    return best;
  };
  let nextId = 0;
  // Every junction made so far, so a new one keeps the lokal floor from them.
  const joints: Pt[] = [];
  const roomAt = (p: Pt) => joints.every((q) => dist(p, q) >= LOK_FLOOR * 1.2);
  const tips = { linked: 0, bulb: 0, through: 0 };

  // Where a slot's street leaves the frontage, and which way it faces inward.
  const entry = (m: Slot) => {
    const [u, v, h] =
      m.name === "S"
        ? [m.t, blk.v0, Math.PI / 2]
        : m.name === "N"
          ? [m.t, blk.v1, -Math.PI / 2]
          : m.name === "W"
            ? [blk.u0, m.t, 0]
            : [blk.u1, m.t, Math.PI];
    const [eu, ev] =
      m.name === "S"
        ? [u, box.rv0]
        : m.name === "N"
          ? [u, box.rv1]
          : m.name === "W"
            ? [box.ru0, v]
            : [box.ru1, v];
    return { u, v, h, eu, ev };
  };
  // The entrance itself runs straight through the frontage.
  const open = (m: Slot) => {
    const e = entry(m);
    const mouthPts = seg(e.u, e.v, e.eu, e.ev);
    line(LOK, mouthPts, { mouth: true });
    mouths.push({ side: m.name, key: blk.edges[m.name].key.join(","), t: m.t, at: F.at(e.u, e.v) });
    joints.push(mouthPts[mouthPts.length - 1]!);
  };
  // A slot no street uses yet, within 260 m and 50 degrees of a heading.
  const freeSlotAhead = (q: Placed, h: number): Slot | null => {
    let best: { c: Slot; dd: number } | null = null;
    for (const c of cand) {
      if (mouths.some((o) => o.side === c.name && Math.abs(o.t - c.t) < 1e-9)) continue;
      const e = entry(c);
      const du = (e.eu - q.u) * F.mu;
      const dv = (e.ev - q.v) * F.mv;
      const dd = Math.hypot(du, dv);
      let off = Math.atan2(dv, du) - h;
      off = Math.abs(Math.atan2(Math.sin(off), Math.cos(off)));
      if (dd < 260 && off < 0.87 && roomAt(F.at(e.eu, e.ev)) && (!best || dd < best.dd))
        best = { c, dd };
    }
    return best ? best.c : null;
  };

  // Grow one street from (u, v) heading `h` (radians in the metric frame).
  // With a `target`, the street steers for it and ends there: a trunk that
  // runs through the block from one big road to another.
  function grow(
    u: number,
    v: number,
    h: number,
    maxLen: number,
    depth: number,
    parent: number,
    from: Pt,
    target: { u: number; v: number } | null = null,
  ): number | null {
    const id = nextId++;
    const path: Placed[] = [{ u, v, p: F.at(u, v), id }];
    let turn = 0;
    let end: "bulb" | "through" | "link" = "bulb";
    let linkTo: Placed | null = null;
    let atEdge = false;
    const skip = (q: Placed) => q.id === parent && dist(q.p, from) < CLEAR * 1.5;
    for (let s = 0; s < maxLen; s += STEP) {
      turn = turn * 0.8 + (R() - 0.5) * 0.07;
      h += turn;
      if (target) {
        const du = (target.u - u) * F.mu;
        const dv = (target.v - v) * F.mv;
        if (Math.hypot(du, dv) < STEP * 1.5) {
          path.push({ u: target.u, v: target.v, p: F.at(target.u, target.v), id });
          end = "through";
          break;
        }
        // Turn towards it, at most a few degrees a step, harder as it nears.
        let want = Math.atan2(dv, du) - h;
        want = Math.atan2(Math.sin(want), Math.cos(want));
        h += Math.max(-0.12, Math.min(0.12, want * (s > 40 ? 0.35 : 0.1)));
      }
      const nu = u + (Math.cos(h) * STEP) / F.mu;
      const nv = v + (Math.sin(h) * STEP) / F.mv;
      if (!inBox(nu, nv) && s > CLEAR) {
        atEdge = true;
        break;
      }
      const p = F.at(nu, nv);
      const hit = nearest(p, id, skip);
      if (hit && hit.d < CLEAR) break;
      u = nu;
      v = nv;
      path.push({ u, v, p, id });
    }
    const len = (path.length - 1) * STEP;
    if (len < 30 || (target && end !== "through")) {
      nextId--;
      return null;
    }
    // Wherever it stopped, a tip with another street a short way ahead, and
    // a clear way to it, links to it, so the tree has loops.
    const tip = path[path.length - 1]!.p;
    const near = nearest(tip, id, (q) => skip(q) || q.id === parent);
    // A link goes on ahead, not back, and never to the branch it grew from,
    // which would close a loop too small to hold a house.
    const back = path[Math.max(0, path.length - 4)]!.p;
    // At the back of the shops a street turns along them, a back lane, so
    // there a link may run sideways and further.
    const cosMin = atEdge ? 0 : 0.5;
    const ahead = (q: Placed) =>
      (tip.x - back.x) * (q.p.x - tip.x) + (tip.z - back.z) * (q.p.z - tip.z) >
      cosMin * dist(tip, back) * dist(tip, q.p);
    // Most streets lead on to another: a trunk nearly always, a branch more
    // often than not, a twig a little less.
    const linkP = depth === 1 ? 0.95 : depth === 2 ? 0.7 : 0.5;
    if (
      end !== "through" &&
      near &&
      near.d < (atEdge ? 80 : 60) &&
      ahead(near.q) &&
      roomAt(near.q.p) &&
      R() < linkP
    ) {
      const crossing = placed.some(
        (q) =>
          q.id !== near.q.id && q.id !== id && dist(q.p, mixp(tip, near.q.p, 0.5)) < near.d / 2 - 2,
      );
      if (!crossing) {
        linkTo = near.q;
        end = "link";
        joints.push(near.q.p);
      }
    }
    for (const q of path) placed.push({ ...q, id });
    const pts = path.map((q) => q.p);
    if (linkTo) pts.push(linkTo.p);
    line(LOK, pts, end === "bulb" ? { tree: true, bulb: pts[pts.length - 1]! } : { tree: true });
    tips[end === "bulb" ? "bulb" : end === "through" ? "through" : "linked"]++;
    // Branches leave at 60 to 100 degrees, every 45 to 80 m, on alternating
    // sides, and now and then on both sides at once: a crossing.
    if (depth < 3) {
      let side = R() < 0.5 ? 1 : -1;
      const every = lerp(80, 45, d);
      for (
        let at = between(0.6, 1.0) * every;
        at < len - LOK_FLOOR;
        at += between(0.8, 1.2) * every
      ) {
        const k = Math.round(at / STEP);
        const q = path[k]!;
        const q1 = path[Math.min(k + 1, path.length - 1)]!;
        const hh = Math.atan2((q1.v - q.v) * F.mv, (q1.u - q.u) * F.mu);
        if (!roomAt(q.p)) continue;
        joints.push(q.p);
        // Twigs are fewer than branches.
        if (depth === 2 && R() < 0.6) {
          side = -side;
          continue;
        }
        const sides = R() < 0.15 ? [1, -1] : [side];
        for (const sd of sides) {
          const hb = hh + sd * between(1.05, 1.75);
          // A branch that points at a free entrance on a big road steers for
          // it, and becomes another way out of the block.
          const x = depth === 1 ? freeSlotAhead(q, hb) : null;
          if (x) {
            const b = entry(x);
            if (grow(q.u, q.v, hb, 600, depth + 1, id, q.p, { u: b.eu, v: b.ev }) !== null) {
              open(x);
              continue;
            }
          }
          grow(q.u, q.v, hb, between(150, 320) / Math.sqrt(depth), depth + 1, id, q.p);
        }
        side = -side;
      }
    }
    return id;
  }

  // The first entrance's trunk runs through to a slot on another big road,
  // the opposite one if it can, so the tree is also a way through.
  const first = used[0]!;
  const exits = cand
    .filter((c) => c.name !== first.name)
    .sort(
      (a, b) =>
        (a.name === OPP[first.name] ? 0 : 1) - (b.name === OPP[first.name] ? 0 : 1) ||
        a.use - b.use,
    );
  let through = false;
  for (const x of exits.slice(0, 3)) {
    const a = entry(first);
    const b = entry(x);
    const trunk = grow(a.eu, a.ev, a.h, 1200, 1, -1, F.at(a.eu, a.ev), { u: b.eu, v: b.ev });
    if (trunk === null) continue;
    open(first);
    open(x);
    through = true;
    break;
  }
  // The other entrances grow trunks that, nearly always, join a street.
  const rest = used.filter(
    (m) =>
      m !== first &&
      (!through ||
        !exits
          .slice(0, 3)
          .some((x) => x === m && mouths.some((o) => o.t === m.t && o.side === m.name))),
  );
  for (const m of through ? rest : used) {
    if (
      mouths.some(
        (o) => o.t === m.t && o.side === m.name && o.key === blk.edges[m.name].key.join(","),
      )
    )
      continue;
    const e = entry(m);
    const trunk = grow(
      e.eu,
      e.ev,
      e.h + between(-0.3, 0.3),
      between(260, 480),
      1,
      -1,
      F.at(e.eu, e.ev),
    );
    if (trunk !== null) open(m);
  }
  blk.tips = tips;
}
