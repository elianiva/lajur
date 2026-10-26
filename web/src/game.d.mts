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
export type Leg = { $: "Leg"; i: number; j: number; dir: number; length: number };

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

export interface Game {
  start(): World;
  advance(world: World, ms: number, input: Controls): World;
  restart(world: World): World;
  lane_offset(lane: Lane): number;
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
  leg_after(leg: Leg, seed: number, turn: number): Leg;
  rule_name(id: number): string;
  header_of(id: number): string;
  fine_of(id: number): number;
}

declare const game: Game;
export default game;
