import game from "./game.mjs";
import type { BendList, Body, Car, Controls, Lane, Shift, Signal, World } from "./game.mjs";

export type { Body, Controls, Shift, Signal, World };

/** The stop the car drives to, in metres, and what it pays. */
export interface OrderView {
  aboard: boolean;
  x: number;
  z: number;
  fare: number;
  /** Seconds until the drop-off is due; negative when late. */
  dueIn: number;
}

/** The light at the crossing ahead, and the crossing behind, in metres. */
export interface LightView {
  /** 0 green, 1 amber, 2 red, 3 no lights. */
  state: number;
  x: number;
  z: number;
  backX: number;
  backZ: number;
  /** Metres to the crossing along the road. */
  ahead: number;
}

/** A ticket as the slip shows it. */
export interface TicketView {
  id: number;
  tick: number;
  points: number;
}

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
  /** Licence points so far, and the count at which the licence is held. */
  points: number;
  heldAt: number;
  phase: Shift["phase"]["$"];
  /** Newest first. */
  tickets: TicketView[];
  /** Seconds left in the shift. */
  clock: number;
  earned: number;
  served: number;
  /** Stars, 1.0 to 5.0. */
  stars: number;
  order: OrderView;
  light: LightView;
  traffic: CarView[];
  oncoming: CarView[];
}

export function start(seed: number): Shift {
  return game.shift_start(seed);
}

export function advance(shift: Shift, ms: number, input: Controls): Shift {
  return game.shift_advance(shift, ms, input);
}

export function withDrive(shift: Shift, world: World): Shift {
  return game.with_drive(shift, world);
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

export function points(id: number): number {
  return game.points_of_rule(id);
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

function orderView(shift: Shift): OrderView {
  const at = game.order_point(shift);
  return {
    aboard: shift.order.aboard,
    x: (at.x | 0) / 100,
    z: (at.z | 0) / 100,
    fare: shift.order.fare,
    dueIn: ((shift.order.due | 0) - (shift.drive.tick | 0)) / 60,
  };
}

function lightView(world: World): LightView {
  const at = game.light_node(world);
  const back = game.light_back(world);
  return {
    state: game.light_state(world),
    x: (at.x | 0) / 100,
    z: (at.z | 0) / 100,
    backX: (back.x | 0) / 100,
    backZ: (back.z | 0) / 100,
    ahead: (world.leg.length - world.along) / 100,
  };
}

export function snapshot(shift: Shift): Snapshot {
  const world = shift.drive;
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
    points: shift.points,
    heldAt: game.held_at(),
    phase: shift.phase.$,
    tickets: items(shift.tickets).map((t) => ({ id: t.id, tick: t.tick, points: t.points })),
    clock: game.clock_left(shift) / 60,
    earned: shift.earned,
    served: shift.served,
    stars: shift.stars / 10,
    order: orderView(shift),
    light: lightView(world),
    // On a lokal street the main road's traffic is out of sight.
    traffic: code === 3 ? [] : cars(world.traffic, code),
    oncoming: code === 3 ? [] : cars(world.oncoming, code, true),
  };
}
