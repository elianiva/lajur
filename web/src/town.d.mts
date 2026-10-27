// The contract with the town model. `town.mjs` is generated from
// logic/town.bend (a flat list over logic/town/) by `vp run logic` (and by every `vp dev` / `vp build`), so
// this file is hand-written to say what that module exports.
//
// Bend's JS target represents a constructor as `{ $: "Name", field: value }`,
// a list as Con/Nil, and leaves U32 and Nat as plain numbers.
//
// Nothing here decides anything: it names values the model computes.

export type Constructor<T extends string> = { $: T };

export type BendList<T> = Constructor<"Nil"> | { $: "Con"; head: T; tail: BendList<T> };

export type Dir = Constructor<"North" | "East" | "South" | "West">;
export type Signed = { $: "Signed"; size: number; down: Constructor<"True" | "False"> };
export type Point = { $: "Pt"; x: number; z: number };
export type SamplePoint = { $: "Sample"; x: number; z: number; dx: Signed; dz: Signed };
export type ApproachRecord = {
  $: "Approach";
  d: Dir;
  present: Constructor<"True" | "False">;
  half: number;
  mark: Constructor<"StopLine" | "GiveWayLine" | "NoLine">;
  line_cm: number;
  zebra_cm: number;
  head: Constructor<"True" | "False">;
  post: Constructor<"PriorityWarning" | "GiveWaySign" | "StopSign" | "NoSign">;
};
export type PropRecord = {
  $: "Prop";
  x: number;
  z: number;
  r: number;
  kind: Constructor<"Mangga" | "Palm" | "Kamboja" | "Semak" | "Pole" | "Pot">;
};

export type LotRecord = {
  $: "Lot";
  x: number;
  z: number;
  fx: Signed;
  fz: Signed;
  w: number;
  d: number;
  kind: Constructor<
    "Ruko" | "Warung" | "House" | "Kos" | "Petak" | "Filler" | "Minimarket" | "Bengkel" | "Gudang"
  >;
  ax: number;
  az: number;
  bx: number;
  bz: number;
  cx: number;
  cz: number;
  dx: number;
  dz: number;
};

export type Control = Constructor<"Signal" | "Roundabout" | "Uncontrolled">;
export type Shape =
  | Constructor<"FourEqual">
  | Constructor<"FourMajor">
  | Constructor<"StraightT">
  | Constructor<"SkewT">
  | Constructor<"Bend">;

declare const town: {
  seed_of_town(): number;
  cols(): number;
  rows(): number;
  pitch_cm(): number;
  margin_cm(): number;
  pavement_cm(): number;
  row_depth_cm(): number;
  gang_cm(): number;
  site(i: number, j: number, seed: number): Point;
  has(i: number, j: number, d: Dir): Constructor<"True" | "False">;
  samples(i: number, j: number, d: Dir, seed: number): BendList<SamplePoint>;
  control(i: number, j: number): Control;
  shape(i: number, j: number, seed: number): Shape;
  approaches(i: number, j: number, seed: number): BendList<ApproachRecord>;
  block_exists(i: number, j: number): Constructor<"True" | "False">;
  rings_in(i: number, j: number, seed: number): number;
  lots_on(i: number, j: number, side: number, ring: number, seed: number): number;
  lot_at(i: number, j: number, side: number, ring: number, k: number, seed: number): LotRecord;
  core_lots_w(i: number, j: number, seed: number): number;
  core_lots_d(i: number, j: number, seed: number): number;
  core_open(i: number, j: number, a: number, b: number, seed: number): boolean;
  core_lot_at(i: number, j: number, a: number, b: number, seed: number): LotRecord;
  prop_at(i: number, j: number, side: number, k: number, seed: number): PropRecord;
  lot_built(
    i: number,
    j: number,
    side: number,
    ring: number,
    t: number,
    seed: number,
  ): Constructor<"True" | "False">;
  prop_built(
    i: number,
    j: number,
    side: number,
    t: number,
    seed: number,
  ): Constructor<"True" | "False">;
  core_lot_built(
    i: number,
    j: number,
    a: number,
    b: number,
    seed: number,
  ): Constructor<"True" | "False">;
  core_tree_built(
    i: number,
    j: number,
    a: number,
    b: number,
    seed: number,
  ): Constructor<"True" | "False">;
  split_code(i: number, j: number, p: number, seed: number): number;
  cut_steps(): number;
  split_point(i: number, j: number, p: number, k: number, seed: number): Point;
  rect_of(
    i: number,
    j: number,
    p: number,
    seed: number,
  ): { $: "Rect"; u0: number; u1: number; v0: number; v1: number };
  patch(i: number, j: number, u: number, v: number, seed: number): Point;
};

export default town;
