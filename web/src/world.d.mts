// The compiled world model (logic/world.bend), as the lab reads it. Every
// number is a U32: coordinates are signed centimetres in two's complement,
// positions along a road or across a frame are 65536ths, rolls and densities
// 1024ths.

type Pt = { $: "Pt"; x: number; z: number };
type Curve = { $: "Curve"; p1: Pt; b: Pt; c: Pt; p2: Pt };
type Frame = { $: "Frame"; a: Pt; s: Curve; n: Curve; w: Curve; e: Curve; mu: number; mv: number };
type List<T> = { $: "Con"; head: T; tail: List<T> } | { $: "Nil" };

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
  slots(
    seed: number,
    k0: number,
    k1: number,
    k2: number,
    len: number,
    a0: number,
    a1: number,
  ): List<number>;
  land(density: number, roll: number): number;
  court(density: number, roll: number): number;
};

export default world;
