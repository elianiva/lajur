import * as THREE from "three";
import { City } from "../render/city.ts";
import { drawn, extent, world } from "../world/world.ts";
import type { View } from "./view.ts";

/**
 * The generated world, 4×4 cells of it, drawn by the town the game drives
 * through: boxes and balls from afar, the shelf's real assets close up.
 */

const CELLS = 4;
/** Screen pixels per metre at which the real assets take over. */
const NEAR_PPM = 1.6;

export function worldView(roll: number): View {
  const seed = Math.floor(roll * 4294967296) >>> 0;
  const w = world(seed, 0, 0, CELLS, CELLS);
  const town = new City();
  town.add("window", drawn(w));

  const [x0, z0, x1, z1] = extent(w);
  return {
    group: town.group,
    bounds: new THREE.Box3(new THREE.Vector3(x0, 0, z0), new THREE.Vector3(x1, 30, z1)),
    maxZoom: 60,
    shadowFollows: true,
    update(_dt, camera) {
      const ppm = (window.innerHeight * camera.zoom) / (camera.top - camera.bottom);
      town.update(camera, ppm >= NEAR_PPM);
    },
  };
}
