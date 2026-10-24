import graph from "./game.mjs";
import type { Body, Car, Controls, Game, Lane, Signal, World } from "./game.mjs";

const game = graph as Game;

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
  index: number;
  along: number;
  seed: number;
  speed: number;
  limit: number;
  metres: number;
  crashed: boolean;
  signal: Signal["$"];
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

export function chunkMetres(): number {
  return game.chunk_cm() / 100;
}

export function curveAt(cm: number, seed: number): { rate: number; left: boolean } {
  const curve = game.curve_at(cm, seed);
  return { rate: game.curve_rate_of(curve), left: game.curve_left_of(curve) };
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
      z: car.z / 100,
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
  return {
    x: laneX(world.player.lane),
    index: world.index,
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
