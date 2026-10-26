import * as THREE from "three";
import { buildCar, PLAYER_COLOUR, trafficColour, type CarMesh } from "../assets/cars.ts";
import type { CarView, Snapshot } from "../bend.ts";
import type { Route } from "./route.ts";

/** Cars ride on the road surface, which lies a little above the ground. */
const ROAD_Y = 0.14;

interface Tracked {
  car: CarMesh;
  lateral: number;
  signature: string;
}

/**
 * Places every car on the route: the player first, then traffic by the gap
 * ahead the model reports. Lane changes ease in; everything else is the
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

  private route: Route;

  constructor(route: Route, player: CarMesh) {
    this.route = route;
    this.player = player;
    this.group.add(player.group);
  }

  update(state: Snapshot, dt: number): void {
    const ease = Math.min(1, dt * 9);
    const here = this.route.here(state.along);

    this.playerLateral += (state.x - this.playerLateral) * ease;
    const at = this.route.at(here, this.playerLateral);
    this.position.set(at.x, ROAD_Y, at.z);
    this.heading = at.heading;

    this.player.group.position.copy(this.position);
    this.player.group.rotation.y = -at.heading;

    this.spin += state.speed * dt * 0.9;
    for (const wheel of this.player.wheels) wheel.rotation.x = -this.spin;

    this.sync(state.traffic, here, ease, false);
    this.sync(state.oncoming, here, ease, true);
  }

  private sync(cars: CarView[], here: number, ease: number, oncoming: boolean): void {
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
      const at = this.route.at(here + Math.max(0, view.z), tracked.lateral);

      tracked.car.group.position.set(at.x, ROAD_Y, at.z);
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
