import * as THREE from "three";
import { buildCar, PLAYER_COLOUR, trafficColour, type CarMesh } from "./cars.ts";
import type { CarView, Snapshot } from "../bend.ts";
import type { RoadPath } from "./path.ts";

interface Tracked {
  car: CarMesh;
  lateral: number;
  signature: string;
}

/**
 * Places every car on the generated road: the player first, then traffic by the
 * gap ahead the model reports. Lane changes ease in; everything else is the
 * model's number in metres.
 */
export class Traffic {
  readonly group = new THREE.Group();
  readonly player: CarMesh;
  private tracked = new Map<number, Tracked>();
  private playerLateral = 0;
  private spin = 0;
  /** Where the player's car ended up, after easing. */
  position = new THREE.Vector3();
  heading = 0;

  private path: RoadPath;

  constructor(path: RoadPath, player: CarMesh) {
    this.path = path;
    this.player = player;
    this.group.add(player.group);
  }

  update(state: Snapshot, dt: number): void {
    const ease = Math.min(1, dt * 9);
    const index = state.index;
    const along = state.along / 100;

    this.playerLateral += (state.x - this.playerLateral) * ease;
    const at = this.path.point(index, along, this.playerLateral);
    this.position.set(at.x, 0, at.z);
    this.heading = at.heading;

    this.player.group.position.copy(this.position);
    this.player.group.rotation.y = -at.heading;

    this.spin += state.speed * dt * 0.9;
    for (const wheel of this.player.wheels) wheel.rotation.x = -this.spin;

    this.sync(state.traffic, index, along, ease, false);
    this.sync(state.oncoming, index, along, ease, true);
  }

  private sync(
    cars: CarView[],
    index: number,
    along: number,
    ease: number,
    oncoming: boolean,
  ): void {
    const seen = new Set<number>();

    for (const view of cars) {
      seen.add(view.id);
      const signature = `${view.body}:${view.colour}:${Math.round(view.length)}`;
      let tracked = this.tracked.get(view.id);

      if (!tracked || tracked.signature !== signature) {
        if (tracked) this.group.remove(tracked.car.group);
        const car = buildCar(view.body, trafficColour(view.colour), view.length);
        tracked = { car, lateral: view.lateral, signature };
        this.group.add(car.group);
        this.tracked.set(view.id, tracked);
      }

      tracked.lateral += (view.lateral - tracked.lateral) * ease;
      const there = this.path.ahead(index, along, view.z);
      const at = this.path.point(there.index, there.along, tracked.lateral);

      tracked.car.group.position.set(at.x, 0, at.z);
      tracked.car.group.rotation.y = oncoming ? -at.heading + Math.PI : -at.heading;
      for (const wheel of tracked.car.wheels) wheel.rotation.x = -this.spin * 0.7;
    }

    for (const [id, tracked] of this.tracked) {
      if (!seen.has(id)) {
        this.group.remove(tracked.car.group);
        this.tracked.delete(id);
      }
    }
  }
}

export { PLAYER_COLOUR };
