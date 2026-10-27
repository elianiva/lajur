import * as THREE from "three";
import { bake } from "../../assets/kit.ts";
import { HX, HZ } from "./site.ts";

// --- vehicles and people --------------------------------------------------------

export interface Variant {
  meshes: THREE.InstancedMesh[];
  length: number;
  count: number;
}

/** One model, baked once, drawn as many times as there are movers using it. */
export function variant(object: THREE.Object3D, capacity: number): Variant {
  const length = new THREE.Box3().setFromObject(object).getSize(new THREE.Vector3()).z;
  const baked = bake(object);
  const meshes = baked.children.map((child) => {
    const mesh = child as THREE.Mesh;
    const instanced = new THREE.InstancedMesh(mesh.geometry, mesh.material, capacity);
    instanced.castShadow = true;
    instanced.receiveShadow = true;
    instanced.frustumCulled = false;
    instanced.count = 0;
    return instanced;
  });
  return { meshes, length, count: 0 };
}

export interface Lane {
  axis: "x" | "z";
  fixed: number;
  dir: 1 | -1;
  /** Stop lines, in metres along the lane. */
  stops: number[];
  movers: Mover[];
  people: boolean;
}

export interface Mover {
  lane: Lane;
  variant: Variant;
  slot: number;
  s: number;
  v: number;
  top: number;
  length: number;
  jitter: number;
  phase: number;
}

export const SPAN = { x: 2 * HX, z: 2 * HZ };

export function lanePoint(lane: Lane, s: number, jitter: number): [number, number] {
  const from = lane.axis === "x" ? -HX : -HZ;
  const to = -from;
  const along = lane.dir > 0 ? from + s : to - s;
  return lane.axis === "x" ? [along, lane.fixed + jitter] : [lane.fixed + jitter, along];
}
