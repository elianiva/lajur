// The route in world space, in metres.
//
// The model plans the stretch the car is on and the one it takes next: a leg
// of a main road or a way of a lokal street, each as points in driving order,
// with the part of it driven. This file lays the pieces end to end, so the
// car, the traffic and the camera share one centreline, and rounds each
// joint: a bend at a junction, a loop at a turning circle.
import type { Piece } from "../bend.ts";

export interface Frame {
  x: number;
  z: number;
  heading: number;
}

interface Laid extends Piece {
  /** Where the driven part starts on the route, in metres. */
  s0: number;
  /** Points along the piece, `s` from its first point, scaled to its length. */
  at: { x: number; z: number; s: number }[];
}

/** How far each side of a joint the corner is rounded, at most. */
const ROUND = 14;
/** Half the width of the loop round a turning circle. */
const LOOP = 3;

function lay(p: Piece, s0: number): Laid {
  const at = p.pts.map((q) => ({ ...q, s: 0 }));
  let run = 0;
  for (let k = 1; k < at.length; k++) {
    run += Math.hypot(at[k]!.x - at[k - 1]!.x, at[k]!.z - at[k - 1]!.z);
    at[k]!.s = run;
  }
  if (run > 0) for (const q of at) q.s *= p.length / run;
  return { ...p, s0, at };
}

export class Route {
  private laid: Laid[] = [];
  private current = 0;

  /**
   * Follows the model's plan: its first piece is the one the car is on. A
   * piece already laid keeps its place, so the car does not jump.
   */
  sync(plan: Piece[]): void {
    const now = plan[0]!;
    const at = this.laid.findIndex((l) => l.id === now.id);
    if (at < 0) {
      this.laid = [lay(now, 0)];
      this.current = 0;
    } else {
      // Keep the piece behind, for the corner the car just took.
      this.laid = this.laid.slice(Math.max(0, at - 1), at + 1);
      this.current = this.laid.length - 1;
      this.laid[this.current]!.to = now.to;
    }
    for (const p of plan.slice(1)) {
      const last = this.laid[this.laid.length - 1]!;
      this.laid.push(lay(p, last.s0 + (last.to - last.from) / 100));
    }
  }

  /** The car's place on the route, in metres, from the model's centimetres. */
  here(along: number): number {
    const c = this.laid[this.current]!;
    return c.s0 + (along - c.from) / 100;
  }

  /** Where the piece the car is on ends: the crossing or junction ahead. */
  next(): { x: number; z: number } {
    const c = this.laid[this.current]!;
    return this.raw(c.s0 + (c.to - c.from) / 100 - 0.01);
  }

  private raw(s: number): { x: number; z: number } {
    let p = this.laid[0]!;
    for (const l of this.laid) if (s >= l.s0) p = l;
    const span = (p.to - p.from) / 100;
    const at = p.from / 100 + Math.max(0, Math.min(s - p.s0, span));
    const pts = p.at;
    let lo = 0;
    let hi = pts.length - 1;
    while (hi - lo > 1) {
      const mid = (lo + hi) >> 1;
      if (pts[mid]!.s <= at) lo = mid;
      else hi = mid;
    }
    const a = pts[lo]!;
    const b = pts[hi]!;
    const t = b.s > a.s ? Math.max(0, Math.min(1, (at - a.s) / (b.s - a.s))) : 0;
    return { x: a.x + (b.x - a.x) * t, z: a.z + (b.z - a.z) * t };
  }

  /** The point `s` metres along the route, `lateral` metres to the right. */
  at(s: number, lateral = 0): Frame {
    // Each joint is rounded within a reach no longer than half either piece.
    let joint: Laid | undefined;
    let reach = ROUND;
    for (let k = 1; k < this.laid.length; k++) {
      const l = this.laid[k]!;
      const prev = this.laid[k - 1]!;
      const r = Math.min(ROUND, (l.to - l.from) / 200, (prev.to - prev.from) / 200);
      if (Math.abs(s - l.s0) < r) {
        joint = l;
        reach = r;
      }
    }
    let x: number;
    let z: number;
    let heading: number;
    if (joint) {
      const p0 = this.raw(joint.s0 - reach);
      const p1 = this.raw(joint.s0);
      const p2 = this.raw(joint.s0 + reach);
      const u = (s - (joint.s0 - reach)) / (2 * reach);
      if (Math.hypot(p2.x - p0.x, p2.z - p0.z) < 0.5) {
        // Back the way it came: round the turning circle, clockwise as left-hand
        // traffic goes, swinging out into the bulb and over to the other side.
        const dx = (p1.x - p0.x) / reach;
        const dz = (p1.z - p0.z) / reach;
        const h0 = Math.atan2(dx, -dz);
        heading = h0 + Math.PI * u;
        const out = reach * (1 - Math.sin(Math.PI * u));
        const swing = LOOP * Math.sin(Math.PI * u);
        x = p1.x - dx * out + dx * swing;
        z = p1.z - dz * out + dz * swing;
      } else {
        const v = 1 - u;
        x = v * v * p0.x + 2 * u * v * p1.x + u * u * p2.x;
        z = v * v * p0.z + 2 * u * v * p1.z + u * u * p2.z;
        heading = Math.atan2(
          v * (p1.x - p0.x) + u * (p2.x - p1.x),
          -(v * (p1.z - p0.z) + u * (p2.z - p1.z)),
        );
      }
    } else {
      const a = this.raw(s);
      const b = this.raw(s + 0.5);
      const c = this.raw(s - 0.5);
      x = a.x;
      z = a.z;
      heading = Math.atan2(b.x - c.x, -(b.z - c.z));
    }
    // Heading 0 drives toward -z; the right of the road is (cos h, sin h).
    return {
      x: x + Math.cos(heading) * lateral,
      z: z + Math.sin(heading) * lateral,
      heading,
    };
  }
}
