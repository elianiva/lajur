import * as THREE from "three";
import { MapControls } from "three/addons/controls/MapControls.js";
import { CSS2DObject, CSS2DRenderer } from "three/addons/renderers/CSS2DRenderer.js";
import type { Shelf } from "../assets/kit.ts";
import { Ink, light, lookByKey, looks, restyle } from "../render/look.ts";
import { shelfView } from "./shelf.ts";
import { townView } from "./town.ts";
import type { View } from "./view.ts";
import "./lab.css";

// Every file in src/assets that exports a `shelf` gets a row. Add a file,
// export a shelf, and it is here on the next reload.
const modules = import.meta.glob<{ shelf?: Shelf }>("../assets/*.ts", { eager: true });
const shelves = Object.values(modules).flatMap((module) => (module.shelf ? [module.shelf] : []));

const stage = document.querySelector<HTMLDivElement>("#stage")!;
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFShadowMap;
stage.append(renderer.domElement);

const labels = new CSS2DRenderer();
labels.domElement.className = "labels";
stage.append(labels.domElement);

const ink = new Ink(renderer);

const scene = new THREE.Scene();
const hemi = new THREE.HemisphereLight();
scene.add(hemi);
const sun = new THREE.DirectionalLight();
sun.castShadow = true;
sun.shadow.mapSize.set(4096, 4096);
sun.shadow.bias = -0.0005;
scene.add(sun, sun.target);

// tiny.london's angle: a steep, fixed-lens bird's-eye view.
const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, -1000, 2000);
const controls = new MapControls(camera, labels.domElement);
controls.enableDamping = true;
controls.zoomToCursor = true;
controls.minZoom = 0.4;
controls.maxZoom = 12;
controls.maxPolarAngle = 1.2;

let frame = 60;
function resize(): void {
  const aspect = window.innerWidth / window.innerHeight;
  camera.left = (-frame * aspect) / 2;
  camera.right = (frame * aspect) / 2;
  camera.top = frame / 2;
  camera.bottom = -frame / 2;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  labels.setSize(window.innerWidth, window.innerHeight);
  ink.resize();
}
window.addEventListener("resize", resize);

type Mode = "shelf" | "town";
let mode: Mode = location.hash === "#town" ? "town" : "shelf";
let seed = 0.2024;
let spinning = false;
let view: View | null = null;
// The look comes from ?look=, then the last one picked here; the game reads
// the same key, so what you pick in the lab is what you drive.
let look = lookByKey(
  new URLSearchParams(location.search).get("look") ?? localStorage.getItem("lajur.look"),
);

function teardown(group: THREE.Object3D): void {
  group.traverse((node) => {
    if (node instanceof CSS2DObject) node.element.remove();
  });
  scene.remove(group);
}

/** Fit the sun's shadow to what is shown, from the look's direction. */
function aim(bounds: THREE.Box3): void {
  const centre = bounds.getCenter(new THREE.Vector3()).setY(0);
  const reach = bounds.getSize(new THREE.Vector3()).length() / 2;
  const shadow = sun.shadow.camera;
  shadow.left = shadow.bottom = -reach;
  shadow.right = shadow.top = reach;
  shadow.near = 1;
  shadow.far = reach * 5;
  shadow.updateProjectionMatrix();
  // About two shadow texels: enough to keep acne off sloped roofs.
  sun.shadow.normalBias = (reach * 4) / sun.shadow.mapSize.x;
  sun.target.position.copy(centre);
  sun.position
    .copy(centre)
    .add(new THREE.Vector3(...look.sunFrom).normalize().multiplyScalar(reach * 2));
}

function show(reframe: boolean): void {
  if (view) teardown(view.group);
  view = mode === "shelf" ? shelfView(shelves, seed, () => spinning) : townView(seed);
  scene.add(view.group);
  restyle(view.group, look);

  const bounds = view.bounds;
  const centre = bounds.getCenter(new THREE.Vector3()).setY(0);
  const reach = bounds.getSize(new THREE.Vector3()).length() / 2;
  aim(bounds);

  if (reframe) {
    // Look from the south, a little to the east, and fit the content's
    // corners as the camera sees them.
    controls.target.copy(centre);
    camera.position.copy(centre).add(new THREE.Vector3(0.35, 1.25, 1).multiplyScalar(reach * 2));
    camera.zoom = 1;
    camera.lookAt(centre);
    camera.updateMatrixWorld();
    const seen = new THREE.Box3();
    for (let corner = 0; corner < 8; corner += 1) {
      const point = new THREE.Vector3(
        corner & 1 ? bounds.max.x : bounds.min.x,
        corner & 2 ? bounds.max.y : bounds.min.y,
        corner & 4 ? bounds.max.z : bounds.min.z,
      );
      seen.expandByPoint(point.applyMatrix4(camera.matrixWorldInverse));
    }
    const size = seen.getSize(new THREE.Vector3());
    const aspect = window.innerWidth / window.innerHeight;
    frame = Math.max(size.y, size.x / aspect) * 1.12;
    resize();

    // ?at=x,z,zoom frames one spot, so a view can be shared as a link.
    const at = new URLSearchParams(location.search).get("at")?.split(",").map(Number);
    if (at?.length === 3 && at.every(Number.isFinite)) {
      const shift = new THREE.Vector3(at[0]!, 0, at[1]!).sub(controls.target);
      controls.target.add(shift);
      camera.position.add(shift);
      camera.zoom = at[2]!;
      camera.updateProjectionMatrix();
    }
  }

  for (const button of document.querySelectorAll<HTMLButtonElement>("[data-mode]")) {
    button.setAttribute("aria-pressed", String(button.dataset.mode === mode));
  }
  document.querySelector<HTMLButtonElement>("#spin")!.hidden = mode !== "shelf";
}

const picker = document.querySelector<HTMLElement>("#looks")!;
for (const option of looks) {
  const button = document.createElement("button");
  button.textContent = option.name;
  button.dataset.look = option.key;
  button.addEventListener("click", () => {
    look = option;
    localStorage.setItem("lajur.look", look.key);
    applyLook();
    if (view) {
      restyle(view.group, look);
      aim(view.bounds);
    }
  });
  picker.append(button);
}

function applyLook(): void {
  light(scene, hemi, sun, look);
  ink.setLook(look);
  for (const button of picker.querySelectorAll<HTMLButtonElement>("button")) {
    button.setAttribute("aria-pressed", String(button.dataset.look === look.key));
  }
}
applyLook();

for (const button of document.querySelectorAll<HTMLButtonElement>("[data-mode]")) {
  button.addEventListener("click", () => {
    mode = button.dataset.mode as Mode;
    history.replaceState(null, "", mode === "town" ? "#town" : "#");
    show(true);
  });
}
document.querySelector("#reroll")!.addEventListener("click", () => {
  seed = Math.random();
  show(false);
});
const spin = document.querySelector<HTMLButtonElement>("#spin")!;
spin.addEventListener("click", () => {
  spinning = !spinning;
  spin.setAttribute("aria-pressed", String(spinning));
});

show(true);

let previous = performance.now();
renderer.setAnimationLoop((now) => {
  const dt = Math.min(now - previous, 100) / 1000;
  previous = now;
  view?.update(dt);
  controls.update();
  // Asset tags only once they have room; row titles always.
  labels.domElement.classList.toggle("far", camera.zoom < 1.6);
  ink.render(scene, camera);
  labels.render(scene, camera);
});
