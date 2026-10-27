import game from "./game.mjs";
import type { BendList, Body, Car, Controls, Lane, Signal, World } from "./game.mjs";

export type { Body, Controls, Signal, World };

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
  /** Centimetres into the stretch the car is on. */
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
// half of the road, so their lanes sit at negative x. The centre depends on
// the class of road: 1 arterial, 2 collector, 3 lokal street.
export function laneX(lane: Lane, code = 1): number {
  return -game.lane_offset_on(code, lane) / 100;
}

/** One tick of the lane change, in the model's own count. */
export function laneChangeTicks(): number {
  return game.lane_change_ticks();
}

/** A stretch of the route in metres, with the part driven in the model's centimetres. */
export interface Piece {
  id: number;
  pts: { x: number; z: number }[];
  length: number;
  from: number;
  to: number;
}

function items<T>(l: BendList<T>): T[] {
  const out: T[] = [];
  for (let node = l; node.$ === "Con"; node = node.tail) out.push(node.head);
  return out;
}

/** The stretch the car is on and the one it takes next. */
export function plan(world: World): Piece[] {
  return items(game.plan(world)).map((p) => ({
    id: p.id,
    pts: items(p.pts).map((q) => ({ x: (q.x | 0) / 100, z: (q.z | 0) / 100 })),
    length: p.length / 100,
    from: p.from,
    to: p.to,
  }));
}

/** Changes whenever `plan` would. */
export function planKey(world: World): number {
  return game.plan_key(world);
}

/** The model's collision envelope, in metres, so meshes match it. */
export function bodyLength(body: Body["$"]): number {
  return game.body_length({ $: body }) / 100;
}

// Oncoming cars keep the other half of the road, in the same Lane enum.
function cars(list: World["traffic"], code: number, oncoming = false): CarView[] {
  const out: CarView[] = [];
  let node = list;
  while (node.$ === "Con") {
    const car: Car = node.head;
    out.push({
      id: car.id,
      lateral: oncoming ? -laneX(car.lane, code) : laneX(car.lane, code),
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
  const code = game.road_code_of(world);
  const from = laneX(world.player.lane, code);
  const to = laneX(target, code);
  const done = 1 - Math.min(moving, game.lane_change_ticks()) / game.lane_change_ticks();
  return {
    x: from + (to - from) * done,
    moving,
    lane: world.player.lane.$,
    target: target.$,
    along: world.along,
    seed: world.seed,
    speed: game.speed_kmh(world),
    limit: game.limit_kmh(world),
    metres: game.metres(world),
    crashed: game.crashed(world),
    signal: game.signal_state(world).$,
    charges: ids(world.charges),
    // On a lokal street the main road's traffic is out of sight.
    traffic: code === 3 ? [] : cars(world.traffic, code),
    oncoming: code === 3 ? [] : cars(world.oncoming, code, true),
  };
}
