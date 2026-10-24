// Unrolls the model's road into world space, in metres.
//
// The model answers curvature as a pure function of distance along the road
// (1-D value noise, eased). This file integrates that curvature to get a
// heading and a position, the way endless driving games do: the same centreline
// feeds the geometry, the traffic and the camera.
import { chunkMetres, curveAt } from "../bend.ts";

export interface Frame {
  x: number;
  z: number;
  heading: number;
}

/** Integration step. The chunk length must be a whole number of these. */
const STEP = 2.5;

export class RoadPath {
  private frames = new Map<number, Frame>([[0, { x: 0, z: 0, heading: 0 }]]);
  private seed: number;
  private chunk: number;

  constructor(seed: number) {
    this.seed = seed;
    this.chunk = chunkMetres();
  }

  /** Radians of heading per metre at `metres` along the road, signed. */
  curvature(metres: number): number {
    const { rate, left } = curveAt(Math.max(0, Math.round(metres * 100)), this.seed);
    const radians = (rate / 100) * (Math.PI / 180);
    return left ? -radians : radians;
  }

  get chunkLength(): number {
    return this.chunk;
  }

  frame(index: number): Frame {
    const known = this.frames.get(index);
    if (known) return known;

    let from = index - 1;
    while (from > 0 && !this.frames.has(from)) from -= 1;
    let frame = this.frames.get(from) ?? { x: 0, z: 0, heading: 0 };

    for (let step = from; step < index; step += 1) {
      frame = this.walk(frame, step * this.chunk, this.chunk);
      this.frames.set(step + 1, frame);
    }
    return frame;
  }

  /** Integrates `length` metres from `from`, sampling curvature every step. */
  private walk(frame: Frame, start: number, length: number): Frame {
    let at = frame;
    let travelled = 0;
    while (travelled < length - 1e-9) {
      const step = Math.min(STEP, length - travelled);
      at = this.advance(at, start + travelled, step);
      travelled += step;
    }
    return at;
  }

  private advance(frame: Frame, at: number, step: number): Frame {
    const k = this.curvature(at + step / 2);
    const heading = frame.heading + k * step;
    if (k === 0) {
      return {
        x: frame.x + Math.sin(frame.heading) * step,
        z: frame.z - Math.cos(frame.heading) * step,
        heading,
      };
    }
    return {
      x: frame.x + (Math.cos(frame.heading) - Math.cos(heading)) / k,
      z: frame.z - (Math.sin(heading) - Math.sin(frame.heading)) / k,
      heading,
    };
  }

  /** A point `along` metres into chunk `index`, `lateral` metres to the right. */
  point(index: number, along: number, lateral = 0): Frame {
    const clamped = Math.max(0, Math.min(along, this.chunk));
    const frame = this.walk(this.frame(index), index * this.chunk, clamped);
    return {
      x: frame.x + Math.cos(frame.heading) * lateral,
      z: frame.z + Math.sin(frame.heading) * lateral,
      heading: frame.heading,
    };
  }

  /** Where `gap` metres ahead of (index, along) lands. */
  ahead(index: number, along: number, gap: number): { index: number; along: number } {
    let at = index;
    let offset = along + Math.max(0, gap);
    let guard = 0;
    while (guard < 64 && offset >= this.chunk) {
      offset -= this.chunk;
      at += 1;
      guard += 1;
    }
    return { index: at, along: offset };
  }
}
