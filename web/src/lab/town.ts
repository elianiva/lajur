import * as THREE from "three";
import { bodyLength } from "../bend.ts";
import { house, ruko, warung } from "../assets/buildings.ts";
import { buildCar, trafficColour } from "../assets/cars.ts";
import { box, mats } from "../assets/kit.ts";
import { cart, motorbike, powerPole } from "../assets/street.ts";
import { banana, palm } from "../assets/trees.ts";
import type { Body } from "../game.mjs";
import { random, type View } from "./view.ts";

/**
 * One town block with every asset in use: a ring road with traffic both ways,
 * rows of ruko and warung facing it, houses behind, a park in the middle.
 * This is a showroom, not the game; nothing here is a rule.
 */

const LANE = 3.25;
const ROAD_HALF = LANE * 2;
const WALK_OUT = ROAD_HALF + 2;
const FRONT = WALK_OUT + 1;
const HX = 46;
const HZ = 30;
const R = 11;

interface Point {
  x: number;
  z: number;
  tx: number;
  tz: number;
}

/** The ring's centre line: four straights and four quarter turns. */
const SIDES = [
  { x: -(HX - R), z: -HZ, dx: 1, dz: 0, length: 2 * (HX - R) },
  { x: HX, z: -(HZ - R), dx: 0, dz: 1, length: 2 * (HZ - R) },
  { x: HX - R, z: HZ, dx: -1, dz: 0, length: 2 * (HX - R) },
  { x: -HX, z: HZ - R, dx: 0, dz: -1, length: 2 * (HZ - R) },
];
const CORNERS = [
  { x: HX - R, z: -(HZ - R) },
  { x: HX - R, z: HZ - R },
  { x: -(HX - R), z: HZ - R },
  { x: -(HX - R), z: -(HZ - R) },
];
const TURN = (R * Math.PI) / 2;
const LOOP = SIDES.reduce((sum, side) => sum + side.length + TURN, 0);

/** A point `lateral` metres outward of the centre line, `s` metres along it. */
function ring(s: number, lateral: number): Point {
  let rest = ((s % LOOP) + LOOP) % LOOP;
  for (let k = 0; k < 4; k += 1) {
    const side = SIDES[k]!;
    if (rest < side.length) {
      // Outward is the direction turned a quarter to the left of travel.
      const nx = side.dz;
      const nz = -side.dx;
      return {
        x: side.x + side.dx * rest + nx * lateral,
        z: side.z + side.dz * rest + nz * lateral,
        tx: side.dx,
        tz: side.dz,
      };
    }
    rest -= side.length;
    if (rest < TURN) {
      const corner = CORNERS[k]!;
      const angle = -Math.PI / 2 + (k * Math.PI) / 2 + rest / R;
      const cos = Math.cos(angle);
      const sin = Math.sin(angle);
      return {
        x: corner.x + cos * (R + lateral),
        z: corner.z + sin * (R + lateral),
        tx: -sin,
        tz: cos,
      };
    }
    rest -= TURN;
  }
  return ring(0, lateral);
}

/** The yaw that points a model's local -z (a car's nose) along (tx, tz). */
function nose(tx: number, tz: number): number {
  return Math.atan2(-tx, -tz);
}

/** The yaw that points a model's local +x (a building's front) along (fx, fz). */
function front(fx: number, fz: number): number {
  return Math.atan2(-fz, fx);
}

function roundedRect(hx: number, hz: number, r: number, path: THREE.Path = new THREE.Shape()) {
  path.moveTo(-hx + r, -hz);
  path.lineTo(hx - r, -hz);
  path.absarc(hx - r, -hz + r, r, -Math.PI / 2, 0, false);
  path.lineTo(hx, hz - r);
  path.absarc(hx - r, hz - r, r, 0, Math.PI / 2, false);
  path.lineTo(-hx + r, hz);
  path.absarc(-hx + r, hz - r, r, Math.PI / 2, Math.PI, false);
  path.lineTo(-hx, -hz + r);
  path.absarc(-hx + r, -hz + r, r, Math.PI, Math.PI * 1.5, false);
  return path;
}

/** A flat band between two offsets from the centre line, `height` thick. */
function band(outer: number, inner: number | null, height: number, material: THREE.Material) {
  const shape = roundedRect(HX + outer, HZ + outer, R + outer) as THREE.Shape;
  if (inner !== null)
    shape.holes.push(roundedRect(HX + inner, HZ + inner, R + inner, new THREE.Path()));
  const geometry = new THREE.ExtrudeGeometry(shape, { depth: height, bevelEnabled: false });
  geometry.rotateX(-Math.PI / 2);
  const mesh = new THREE.Mesh(geometry, material);
  mesh.receiveShadow = true;
  return mesh;
}

interface Mover {
  object: THREE.Object3D;
  wheels: THREE.Object3D[];
  s: number;
  lateral: number;
  speed: number;
}

const BODIES: Body["$"][] = ["Sedan", "Sedan", "Hatch", "Hatch", "Taxi", "Van", "Bus", "Truck"];

export function townView(seed: number): View {
  const group = new THREE.Group();
  const roll = random(seed);
  const add = (object: THREE.Object3D, x: number, y: number, z: number, yaw = 0) => {
    object.position.set(x, y, z);
    object.rotation.y = yaw;
    group.add(object);
  };

  // Ground, the ring of asphalt, pavements both sides, and the park inside.
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(420, 420), mats.ground);
  ground.rotation.x = -Math.PI / 2;
  ground.position.y = -0.02;
  ground.receiveShadow = true;
  group.add(ground);
  group.add(band(ROAD_HALF, -ROAD_HALF, 0.02, mats.asphalt));
  group.add(band(WALK_OUT, ROAD_HALF, 0.16, mats.walk));
  group.add(band(-ROAD_HALF, -WALK_OUT, 0.16, mats.walk));
  group.add(band(-WALK_OUT, null, 0.1, mats.grass));

  // Lane markings: a dashed centre and dashed lane dividers.
  for (const lateral of [-LANE, 0, LANE]) {
    for (let s = 0; s < LOOP; s += 9) {
      const at = ring(s + 1.5, lateral);
      add(new THREE.Mesh(box(0.15, 0.02, 3), mats.paint), at.x, 0.03, at.z, nose(at.tx, at.tz));
    }
  }
  // A zebra crossing over the top straight.
  for (let lateral = -ROAD_HALF + 0.7; lateral < ROAD_HALF - 0.5; lateral += 1.2) {
    const at = ring(SIDES[0]!.length / 2, lateral);
    add(new THREE.Mesh(box(3.2, 0.02, 0.6), mats.paint), at.x, 0.03, at.z);
  }

  let along = 0;
  for (const side of SIDES) {
    const start = along;
    along += side.length + TURN;
    const nx = side.dz;
    const nz = -side.dx;
    const long = side.dx !== 0;

    // The outer row faces in: ruko, warung and houses shoulder to shoulder.
    for (let cursor = -6; cursor < side.length + 4;) {
      const pick = roll();
      const width = pick < 0.3 ? 3.6 : 4.5 + roll() * 2.5;
      const depth = 7 + roll() * 4;
      const cue = roll();
      const at = ring(start + cursor + width / 2, FRONT + depth / 2);
      const building =
        pick < 0.3 ? warung(cue) : pick < 0.75 ? ruko(cue, width, depth) : house(cue, width, depth);
      const offset = pick < 0.3 ? -depth / 2 + 1.4 : 0;
      add(building, at.x + nx * offset, 0, at.z + nz * offset, front(-nx, -nz));

      if (roll() > 0.45) {
        for (let n = 0, bikes = 1 + Math.floor(roll() * 3); n < bikes; n += 1) {
          const spot = ring(start + cursor + 0.9 + n * 0.85, ROAD_HALF + 0.9);
          add(motorbike(roll()), spot.x, 0.16, spot.z, nose(nx, nz) + 0.2);
        }
      }
      if (roll() > 0.85) {
        const spot = ring(start + cursor + width + 0.4, WALK_OUT - 0.4);
        add(cart(roll()), spot.x, 0.16, spot.z, nose(side.dx, side.dz));
      }
      cursor += width + 0.6 + roll() * 1.6;
    }

    // A row of houses behind it, so the block is not one wall deep.
    for (let cursor = -10; cursor < side.length + 8;) {
      const width = 8 + roll() * 7;
      const depth = 8 + roll() * 5;
      const at = ring(start + cursor + width / 2, FRONT + 14 + depth / 2);
      add(house(roll(), width, depth), at.x, 0, at.z, front(-nx, -nz) + (roll() - 0.5) * 0.15);
      cursor += width + 2 + roll() * 3;
    }

    // Poles down the outer kerb, wires strung between them.
    const poles: THREE.Vector3[] = [];
    for (let cursor = 3; cursor < side.length; cursor += 16) {
      const at = ring(start + cursor, ROAD_HALF + 0.35);
      const pole = powerPole();
      add(pole, at.x, 0, at.z, nose(side.dx, side.dz) + Math.PI / 2);
      poles.push(pole.position.clone());
    }
    for (let i = 0; i + 1 < poles.length; i += 1) {
      for (const height of [6.85, 7.25]) {
        const from = poles[i]!.clone().setY(height);
        const to = poles[i + 1]!.clone().setY(height);
        const wire = new THREE.Mesh(
          new THREE.BoxGeometry(0.035, 0.035, from.distanceTo(to)),
          mats.wire,
        );
        wire.position.copy(from).lerp(to, 0.5);
        wire.lookAt(to);
        group.add(wire);
      }
    }

    // Inside the ring: shops back onto the park along the long sides, and
    // trees line the short ones.
    if (long) {
      for (let cursor = 0.5; cursor < side.length - 4;) {
        const width = 4.5 + roll() * 2.5;
        const depth = 7 + roll() * 3;
        const at = ring(start + cursor + width / 2, -(FRONT + depth / 2));
        add(ruko(roll(), width, depth), at.x, 0.1, at.z, front(nx, nz));
        cursor += width + 0.4 + roll() * 1.2;
      }
    } else {
      for (let cursor = 2; cursor < side.length; cursor += 4 + roll() * 3) {
        const at = ring(start + cursor, -(WALK_OUT + 2));
        add(roll() > 0.5 ? palm(roll()) : banana(roll()), at.x, 0.1, at.z, roll() * 6);
      }
    }
  }

  // The park: a scatter of palms and bananas between the two inner rows.
  for (let n = 0; n < 34; n += 1) {
    const x = (roll() - 0.5) * 2 * (HX - WALK_OUT - 6);
    const z = (roll() - 0.5) * 2 * (HZ - FRONT - 13);
    add(roll() > 0.4 ? palm(roll()) : banana(roll()), x, 0.1, z, roll() * 6);
  }
  // A clump of palms on each outer corner, where the rows leave a gap.
  for (const corner of CORNERS) {
    const facing = Math.atan2(Math.sign(corner.z), Math.sign(corner.x));
    for (let n = 0; n < 6; n += 1) {
      const angle = facing + (roll() - 0.5) * 0.9;
      const reach = R + WALK_OUT + 2 + roll() * 7;
      add(palm(roll()), corner.x + Math.cos(angle) * reach, 0, corner.z + Math.sin(angle) * reach);
    }
  }

  group.traverse((node) => {
    if (node instanceof THREE.Mesh) {
      node.castShadow = true;
      node.receiveShadow = true;
    }
  });
  ground.castShadow = false;

  // Traffic keeps left: the outer lanes run with the loop, the inner against.
  const movers: Mover[] = [];
  for (const lateral of [-4.875, -1.625, 1.625, 4.875]) {
    const speed = (lateral > 0 ? 1 : -1) * (7 + Math.abs(lateral) * 0.5 + roll() * 2);
    for (let s = roll() * 10; s < LOOP - 10; s += 16 + roll() * 22) {
      let object: THREE.Object3D;
      if (roll() < 0.3) {
        object = motorbike(roll());
      } else {
        const body = BODIES[Math.floor(roll() * BODIES.length)]!;
        object = buildCar(body, trafficColour(Math.floor(roll() * 97)), bodyLength(body)).group;
      }
      const wheels: THREE.Object3D[] = [];
      object.traverse((node) => {
        if (node instanceof THREE.Mesh) node.castShadow = true;
        if (node.name === "wheel") wheels.push(node);
      });
      group.add(object);
      movers.push({ object, wheels, s, lateral, speed });
    }
  }

  const place = (mover: Mover) => {
    const at = ring(mover.s, mover.lateral);
    const sign = Math.sign(mover.speed);
    mover.object.position.set(at.x, 0.02, at.z);
    mover.object.rotation.y = nose(at.tx * sign, at.tz * sign);
  };
  movers.forEach(place);

  return {
    group,
    bounds: new THREE.Box3(
      new THREE.Vector3(-HX - FRONT - 4, 0, -HZ - FRONT - 4),
      new THREE.Vector3(HX + FRONT + 4, 8, HZ + FRONT + 4),
    ),
    update(dt) {
      for (const mover of movers) {
        mover.s += mover.speed * dt;
        place(mover);
        for (const wheel of mover.wheels) wheel.rotation.x -= (Math.abs(mover.speed) * dt) / 0.34;
      }
    },
  };
}
