import * as THREE from "three";
import { Ink, light, lookByKey, restyle } from "../render/look.ts";
import { townView } from "./view.ts";
import "./town.css";

/**
 * The town, whole, from above.
 *
 * This page exists to be looked at: it frames every junction the model lays
 * out, draws it with the kit, and stops. The game will stream what this page
 * shows at once.
 */

const stage = document.querySelector<HTMLDivElement>("#stage");
if (!stage) throw new Error("missing #stage");

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFShadowMap;
stage.append(renderer.domElement);

const ink = new Ink(renderer);
const look = lookByKey(
  new URLSearchParams(location.search).get("look") ?? localStorage.getItem("lajur.look"),
);
ink.setLook(look);

const scene = new THREE.Scene();

const hemi = new THREE.HemisphereLight();
scene.add(hemi);
const sun = new THREE.DirectionalLight();
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.bias = -0.0005;
scene.add(sun, sun.target);
light(scene, hemi, sun, look);

const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, -500, 2000);

const town = townView({ buildings: new URLSearchParams(location.search).get("buildings") !== "0" });
scene.add(town.group);
restyle(town.group, look);

const bounds = town.bounds;
const centre = bounds.getCenter(new THREE.Vector3()).setY(0);

// ?at=x,z centres the view on a spot in metres; ?span=metres fixes the height
// of the frame, so a corner can be looked at without moving the camera.
const query = new URLSearchParams(location.search);
const at = query.get("at")?.split(",").map(Number);
const fixed = Number(query.get("span"));
if (at?.length === 2 && at.every(Number.isFinite)) centre.set(at[0]!, 0, at[1]!);

function frame(): void {
  renderer.setSize(window.innerWidth, window.innerHeight);
  ink.resize();

  camera.updateMatrixWorld();
  const inverse = camera.matrixWorldInverse;

  // Fit the town as the camera sees it, corners and all, and centre on it.
  const seen = new THREE.Box3();
  for (let corner = 0; corner < 8; corner += 1) {
    const point = new THREE.Vector3(
      corner & 1 ? bounds.max.x : bounds.min.x,
      corner & 2 ? bounds.max.y : bounds.min.y,
      corner & 4 ? bounds.max.z : bounds.min.z,
    );
    seen.expandByPoint(point.applyMatrix4(inverse));
  }
  const aspect = window.innerWidth / window.innerHeight;
  const across = seen.getSize(new THREE.Vector3());
  const fixedSpan = Number.isFinite(fixed) && fixed > 0 ? fixed : 0;
  const tall = fixedSpan > 0 ? fixedSpan : Math.max(across.y, across.x / aspect) * 1.06;
  const wide = tall * aspect;
  const midX = (seen.min.x + seen.max.x) / 2;
  const midY = (seen.min.y + seen.max.y) / 2;

  camera.left = midX - wide / 2;
  camera.right = midX + wide / 2;
  camera.top = midY + tall / 2;
  camera.bottom = midY - tall / 2;
  camera.updateProjectionMatrix();

  const reach = bounds.getSize(new THREE.Vector3()).length() / 2;
  sun.shadow.camera.left = sun.shadow.camera.bottom = -reach;
  sun.shadow.camera.right = sun.shadow.camera.top = reach;
  sun.shadow.camera.near = 1;
  sun.shadow.camera.far = reach * 4;
  sun.shadow.camera.updateProjectionMatrix();
  sun.shadow.normalBias = 0.02;
  sun.shadow.bias = -0.0002;
  sun.target.position.copy(centre);
  sun.position
    .copy(centre)
    .add(new THREE.Vector3(...look.sunFrom).normalize().multiplyScalar(reach * 2));
}

// A steep bird's-eye view from the south, so the streets read as a drawing.
camera.position.copy(centre).add(new THREE.Vector3(0.36, 0.95, 1).multiplyScalar(900));
camera.lookAt(centre);
camera.updateMatrixWorld();
frame();
window.addEventListener("resize", frame);

renderer.setAnimationLoop(() => {
  ink.render(scene, camera);
});
