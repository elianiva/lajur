import * as THREE from "three";
import type { Body } from "../game.mjs";
import { bodyLength } from "../bend.ts";
import { box, type Shelf } from "./kit.ts";

/**
 * Low-poly cars. Shape, colour and proportions only: position, heading and
 * every rule about the car come from the Bend model.
 */

export const PLAYER_COLOUR = 0xe0392b;

const TRAFFIC_COLOURS = [
  0x3f8cff, 0xffc93c, 0xf7f4ea, 0x22c3a6, 0xa070ff, 0x52c75a, 0xff8a3d, 0xff6fa8, 0x5ad1ff,
];

export function trafficColour(index: number): number {
  return TRAFFIC_COLOURS[index % TRAFFIC_COLOURS.length]!;
}

const paints = new Map<number, THREE.MeshStandardMaterial>();

function paint(colour: number): THREE.MeshStandardMaterial {
  const cached = paints.get(colour);
  if (cached) return cached;
  const material = new THREE.MeshStandardMaterial({
    color: colour,
    roughness: 0.72,
    metalness: 0.05,
    flatShading: true,
  });
  material.name = "car";
  paints.set(colour, material);
  return material;
}

const glass = new THREE.MeshStandardMaterial({
  color: 0x2b3a45,
  roughness: 0.28,
  metalness: 0.2,
  flatShading: true,
});

const rubber = new THREE.MeshStandardMaterial({
  color: 0x1e1f24,
  roughness: 0.95,
  flatShading: true,
});

glass.name = "glass";

const tail = new THREE.MeshStandardMaterial({
  color: 0xd8442f,
  emissive: 0x4d0f08,
  roughness: 0.5,
});
const beam = new THREE.MeshStandardMaterial({
  color: 0xfff1c9,
  emissive: 0x3a3220,
  roughness: 0.5,
});
tail.name = "accent";
beam.name = "lamp";

const trim = new THREE.MeshStandardMaterial({ color: 0x3a3d48, roughness: 0.8 });
trim.name = "accent";

const wheelGeometry = new THREE.CylinderGeometry(0.34, 0.34, 0.26, 8);
wheelGeometry.rotateZ(Math.PI / 2);

export interface CarMesh {
  group: THREE.Group;
  wheels: THREE.Mesh[];
  key: string;
}

function piece(
  parent: THREE.Group,
  size: [number, number, number],
  material: THREE.Material,
  at: [number, number, number],
): THREE.Mesh {
  const mesh = new THREE.Mesh(box(...size), material);
  mesh.position.set(...at);
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  parent.add(mesh);
  return mesh;
}

function wheel(parent: THREE.Group, x: number, z: number): THREE.Mesh {
  const mesh = new THREE.Mesh(wheelGeometry, rubber);
  mesh.name = "wheel";
  mesh.position.set(x, 0.34, z);
  mesh.castShadow = true;
  parent.add(mesh);
  return mesh;
}

/**
 * Hull, cabin and wheels, sized from the model's envelope length so the mesh
 * matches the distance the collision test uses.
 */
function outline(body: Body["$"], colour: number, length: number): CarMesh {
  const group = new THREE.Group();
  const wheels: THREE.Mesh[] = [];
  const skin = paint(colour);

  switch (body) {
    case "Sedan": {
      piece(group, [1.84, 0.62, length], skin, [0, 0.64, 0]);
      piece(group, [1.66, 0.54, length * 0.48], glass, [0, 1.16, 0.18]);
      piece(group, [1.7, 0.12, length * 0.5], skin, [0, 1.47, 0.18]);
      piece(group, [0.5, 0.12, 0.06], tail, [-0.56, 0.78, length / 2 + 0.01]);
      piece(group, [0.5, 0.12, 0.06], tail, [0.56, 0.78, length / 2 + 0.01]);
      piece(group, [0.44, 0.14, 0.06], beam, [-0.56, 0.72, -length / 2 - 0.01]);
      piece(group, [0.44, 0.14, 0.06], beam, [0.56, 0.72, -length / 2 - 0.01]);
      wheels.push(wheel(group, -0.84, length * 0.32), wheel(group, 0.84, length * 0.32));
      wheels.push(wheel(group, -0.84, -length * 0.32), wheel(group, 0.84, -length * 0.32));
      break;
    }
    case "Hatch": {
      piece(group, [1.78, 0.66, length], skin, [0, 0.66, 0]);
      piece(group, [1.62, 0.62, length * 0.58], glass, [0, 1.2, 0.32]);
      piece(group, [1.66, 0.12, length * 0.6], skin, [0, 1.55, 0.32]);
      piece(group, [0.46, 0.16, 0.06], tail, [-0.56, 0.86, length / 2 + 0.01]);
      piece(group, [0.46, 0.16, 0.06], tail, [0.56, 0.86, length / 2 + 0.01]);
      wheels.push(wheel(group, -0.82, length * 0.31), wheel(group, 0.82, length * 0.31));
      wheels.push(wheel(group, -0.82, -length * 0.31), wheel(group, 0.82, -length * 0.31));
      break;
    }
    case "Taxi": {
      piece(group, [1.84, 0.62, length], paint(0xe4b33c), [0, 0.64, 0]);
      piece(group, [1.66, 0.54, length * 0.48], glass, [0, 1.16, 0.18]);
      piece(group, [1.7, 0.12, length * 0.5], paint(0xe4b33c), [0, 1.47, 0.18]);
      piece(group, [0.62, 0.2, 0.32], paint(0xfff3c4), [0, 1.63, 0.1]);
      piece(group, [0.16, 0.06, 0.3], tail, [-0.5, 0.78, length / 2 + 0.01]);
      piece(group, [0.16, 0.06, 0.3], tail, [0.5, 0.78, length / 2 + 0.01]);
      wheels.push(wheel(group, -0.84, length * 0.32), wheel(group, 0.84, length * 0.32));
      wheels.push(wheel(group, -0.84, -length * 0.32), wheel(group, 0.84, -length * 0.32));
      break;
    }
    case "Van": {
      piece(group, [1.94, 1.12, length], skin, [0, 0.9, 0]);
      piece(group, [1.82, 0.52, length * 0.22], glass, [0, 1.32, -length * 0.36]);
      piece(group, [1.7, 0.1, length * 0.8], paint(0xf0ede2), [0, 1.48, 0.06]);
      piece(group, [0.4, 0.24, 0.06], tail, [-0.66, 1.0, length / 2 + 0.01]);
      piece(group, [0.4, 0.24, 0.06], tail, [0.66, 1.0, length / 2 + 0.01]);
      wheels.push(wheel(group, -0.88, length * 0.33), wheel(group, 0.88, length * 0.33));
      wheels.push(wheel(group, -0.88, -length * 0.33), wheel(group, 0.88, -length * 0.33));
      break;
    }
    case "Bus": {
      piece(group, [2.36, 1.5, length], skin, [0, 1.12, 0]);
      piece(group, [2.4, 0.62, length * 0.82], glass, [0, 1.72, 0.1]);
      piece(group, [2.3, 0.1, length * 0.86], paint(0xf2efe4), [0, 2.06, 0.1]);
      piece(group, [0.9, 0.5, 0.06], glass, [0, 1.6, -length / 2 - 0.01]);
      piece(group, [0.3, 0.3, 0.06], tail, [-0.86, 0.8, length / 2 + 0.01]);
      piece(group, [0.3, 0.3, 0.06], tail, [0.86, 0.8, length / 2 + 0.01]);
      for (const z of [length * 0.32, length * 0.12, -length * 0.28]) {
        wheels.push(wheel(group, -1.06, z), wheel(group, 1.06, z));
      }
      break;
    }
    case "Truck": {
      const cab = length * 0.36;
      piece(group, [2.16, 1.34, cab], skin, [0, 1.0, -length / 2 + cab / 2]);
      piece(group, [2.0, 0.5, cab * 0.5], glass, [0, 1.36, -length / 2 + cab * 0.34]);
      piece(group, [2.16, 0.9, length - cab - 0.2], paint(0xcfc7b4), [0, 1.22, cab / 2 + 0.1]);
      piece(group, [2.2, 0.14, length - cab - 0.2], skin, [0, 1.72, cab / 2 + 0.1]);
      piece(group, [0.34, 0.28, 0.06], tail, [-0.8, 1.0, length / 2 + 0.01]);
      piece(group, [0.34, 0.28, 0.06], tail, [0.8, 1.0, length / 2 + 0.01]);
      wheels.push(wheel(group, -0.92, -length * 0.34), wheel(group, 0.92, -length * 0.34));
      wheels.push(wheel(group, -0.92, length * 0.28), wheel(group, 0.92, length * 0.28));
      wheels.push(wheel(group, -0.92, length * 0.4), wheel(group, 0.92, length * 0.4));
      break;
    }
  }

  // Bumpers front and back, a dark sill: the ink reads them as one silhouette.
  const width = body === "Bus" ? 2.4 : body === "Truck" ? 2.2 : 1.9;
  piece(group, [width, 0.22, 0.22], trim, [0, 0.42, -length / 2]);
  piece(group, [width, 0.22, 0.22], trim, [0, 0.42, length / 2]);

  return { group, wheels, key: `${body}:${colour}:${Math.round(length)}` };
}

export function buildCar(body: Body["$"], colour: number, length: number): CarMesh {
  const car = outline(body, colour, length);
  car.group.traverse((node) => {
    if (node instanceof THREE.Mesh) {
      node.castShadow = true;
    }
  });
  return car;
}

const BODIES: Body["$"][] = ["Sedan", "Hatch", "Taxi", "Van", "Bus", "Truck"];

// Lengths come from the model, so the lab shows the envelope the game collides.
export const shelf: Shelf = {
  title: "Cars",
  assets: BODIES.map((body) => ({
    name: body,
    build: (seed: number) =>
      buildCar(body, trafficColour(Math.floor(seed * 97)), bodyLength(body)).group,
  })),
};
