// The compiled world model (logic/world.bend), as the lab reads it. Every
// number is a U32: coordinates are signed centimetres in two's complement,
// positions along a road or across a frame are 65536ths, rolls and densities
// 1024ths.

export type Pt = { $: "Pt"; x: number; z: number };
type Curve = { $: "Curve"; p1: Pt; b: Pt; c: Pt; p2: Pt };
type Frame = { $: "Frame"; a: Pt; s: Curve; n: Curve; w: Curve; e: Curve; mu: number; mv: number };
export type List<T> = { $: "Con"; head: T; tail: List<T> } | { $: "Nil" };
type Box = { $: "Box"; x0: number; x1: number; z0: number; z1: number };
/** What a block became: 0 sawah, 1 kebun, 2 tree, 3 comb, 4 grid, 5 ring, 6 shops. */
type Fill = {
  $: "Fill";
  land: number;
  court: number;
  ring: Box;
  linked: number;
  bulb: number;
  thru: number;
};
/** A line of a cell, world centimetres; see logic/world.bend for its tags. */
type Line = { $: "Line"; kind: number; tag: number; pts: List<Pt> };
type Blk = {
  $: "Blk";
  u0: number;
  u1: number;
  v0: number;
  v1: number;
  d: number;
  s_road: boolean;
  n_road: boolean;
  w_road: boolean;
  e_road: boolean;
  fill: Fill;
};
type Cell = { $: "Cell"; f: Frame; lines: List<Line>; blocks: List<Blk> };

declare const world: {
  node(seed: number, i: number, j: number): Pt;
  has_road(seed: number, i: number, j: number, east: boolean): boolean;
  road_code(i: number, j: number, east: boolean): number;
  curve_of(seed: number, i: number, j: number, east: boolean): Curve;
  curve_at(curve: Curve, t: number): Pt;
  frame_of(seed: number, i: number, j: number): Frame;
  frame_at(frame: Frame, u: number, v: number): Pt;
  density(seed: number, x: number, z: number): number;
  cell_of(seed: number, i: number, j: number): Cell;
};

export default world;
