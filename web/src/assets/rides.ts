import * as THREE from "three";
import { ball, board, cyl, mats, piece, pick, tarps, wheel, walls, type Shelf } from "./kit.ts";
import { motorbike } from "./street.ts";

/**
 * Vehicles the lab and the town show that the model does not drive: the
 * angkot, bajaj, becak and ojek of every Indonesian street. Noses face -z,
 * like the cars.
 */

function wheels(group: THREE.Group, radius: number, x: number, zs: number[]) {
  for (const z of zs) {
    for (const side of [-x, x]) {
      const rim = wheel(radius, 0.22, mats.rubber);
      rim.position.set(side, radius, z);
      group.add(rim);
    }
  }
}

/** An angkot: a boxy minivan in its route colour, the route board on the roof. */
export function angkot(seed: number): THREE.Group {
  const group = new THREE.Group();
  const paint = pick([tarps[0]!, mats.green, mats.red, mats.yellow, tarps[5]!, walls[5]!], seed, 3);
  piece(group, [1.7, 1.4, 4.2], paint, [0, 1.15, 0]);
  piece(group, [1.72, 0.55, 3.0], mats.glass, [0, 1.5, 0.4]);
  piece(group, [1.6, 0.5, 0.06], mats.glass, [0, 1.45, -2.11]);
  piece(group, [1.74, 0.16, 4.22], mats.white, [0, 0.95, 0]);
  piece(group, [0.06, 1.0, 1.0], mats.black, [0.86, 1.1, 1.4]);
  piece(
    group,
    [1.0, 0.3, 0.5],
    board(pick(["ADL", "AMG", "GML", "LDG", "T01"], seed), "#1f2a44", "#f4b42e"),
    [0, 2.0, -1.4],
  ).rotation.y = Math.PI / 2;
  for (const x of [-0.6, 0.6]) piece(group, [0.3, 0.16, 0.06], mats.lamp, [x, 0.95, -2.12]);
  wheels(group, 0.34, 0.78, [-1.4, 1.4]);
  return group;
}

/** A bajaj: the orange three-wheeler, a canvas cab, one wheel in front. */
export function bajaj(seed: number): THREE.Group {
  const group = new THREE.Group();
  const paint = seed > 0.3 ? mats.rust : tarps[0]!;
  piece(group, [1.3, 0.6, 2.2], paint, [0, 0.75, 0.2]);
  piece(group, [1.3, 0.12, 2.0], paint, [0, 1.85, 0.1]);
  for (const x of [-0.6, 0.6]) piece(group, [0.08, 1.0, 0.08], mats.black, [x, 1.35, -0.8]);
  piece(group, [1.2, 0.6, 0.06], mats.glass, [0, 1.4, -0.86]);
  piece(group, [0.06, 0.8, 1.2], mats.black, [-0.63, 1.4, 0.6]);
  piece(group, [0.06, 0.8, 1.2], mats.black, [0.63, 1.4, 0.6]);
  const front = wheel(0.25, 0.14, mats.rubber);
  front.position.set(0, 0.25, -1.0);
  group.add(front);
  wheels(group, 0.25, 0.55, [0.8]);
  return group;
}

/** A becak: the pedal rickshaw, the seat in front, a hood, the rider behind. */
export function becak(seed: number): THREE.Group {
  const group = new THREE.Group();
  const paint = pick([mats.red, tarps[0]!, mats.green, mats.yellow], seed, 5);
  piece(group, [1.1, 0.5, 0.9], paint, [0, 0.75, -0.5]);
  piece(group, [1.0, 0.1, 0.7], mats.black, [0, 0.95, -0.45]);
  const hood = new THREE.Mesh(
    new THREE.CylinderGeometry(0.55, 0.55, 1.1, 8, 1, false, 0, Math.PI),
    pick(tarps, seed, 7),
  );
  hood.rotation.z = Math.PI / 2;
  hood.position.set(0, 1.2, -0.1);
  group.add(hood);
  piece(group, [0.08, 0.08, 1.4], mats.metal, [0, 0.55, 0.5]);
  piece(group, [0.3, 0.06, 0.25], mats.black, [0, 1.15, 1.0]);
  for (const x of [-0.5, 0.5]) {
    const rim = wheel(0.3, 0.06, mats.rubber);
    rim.position.set(x, 0.3, -0.4);
    group.add(rim);
  }
  const back = wheel(0.32, 0.06, mats.rubber);
  back.position.set(0, 0.32, 1.1);
  group.add(back);
  // The rider, pedalling.
  piece(
    group,
    [0.3, 0.5, 0.25],
    pick([mats.white, mats.black, tarps[1]!], seed, 9),
    [0, 1.45, 1.0],
  );
  ball(group, 0.16, mats.skinDark, [0, 1.85, 1.0], 1);
  const hat = new THREE.Mesh(new THREE.ConeGeometry(0.32, 0.18, 8), mats.yellow);
  hat.position.set(0, 2.0, 1.0);
  group.add(hat);
  return group;
}

/** An ojek: a motorbike with its rider in the app's green jacket and helmet. */
export function ojek(seed: number): THREE.Group {
  const group = motorbike(seed);
  const jacket = seed > 0.4 ? mats.green : seed > 0.2 ? mats.black : mats.yellow;
  for (const x of [-0.14, 0.14]) piece(group, [0.12, 0.5, 0.14], mats.black, [x, 0.95, 0.0]);
  piece(group, [0.4, 0.55, 0.3], jacket, [0, 1.35, 0.15]);
  for (const x of [-0.22, 0.22]) piece(group, [0.1, 0.1, 0.5], jacket, [x, 1.4, -0.15]);
  ball(group, 0.2, jacket, [0, 1.8, 0.12], 1);
  piece(group, [0.3, 0.1, 0.06], mats.glass, [0, 1.78, -0.06]);
  if (seed > 0.6) {
    // A passenger, or a box of deliveries.
    piece(group, [0.38, 0.5, 0.28], pick(tarps, seed, 2), [0, 1.35, 0.5]);
    ball(group, 0.19, mats.white, [0, 1.78, 0.5], 1);
  } else {
    piece(group, [0.45, 0.45, 0.45], jacket, [0, 1.15, 0.65]);
  }
  return group;
}

/** A pickup with a load: sacks, a tarp, or a crate of bottles. */
export function pickup(seed: number): THREE.Group {
  const group = new THREE.Group();
  const paint = pick([mats.white, mats.black, tarps[0]!, mats.concrete], seed, 4);
  piece(group, [1.8, 0.7, 4.6], paint, [0, 0.75, 0]);
  piece(group, [1.7, 0.7, 1.4], paint, [0, 1.45, -1.0]);
  piece(group, [1.72, 0.45, 1.0], mats.glass, [0, 1.5, -1.2]);
  piece(group, [1.7, 0.5, 2.2], mats.woodDark, [0, 1.25, 1.2]);
  const load = seed > 0.5 ? mats.wood : pick(tarps, seed, 6);
  for (let k = 0; k < 4; k += 1)
    piece(group, [0.7, 0.45, 0.9], load, [
      k % 2 ? 0.38 : -0.38,
      1.4,
      0.6 + Math.floor(k / 2) * 1.1,
    ]);
  wheels(group, 0.36, 0.84, [-1.5, 1.5]);
  return group;
}

/** A Metromini: the small orange-and-blue city bus, door open. */
export function metromini(seed: number): THREE.Group {
  const group = new THREE.Group();
  const body = seed > 0.5 ? mats.rust : walls[0]!;
  piece(group, [2.2, 1.9, 7.6], body, [0, 1.45, 0]);
  piece(group, [2.24, 0.25, 7.62], tarps[0]!, [0, 0.9, 0]);
  piece(group, [2.24, 0.7, 6.0], mats.glass, [0, 1.95, 0.5]);
  piece(group, [2.0, 0.8, 0.06], mats.glass, [0, 1.9, -3.81]);
  piece(group, [0.06, 1.6, 0.9], mats.black, [1.11, 1.2, -2.6]);
  piece(group, [1.4, 0.3, 0.06], board("P 52", "#1f2a44", "#f4b42e"), [0, 2.6, -3.82]);
  wheels(group, 0.42, 0.98, [-2.6, 2.4]);
  cyl(group, 0.1, 0.1, 0.4, mats.black, [-0.8, 0.4, 3.9], 6).rotation.x = Math.PI / 2;
  return group;
}

export const shelf: Shelf = {
  title: "Rides",
  assets: [
    { name: "Angkot", build: angkot },
    { name: "Bajaj", build: bajaj },
    { name: "Becak", build: becak },
    { name: "Ojek", build: ojek },
    { name: "Pickup", build: pickup },
    { name: "Metromini", build: metromini },
  ],
};
