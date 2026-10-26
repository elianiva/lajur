import graph from "./game.mjs";
import type { Body, Car, Controls, Game, Lane, Leg, Signal, World } from "./game.mjs";

const game = graph as Game;

export type { Body, Controls, Leg, Signal, World };

/** One car as the renderer needs it: metres, not the model's centimetres. */
export interface CarView {
  id: number;
  lateral: number;
  z: number;
  speed: number;
  body: Body["$"];
  colour: number;
  length: number;
}

/** The world flattened for drawing. The model stays the only source of truth. */
export interface Snapshot {
  x: number;
  /** The road the car is on, and centimetres into it. */
  leg: Leg;
  along: number;
  seed: number;
  speed: number;
  limit: number;
  metres: number;
  crashed: boolean;
  signal: Signal["$"];
  /** Ticks left in a lane change, and the lane it arrives in. */
  moving: number;
  lane: Lane["$"];
  target: Lane["$"];
  charges: number[];
  traffic: CarView[];
  oncoming: CarView[];
}

export function start(): World {
  return game.start();
}

export function advance(world: World, ms: number, input: Controls): World {
  return game.advance(world, ms, input);
}

export function restart(world: World): World {
  return game.restart(world);
}

// The catalogue's numbers, asked of the catalogue itself rather than copied.
export function ruleName(id: number): string {
  return game.rule_name(id);
}

export function citation(id: number): string {
  return game.header_of(id);
}

export function fine(id: number): number {
  return game.fine_of(id);
}

// The model measures lanes from the centre line; the player keeps the left
// half of the road, so their lanes sit at negative x.
export function laneX(lane: Lane): number {
  return -game.lane_offset(lane) / 100;
}

/** One tick of the lane change, in the model's own count. */
export function laneChangeTicks(): number {
  return game.lane_change_ticks();
}

/** The road the route takes at the far crossing of `leg`. */
export function legAfter(leg: Leg, seed: number): Leg {
  return game.leg_after(leg, seed);
}

/** The model's collision envelope, in metres, so meshes match it. */
export function bodyLength(body: Body["$"]): number {
  return game.body_length({ $: body }) / 100;
}

// The oncoming carriageway sits across the median, so its lanes are offset by
// the median and two more lanes; the model keeps them in the same Lane enum.
const ONCOMING: Record<string, number> = { Inner: 1.6, Outer: 4.8 };

function cars(list: World["traffic"], oncoming = false): CarView[] {
  const out: CarView[] = [];
  let node = list;
  while (node.$ === "Con") {
    const car: Car = node.head;
    out.push({
      id: car.id,
      lateral: oncoming ? (ONCOMING[car.lane.$] ?? 12.6) : laneX(car.lane),
      z: car.gap / 100,
      speed: car.speed,
      body: car.body.$,
      colour: car.colour,
      length: game.body_length(car.body) / 100,
    });
    node = node.tail;
  }
  return out;
}

function ids(list: World["charges"]): number[] {
  const out: number[] = [];
  let node = list;
  while (node.$ === "Con") {
    out.push(node.head);
    node = node.tail;
  }
  return out;
}

export function snapshot(world: World): Snapshot {
  // A manoeuvre is a count of ticks, not a jump: the car sits part way between
  // the lane it left and the one it is taking, by the model's own arithmetic.
  const moving = game.lane_move(world);
  const target = game.lane_target(world);
  const from = laneX(world.player.lane);
  const to = laneX(target);
  const done = 1 - Math.min(moving, game.lane_change_ticks()) / game.lane_change_ticks();
  return {
    x: from + (to - from) * done,
    moving,
    lane: world.player.lane.$,
    target: target.$,
    leg: world.leg,
    along: world.along,
    seed: world.seed,
    speed: game.speed_kmh(world),
    limit: game.limit_kmh(world),
    metres: game.metres(world),
    crashed: game.crashed(world),
    signal: game.signal_state(world).$,
    charges: ids(world.charges),
    traffic: cars(world.traffic),
    oncoming: cars(world.oncoming, true),
  };
}
