import * as THREE from "three";
import { mats } from "../assets/kit.ts";
import type { Drawn } from "../world/world.ts";
import { Town } from "./town.ts";

/**
 * The town around the car, made a cell at a time.
 *
 * Every cell is a function of (seed, i, j), so the worker makes the cells near
 * the car and near the crossing it drives toward, long before it gets there,
 * and the main thread only bakes the meshes. Cells far behind are dropped.
 */

const PITCH = 650;
const JITTER = 210;
/** Make a cell when any of it may come this near the car or the next crossing. */
const MAKE = 260;
/** Drop a cell when all of it is this far from both. */
const DROP = 700;

type Spot = { x: number; z: number };

function reach(i: number, j: number, p: Spot): number {
  const x0 = i * PITCH - JITTER;
  const x1 = (i + 1) * PITCH + JITTER;
  const z0 = j * PITCH - JITTER;
  const z1 = (j + 1) * PITCH + JITTER;
  return Math.hypot(Math.max(x0 - p.x, 0, p.x - x1), Math.max(z0 - p.z, 0, p.z - z1));
}

export class Around {
  readonly group = new THREE.Group();
  private town = new Town();
  private worker = new Worker(new URL("../world/worker.ts", import.meta.url), { type: "module" });
  private asked: string | null = null;
  private ready: { key: string; drawn: Drawn }[] = [];
  private floor: THREE.Mesh;

  private seed: number;

  constructor(seed: number) {
    this.seed = seed;
    this.group.add(this.town.group);
    // The land under and between the cells, out to the fog.
    this.floor = new THREE.Mesh(
      new THREE.PlaneGeometry(1200, 1200).rotateX(-Math.PI / 2),
      mats.ground,
    );
    this.floor.position.y = -0.05;
    this.floor.receiveShadow = true;
    this.group.add(this.floor);
    this.worker.onmessage = (event: MessageEvent<{ i: number; j: number; drawn: Drawn }>) => {
      const { i, j, drawn } = event.data;
      this.ready.push({ key: `${i},${j}`, drawn });
      this.asked = null;
    };
  }

  /** `car` is where the car is; `next` is the crossing it drives toward. */
  update(car: Spot, next: Spot, camera: THREE.Camera): void {
    this.floor.position.x = car.x;
    this.floor.position.z = car.z;

    // One finished cell a frame, so baking never stacks up in one frame.
    const done = this.ready.shift();
    if (done) this.town.add(done.key, done.drawn);

    const near = (i: number, j: number) => Math.min(reach(i, j, car), reach(i, j, next));
    for (const key of this.town.keys()) {
      const [i, j] = key.split(",").map(Number) as [number, number];
      if (near(i, j) > DROP) this.town.remove(key);
    }

    if (this.asked === null) {
      let best: [number, number, number] | null = null;
      const ci = Math.floor(car.x / PITCH);
      const cj = Math.floor(car.z / PITCH);
      for (let i = ci - 2; i <= ci + 2; i++)
        for (let j = cj - 2; j <= cj + 2; j++) {
          const key = `${i},${j}`;
          if (this.town.has(key) || this.ready.some((r) => r.key === key)) continue;
          // The car's own surroundings first, then the crossing ahead.
          const d = Math.min(reach(i, j, car), reach(i, j, next) + MAKE / 2);
          if (d <= MAKE && (!best || d < best[2])) best = [i, j, d];
        }
      if (best) {
        this.asked = `${best[0]},${best[1]}`;
        this.worker.postMessage({ seed: this.seed, i: best[0], j: best[1] });
      }
    }

    this.town.update(camera, true);
  }
}
