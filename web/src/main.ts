import * as THREE from "three";
import "./style.css";
import { Hud } from "./hud.ts";
import { Keyboard } from "./input.ts";
import { buildCar, PLAYER_COLOUR } from "./assets/cars.ts";
import { Around } from "./render/around.ts";
import { Route } from "./render/route.ts";
import { Traffic } from "./render/traffic.ts";
import { advance, bodyLength, restart, snapshot, start } from "./bend.ts";
import { Ink, light, lookByKey, restyle } from "./render/look.ts";

const VIEW_HEIGHT = 46;
const UP = new THREE.Vector3(0, 1, 0);
const CAMERA_OFFSET = new THREE.Vector3(14, 39, 22);
const LOOK_AHEAD = new THREE.Vector3(0, 0, -11);

const stage = document.querySelector<HTMLDivElement>("#stage");
if (!stage) throw new Error("missing #stage");

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFShadowMap;
stage.append(renderer.domElement);

const ink = new Ink(renderer);
// The look picked in the lab (or ?look=) is the look you drive.
const look = lookByKey(
  new URLSearchParams(location.search).get("look") ?? localStorage.getItem("lajur.look"),
);
ink.setLook(look);

const scene = new THREE.Scene();
scene.fog = new THREE.Fog(look.sky, 90, 220);

const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 1, 600);

function resize(): void {
  const aspect = window.innerWidth / window.innerHeight;
  camera.left = (-VIEW_HEIGHT * aspect) / 2;
  camera.right = (VIEW_HEIGHT * aspect) / 2;
  camera.top = VIEW_HEIGHT / 2;
  camera.bottom = -VIEW_HEIGHT / 2;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  ink.resize();
}
window.addEventListener("resize", resize);
resize();

const hemi = new THREE.HemisphereLight();
scene.add(hemi);

const sun = new THREE.DirectionalLight();
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.camera.left = -42;
sun.shadow.camera.right = 42;
sun.shadow.camera.top = 42;
sun.shadow.camera.bottom = -42;
sun.shadow.camera.near = 1;
sun.shadow.camera.far = 180;
sun.shadow.bias = -0.0006;
sun.shadow.normalBias = 0.05;
scene.add(sun, sun.target);
light(scene, hemi, sun, look);

// The model first: it owns the seed, the road and every rule.
let world = start();
let state = snapshot(world);

const route = new Route(state.seed);
const town = new Around(state.seed);
scene.add(town.group);

const player = buildCar("Sedan", PLAYER_COLOUR, bodyLength("Sedan"));
const traffic = new Traffic(route, player);
scene.add(traffic.group);

const hud = new Hud();
const keyboard = new Keyboard(window);

let heading = 0;
let previous = performance.now();

function follow(dt: number): void {
  // The camera sits behind the car and turns with the road; the angle eases so
  // a bend swings the view instead of snapping it.
  let delta = traffic.heading - heading;
  delta = Math.atan2(Math.sin(delta), Math.cos(delta));
  heading += delta * Math.min(1, dt * 4);

  const offset = CAMERA_OFFSET.clone().applyAxisAngle(UP, -heading);
  camera.position.copy(traffic.position).add(offset);
  const ahead = LOOK_AHEAD.clone().applyAxisAngle(UP, -heading).add(traffic.position);
  camera.lookAt(ahead);

  const sunAt = new THREE.Vector3(...look.sunFrom)
    .normalize()
    .multiplyScalar(58)
    .applyAxisAngle(UP, -heading);
  sun.position.copy(traffic.position).add(sunAt);
  sun.target.position.copy(traffic.position);
}

function step(ms: number): void {
  world = advance(world, ms, keyboard.controls());
  state = snapshot(world);

  traffic.update(state, ms / 1000);
  follow(ms / 1000);
  town.update(traffic.position, route.next(), camera);
  hud.update(state);
}

function frame(now: number): void {
  const elapsed = Math.min(now - previous, 100);
  previous = now;

  if (keyboard.takeRestart()) world = restart(world);
  step(Math.round(elapsed));

  // Chunks stream in with the kit's materials; bring them into the look.
  restyle(scene, look);
  ink.render(scene, camera);
  requestAnimationFrame(frame);
}

requestAnimationFrame(frame);
