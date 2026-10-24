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
export type LotKind = "Ruko" | "Warung" | "House" | "Kos" | "Petak";

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

export interface Lot extends Pt {
  /** The way the front looks, a step of 1024. */
  fx: number;
  fz: number;
  w: number;
  d: number;
  kind: LotKind;
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

export function rowsIn(i: number, j: number): number {
  return g.rows_in(i, j, SEED) as number;
}

export function lotsIn(i: number, j: number): number {
  return g.lots_in(i, j, SEED) as number;
}

export function lotAt(i: number, j: number, row: number, k: number): Lot {
  const l = g.lot_at(i, j, row, k, SEED) as Bend;
  return {
    x: l.x as number,
    z: l.z as number,
    fx: signed(l.fx),
    fz: signed(l.fz),
    w: l.w as number,
    d: l.d as number,
    kind: (l.kind as Bend).$ as LotKind,
  };
}
