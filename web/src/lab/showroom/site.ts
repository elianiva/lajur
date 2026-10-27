import * as THREE from "three";
import { mats } from "../../assets/kit.ts";

export const HX = 170;
export const HZ = 120;
export const UP = new THREE.Vector3(0, 1, 0);

export type Kind = "raya" | "jalan" | "lokal";

export interface Road {
  axis: "x" | "z";
  at: number;
  kind: Kind;
  half: number;
  walk: number;
  /** Lane centres from the road's middle, one direction's worth. */
  lanes: number[];
}

export const ROADS: Road[] = [
  { axis: "x", at: -70, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
  { axis: "x", at: 0, kind: "raya", half: 7.4, walk: 3, lanes: [2.5, 5.75] },
  { axis: "x", at: 75, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
  { axis: "z", at: -105, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
  { axis: "z", at: -40, kind: "lokal", half: 2.9, walk: 1.5, lanes: [1.4] },
  { axis: "z", at: 65, kind: "lokal", half: 2.9, walk: 1.5, lanes: [1.4] },
  { axis: "z", at: 100, kind: "jalan", half: 3.75, walk: 2.2, lanes: [1.75] },
];
export const ALONG_X = ROADS.filter((road) => road.axis === "x");
export const ALONG_Z = ROADS.filter((road) => road.axis === "z");

// --- the river ------------------------------------------------------------------

export const WATER = 7;
export const WALL = 8.5;
export const BANK = 12;

export function riverX(z: number): number {
  return 26 + 13 * Math.sin(z / 34) + 5 * Math.sin(z / 13 + 1);
}

/** A quad strip along z between two x functions, at height y, facing up. */
export function stripZ(left: (z: number) => number, right: (z: number) => number, y: number) {
  const position: number[] = [];
  for (let z = -HZ; z < HZ; z += 2) {
    const z1 = Math.min(z + 2, HZ);
    const a = [left(z), y, z];
    const b = [right(z), y, z];
    const c = [right(z1), y, z1];
    const d = [left(z1), y, z1];
    position.push(...a, ...d, ...b, ...b, ...d, ...c);
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute("position", new THREE.Float32BufferAttribute(position, 3));
  geometry.computeVertexNormals();
  return geometry;
}

/** An upright wall along z at x = at(z), from y0 to y1. */
export function wallZ(at: (z: number) => number, y0: number, y1: number) {
  const position: number[] = [];
  for (let z = -HZ; z < HZ; z += 2) {
    const z1 = Math.min(z + 2, HZ);
    const a = [at(z), y0, z];
    const b = [at(z), y1, z];
    const c = [at(z1), y1, z1];
    const d = [at(z1), y0, z1];
    position.push(...a, ...b, ...d, ...d, ...b, ...c);
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute("position", new THREE.Float32BufferAttribute(position, 3));
  geometry.computeVertexNormals();
  return geometry;
}

/** Whether a riverside z falls under one of the road bridges. */
export function onBridge(z: number): boolean {
  return ALONG_X.some((road) => Math.abs(z - road.at) < road.half + road.walk + 0.6);
}

export const bankWall = mats.concrete.clone();
bankWall.side = THREE.DoubleSide;

// --- the plinth -------------------------------------------------------------------

/** How far the base reaches past the city, and how deep it stands. */
export const APRON = 4.5;
export const DEEP = 14;

/**
 * The base: a rounded, bevelled rim the city stands on. Hollow, so the river
 * runs on under it and out of the frame, the way a cut-away model does.
 */
export function plinth(): THREE.ExtrudeGeometry {
  const hx = HX + APRON;
  const hz = HZ + APRON;
  const corner = 9;
  const shape = new THREE.Shape();
  shape.moveTo(-hx + corner, -hz);
  // Round the corners, and let the river run on under the rim.
  shape.lineTo(hx - corner, -hz);
  shape.quadraticCurveTo(hx, -hz, hx, -hz + corner);
  shape.lineTo(hx, hz - corner);
  shape.quadraticCurveTo(hx, hz, hx - corner, hz);
  shape.lineTo(-hx + corner, hz);
  shape.quadraticCurveTo(-hx, hz, -hx, hz - corner);
  shape.lineTo(-hx, -hz + corner);
  shape.quadraticCurveTo(-hx, -hz, -hx + corner, -hz);

  const hollow = new THREE.Path();
  hollow.moveTo(-HX + 0.5, -HZ + 0.5);
  hollow.lineTo(HX - 0.5, -HZ + 0.5);
  hollow.lineTo(HX - 0.5, HZ - 0.5);
  hollow.lineTo(-HX + 0.5, HZ - 0.5);
  shape.holes.push(hollow);

  const geometry = new THREE.ExtrudeGeometry(shape, {
    depth: DEEP,
    bevelEnabled: true,
    bevelThickness: 2.2,
    bevelSize: 1.4,
    bevelSegments: 3,
    curveSegments: 6,
  });
  // Stand it up: the shape's plane becomes the ground, its extrusion the drop.
  // The top sits a hair under the road so the two never fight for a pixel.
  geometry.rotateX(Math.PI / 2);
  geometry.computeBoundingBox();
  geometry.translate(0, -0.06 - geometry.boundingBox!.max.y, 0);
  geometry.computeBoundingBox();
  return geometry;
}
