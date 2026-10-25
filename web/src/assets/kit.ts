import * as THREE from "three";
import { mergeGeometries } from "three/addons/utils/BufferGeometryUtils.js";

/**
 * What every asset file shares: the palette, the geometry caches, and the
 * shelf contract the lab page reads. Each file in this folder that exports a
 * `shelf` shows up in the lab (`/lab.html`) without registering anywhere.
 *
 * Every material carries a role in its `name` ("glass", "glow", "lamp", ...)
 * so a look (`src/render/look.ts`) can restyle the whole set: toon bands,
 * ink, lit windows at night.
 */

export interface Asset {
  name: string;
  /** One instance. `seed` in [0, 1) picks the variant. */
  build(seed: number): THREE.Object3D;
}

export interface Shelf {
  title: string;
  assets: Asset[];
}

function mat(role: string, color: number, extra: THREE.MeshStandardMaterialParameters = {}) {
  const material = new THREE.MeshStandardMaterial({ color, roughness: 0.9, ...extra });
  material.name = role;
  return material;
}

export const mats = {
  asphalt: mat("asphalt", 0x4b4f5c, { roughness: 0.97 }),
  patch: mat("asphalt", 0x555a68, { roughness: 0.97 }),
  paint: mat("paint", 0xfbf8ef, { roughness: 0.8 }),
  yellow: mat("paint", 0xffc93c, { roughness: 0.8 }),
  concrete: mat("concrete", 0xd2cbbb, { roughness: 0.96 }),
  kerb: mat("concrete", 0xe9e1cc, { roughness: 0.95 }),
  walk: mat("walk", 0xeedfbf, { roughness: 0.95 }),
  paving: mat("walk", 0xd9b48c, { roughness: 0.95 }),
  ground: mat("ground", 0x9fcf6a, { roughness: 1 }),
  dirt: mat("ground", 0xd8b27a, { roughness: 1 }),
  plinth: mat("plinth", 0xdec6a2, { roughness: 1 }),
  grass: mat("grass", 0x7cc957, { roughness: 1 }),
  field: mat("grass", 0x5fbf4f, { roughness: 1 }),
  water: mat("water", 0x48c6e8, { roughness: 0.3, metalness: 0.05 }),
  glass: mat("glass", 0x3f6f8c, { roughness: 0.3, metalness: 0.1 }),
  glow: mat("glow", 0x3f6f8c, { roughness: 0.3, metalness: 0.1 }),
  mirror: mat("glow", 0x7fc4e6, { roughness: 0.2, metalness: 0.2 }),
  curtain: mat("glass", 0x6fb6e0, { roughness: 0.2, metalness: 0.25 }),
  lamp: mat("lamp", 0xfff3c2, { emissive: 0x2a2410, roughness: 0.5 }),
  roof: mat("roof", 0x8e97a3, { roughness: 0.9 }),
  tile: mat("roof", 0xe46f3c, { roughness: 0.9 }),
  tileDark: mat("roof", 0xb9473a, { roughness: 0.9 }),
  tin: mat("roof", 0xc3ced4, { roughness: 0.85 }),
  spandek: mat("roof", 0x3f8fd6, { roughness: 0.85 }),
  greenRoof: mat("roof", 0x3fae74, { roughness: 0.85 }),
  rust: mat("rust", 0xc1784f, { roughness: 0.95 }),
  wood: mat("wood", 0xa8743f, { roughness: 0.95 }),
  woodDark: mat("wood", 0x6e4527, { roughness: 0.95 }),
  metal: mat("metal", 0x7d848c, { roughness: 0.7 }),
  steel: mat("metal", 0xb9c2c9, { roughness: 0.6 }),
  trunk: mat("trunk", 0x8a5a3a, { roughness: 1 }),
  leaf: mat("leaf", 0x5fc248, { roughness: 0.95, flatShading: true }),
  leafDeep: mat("leaf", 0x2f9a4a, { roughness: 0.95, flatShading: true }),
  leafLight: mat("leaf", 0x9ad94e, { roughness: 0.95, flatShading: true }),
  wire: mat("wire", 0x2a2b33, { roughness: 0.9 }),
  white: mat("wall", 0xfbf6ea, { roughness: 0.9 }),
  red: mat("accent", 0xe8382f, { roughness: 0.8 }),
  green: mat("accent", 0x23a35a, { roughness: 0.8 }),
  gold: mat("accent", 0xf2c230, { roughness: 0.5, metalness: 0.3 }),
  black: mat("accent", 0x2c2d36, { roughness: 0.8 }),
  rubber: mat("wire", 0x26272e, { roughness: 0.95, flatShading: true }),
  skin: mat("skin", 0xc98d5f, { roughness: 0.9 }),
  skinDark: mat("skin", 0x8f5a37, { roughness: 0.9 }),
  hair: mat("hair", 0x22201f, { roughness: 0.9 }),
};

// Kampung warna-warni: the painted houses of Jodipan, the ruko rows of every
// kota. Bright on purpose; a look can mute them.
export const walls = [
  0xffe08a, 0x9fe3c8, 0xffb08a, 0x9fd0ff, 0xffb3cc, 0xd5ec86, 0xcdb8ff, 0xfbf3e2, 0xf6a76b,
  0x6fd6cc, 0xfff1b8, 0xe9f5f0,
].map((color) => mat("wall", color, { roughness: 0.93 }));
export const tarps = [0x2f7fe0, 0xec4a3c, 0xf4b42e, 0x2fae6a, 0xd2489a, 0x21b5c9].map((color) =>
  mat("tarp", color, { roughness: 0.9, side: THREE.DoubleSide }),
);
export const signs = [0xe8382f, 0x2f7fe0, 0xf4b42e, 0x23a35a, 0x8a4fd8, 0xff7a2f].map((color) =>
  mat("accent", color, { roughness: 0.8 }),
);
export const roofs = [mats.tile, mats.tile, mats.tileDark, mats.tin, mats.spandek, mats.greenRoof];

export function pick<T>(list: readonly T[], seed: number, salt = 1): T {
  return list[Math.floor(Math.abs(seed * 9973 * salt)) % list.length]!;
}

// --- text boards --------------------------------------------------------------

const boards = new Map<string, THREE.MeshStandardMaterial>();

/**
 * A painted board with a word on it: WARUNG, BAKSO, APOTEK. The texture maps
 * onto a box's +x face (the street side of every building).
 */
export function board(text: string, background = "#e8382f", ink = "#fffdf2"): THREE.Material {
  const key = `${text}|${background}|${ink}`;
  const cached = boards.get(key);
  if (cached) return cached;
  const canvas = document.createElement("canvas");
  canvas.width = 256;
  canvas.height = 64;
  const context = canvas.getContext("2d")!;
  context.fillStyle = background;
  context.fillRect(0, 0, 256, 64);
  context.fillStyle = ink;
  context.font = `900 ${text.length > 9 ? 30 : 40}px "Arial Black", Impact, system-ui, sans-serif`;
  context.textAlign = "center";
  context.textBaseline = "middle";
  context.fillText(text, 128, 35, 240);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  const material = mat("board", 0xffffff, { map: texture, roughness: 0.8 });
  boards.set(key, material);
  return material;
}

// --- geometry -----------------------------------------------------------------

const geometries = new Map<string, THREE.BufferGeometry>();

function cached(key: string, make: () => THREE.BufferGeometry): THREE.BufferGeometry {
  const found = geometries.get(key);
  if (found) return found;
  const geometry = make();
  geometries.set(key, geometry);
  return geometry;
}

export function box(width: number, height: number, depth: number): THREE.BufferGeometry {
  return cached(`b${width}:${height}:${depth}`, () => new THREE.BoxGeometry(width, height, depth));
}

export function piece(
  parent: THREE.Object3D,
  size: [number, number, number],
  material: THREE.Material,
  at: [number, number, number],
): THREE.Mesh {
  const mesh = new THREE.Mesh(box(...size), material);
  mesh.position.set(...at);
  parent.add(mesh);
  return mesh;
}

/** An upright cylinder (or cone, when the radii differ) standing at `at`. */
export function cyl(
  parent: THREE.Object3D,
  top: number,
  bottom: number,
  height: number,
  material: THREE.Material,
  at: [number, number, number],
  sides = 8,
): THREE.Mesh {
  const geometry = cached(
    `c${top}:${bottom}:${height}:${sides}`,
    () => new THREE.CylinderGeometry(top, bottom, height, sides),
  );
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(...at);
  parent.add(mesh);
  return mesh;
}

/** A low-poly ball: canopies, domes, heads. */
export function ball(
  parent: THREE.Object3D,
  radius: number,
  material: THREE.Material,
  at: [number, number, number],
  detail = 0,
): THREE.Mesh {
  const geometry = cached(
    `s${radius}:${detail}`,
    () => new THREE.IcosahedronGeometry(radius, detail),
  );
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(...at);
  parent.add(mesh);
  return mesh;
}

/** A half sphere sitting on y = 0: a mosque dome. */
export function dome(
  parent: THREE.Object3D,
  radius: number,
  material: THREE.Material,
  at: [number, number, number],
) {
  const geometry = cached(
    `d${radius}`,
    () => new THREE.SphereGeometry(radius, 12, 6, 0, Math.PI * 2, 0, Math.PI / 2),
  );
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(...at);
  parent.add(mesh);
  return mesh;
}

/**
 * A pitched roof over a `depth` (x) by `width` (z) plan, `height` tall at the
 * ridge, base at y = 0. Hipped (limasan) slopes on all four sides; otherwise a
 * gable (kampung) with upright ends. Flat-shaded faces, so ink finds every
 * crease.
 */
export function roofGeometry(depth: number, width: number, height: number, hipped: boolean) {
  return cached(`r${depth}:${width}:${height}:${hipped}`, () => {
    const hx = depth / 2;
    const hz = width / 2;
    const ridge = hipped ? Math.max(0, hz - hx) : hz;
    const a = [-hx, 0, -hz];
    const b = [hx, 0, -hz];
    const c = [hx, 0, hz];
    const d = [-hx, 0, hz];
    const r0 = [0, height, -ridge];
    const r1 = [0, height, ridge];
    const faces = [
      [b, c, r1, r0], // front slope (+x)
      [d, a, r0, r1], // back slope (-x)
      [a, b, r0], // end at -z
      [c, d, r1], // end at +z
      [a, d, c, b], // soffit
    ];
    const position: number[] = [];
    const index: number[] = [];
    for (const face of faces) {
      const start = position.length / 3;
      for (const vertex of face) position.push(...vertex);
      // Faces are listed clockwise seen from outside; wind them back to front.
      for (let k = 1; k + 1 < face.length; k += 1) index.push(start, start + k + 1, start + k);
    }
    let geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.Float32BufferAttribute(position, 3));
    geometry.setIndex(index);
    geometry = geometry.toNonIndexed();
    geometry.computeVertexNormals();
    return geometry;
  });
}

export function roof(
  parent: THREE.Object3D,
  depth: number,
  width: number,
  height: number,
  hipped: boolean,
  material: THREE.Material,
  at: [number, number, number],
): THREE.Mesh {
  const mesh = new THREE.Mesh(roofGeometry(depth, width, height, hipped), material);
  mesh.position.set(...at);
  parent.add(mesh);
  return mesh;
}

/** A wheel the lab spins: anything named "wheel" turns about its local x. */
export function wheel(radius: number, width: number, material: THREE.Material): THREE.Mesh {
  const geometry = cached(`w${radius}:${width}`, () => {
    const made = new THREE.CylinderGeometry(radius, radius, width, 10);
    made.rotateZ(Math.PI / 2);
    return made;
  });
  const mesh = new THREE.Mesh(geometry, material);
  mesh.name = "wheel";
  return mesh;
}

/** A thin box from `from` to `to`: wires, rails, bunting strings. */
export function span(
  parent: THREE.Object3D,
  from: THREE.Vector3,
  to: THREE.Vector3,
  thickness: number,
  material: THREE.Material,
): THREE.Mesh {
  const mesh = new THREE.Mesh(
    new THREE.BoxGeometry(thickness, thickness, from.distanceTo(to)),
    material,
  );
  mesh.position.copy(from).lerp(to, 0.5);
  mesh.lookAt(to);
  parent.add(mesh);
  return mesh;
}

// --- baking -------------------------------------------------------------------

/**
 * Merges a group's meshes into one mesh per material. A busy street is a
 * thousand little boxes; without this the draw calls, not the geometry, are
 * what the frame time goes to.
 */
export function bake(group: THREE.Object3D, shadows = true): THREE.Group {
  group.updateMatrixWorld(true);
  const buckets = new Map<THREE.Material, THREE.BufferGeometry[]>();

  group.traverse((node) => {
    if (!(node instanceof THREE.Mesh)) return;
    const material = node.material as THREE.Material & { map?: THREE.Texture | null };
    const geometry = node.geometry.index ? node.geometry.toNonIndexed() : node.geometry.clone();
    geometry.applyMatrix4(node.matrixWorld);
    // Merging demands one attribute set per bucket: position and normal, and
    // uv only where a texture reads it.
    for (const name of Object.keys(geometry.attributes)) {
      if (name === "position" || name === "normal") continue;
      if (name === "uv" && material.map) continue;
      geometry.deleteAttribute(name);
    }
    if (!geometry.getAttribute("normal")) geometry.computeVertexNormals();
    const bucket = buckets.get(material) ?? [];
    bucket.push(geometry);
    buckets.set(material, bucket);
  });

  const baked = new THREE.Group();
  for (const [material, list] of buckets) {
    const merged = mergeGeometries(list, false);
    for (const geometry of list) geometry.dispose();
    if (!merged) continue;
    const mesh = new THREE.Mesh(merged, material);
    mesh.castShadow = shadows;
    mesh.receiveShadow = true;
    baked.add(mesh);
  }
  return baked;
}
