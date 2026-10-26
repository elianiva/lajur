// The route in world space, in metres.
//
// The model names each road the car drives as a leg of the world's lattice and
// measures the car in centimetres along it. This file lays the legs end to end
// along the world's own curves, so the car, the traffic and the camera share
// one centreline, and rounds each corner so a turn is a bend, not a snap.
import W from "../world.mjs";
import { legAfter, type Leg } from "../bend.ts";

export interface Frame {
  x: number;
  z: number;
  heading: number;
}

interface Laid {
  key: string;
  leg: Leg;
  /** Where the leg starts on the route, in metres. */
  s0: number;
  length: number;
  /** Points along the leg in driving order, `s` from its start, scaled to the model's length. */
  pts: { x: number; z: number; s: number }[];
}

const SAMPLES = 96;
/** How far each side of a crossing the corner is rounded. */
const ROUND = 14;
/** Legs kept laid behind the car and ahead of it. */
const BEHIND = 1;
const AHEAD = 2;

const keyOf = (l: Leg) => `${l.i | 0},${l.j | 0},${l.dir}`;

function lay(seed: number, leg: Leg, s0: number): Laid {
  // A leg west or north runs its road backwards: the lattice names a road by
  // its west or north crossing.
  const back = leg.dir === 0 || leg.dir === 3;
  const east = leg.dir % 2 === 1;
  const i = leg.dir === 3 ? leg.i - 1 : leg.i;
  const j = leg.dir === 0 ? leg.j - 1 : leg.j;
  const curve = W.curve_of(seed, i >>> 0, j >>> 0, east);
  const pts: Laid["pts"] = [];
  for (let k = 0; k <= SAMPLES; k++) {
    const t = back ? 1 - k / SAMPLES : k / SAMPLES;
    const p = W.curve_at(curve, Math.round(t * 65536));
    pts.push({ x: (p.x | 0) / 100, z: (p.z | 0) / 100, s: 0 });
  }
  let run = 0;
  for (let k = 1; k < pts.length; k++) {
    run += Math.hypot(pts[k]!.x - pts[k - 1]!.x, pts[k]!.z - pts[k - 1]!.z);
    pts[k]!.s = run;
  }
  const length = leg.length / 100;
  for (const p of pts) p.s *= length / run;
  return { key: keyOf(leg), leg, s0, length, pts };
}

export class Route {
  private legs: Laid[] = [];
  private current = 0;
  /** The turn the leg after the current one was laid for. */
  private turn = 1;
  private seed: number;

  constructor(seed: number) {
    this.seed = seed;
  }

  /**
   * Follows the model onto its leg, and keeps the legs either side laid: the
   * next for the turn the driver chose, the ones after it straight on.
   */
  sync(leg: Leg, turn: number): void {
    const key = keyOf(leg);
    const at = this.legs.findIndex((l) => l.key === key);
    if (at < 0) {
      this.legs = [lay(this.seed, leg, 0)];
      this.current = 0;
    } else this.current = at;
    if (this.current > BEHIND) {
      this.legs.splice(0, this.current - BEHIND);
      this.current = BEHIND;
    }
    if (turn !== this.turn) {
      this.legs.length = this.current + 1;
      this.turn = turn;
    }
    while (this.legs.length - 1 - this.current < AHEAD) {
      const last = this.legs[this.legs.length - 1]!;
      const next = legAfter(last.leg, this.seed, last === this.legs[this.current] ? turn : 1);
      this.legs.push(lay(this.seed, next, last.s0 + last.length));
    }
  }

  /** The car's place on the route, in metres. */
  here(along: number): number {
    return this.legs[this.current]!.s0 + along;
  }

  /** The crossing the car drives toward. */
  next(): { x: number; z: number } {
    return this.legs[this.current]!.pts[SAMPLES]!;
  }

  private raw(s: number): { x: number; z: number } {
    let leg = this.legs[0]!;
    for (const l of this.legs) if (s >= l.s0) leg = l;
    const at = Math.max(0, Math.min(s - leg.s0, leg.length));
    const pts = leg.pts;
    let lo = 0;
    let hi = pts.length - 1;
    while (hi - lo > 1) {
      const mid = (lo + hi) >> 1;
      if (pts[mid]!.s <= at) lo = mid;
      else hi = mid;
    }
    const a = pts[lo]!;
    const b = pts[hi]!;
    const t = b.s > a.s ? (at - a.s) / (b.s - a.s) : 0;
    return { x: a.x + (b.x - a.x) * t, z: a.z + (b.z - a.z) * t };
  }

  /** The point `s` metres along the route, `lateral` metres to the right. */
  at(s: number, lateral = 0): Frame {
    let x: number;
    let z: number;
    let dx: number;
    let dz: number;
    // Near a crossing the route follows a quadratic through the crossing
    // instead of its two legs.
    const corner = this.legs.find((l, k) => k > 0 && Math.abs(s - l.s0) < ROUND);
    if (corner) {
      const p0 = this.raw(corner.s0 - ROUND);
      const p1 = this.raw(corner.s0);
      const p2 = this.raw(corner.s0 + ROUND);
      const u = (s - (corner.s0 - ROUND)) / (2 * ROUND);
      const v = 1 - u;
      x = v * v * p0.x + 2 * u * v * p1.x + u * u * p2.x;
      z = v * v * p0.z + 2 * u * v * p1.z + u * u * p2.z;
      dx = v * (p1.x - p0.x) + u * (p2.x - p1.x);
      dz = v * (p1.z - p0.z) + u * (p2.z - p1.z);
    } else {
      const a = this.raw(s);
      const b = this.raw(s + 0.5);
      const c = this.raw(s - 0.5);
      x = a.x;
      z = a.z;
      dx = b.x - c.x;
      dz = b.z - c.z;
    }
    // Heading 0 drives toward -z; the right of the road is (cos h, sin h).
    const heading = Math.atan2(dx, -dz);
    return {
      x: x + Math.cos(heading) * lateral,
      z: z + Math.sin(heading) * lateral,
      heading,
    };
  }
}
