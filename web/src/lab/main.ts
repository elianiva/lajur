import * as THREE from "three";
import { MapControls } from "three/addons/controls/MapControls.js";
import { CSS2DObject, CSS2DRenderer } from "three/addons/renderers/CSS2DRenderer.js";
import type { Shelf } from "../assets/kit.ts";
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

const scene = new THREE.Scene();
const sky = new THREE.Color(0xb8cdc7);
scene.background = sky;

scene.add(new THREE.HemisphereLight(0xdcecff, 0x6d6552, 1.35));
const sun = new THREE.DirectionalLight(0xfff0d2, 2.6);
sun.castShadow = true;
sun.shadow.mapSize.set(4096, 4096);
sun.shadow.bias = -0.0005;
sun.shadow.normalBias = 0.02;
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
}
window.addEventListener("resize", resize);

type Mode = "shelf" | "town";
let mode: Mode = location.hash === "#town" ? "town" : "shelf";
let seed = 0.2024;
let spinning = false;
let view: View | null = null;

function teardown(group: THREE.Object3D): void {
  group.traverse((node) => {
    if (node instanceof CSS2DObject) node.element.remove();
  });
  scene.remove(group);
}

function show(reframe: boolean): void {
  if (view) teardown(view.group);
  view = mode === "shelf" ? shelfView(shelves, seed, () => spinning) : townView(seed);
  scene.add(view.group);

  const bounds = view.bounds;
  const centre = bounds.getCenter(new THREE.Vector3()).setY(0);
  const reach = bounds.getSize(new THREE.Vector3()).length() / 2;
  const shadow = sun.shadow.camera;
  shadow.left = shadow.bottom = -reach;
  shadow.right = shadow.top = reach;
  shadow.near = 1;
  shadow.far = reach * 5;
  shadow.updateProjectionMatrix();
  sun.target.position.copy(centre);
  sun.position.copy(centre).add(new THREE.Vector3(-0.8, 2, 1).multiplyScalar(reach));

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
  }

  for (const button of document.querySelectorAll<HTMLButtonElement>("[data-mode]")) {
    button.setAttribute("aria-pressed", String(button.dataset.mode === mode));
  }
  document.querySelector<HTMLButtonElement>("#spin")!.hidden = mode !== "shelf";
}

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
  renderer.render(scene, camera);
  labels.render(scene, camera);
});
