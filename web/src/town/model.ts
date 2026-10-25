import graph from "../town.mjs";

/**
 * The town, read out of the model.
 *
 * `logic/town.bend` decides everything: where a junction sits, how its street
 * bends, what each approach carries, and which lot holds which building. This
 * file only unwraps the compiler's encoding into plain numbers. It decides
 * nothing, and it must not: a rule that lives here cannot be proved.
 */

type Bend = { $: string } & Record<string, unknown>;

const g = graph as unknown as Record<string, (...args: unknown[]) => unknown>;

/** The seed the game ships. */
export const SEED = g.seed_of_town() as number;
export const COLS = g.cols() as number;
export const ROWS = g.rows() as number;
export const PITCH_CM = g.pitch_cm() as number;
export const MARGIN_CM = g.margin_cm() as number;
export const PAVEMENT_CM = g.pavement_cm() as number;

export type DirName = "North" | "East" | "South" | "West";
export const DIRS: DirName[] = ["North", "East", "South", "West"];

const dir = (d: DirName) => ({ $: d });

function bool(value: unknown): boolean {
  return value === true || (value as Bend).$ === "True";
}

function signed(value: unknown): number {
  const s = value as { size: number; down: unknown };
  return bool(s.down) ? -s.size : s.size;
}

function list<T>(value: unknown, read: (item: Bend) => T): T[] {
  const out: T[] = [];
  let node = value as Bend;
  while (node.$ === "Con") {
    out.push(read(node.head as Bend));
    node = node.tail as Bend;
  }
  return out;
}

export interface Pt {
  x: number;
  z: number;
}

export interface Sample extends Pt {
  /** Where the street is heading, a step of 1024. */
  dx: number;
  dz: number;
}

export type Mark = "StopLine" | "GiveWayLine" | "NoLine";
export type Post = "PriorityWarning" | "GiveWaySign" | "StopSign" | "NoSign";
export type Control = "Signal" | "Roundabout" | "Uncontrolled";
export type Shape = "FourEqual" | "FourMajor" | "StraightT" | "SkewT" | "Bend";
export type LotKind =
  | "Ruko"
  | "Warung"
  | "House"
  | "Kos"
  | "Petak"
  | "Filler"
  | "Minimarket"
  | "Bengkel"
  | "Gudang";
export type PropKind = "Mangga" | "Palm" | "Kamboja" | "Semak" | "Pole" | "Pot";

export interface Approach {
  d: DirName;
  present: boolean;
  /** Half the carriageway, in centimetres. */
  half: number;
  mark: Mark;
  line: number;
  zebra: number;
  head: boolean;
  post: Post;
}

export interface Prop extends Pt {
  /** The ground it takes, in centimetres: half a crown for a tree. */
  r: number;
  kind: PropKind;
}

export interface Lot extends Pt {
  /** The way the front looks, a step of 1024. */
  fx: number;
  fz: number;
  w: number;
  d: number;
  kind: LotKind;
  /**
   * The footprint, in centimetres, clockwise from the street side: `a` and `b`
   * are the two front corners on the frontage line, `c` and `d` the two back
   * corners. A cell of a band, so the back edge may be shorter than the front.
   */
  ax: number;
  az: number;
  bx: number;
  bz: number;
  cx: number;
  cz: number;
  dx: number;
  dz: number;
}

/** The river runs between this column and the next; only the bridges cross. */
export function riverGap(): number {
  return g.river_gap() as number;
}

export function bridge(j: number): boolean {
  return bool(g.bridge(j));
}

export function site(i: number, j: number): Pt {
  const p = g.site(i, j, SEED) as Pt;
  return { x: p.x, z: p.z };
}

export function has(i: number, j: number, d: DirName): boolean {
  return bool(g.has(i, j, dir(d)));
}

export function samples(i: number, j: number, d: DirName): Sample[] {
  return list(g.samples(i, j, dir(d), SEED), (s) => ({
    x: s.x as number,
    z: s.z as number,
    dx: signed(s.dx),
    dz: signed(s.dz),
  }));
}

export function control(i: number, j: number): Control {
  return (g.control(i, j) as Bend).$ as Control;
}

export function shape(i: number, j: number): Shape {
  return (g.shape(i, j, SEED) as Bend).$ as Shape;
}

export function approaches(i: number, j: number): Approach[] {
  return list(g.approaches(i, j, SEED), (a) => ({
    d: (a.d as Bend).$ as DirName,
    present: bool(a.present),
    half: a.half as number,
    mark: (a.mark as Bend).$ as Mark,
    line: a.line_cm as number,
    zebra: a.zebra_cm as number,
    head: bool(a.head),
    post: (a.post as Bend).$ as Post,
  }));
}

/** A block exists where both of its bounding streets do. */
export function blockExists(i: number, j: number): boolean {
  return bool(g.block_exists(i, j));
}

/** How many rings of lots a block holds, counting the frontage as ring 0. */
export function ringsIn(i: number, j: number): number {
  return g.rings_in(i, j, SEED) as number;
}

/** Lots on one of a block's four frontages, at one ring in from it. */
export function lotsOn(i: number, j: number, side: number, ring: number): number {
  return g.lots_on(i, j, side, ring, SEED) as number;
}

/** How far from the node an approach's kerb stops, in centimetres. */
export function mouthCm(i: number, j: number, d: DirName): number {
  return g.mouth_cm(i, j, dir(d), SEED) as number;
}

/** One end of that mouth: `left` is the left of travel, as on the road. */
export function mouthSide(i: number, j: number, d: DirName, left: boolean): Pt {
  const p = g.mouth_side(i, j, dir(d), left, SEED) as Pt;
  return { x: p.x, z: p.z };
}

/** The point between the two kerb ends of a mouth. */
export function mouthMid(i: number, j: number, d: DirName): Pt {
  const p = g.mouth_mid(i, j, dir(d), SEED) as Pt;
  return { x: p.x, z: p.z };
}

/** Where the two kerbs of a corner would meet if the return were square. */
export function cornerBetween(i: number, j: number, a: DirName, b: DirName): Pt {
  const p = g.corner_between(i, j, dir(a), dir(b), SEED) as Pt;
  return { x: p.x, z: p.z };
}

/** The kerb return of a junction, in centimetres. */
export function junctionRadius(i: number, j: number): number {
  return g.junction_radius_cm(i, j, SEED) as number;
}

export function lotAt(i: number, j: number, side: number, ring: number, k: number): Lot {
  const l = g.lot_at(i, j, side, ring, k, SEED) as Bend;
  return {
    x: l.x as number,
    z: l.z as number,
    fx: signed(l.fx),
    fz: signed(l.fz),
    w: l.w as number,
    d: l.d as number,
    kind: (l.kind as Bend).$ as LotKind,
    ax: l.ax as number,
    az: l.az as number,
    bx: l.bx as number,
    bz: l.bz as number,
    cx: l.cx as number,
    cz: l.cz as number,
    dx: l.dx as number,
    dz: l.dz as number,
  };
}

/** The prop that stands on the pavement in front of lot `t`. */
export function propAt(i: number, j: number, side: number, t: number): Prop {
  const p = g.prop_at(i, j, side, t, SEED) as Bend;
  return {
    x: p.x as number,
    z: p.z as number,
    r: p.r as number,
    kind: (p.kind as Bend).$ as PropKind,
  };
}

/** The grid of lots that fills a block's core. */
export function coreLots(i: number, j: number): [number, number] {
  return [g.core_lots_w(i, j, SEED) as number, g.core_lots_d(i, j, SEED) as number];
}

/**
 * A point of a block's core, in thousand-and-twenty-fourths of the core
 * itself. The four corners of the block's ground are (0,0) to (1024,1024).
 */
export function coreAt(i: number, j: number, u: number, v: number): Pt {
  const p = g.core_at(i, j, u, v, SEED) as Pt;
  return { x: p.x, z: p.z };
}

/** Whether a core cell stands open: a kebun with a tree, or a yard block's square. */
export function coreOpen(i: number, j: number, a: number, b: number): boolean {
  return bool(g.core_open(i, j, a, b, SEED));
}

/** The tree of an open core cell. A kebun holds a tree, never furniture. */
export interface CoreTree extends Pt {
  /** Half the crown, in centimetres. */
  r: number;
  kind: "Mangga" | "Palm" | "Kamboja";
}

export function coreTree(i: number, j: number, a: number, b: number): CoreTree {
  const p = g.core_tree(i, j, a, b, SEED) as Bend;
  return {
    x: p.x as number,
    z: p.z as number,
    r: p.r as number,
    kind: (p.kind as Bend).$ as CoreTree["kind"],
  };
}

export function coreLotAt(i: number, j: number, a: number, b: number): Lot {
  const l = g.core_lot_at(i, j, a, b, SEED) as Bend;
  return {
    x: l.x as number,
    z: l.z as number,
    fx: signed(l.fx),
    fz: signed(l.fz),
    w: l.w as number,
    d: l.d as number,
    kind: (l.kind as Bend).$ as LotKind,
    ax: l.ax as number,
    az: l.az as number,
    bx: l.bx as number,
    bz: l.bz as number,
    cx: l.cx as number,
    cz: l.cz as number,
    dx: l.dx as number,
    dz: l.dz as number,
  };
}

/** A street cut inside a block: a lokal street, a gang that links, or a stub that ends. */
export interface Split {
  kind: "Through" | "Gang" | "Stub";
  a: Pt;
  b: Pt;
  /** Half the carriageway, in centimetres. */
  half: number;
}

const SPLIT_KINDS = [undefined, "Through", "Gang", "Stub"] as const;
const SPLIT_HALF = [0, 300, 150, 150];

/** The paths a block can be cut along; node 1 is the block itself. */
export const SPLIT_PATHS = [1, 2, 3, 4, 5, 6, 7];

/** What the block's cut at a path is, if it makes one. */
export function splitAt(i: number, j: number, p: number): Split | undefined {
  const code = g.split_code(i, j, p, SEED) as number;
  const kind = SPLIT_KINDS[code];
  if (!kind) return undefined;
  const a = g.split_start(i, j, p, SEED) as Pt;
  const b = g.split_end(i, j, p, SEED) as Pt;
  return { kind, a: { x: a.x, z: a.z }, b: { x: b.x, z: b.z }, half: SPLIT_HALF[code]! };
}

/** Whether a frontage lot is built, or left out because a cut runs through it. */
export function lotBuilt(i: number, j: number, side: number, ring: number, k: number): boolean {
  return bool(g.lot_built(i, j, side, ring, k, SEED));
}

/** Whether the prop in front of frontage lot `k` stands. */
export function propBuilt(i: number, j: number, side: number, k: number): boolean {
  return bool(g.prop_built(i, j, side, k, SEED));
}

export function coreLotBuilt(i: number, j: number, a: number, b: number): boolean {
  return bool(g.core_lot_built(i, j, a, b, SEED));
}

export function coreTreeBuilt(i: number, j: number, a: number, b: number): boolean {
  return bool(g.core_tree_built(i, j, a, b, SEED));
}
