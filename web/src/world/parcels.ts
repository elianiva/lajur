/**
 * Layer 4: parcels. Each cell's roads and blocks become placements: a lot per
 * building asset, civic courts inside ring blocks, and big round canopies
 * (mangga, beringin, flamboyan, bambu) wherever land is left.
 *
 * Everything is a function of (seed, i, j) and the cell, and every placement
 * stays inside its own cell's blocks, so cells stay order-free and never
 * overlap.
 */
import {
  ART,
  COL,
  LOK,
  along,
  density,
  hash,
  lerp,
  pt,
  segCurve,
  segExists,
  segKind,
  type Block,
  type Cell,
  type Frame,
  type Line,
  type Pt,
} from "./cells.ts";

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

/** Centreline to parcel front, by road class. */
const FRONT: Record<number, number> = { [ART]: 10, [COL]: 7, [LOK]: 3.5 };
/** Half the carriageway, by road class; the river counts as a road 28 m wide. */
export const ROAD: Record<number, number> = { [ART]: 7, [COL]: 4.5, [LOK]: 2, 0: 14 };

/** Lot sizes: frontage [min, max] by depth [min, max], and the gap after it. */
export const SIZE: Record<Use, [[number, number], [number, number], number]> = {
  rumah: [[8, 11], [10, 14], 1.5],
  petak: [[14, 18], [8, 10], 1],
  kos: [[10, 13], [12, 15], 1.5],
  warung: [[5, 7], [5, 7], 1],
  ruko: [[4.5, 6], [13, 16], 0],
  minimarket: [[13, 16], [16, 20], 3],
  bengkel: [[9, 12], [10, 14], 2],
  gudang: [[25, 35], [20, 28], 3],
  kantor: [[22, 28], [20, 26], 4],
  apartemen: [[22, 26], [22, 26], 5],
  rusun: [[30, 40], [12, 14], 5],
  mal: [[55, 70], [40, 50], 5],
  masjid: [[15, 20], [15, 20], 3],
  gereja: [[18, 24], [24, 30], 3],
  klenteng: [[16, 20], [18, 22], 3],
  sekolah: [[40, 50], [30, 38], 3],
  puskesmas: [[20, 26], [16, 20], 3],
  spbu: [[32, 40], [26, 32], 3],
};

/** How big a court may grow inside its ring, long side by short side. */
const COURT: Record<"alun" | "pasar" | "sekolah" | "gudang", [number, number]> = {
  alun: [120, 95],
  pasar: [80, 60],
  sekolah: [90, 60],
  gudang: [90, 65],
};

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
const cross = (o: Pt, a: Pt, b: Pt) => (a.x - o.x) * (b.z - o.z) - (a.z - o.z) * (b.x - o.x);
function segSeg(a: Pt, b: Pt, c: Pt, d: Pt): number {
  const d1 = cross(c, d, a);
  const d2 = cross(c, d, b);
  const d3 = cross(a, b, c);
  const d4 = cross(a, b, d);
  if (d1 * d2 < 0 && d3 * d4 < 0) return 0;
  return Math.min(pointSeg(a, c, d), pointSeg(b, c, d), pointSeg(c, a, b), pointSeg(d, a, b));
}
function polySegDist(poly: Pt[], a: Pt, b: Pt): number {
  if (inPoly(a, poly)) return 0;
  let m = Infinity;
  for (let k = 0; k < poly.length; k++)
    m = Math.min(m, segSeg(a, b, poly[k]!, poly[(k + 1) % poly.length]!));
  return m;
}
/** Two convex polygons overlap, by separating axes, with a small gap allowed. */
function overlap(A: Pt[], B: Pt[], gap = 0.3): boolean {
  for (const Q of [A, B])
    for (let k = 0; k < Q.length; k++) {
      const p = Q[k]!;
      const q = Q[(k + 1) % Q.length]!;
      const nx = q.z - p.z;
      const nz = p.x - q.x;
      const l = Math.hypot(nx, nz);
      let a0 = Infinity;
      let a1 = -Infinity;
      let b0 = Infinity;
      let b1 = -Infinity;
      for (const v of A) {
        const s = (v.x * nx + v.z * nz) / l;
        a0 = Math.min(a0, s);
        a1 = Math.max(a1, s);
      }
      for (const v of B) {
        const s = (v.x * nx + v.z * nz) / l;
        b0 = Math.min(b0, s);
        b1 = Math.max(b1, s);
      }
      if (a1 + gap <= b0 || b1 + gap <= a0) return false;
    }
  return true;
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

/** The lines a cell's parcels must keep clear of: its own, and its north and east roads. */
export function boundingLines(seed: number, c: Cell): Line[] {
  const { i, j } = c;
  const out = [...c.lines];
  if (segExists(seed, i, j + 1, "E"))
    out.push({
      kind: segKind(i, j + 1, "E"),
      pts: along(segCurve(seed, i, j + 1, "E"), 64),
      seg: `${i},${j + 1},E`,
    });
  if (segExists(seed, i + 1, j, "S"))
    out.push({
      kind: segKind(i + 1, j, "S"),
      pts: along(segCurve(seed, i + 1, j, "S"), 64),
      seg: `${i + 1},${j},S`,
    });
  return out;
}

interface Piece {
  a: Pt;
  b: Pt;
  kind: number;
}
interface Street {
  L: number;
  kind: number;
  at(s: number): { p: Pt; t: Pt };
}

// ---- One cell's parcels -----------------------------------------------------

export function parcels(seed: number, c: Cell): Plan {
  const { i, j, frame: F } = c;
  const H = (...xs: number[]) => hash(seed, 40, i, j, ...xs);

  // The roads that bound or cross this cell: its own lines and its north and
  // east lattice sides, which belong to the neighbours but are pure functions.
  const roads = boundingLines(seed, c);
  const segs = new Grid<Piece>(24);
  for (const l of roads) {
    const kind = l.river ? 0 : l.kind;
    for (let k = 0; k + 1 < l.pts.length; k++) {
      const s = { a: l.pts[k]!, b: l.pts[k + 1]!, kind };
      segs.add(s, bbox([s.a, s.b], ROAD[kind]! + 12));
    }
  }
  // Clearance from every road: true when the polygon keeps `pad` metres
  // beyond each carriageway, and 6 m from the river.
  const clear = (poly: Pt[], pad: (kind: number) => number) => {
    for (const s of segs.near(bbox(poly))) {
      const need = s.kind === 0 ? ROAD[0]! + 6 : ROAD[s.kind]! + pad(s.kind);
      if (polySegDist(poly, s.a, s.b) < need) return false;
    }
    return true;
  };

  const blocks: BlockArea[] = c.blocks.map((b) => {
    const poly = framePoly(F, b.u0, b.u1, b.v0, b.v1, 12);
    return { b, poly, box: bbox(poly) };
  });
  const blockAt = (p: Pt) =>
    blocks.find(
      (k) =>
        p.x >= k.box[0] &&
        p.x <= k.box[2] &&
        p.z >= k.box[1] &&
        p.z <= k.box[3] &&
        inPoly(p, k.poly),
    );

  const lots: Lot[] = [];
  const courts: CourtArea[] = [];
  const trees: Tree[] = [];
  const solid = new Grid<{ poly: Pt[] }>(24); // lots and courts: what a new lot may not touch
  const place = (use: Use, poly: Pt[]) => {
    if (!poly.every((p) => blockAt(p))) return false;
    // A lot keeps its front verge beyond every other road's front line.
    if (!clear(poly, (k) => FRONT[k]! - ROAD[k]! - 0.6)) return false;
    for (const o of solid.near(bbox(poly))) if (overlap(o.poly, poly)) return false;
    const lot = { use, poly };
    lots.push(lot);
    solid.add(lot, bbox(poly));
    return true;
  };

  // ---- Civic courts inside ring blocks ----------------------------------------
  for (const { b } of blocks) {
    if (!b.court || !b.inner) continue;
    const m = 3.5; // the ring lane's verge
    let { ru0, ru1, rv0, rv1 } = b.inner;
    ru0 += m / F.mu;
    ru1 -= m / F.mu;
    rv0 += m / F.mv;
    rv1 -= m / F.mv;
    if (b.mid?.axis === "u") ru1 = b.mid.t - 6 / F.mu;
    if (b.mid?.axis === "v") rv1 = b.mid.t - 6 / F.mv;
    // A court is town-sized, not block-sized: it sits against the ring lane
    // and the rest of the inside is kampung.
    const cap = COURT[b.court];
    const [cl, cs] = (ru1 - ru0) * F.mu >= (rv1 - rv0) * F.mv ? cap : [cap[1], cap[0]];
    const hu = H(b.u0 * 1e3, 60) < 0.5;
    const hv = H(b.v0 * 1e3, 61) < 0.5;
    if ((ru1 - ru0) * F.mu > cl) {
      const w = cl / F.mu;
      if (hu) ru1 = ru0 + w;
      else ru0 = ru1 - w;
    }
    if ((rv1 - rv0) * F.mv > cs) {
      const w = cs / F.mv;
      if (hv) rv1 = rv0 + w;
      else rv0 = rv1 - w;
    }
    const wu = (ru1 - ru0) * F.mu;
    const wv = (rv1 - rv0) * F.mv;
    const add = (use: CourtUse, u0: number, u1: number, v0: number, v1: number, yard = false) => {
      const court: CourtArea = { use, poly: framePoly(F, u0, u1, v0, v1, 8) };
      if (yard) court.yard = true;
      courts.push(court);
      if (use !== "alun") solid.add(court, bbox(court.poly));
      return court;
    };
    const outer = add(b.court, ru0, ru1, rv0, rv1, b.court === "alun" || b.court === "sekolah");
    solid.add(outer, bbox(outer.poly));
    if (b.court === "alun") {
      // A square field in the middle, the masjid on its west, a pendopo north.
      const g = 16;
      const fu0 = ru0 + Math.max(g, 34) / F.mu;
      const fu1 = ru1 - g / F.mu;
      const fv0 = rv0 + g / F.mv;
      const fv1 = rv1 - (g + 4) / F.mv;
      add("lapangan", fu0, fu1, fv0, fv1);
      const mid = (rv0 + rv1) / 2;
      const half = Math.min(14, wv / 2 - 4) / F.mv;
      add("masjid", ru0 + 3 / F.mu, ru0 + 30 / F.mu, mid - half, mid + half);
      const cu = (fu0 + fu1) / 2;
      const ph = Math.min(10, wu / 4) / F.mu;
      add("pendopo", cu - ph, cu + ph, fv1 + 3 / F.mv, rv1 - 2 / F.mv);
      // Beringin round the field.
      for (const [u, v] of [
        [fu0, fv0],
        [fu1, fv0],
        [fu0, fv1],
        [fu1, fv1],
      ] as const) {
        const p = F.at(u, v);
        trees.push({ x: p.x, z: p.z, r: 7.5, sp: "beringin" });
      }
    } else if (b.court === "sekolah") {
      const s = 0.55;
      if (wu >= wv) {
        add("sekolah", ru0, lerp(ru0, ru1, s), rv0, rv1);
        add("lapangan", lerp(ru0, ru1, s) + 4 / F.mu, ru1, rv0, rv1);
      } else {
        add("sekolah", ru0, ru1, rv0, lerp(rv0, rv1, s));
        add("lapangan", ru0, ru1, lerp(rv0, rv1, s) + 4 / F.mv, rv1);
      }
    }
  }

  // ---- Frontage lots along every road -------------------------------------------
  // What a lot facing a road of `kind`, in a block of `type`, at density d, is.
  const pick = (kind: number, type: Block["type"], d: number, h: number): Use => {
    if (kind !== LOK) {
      if (d > 0.72)
        return h < 0.34
          ? "ruko"
          : h < 0.46
            ? "kantor"
            : h < 0.56
              ? "apartemen"
              : h < 0.66
                ? "minimarket"
                : h < 0.74
                  ? "rusun"
                  : h < 0.77
                    ? "mal"
                    : h < 0.87
                      ? "warung"
                      : "kos";
      return h < 0.4
        ? "ruko"
        : h < 0.52
          ? "warung"
          : h < 0.66
            ? "rumah"
            : h < 0.74
              ? "minimarket"
              : h < 0.83
                ? "bengkel"
                : h < 0.9
                  ? "kos"
                  : d < 0.32 && h < 0.93
                    ? "gudang"
                    : "ruko";
    }
    if (type === "grid" && d > 0.72)
      return h < 0.25
        ? "kos"
        : h < 0.45
          ? "ruko"
          : h < 0.6
            ? "kantor"
            : h < 0.74
              ? "apartemen"
              : h < 0.86
                ? "rusun"
                : h < 0.95
                  ? "minimarket"
                  : "warung";
    if (type === "shops") return h < 0.5 ? "ruko" : h < 0.8 ? "rumah" : "warung";
    return h < 0.56
      ? "rumah"
      : h < 0.7
        ? "petak"
        : h < 0.7 + (d > 0.5 ? 0.14 : 0.05)
          ? "kos"
          : h < 0.89
            ? "warung"
            : "rumah";
  };
  const ribbonUse = (h: number): Use => (h < 0.74 ? "rumah" : h < 0.9 ? "warung" : "petak");
  const civicUse = (kind: number, d: number, h: number): Use | null =>
    kind === ART && h < 0.05
      ? "spbu"
      : h < 0.11
        ? "masjid"
        : h < 0.16
          ? "sekolah"
          : h < 0.18
            ? "puskesmas"
            : h < 0.2
              ? "gereja"
              : d > 0.55 && h < 0.21
                ? "klenteng"
                : null;

  const lotAt = (geo: Street, s: number, side: number, use: Use, h: number) => {
    const [[w0, w1], [d0, d1]] = SIZE[use];
    const w = lerp(w0, w1, h);
    const dep = lerp(d0, d1, hash(seed, 41, Math.round(h * 1e6)));
    if (s + w > geo.L - 2) return 0;
    const { p, t } = geo.at(s + w / 2);
    const n = pt(-t.z * side, t.x * side);
    const f = FRONT[geo.kind]! + 0.3;
    const q = (a: number, b: number) => pt(p.x + t.x * a + n.x * b, p.z + t.z * a + n.z * b);
    const poly = [q(-w / 2, f), q(w / 2, f), q(w / 2, f + dep), q(-w / 2, f + dep)];
    return place(use, poly) ? w : 0;
  };
  const streetOf = (l: Line): Street => {
    const cum = [0];
    for (let k = 1; k < l.pts.length; k++)
      cum.push(
        cum[k - 1]! + Math.hypot(l.pts[k]!.x - l.pts[k - 1]!.x, l.pts[k]!.z - l.pts[k - 1]!.z),
      );
    const L = cum[cum.length - 1]!;
    const at = (s: number) => {
      let k = 1;
      while (k < cum.length - 1 && cum[k]! < s) k++;
      const a = l.pts[k - 1]!;
      const b = l.pts[k]!;
      const t = (s - cum[k - 1]!) / (cum[k]! - cum[k - 1]! || 1);
      const len = Math.hypot(b.x - a.x, b.z - a.z) || 1;
      return {
        p: pt(lerp(a.x, b.x, t), lerp(a.z, b.z, t)),
        t: pt((b.x - a.x) / len, (b.z - a.z) / len),
      };
    };
    return { L, at, kind: l.kind };
  };
  const streets = roads.filter((l) => l.kind && !l.river).map((l) => ({ l, geo: streetOf(l) }));
  // Main roads first, so shops claim the corners.
  streets.sort((a, b) => a.l.kind - b.l.kind);
  // The block and density beside a point of a road.
  const beside = (geo: Street, s: number, side: number) => {
    const { p, t } = geo.at(Math.min(s, geo.L));
    const off = FRONT[geo.kind]! + 6;
    const q = pt(p.x - t.z * side * off, p.z + t.x * side * off);
    const k = blockAt(q);
    return k ? { b: k.b, d: density(seed, q.x, q.z) } : null;
  };

  // Civic singles, one roll per 100 m of road side.
  for (const [n, { l, geo }] of streets.entries())
    for (const side of [1, -1])
      for (let s0 = 0; s0 < geo.L - 40; s0 += 100) {
        const h = H(n, side, s0, 42);
        const at = beside(geo, s0 + 30, side);
        if (!at) continue;
        const open = at.b.type === "sawah" || at.b.type === "kebun";
        const use = civicUse(l.kind, at.d, open ? h * 2.5 : h);
        if (use)
          lotAt(geo, s0 + 10 + hash(seed, 43, Math.round(h * 1e6)) * 40, side, use, (h * 7) % 1);
      }

  // Then every road side, walked lot by lot.
  for (const [n, { l, geo }] of streets.entries())
    for (const side of [1, -1]) {
      let s = 2 + H(n, side, 1) * 5;
      let run = 0;
      let step = 0;
      while (s < geo.L - 4) {
        step++;
        const h = H(n, side, step);
        const at = beside(geo, s + 4, side);
        if (!at) {
          s += 4;
          continue;
        }
        const type = at.b.type;
        let use: Use;
        if (type === "sawah" || type === "kebun") {
          // A ribbon of houses along a road through the fields, 160 m at a time.
          const stretch = H(n, side, 900 + Math.floor(s / 160));
          if (stretch > (type === "kebun" ? 0.65 : 0.5)) {
            s += 6;
            continue;
          }
          use = ribbonUse(h);
        } else use = run > 0 ? "ruko" : pick(l.kind, type, at.d, h);
        if (use === "ruko" && run === 0) run = 3 + Math.floor(H(n, side, step, 2) * 7);
        let w = lotAt(geo, s, side, use, H(n, side, step, 3));
        if (!w && use !== "rumah" && use !== "warung")
          w = lotAt(geo, s, side, "rumah", H(n, side, step, 4));
        if (!w && H(n, side, step, 7) < 0.25)
          w = lotAt(geo, s, side, "warung", H(n, side, step, 5));
        if (w) {
          s +=
            w + (run > 1 ? 0 : SIZE[use][2] + H(n, side, step, 6) * (type === "sawah" ? 6 : 1.5));
          if (run > 0) run--;
        } else {
          s += 3;
          run = 0;
        }
      }
    }

  // ---- Back lots ------------------------------------------------------------------
  // Kampung land behind the frontage fills with houses reached by gangs, which
  // the road layer does not draw. Each faces the nearest street.
  for (const { b, poly, box } of blocks) {
    if (b.type === "sawah" || b.type === "kebun") continue;
    const core = b.type === "grid" && b.d > 0.72;
    const keep = b.type === "shops" ? 0.6 : core ? 0.5 : 0.88;
    const step = core ? 26 : 11;
    for (let x = Math.floor(box[0] / step); x * step < box[2]; x++)
      for (let z = Math.floor(box[1] / step); z * step < box[3]; z++) {
        const h = hash(seed, 70, x, z);
        if (h >= keep) continue;
        const p = pt(
          x * step + (hash(seed, 71, x, z) - 0.5) * 3,
          z * step + (hash(seed, 72, x, z) - 0.5) * 3,
        );
        if (!inPoly(p, poly)) continue;
        let best: Piece | null = null;
        let bd = 70;
        for (const s of segs.near([p.x - 70, p.z - 70, p.x + 70, p.z + 70])) {
          if (s.kind === 0) continue;
          const d = pointSeg(p, s.a, s.b);
          if (d < bd) {
            bd = d;
            best = s;
          }
        }
        if (!best) continue;
        const len = Math.hypot(best.b.x - best.a.x, best.b.z - best.a.z) || 1;
        const t = pt((best.b.x - best.a.x) / len, (best.b.z - best.a.z) / len);
        const n = pt(-t.z, t.x);
        const h2 = hash(seed, 73, x, z);
        const use: Use = core
          ? h2 < 0.4
            ? "apartemen"
            : h2 < 0.7
              ? "rusun"
              : "kantor"
          : h2 < 0.68
            ? "rumah"
            : h2 < 0.82
              ? "petak"
              : b.d > 0.5 || h2 < 0.9
                ? "kos"
                : "rumah";
        const [[w0, w1], [d0, d1]] = SIZE[use];
        const w = lerp(w0, w1, h * 0.8) * (core ? 1 : 0.85);
        const dep = lerp(d0, d1, h2) * (core ? 1 : 0.85);
        const q = (a: number, c: number) => pt(p.x + t.x * a + n.x * c, p.z + t.z * a + n.z * c);
        place(use, [
          q(-w / 2, -dep / 2),
          q(w / 2, -dep / 2),
          q(w / 2, dep / 2),
          q(-w / 2, dep / 2),
        ]);
      }
  }

  // ---- Trees ------------------------------------------------------------------
  // Big round canopies only: mangga mostly, flamboyan on main roads, beringin
  // now and then, bambu along the river. No palms.
  const lotGrid = new Grid<Lot>(24);
  for (const o of lots) lotGrid.add(o, bbox(o.poly));
  const inLot = (p: Pt) =>
    [...lotGrid.near([p.x - 1, p.z - 1, p.x + 1, p.z + 1])].some((o) => inPoly(p, o.poly));
  const inCourt = (p: Pt) => courts.some((o) => o.use !== "alun" && inPoly(p, o.poly));
  const nearLot = (p: Pt, r: number) => lotGrid.near([p.x - r, p.z - r, p.x + r, p.z + r]).size > 0;
  const roadGap = (p: Pt, r: number) => {
    let m = Infinity;
    for (const s of segs.near([p.x - r - 16, p.z - r - 16, p.x + r + 16, p.z + r + 16]))
      m = Math.min(m, pointSeg(p, s.a, s.b) - ROAD[s.kind]!);
    return m;
  };
  const treeAt = (p: Pt, r: number, sp: Species) => trees.push({ x: p.x, z: p.z, r, sp });
  // Street trees on the verges of main roads.
  for (const [n, { l, geo }] of streets.entries()) {
    if (l.kind === LOK) continue;
    for (const side of [1, -1])
      for (let s = 6, k = 0; s < geo.L - 6; s += 11, k++) {
        const h = H(n, side, 5000 + k);
        if (h < 0.2) continue;
        const { p, t } = geo.at(s);
        const off = ROAD[l.kind]! + 1.6;
        const q = pt(p.x - t.z * side * off, p.z + t.x * side * off);
        if (!blockAt(q) || roadGap(q, 0) < 1.2 || inCourt(q)) continue;
        treeAt(q, lerp(3, 4.5, h), h > 0.88 ? "flamboyan" : "mangga");
      }
  }
  // The rest of the land, on a jittered 7 m lattice.
  for (const { b, poly, box } of blocks) {
    const step = b.type === "kebun" ? 6.5 : 7;
    const core = b.type === "grid" && b.d > 0.72;
    for (let x = Math.floor(box[0] / step); x * step < box[2]; x++)
      for (let z = Math.floor(box[1] / step); z * step < box[3]; z++) {
        const h = hash(seed, 50, x, z);
        const h2 = hash(seed, 51, x, z);
        const p = pt(x * step + (h - 0.5) * step * 0.8, z * step + (h2 - 0.5) * step * 0.8);
        if (!inPoly(p, poly)) continue;
        const r = lerp(3, 5.8, hash(seed, 52, x, z));
        const g = roadGap(p, r);
        if (g < r * 0.5 + 1) continue;
        if (inLot(p) || inCourt(p)) continue;
        const river = [...segs.near([p.x - 30, p.z - 30, p.x + 30, p.z + 30])].some(
          (s) => s.kind === 0 && pointSeg(p, s.a, s.b) < 32,
        );
        const clump = hash(seed, 53, Math.floor(p.x / 70), Math.floor(p.z / 70)) < 0.14;
        const keep =
          b.type === "kebun"
            ? 0.92
            : b.type === "sawah"
              ? river
                ? 0.6
                : nearLot(p, 14)
                  ? 0.8
                  : clump
                    ? 0.85
                    : 0
              : core
                ? 0.2
                : b.type === "shops"
                  ? 0.55
                  : 0.8;
        if (hash(seed, 54, x, z) >= keep) continue;
        const roll = hash(seed, 55, x, z);
        const sp: Species =
          river && b.type !== "kebun" && roll < 0.6
            ? "bambu"
            : roll < 0.04
              ? "beringin"
              : roll < 0.1
                ? "flamboyan"
                : "mangga";
        treeAt(p, sp === "beringin" ? r + 2.5 : sp === "bambu" ? r * 0.7 : r, sp);
      }
  }
  return { lots, courts, trees, blocks };
}
