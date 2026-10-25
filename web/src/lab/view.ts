import type * as THREE from "three";

/** One scene the lab can show. */
export interface View {
  group: THREE.Group;
  /** What is worth framing, in metres. */
  bounds: THREE.Box3;
  update(dt: number, camera: THREE.OrthographicCamera): void;
  /** How far the camera may zoom in; the lab's default is 12. */
  maxZoom?: number;
  /** Fit the sun's shadow to what is on screen, not to the whole view. */
  shadowFollows?: boolean;
}

/** A small seeded generator, so a reroll is a number you can come back to. */
export function random(seed: number): () => number {
  let state = Math.floor(seed * 0xffffffff) >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
