import * as THREE from "three";
import type { OrderView } from "../bend.ts";

const PICKUP = 0xffb02e;
const DROP = 0x2ec27e;
/** How far the model lets the car stop from the stop, in metres. */
const REACH = 25;

/**
 * The stop the model chose, drawn where it is: a ring the size of the stretch
 * the car may stop in and a light column above it, amber for a passenger
 * waiting and green for a drop-off. An arrow over the car points at it.
 */
export class Stop {
  readonly group = new THREE.Group();
  private ring: THREE.Mesh<THREE.RingGeometry, THREE.MeshBasicMaterial>;
  private column: THREE.Mesh<THREE.CylinderGeometry, THREE.MeshBasicMaterial>;
  private arrow: THREE.Mesh<THREE.ShapeGeometry, THREE.MeshBasicMaterial>;
  private time = 0;

  constructor() {
    this.ring = new THREE.Mesh(
      new THREE.RingGeometry(REACH - 2, REACH, 48).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ transparent: true, opacity: 0.55, depthWrite: false }),
    );
    this.ring.position.y = 0.3;
    this.column = new THREE.Mesh(
      new THREE.CylinderGeometry(2.4, 2.4, 40, 24, 1, true),
      new THREE.MeshBasicMaterial({
        transparent: true,
        opacity: 0.35,
        depthWrite: false,
        side: THREE.DoubleSide,
      }),
    );
    this.column.position.y = 20;
    const shape = new THREE.Shape();
    shape.moveTo(0, 3.2);
    shape.lineTo(2.2, -0.6);
    shape.lineTo(0.8, -0.6);
    shape.lineTo(0.8, -2.4);
    shape.lineTo(-0.8, -2.4);
    shape.lineTo(-0.8, -0.6);
    shape.lineTo(-2.2, -0.6);
    shape.closePath();
    this.arrow = new THREE.Mesh(
      new THREE.ShapeGeometry(shape).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ transparent: true, opacity: 0.9, depthTest: false }),
    );
    this.arrow.renderOrder = 10;
    this.group.add(this.ring, this.column, this.arrow);
  }

  update(order: OrderView, car: THREE.Vector3, dt: number): void {
    this.time += dt;
    const colour = order.aboard ? DROP : PICKUP;
    for (const mesh of [this.ring, this.column, this.arrow]) mesh.material.color.setHex(colour);
    this.ring.position.x = this.column.position.x = order.x;
    this.ring.position.z = this.column.position.z = order.z;
    this.column.material.opacity = 0.25 + 0.12 * Math.sin(this.time * 4);

    // The arrow floats ahead of the car toward the stop, and hides once the
    // stop is in reach.
    const dx = order.x - car.x;
    const dz = order.z - car.z;
    const far = Math.hypot(dx, dz);
    this.arrow.visible = far > REACH * 1.6;
    this.arrow.position.set(car.x + (dx / far) * 7, 3.5, car.z + (dz / far) * 7);
    this.arrow.rotation.y = Math.atan2(-dx, -dz);
  }
}
