import * as THREE from "three";

/**
 * What every asset file shares: the palette, the box cache, and the shelf
 * contract the lab page reads. Each file in this folder that exports a
 * `shelf` shows up in the lab (`/lab.html`) without registering anywhere.
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

export const mats = {
  asphalt: new THREE.MeshStandardMaterial({ color: 0x33343a, roughness: 0.97 }),
  patch: new THREE.MeshStandardMaterial({ color: 0x3b3c43, roughness: 0.97 }),
  paint: new THREE.MeshStandardMaterial({ color: 0xece5d2, roughness: 0.85 }),
  concrete: new THREE.MeshStandardMaterial({ color: 0xb9b2a1, roughness: 0.96 }),
  kerb: new THREE.MeshStandardMaterial({ color: 0xcdc6b2, roughness: 0.95 }),
  walk: new THREE.MeshStandardMaterial({ color: 0xd3cbb4, roughness: 0.95 }),
  ground: new THREE.MeshStandardMaterial({ color: 0x8c946f, roughness: 1 }),
  grass: new THREE.MeshStandardMaterial({ color: 0x71934a, roughness: 1 }),
  glass: new THREE.MeshStandardMaterial({ color: 0x44555e, roughness: 0.35, metalness: 0.1 }),
  roof: new THREE.MeshStandardMaterial({ color: 0x8b8478, roughness: 0.9 }),
  tile: new THREE.MeshStandardMaterial({ color: 0xa65a3f, roughness: 0.9 }),
  tin: new THREE.MeshStandardMaterial({ color: 0x9aa0a2, roughness: 0.85 }),
  rust: new THREE.MeshStandardMaterial({ color: 0x9a6b4f, roughness: 0.95 }),
  wood: new THREE.MeshStandardMaterial({ color: 0x8a6a45, roughness: 0.95 }),
  metal: new THREE.MeshStandardMaterial({ color: 0x6f7378, roughness: 0.8 }),
  trunk: new THREE.MeshStandardMaterial({ color: 0x6a5139, roughness: 1 }),
  leaf: new THREE.MeshStandardMaterial({ color: 0x5f9a3c, roughness: 0.95, flatShading: true }),
  leafDeep: new THREE.MeshStandardMaterial({ color: 0x487a2d, roughness: 0.95, flatShading: true }),
  wire: new THREE.MeshStandardMaterial({ color: 0x2a2b2e, roughness: 0.9 }),
};

// Faded paint and corrugated roofs: the palette of every ruko row.
export const walls = [
  0xd9c7a4, 0xe3d6b6, 0xc9a184, 0xa9b6a5, 0xd8b98d, 0xb98a6a, 0xe0d3bd, 0x9fb3b5, 0xcaa88e,
].map((color) => new THREE.MeshStandardMaterial({ color, roughness: 0.93 }));
export const tarps = [0x2f6fb5, 0xd8543f, 0xe0a63c, 0x3f8f6a, 0xb84b8c].map(
  (color) => new THREE.MeshStandardMaterial({ color, roughness: 0.9, side: THREE.DoubleSide }),
);
export const signs = [0xd23f34, 0x2f7ec4, 0xe0a63c, 0x2f8f5f].map(
  (color) => new THREE.MeshStandardMaterial({ color, roughness: 0.8 }),
);

const boxes = new Map<string, THREE.BoxGeometry>();

export function box(width: number, height: number, depth: number): THREE.BoxGeometry {
  const key = `${width}:${height}:${depth}`;
  const cached = boxes.get(key);
  if (cached) return cached;
  const geometry = new THREE.BoxGeometry(width, height, depth);
  boxes.set(key, geometry);
  return geometry;
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

/** A wheel the lab spins: anything named "wheel" turns about its local x. */
export function wheel(radius: number, width: number, material: THREE.Material): THREE.Mesh {
  const geometry = new THREE.CylinderGeometry(radius, radius, width, 8);
  geometry.rotateZ(Math.PI / 2);
  const mesh = new THREE.Mesh(geometry, material);
  mesh.name = "wheel";
  return mesh;
}
