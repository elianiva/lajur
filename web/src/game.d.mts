// The contract with the Bend model. `game.mjs` is generated from
// logic/game.bend by `vp run logic` (and by every `vp dev` / `vp build`), so
// this file is hand-written to say what that module exports.
//
// Bend's JS target represents a constructor as `{ $: "Name", field: value }`,
// a list as Con/Nil, and leaves U32 as a plain number.
//
// Nothing here decides anything: it names values the model computes.

export type Constructor<T extends string> = { $: T };

export type Lane = Constructor<"Inner" | "Middle" | "Outer">;
export type Signal = Constructor<"Off" | "ToLeft" | "ToRight">;
export type Body = Constructor<"Sedan" | "Hatch" | "Taxi" | "Van" | "Bus" | "Truck">;
export type Status = Constructor<"Driving" | "Crashed">;
/** One road of the world's lattice, from crossing (i, j) toward `dir`: 0 north, 1 east, 2 south, 3 west. */
export type Leg =
  | { $: "Leg"; i: number; j: number; dir: number; length: number }
  /** A collector inside cell (ci, cj), from parameter t0 toward `dir`. */
  | { $: "Cut"; ci: number; cj: number; dir: number; t0: number; length: number };
/** A place to turn off a road; the renderer only carries it. */
export type Door = Constructor<"Door" | "Gate">;
/** One way of a lokal street network; the renderer only carries it. */
export type Way = Constructor<"Way">;

export type Pt = { $: "Pt"; x: number; z: number };

/** A stretch of the route: points in driving order, its length, and the part driven, in centimetres. */
export type Piece = {
  $: "Piece";
  id: number;
  pts: BendList<Pt>;
  length: number;
  from: number;
  to: number;
};

export type BendList<T> = Constructor<"Nil"> | { $: "Con"; head: T; tail: BendList<T> };

export type Car = {
  $: "Car";
  id: number;
  lane: Lane;
  /** Centimetres ahead of the player. */
  gap: number;
  speed: number;
  body: Body;
  colour: number;
};

export type Player = {
  $: "Player";
  lane: Lane;
  speed: number;
  signal: Signal;
  lamp: number;
};

export type Controls = {
  $: "Controls";
  left: boolean;
  right: boolean;
  up: boolean;
  down: boolean;
};

export type World = {
  $: "World";
  tick: number;
  player: Player;
  traffic: BendList<Car>;
  oncoming: BendList<Car>;
  distance: number;
  zone: Constructor<string>;
  charges: BendList<number>;
  status: Status;
  held: Controls;
  residual: number;
  leg: Leg;
  along: number;
  /** The turn chosen at the crossing ahead: 0 left, 1 straight on, 2 right. */
  turn: number;
  seed: number;
};

export type Phase = Constructor<"Running" | "Over" | "Held" | "Wrecked">;

/** A passenger waiting (`aboard` false) or being carried (true) to a stop on a road. */
export type Order = {
  $: "Order";
  aboard: boolean;
  ki: number;
  kj: number;
  east: boolean;
  t: number;
  cm: number;
  fare: number;
  /** The tick the drop-off is due by. */
  due: number;
};

/** A charge written up: the rule, the tick it was written and its licence points. */
export type Ticket = { $: "Ticket"; id: number; tick: number; points: number };

export type Shift = {
  $: "Shift";
  drive: World;
  points: number;
  /** Newest first. */
  tickets: BendList<Ticket>;
  live: BendList<Ticket>;
  phase: Phase;
  order: Order;
  earned: number;
  served: number;
};

export interface Game {
  start(): World;
  advance(world: World, ms: number, input: Controls): World;
  restart(world: World): World;
  lane_offset(lane: Lane): number;
  lane_offset_on(code: number, lane: Lane): number;
  road_code_of(world: World): number;
  plan(world: World): BendList<Piece>;
  plan_key(world: World): number;
  body_length(body: Body): number;
  speed_kmh(world: World): number;
  limit_kmh(world: World): number;
  metres(world: World): number;
  crashed(world: World): boolean;
  signal_state(world: World): Signal;
  lane_centre(world: World): number;
  lane_move(world: World): number;
  lane_target(world: World): Lane;
  lane_change_ticks(): number;
  lamp_ticks(): number;
  rule_name(id: number): string;
  header_of(id: number): string;
  fine_of(id: number): number;
  seed_of(world: World): number;
  leg_id(leg: Leg): number;
  leg_key(world: World): number;
  legs_ahead(world: World): BendList<Leg>;
  leg_doors(seed: number, leg: Leg): BendList<Door>;
  needs_doors(world: World): boolean;
  with_doors(world: World, leg: Leg, doors: BendList<Door>): World;
  armed(world: World): Door;
  door_key(door: Door): number;
  door_net(seed: number, door: Door): BendList<Way>;
  wants_net(world: World): boolean;
  with_net(world: World, door: Door, net: BendList<Way>): World;
  shift_start(seed: number): Shift;
  shift_advance(shift: Shift, ms: number, input: Controls): Shift;
  drive_of(shift: Shift): World;
  with_drive(shift: Shift, world: World): Shift;
  held_at(): number;
  points_of_rule(id: number): number;
  clock_left(shift: Shift): number;
  order_point(shift: Shift): Pt;
  /** The light ahead: 0 green, 1 amber, 2 red, 3 none. */
  light_state(world: World): number;
  light_node(world: World): Pt;
  light_back(world: World): Pt;
}

declare const game: Game;
export default game;
