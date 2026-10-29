import * as THREE from "three";
import type { LightView } from "../bend.ts";

const LIT = [0x2ec27e, 0xffb02e, 0xe0392b];
const DARK = 0x1c2226;
/** Metres back from the crossing and out to the kerb, on the left. */
const BACK = 12;
const KERB = 8.5;

/**
 * The lights at the crossing ahead, as the model reports them: a post on the
 * kerb before the crossing with three lamps, the lit one the model's state.
 * A crossing without lights shows no post.
 */
export class Signal {
  readonly group = new THREE.Group();
  private lamps: THREE.Mesh<THREE.SphereGeometry, THREE.MeshBasicMaterial>[] = [];
  private cap: THREE.Mesh<THREE.CircleGeometry, THREE.MeshBasicMaterial>;

  constructor() {
    const dark = new THREE.MeshLambertMaterial({ color: 0x2b3238 });
    const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.3, 7, 8), dark);
    pole.position.y = 3.5;
    const head = new THREE.Mesh(new THREE.BoxGeometry(2, 5.6, 2), dark);
    head.position.y = 9;
    head.castShadow = true;
    this.group.add(pole, head);
    for (let k = 0; k < 3; k++) {
      const lamp = new THREE.Mesh(
        new THREE.SphereGeometry(0.8, 16, 10),
        new THREE.MeshBasicMaterial({ color: DARK }),
      );
      // Red on top, green at the bottom.
      lamp.position.set(0, 10.8 - k * 1.8, 0);
      this.lamps.push(lamp);
      this.group.add(lamp);
    }
    this.lamps.reverse();
    // The camera looks down from high behind the car: the lit colour on top.
    this.cap = new THREE.Mesh(
      new THREE.CircleGeometry(1.1, 20).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ color: DARK }),
    );
    this.cap.position.y = 11.85;
    this.group.add(this.cap);
  }

  update(light: LightView): void {
    this.group.visible = light.state < 3;
    if (!this.group.visible) return;
    const fx = light.x - light.backX;
    const fz = light.z - light.backZ;
    const n = Math.hypot(fx, fz) || 1;
    const [ux, uz] = [fx / n, fz / n];
    // Forward is (ux, uz); the left of the road is (uz, -ux).
    this.group.position.set(light.x - ux * BACK + uz * KERB, 0, light.z - uz * BACK - ux * KERB);
    // The lamps face the car coming up to the crossing.
    for (const [k, lamp] of this.lamps.entries()) {
      lamp.position.x = -ux * 1.05;
      lamp.position.z = -uz * 1.05;
      lamp.material.color.setHex(k === light.state ? LIT[k]! : DARK);
    }
    this.cap.material.color.setHex(LIT[light.state]!);
  }
}
