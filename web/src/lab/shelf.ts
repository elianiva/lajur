import * as THREE from "three";
import { CSS2DObject } from "three/addons/renderers/CSS2DRenderer.js";
import type { Shelf } from "../assets/kit.ts";
import type { View } from "./view.ts";

/**
 * Every asset on its own plinth, three variants each, one row per asset file.
 * The variants show how much a seed changes; spin turns each one on the spot.
 */

const VARIANTS = 3;
const GAP = 1.6;
const MARGIN = 1.4;
const ROW_GAP = 12;
/** Rows wrap past this width, so a long shelf stays on screen. */
const WRAP = 320;

const plinth = new THREE.MeshStandardMaterial({ color: 0xfff6dd, roughness: 0.95 });
plinth.name = "walk";
const floor = new THREE.MeshStandardMaterial({ color: 0x9ccf86, roughness: 1 });
floor.name = "ground";

function label(text: string, className: string): CSS2DObject {
  const element = document.createElement("div");
  element.className = className;
  element.textContent = text;
  return new CSS2DObject(element);
}

export function shelfView(shelves: Shelf[], seed: number, spin: () => boolean): View {
  const group = new THREE.Group();
  const turning: THREE.Object3D[] = [];
  const wheels: THREE.Object3D[] = [];
  const bounds = new THREE.Box3();
  const size = new THREE.Vector3();
  const centre = new THREE.Vector3();
  let z = 0;
  let width = 0;

  shelves.forEach((shelf, row) => {
    let x = 0;
    let depth = 0;
    const top = z;

    shelf.assets.forEach((asset, column) => {
      if (x > WRAP) {
        width = Math.max(width, x);
        z += depth + ROW_GAP * 0.6;
        x = 0;
        depth = 0;
      }
      const stand = new THREE.Group();
      let along = MARGIN;
      let deep = 0;

      for (let variant = 0; variant < VARIANTS; variant += 1) {
        const pick = (seed + row * 0.37 + column * 0.13 + variant / VARIANTS) % 1;
        const model = asset.build(pick);
        bounds.setFromObject(model).getSize(size);
        bounds.getCenter(centre);

        // Room for the widest turn, so spinning neighbours never touch.
        const reach = Math.hypot(size.x, size.z);
        const pivot = new THREE.Group();
        model.position.set(-centre.x, 0, -centre.z);
        pivot.add(model);
        pivot.position.set(along + reach / 2, 0.3, 0);
        stand.add(pivot);
        turning.push(pivot);
        model.traverse((node) => {
          if (node instanceof THREE.Mesh) {
            node.castShadow = true;
            node.receiveShadow = true;
          }
          if (node.name === "wheel") wheels.push(node);
        });

        along += reach + GAP;
        deep = Math.max(deep, reach);
      }

      const span = along - GAP + MARGIN;
      const depthWithMargin = deep + MARGIN * 2;
      const base = new THREE.Mesh(new THREE.BoxGeometry(span, 0.3, depthWithMargin), plinth);
      base.position.set(span / 2, 0.15, 0);
      base.receiveShadow = true;
      stand.add(base);

      const tag = label(asset.name, "tag");
      tag.position.set(span / 2, 0, depthWithMargin / 2 + 0.6);
      stand.add(tag);

      stand.position.set(x, 0, z + depthWithMargin / 2);
      group.add(stand);
      x += span + GAP * 2;
      depth = Math.max(depth, depthWithMargin);
    });

    const title = label(shelf.title, "row");
    title.position.set(-2, 0, top + 4);
    title.center.set(1, 0.5);
    group.add(title);

    width = Math.max(width, x);
    z += depth + ROW_GAP;
  });

  // Centre the rows on the origin, and lay a floor under them.
  const halfX = width / 2;
  const halfZ = (z - ROW_GAP) / 2;
  for (const child of group.children) child.position.add(new THREE.Vector3(-halfX, 0, -halfZ));
  const framed = new THREE.Box3().setFromObject(group);
  framed.min.x -= 12; // the row titles hang off the left edge
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(width + 400, z + 400), floor);
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  group.add(ground);

  return {
    group,
    bounds: framed,
    update(dt) {
      if (spin()) for (const pivot of turning) pivot.rotation.y += dt * 0.5;
      for (const wheel of wheels) wheel.rotation.x -= dt * 6;
    },
  };
}
