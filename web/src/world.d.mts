// The compiled world model (logic/world.bend), as the lab reads it. Every
// number is a U32: coordinates are signed centimetres in two's complement,
// positions along a road or across a frame are 65536ths, rolls and densities
// 1024ths.

export type Pt = { $: "Pt"; x: number; z: number };
type Curve = { $: "Curve"; p1: Pt; b: Pt; c: Pt; p2: Pt };
type Frame = { $: "Frame"; a: Pt; s: Curve; n: Curve; w: Curve; e: Curve; mu: number; mv: number };
export type List<T> = { $: "Con"; head: T; tail: List<T> } | { $: "Nil" };
/** A road along one side of a block, and the stretch of it the block owns. */
export type Edge = {
  $: "Edge";
  road: boolean;
  k0: number;
  k1: number;
  k2: number;
  len: number;
  a0: number;
  a1: number;
  t0: number;
  t1: number;
};
type Box = { $: "Box"; x0: number; x1: number; z0: number; z1: number };
/** A street in the block's metric frame: 0 tree, 1 ring lane, 2 mouth, 3 cross. */
export type Street = { $: "Street"; tag: number; bulb: boolean; pts: List<Pt> };
/** What a block became: 0 sawah, 1 kebun, 2 tree, 3 comb, 4 grid, 5 ring, 6 shops. */
type Fill = {
  $: "Fill";
  land: number;
  court: number;
  ring: Box;
  streets: List<Street>;
  mouths: List<{ $: "Mouth"; side: number; t: number }>;
  linked: number;
  bulb: number;
  thru: number;
};

declare const world: {
  node(seed: number, i: number, j: number): Pt;
  has_road(seed: number, i: number, j: number, east: boolean): boolean;
  road_code(i: number, j: number, east: boolean): number;
  curve_of(seed: number, i: number, j: number, east: boolean): Curve;
  curve_at(curve: Curve, t: number): Pt;
  road_length(seed: number, i: number, j: number, east: boolean): number;
  frame_of(seed: number, i: number, j: number): Frame;
  frame_at(frame: Frame, u: number, v: number): Pt;
  frame_line_length(frame: Frame, fixedU: boolean, at: number): number;
  density(seed: number, x: number, z: number): number;
  river_row(j: number): boolean;
  river_v(seed: number, i: number, j: number, u: number): number;
  side_mouth(seed: number, i: number, j: number, east: boolean, side: number): number;
  cell_cuts(seed: number, i: number, j: number): { $: "Cuts"; uc: number; vc: number };
  block_fill(
    seed: number,
    i: number,
    j: number,
    u0: number,
    u1: number,
    v0: number,
    v1: number,
    s: Edge,
    n: Edge,
    w: Edge,
    e: Edge,
  ): Fill;
};

export default world;
