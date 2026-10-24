import * as THREE from "three";
import "./style.css";
import { Hud } from "./hud.ts";
import { Keyboard } from "./input.ts";
import { buildCar, PLAYER_COLOUR } from "./render/cars.ts";
import { RoadPath } from "./render/path.ts";
import { RoadView } from "./render/road.ts";
import { Traffic } from "./render/traffic.ts";
import { advance, bodyLength, restart, snapshot, start } from "./bend.ts";

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

const scene = new THREE.Scene();
const sky = new THREE.Color(0xb8cdc7);
scene.background = sky;
scene.fog = new THREE.Fog(sky, 90, 220);

const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 1, 600);

function resize(): void {
  const aspect = window.innerWidth / window.innerHeight;
  camera.left = (-VIEW_HEIGHT * aspect) / 2;
  camera.right = (VIEW_HEIGHT * aspect) / 2;
  camera.top = VIEW_HEIGHT / 2;
  camera.bottom = -VIEW_HEIGHT / 2;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}
window.addEventListener("resize", resize);
resize();

scene.add(new THREE.HemisphereLight(0xdcecff, 0x6d6552, 1.35));

const sun = new THREE.DirectionalLight(0xfff0d2, 2.6);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.camera.left = -42;
sun.shadow.camera.right = 42;
sun.shadow.camera.top = 42;
sun.shadow.camera.bottom = -42;
sun.shadow.camera.near = 1;
sun.shadow.camera.far = 180;
sun.shadow.bias = -0.0006;
scene.add(sun, sun.target);

// The model first: it owns the seed, the road and every rule.
let world = start();
let state = snapshot(world);

const path = new RoadPath(state.seed);
const road = new RoadView(path);
scene.add(road.group);

const player = buildCar("Sedan", PLAYER_COLOUR, bodyLength("Sedan"));
const traffic = new Traffic(path, player);
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
  const look = LOOK_AHEAD.clone().applyAxisAngle(UP, -heading).add(traffic.position);
  camera.lookAt(look);

  const sunAt = new THREE.Vector3(-26, 46, 24).applyAxisAngle(UP, -heading);
  sun.position.copy(traffic.position).add(sunAt);
  sun.target.position.copy(traffic.position);
}

function step(ms: number): void {
  world = advance(world, ms, keyboard.controls());
  state = snapshot(world);

  traffic.update(state, ms / 1000);
  road.update(state.index);
  follow(ms / 1000);
  hud.update(state);
}

function frame(now: number): void {
  const elapsed = Math.min(now - previous, 100);
  previous = now;

  if (keyboard.takeRestart()) world = restart(world);
  step(Math.round(elapsed));

  renderer.render(scene, camera);
  requestAnimationFrame(frame);
}

requestAnimationFrame(frame);
