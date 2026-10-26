import * as THREE from "three";
import { shelf as homes } from "../assets/buildings.ts";
import { shelf as civic } from "../assets/civic.ts";
import { bake, mats } from "../assets/kit.ts";
import { shelf as trees } from "../assets/trees.ts";
import { ART, COL, LOK, hash, type Line, type Pt } from "../world/cells.ts";
import { ROAD } from "../world/parcels.ts";
import type { Drawn } from "../world/world.ts";

/**
 * The generated world in three dimensions, in two levels of detail.
 *
 * A town holds pieces, each one window of cells. Far: every lot of a piece is
 * a box and every tree a ball, all in one BatchedMesh. Near: the 120 m tiles
 * in view swap their boxes for the shelf's real assets, baked per material
 * into one BatchedMesh each that every piece shares, so draw calls follow the
 * number of materials and not the number of lots. Everything is drawn with the
 * kit's materials, so a look restyles it like any other mesh.
 */

const TILE = 120;
/** Height of the painted lines above the ground. */
const PAINT_Y = 0.15;

type Part = { material: THREE.Material; geometry: THREE.BufferGeometry };
type Variant = { parts: Part[]; size: THREE.Vector3; top: THREE.Material };

/** The shelf asset each lot use, court and tree is drawn with. */
const ASSET: Record<string, string> = {
  rumah: "Rumah",
  petak: "Rumah petak",
  kos: "Kos",
  warung: "Warung",
  ruko: "Ruko",
  minimarket: "Minimarket",
  bengkel: "Bengkel",
  gudang: "Gudang",
  kantor: "Kantor",
  apartemen: "Apartemen",
  rusun: "Rusun",
  mal: "Mal",
  masjid: "Masjid",
  gereja: "Gereja",
  klenteng: "Klenteng",
  sekolah: "Sekolah",
  puskesmas: "Puskesmas",
  spbu: "SPBU",
  pasar: "Pasar",
  pendopo: "Pendopo",
  lapangan: "Lapangan",
  mangga: "Mangga",
  beringin: "Beringin",
  flamboyan: "Flamboyan",
  bambu: "Bambu",
};

/** Each use, baked in a few variants, centred on its footprint, base at y = 0. */
function library(): Map<string, Variant[]> {
  const assets = new Map(
    [...homes.assets, ...civic.assets, ...trees.assets].map((a) => [a.name, a]),
  );
  const out = new Map<string, Variant[]>();
  for (const [use, name] of Object.entries(ASSET)) {
    const asset = assets.get(name);
    if (!asset) continue;
    out.set(
      use,
      [0.13, 0.47, 0.81].map((seed) => {
        const baked = bake(asset.build(seed));
        const box = new THREE.Box3().setFromObject(baked);
        const centre = box.getCenter(new THREE.Vector3());
        let top: THREE.Material = mats.roof;
        let height = -Infinity;
        const parts: Part[] = [];
        for (const mesh of baked.children as THREE.Mesh[]) {
          mesh.geometry.translate(-centre.x, -box.min.y, -centre.z);
          mesh.geometry.computeBoundingBox();
          const material = mesh.material as THREE.Material;
          // The far box wears the colour seen from above: the highest part.
          if (mesh.geometry.boundingBox!.max.y > height) {
            height = mesh.geometry.boundingBox!.max.y;
            top = material;
          }
          parts.push({ material, geometry: mesh.geometry });
        }
        return { parts, size: box.getSize(new THREE.Vector3()), top };
      }),
    );
  }
  return out;
}

/** One BatchedMesh per material; its geometries are the variants' parts. */
class Batch {
  mesh: THREE.BatchedMesh;
  private ids = new Map<THREE.BufferGeometry, number>();
  constructor(material: THREE.Material, geometries: THREE.BufferGeometry[], capacity: number) {
    const vertices = geometries.reduce((s, g) => s + g.getAttribute("position").count, 0);
    this.mesh = new THREE.BatchedMesh(capacity, vertices, vertices * 2, material);
    this.mesh.sortObjects = false;
    // Culled per object instead: the batch spans the whole window.
    this.mesh.frustumCulled = false;
    this.mesh.castShadow = true;
    this.mesh.receiveShadow = true;
    for (const g of geometries) this.ids.set(g, this.mesh.addGeometry(g));
  }
  add(geometry: THREE.BufferGeometry, matrix: THREE.Matrix4): number {
    const m = this.mesh;
    if (m.instanceCount >= m.maxInstanceCount) m.setInstanceCount(m.maxInstanceCount * 2);
    const id = m.addInstance(this.ids.get(geometry)!);
    m.setMatrixAt(id, matrix);
    return id;
  }
}

/** Flat ground, one mesh per kit material, so a look can restyle each. */
class Ground {
  private buckets = new Map<THREE.Material, number[]>();
  private push(material: THREE.Material, xs: number[]) {
    let bucket = this.buckets.get(material);
    if (!bucket) this.buckets.set(material, (bucket = []));
    bucket.push(...xs);
  }
  area(poly: Pt[], material: THREE.Material, y: number) {
    const pts = poly.map((p) => new THREE.Vector2(p.x, p.z));
    const xs: number[] = [];
    for (const [a, b, c] of THREE.ShapeUtils.triangulateShape(pts, []))
      for (const k of [a!, c!, b!]) xs.push(pts[k]!.x, y, pts[k]!.y);
    this.push(material, xs);
  }
  ribbon(pts: Pt[], half: number, material: THREE.Material, y: number) {
    const xs: number[] = [];
    for (let k = 0; k + 1 < pts.length; k++) {
      const a = pts[k]!;
      const b = pts[k + 1]!;
      const dx = b.x - a.x;
      const dz = b.z - a.z;
      const l = Math.hypot(dx, dz) || 1;
      const nx = (-dz / l) * half;
      const nz = (dx / l) * half;
      // Each piece overlaps the next a little, so bends have no cracks.
      const ex = (dx / l) * half * 0.5;
      const ez = (dz / l) * half * 0.5;
      const q = [
        [a.x - ex + nx, a.z - ez + nz],
        [a.x - ex - nx, a.z - ez - nz],
        [b.x + ex - nx, b.z + ez - nz],
        [b.x + ex + nx, b.z + ez + nz],
      ];
      for (const m of [0, 2, 1, 0, 3, 2]) xs.push(q[m]![0]!, y, q[m]![1]!);
    }
    this.push(material, xs);
  }
  meshes(): THREE.Mesh[] {
    return [...this.buckets].map(([material, xs]) => {
      const g = new THREE.BufferGeometry();
      g.setAttribute("position", new THREE.Float32BufferAttribute(xs, 3));
      g.computeVertexNormals();
      const mesh = new THREE.Mesh(g, material);
      mesh.receiveShadow = true;
      return mesh;
    });
  }
}

// ---- Painted lines ---------------------------------------------------------------

/** The line `d` metres to the side of a polyline. */
function offset(pts: Pt[], d: number): Pt[] {
  return pts.map((p, k) => {
    const a = pts[Math.max(0, k - 1)]!;
    const b = pts[Math.min(pts.length - 1, k + 1)]!;
    const l = Math.hypot(b.x - a.x, b.z - a.z) || 1;
    return { x: p.x - ((b.z - a.z) / l) * d, z: p.z + ((b.x - a.x) / l) * d };
  });
}

/** The stretches of a polyline from `from` metres to `to`, `on` metres in every `period`. */
function stretches(pts: Pt[], from: number, to: number, on: number, period: number): Pt[][] {
  const out: Pt[][] = [];
  let run: Pt[] = [];
  let s = 0;
  const inside = (at: number) => at >= from && at <= to && (at - from) % period < on;
  for (let k = 0; k + 1 < pts.length; k++) {
    const a = pts[k]!;
    const b = pts[k + 1]!;
    const l = Math.hypot(b.x - a.x, b.z - a.z);
    for (let t = 0; t < l; t += 0.5) {
      const p = { x: a.x + ((b.x - a.x) * t) / l, z: a.z + ((b.z - a.z) * t) / l };
      if (inside(s + t)) run.push(p);
      else if (run.length) {
        if (run.length > 1) out.push(run);
        run = [];
      }
    }
    s += l;
  }
  if (run.length > 1) out.push(run);
  return out;
}

function length(pts: Pt[]): number {
  let s = 0;
  for (let k = 1; k < pts.length; k++)
    s += Math.hypot(pts[k]!.x - pts[k - 1]!.x, pts[k]!.z - pts[k - 1]!.z);
  return s;
}

/**
 * The markings of a main road: an arterial has a dashed centre line, a dashed
 * line between its two lanes each way and solid edges; a collector has one
 * lane each way, so a dashed centre and its edges. Every main road ends at a
 * crossing, so the paint stops short of both ends.
 */
function paint(ground: Ground, line: Line) {
  if (!(line.seg || line.cut) || (line.kind !== ART && line.kind !== COL)) return;
  const half = ROAD[line.kind]!;
  const cut = half + 3;
  const to = length(line.pts) - cut;
  const lines: [number, number, number][] = [
    [0, 3, 9],
    [half - 0.45, 1, 1],
    [-(half - 0.45), 1, 1],
  ];
  if (line.kind === ART) lines.push([3.25, 3, 9], [-3.25, 3, 9]);
  for (const [d, on, period] of lines)
    for (const run of stretches(d ? offset(line.pts, d) : line.pts, cut, to, on, period))
      ground.ribbon(run, 0.08, mats.paint, PAINT_Y);
}

const BLOCK_GROUND: Record<string, THREE.Material> = {
  sawah: mats.field,
  kebun: mats.ground,
  tree: mats.walk,
  comb: mats.walk,
  ring: mats.walk,
  grid: mats.paving,
  shops: mats.paving,
};
const COURT_GROUND: Record<string, THREE.Material> = {
  alun: mats.walk,
  lapangan: mats.grass,
  pasar: mats.paving,
  sekolah: mats.concrete,
  gudang: mats.concrete,
  masjid: mats.kerb,
  pendopo: mats.kerb,
};
const ROAD_MATERIAL: Record<number, THREE.Material> = {
  [ART]: mats.asphalt,
  [COL]: mats.asphalt,
  [LOK]: mats.concrete,
};

/** The height of a road's surface, by class: a main road lies over a lokal street. */
export const roadY = (kind: number) => 0.14 - kind * 0.01;

// ---- One window of cells ----------------------------------------------------------

type Placed = [Batch, number][];
type Item = { farId: number; place: () => Placed };
type Tile = { box: THREE.Box3; items: Item[]; loaded: Placed | null; seen: number };

class Piece {
  readonly group = new THREE.Group();
  private far: Batch;
  private farTop: THREE.Material[] = [];
  private tiles = new Map<string, Tile>();
  private styledAs: unknown = null;

  private town: Town;

  constructor(town: Town, d: Drawn) {
    this.town = town;
    const kinds = town.kinds;
    // ---- Ground ----------------------------------------------------------------
    const ground = new Ground();
    for (const plan of d.plans) {
      for (const { b, poly } of plan.blocks)
        ground.area(poly, BLOCK_GROUND[b.type] ?? mats.walk, 0);
      for (const c of plan.courts) ground.area(c.poly, COURT_GROUND[c.use] ?? mats.walk, 0.04);
    }
    for (const bank of d.banks) ground.area(bank, mats.grass, 0);
    for (const l of d.lines) if (l.river) ground.ribbon(l.pts, ROAD[0]!, mats.water, 0.06);
    for (const kind of [LOK, COL, ART])
      for (const l of d.lines)
        if (l.kind === kind && !l.river)
          ground.ribbon(l.pts, ROAD[kind]!, ROAD_MATERIAL[kind]!, roadY(kind));
    for (const l of d.lines) paint(ground, l);
    this.group.add(...ground.meshes());

    // ---- The far level of detail ----------------------------------------------------
    const capacity = d.plans.reduce(
      (s, p) => s + p.lots.length + p.courts.length + p.trees.length,
      16,
    );
    this.far = new Batch(town.farBase, [town.boxG, town.ballG], capacity);
    this.group.add(this.far.mesh);

    // ---- Placement ---------------------------------------------------------------
    const seed = d.seed;
    const roll3 = (x: number, z: number, salt: number) =>
      hash(seed, 300 + salt, Math.round(x * 10), Math.round(z * 10));
    const near = town.near;
    const realAt = (v: Variant, m: THREE.Matrix4) => () =>
      v.parts.map((p): [Batch, number] => [
        near.get(p.material)!,
        near.get(p.material)!.add(p.geometry, m),
      ]);
    const X = new THREE.Vector3();
    const Y = new THREE.Vector3(0, 1, 0);
    const Z = new THREE.Vector3();
    const scale = new THREE.Matrix4();
    const addFar = (geometry: THREE.BufferGeometry, matrix: THREE.Matrix4, top: THREE.Material) => {
      const id = this.far.add(geometry, matrix);
      this.farTop[id] = top;
      return id;
    };

    // A footprint whose edge a→b faces the street and whose edge d→c runs back
    // from it. The street side of every asset is its local +x.
    const building = (use: string, poly: Pt[], a: Pt, b: Pt, dd: Pt, c: Pt) => {
      const variants = kinds.get(use);
      if (!variants) return;
      const cx = poly.reduce((s, p) => s + p.x, 0) / poly.length;
      const cz = poly.reduce((s, p) => s + p.z, 0) / poly.length;
      const width = Math.hypot(b.x - a.x, b.z - a.z);
      const depth = Math.hypot(c.x - dd.x, c.z - dd.z);
      X.set(-(c.x - dd.x) / depth, 0, -(c.z - dd.z) / depth);
      Z.crossVectors(X, Y);
      const basis = new THREE.Matrix4().makeBasis(X, Y, Z).setPosition(cx, 0, cz);
      const v = variants[Math.floor(roll3(cx, cz, 1) * variants.length)]!;
      const s = Math.min(depth / v.size.x, width / v.size.z);
      const real = basis
        .clone()
        .multiply(
          scale.makeScale(
            Math.min(depth / v.size.x, s * 1.3),
            s,
            Math.min(width / v.size.z, s * 1.3),
          ),
        );
      const box = basis
        .clone()
        .multiply(scale.makeScale(depth * 0.92, Math.max(1, v.size.y * s), width * 0.92));
      this.tileOf(cx, cz).items.push({
        farId: addFar(town.boxG, box, v.top),
        place: realAt(v, real),
      });
    };
    for (const plan of d.plans) {
      for (const lot of plan.lots) {
        const [a, b, c] = lot.poly as [Pt, Pt, Pt];
        building(lot.use, lot.poly, a, b, b, c);
      }
      // Courts are frame rectangles of 8 points a side; a yard holds no building.
      for (const court of plan.courts) {
        if (court.yard) continue;
        const p = court.poly;
        building(court.use, p, p[0]!, p[8]!, p[8]!, p[16]!);
      }
      for (const t of plan.trees) {
        const variants = kinds.get(t.sp)!;
        const v = variants[Math.floor(roll3(t.x, t.z, 2) * variants.length)]!;
        const s = t.r / (Math.max(v.size.x, v.size.z) / 2);
        const real = new THREE.Matrix4()
          .makeRotationY(roll3(t.x, t.z, 3) * Math.PI * 2)
          .setPosition(t.x, 0, t.z)
          .multiply(scale.makeScale(s, s, s));
        const ball = new THREE.Matrix4()
          .makeTranslation(t.x, v.size.y * s - t.r * 0.9, t.z)
          .multiply(scale.makeScale(t.r, t.r * 0.9, t.r));
        this.tileOf(t.x, t.z).items.push({
          farId: addFar(town.ballG, ball, v.top),
          place: realAt(v, real),
        });
      }
    }
  }

  private tileOf(x: number, z: number): Tile {
    const a = Math.floor(x / TILE);
    const b = Math.floor(z / TILE);
    const key = `${a},${b}`;
    let t = this.tiles.get(key);
    if (!t) {
      const box = new THREE.Box3(
        new THREE.Vector3(a * TILE - 20, 0, b * TILE - 20),
        new THREE.Vector3((a + 1) * TILE + 20, 45, (b + 1) * TILE + 20),
      );
      this.tiles.set(key, (t = { box, items: [], loaded: null, seen: 0 }));
    }
    return t;
  }

  // A look restyles each batch's material; the far boxes copy the colours it
  // chose, and the far material itself stays white so it does not tint twice.
  private recolour() {
    const colour = new THREE.Color();
    const material = this.far.mesh.material as THREE.MeshStandardMaterial;
    material.color.set(0xffffff);
    for (let id = 0; id < this.farTop.length; id++) {
      const batch = this.town.near.get(this.farTop[id]!);
      const styled = (batch?.mesh.material ?? this.farTop[id]) as THREE.MeshStandardMaterial;
      this.far.mesh.setColorAt(id, colour.copy(styled.color));
    }
  }

  update(frustum: THREE.Frustum, close: boolean, frameNo: number, budget: number) {
    if (this.far.mesh.userData.look !== this.styledAs) {
      this.styledAs = this.far.mesh.userData.look;
      this.recolour();
    }
    // Zoomed out, every object is in view: skip the per-object test.
    this.far.mesh.perObjectFrustumCulled = close;
    for (const t of this.tiles.values()) {
      const want = close && frustum.intersectsBox(t.box);
      if (want) t.seen = frameNo;
      if (want && !t.loaded && performance.now() < budget) {
        t.loaded = t.items.flatMap((it) => {
          this.far.mesh.setVisibleAt(it.farId, false);
          return it.place();
        });
      } else if (t.loaded && frameNo - t.seen > 30) {
        // Out of view for half a second: drop the real assets, show the boxes.
        this.unload(t);
      }
    }
  }

  private unload(t: Tile) {
    for (const [b, id] of t.loaded!) b.mesh.deleteInstance(id);
    for (const it of t.items) this.far.mesh.setVisibleAt(it.farId, true);
    t.loaded = null;
  }

  dispose() {
    for (const t of this.tiles.values()) if (t.loaded) this.unload(t);
    this.group.removeFromParent();
    this.group.traverse((node) => {
      if (node instanceof THREE.BatchedMesh) node.dispose();
      else if (node instanceof THREE.Mesh) node.geometry.dispose();
    });
  }
}

let shared: Map<string, Variant[]> | null = null;

/** Every piece of the world on screen, and the batches their near assets share. */
export class Town {
  readonly group = new THREE.Group();
  readonly kinds: Map<string, Variant[]>;
  readonly near = new Map<THREE.Material, Batch>();
  readonly boxG = new THREE.BoxGeometry(1, 1, 1).translate(0, 0.5, 0).toNonIndexed();
  readonly ballG = new THREE.IcosahedronGeometry(1, 0);
  /** White, so each far instance shows the colour of the material it stands for. */
  readonly farBase = new THREE.MeshStandardMaterial({ roughness: 0.9, flatShading: true });
  private pieces = new Map<string, Piece>();
  private frustum = new THREE.Frustum();
  private pv = new THREE.Matrix4();
  private frameNo = 0;

  constructor() {
    this.kinds = shared ??= library();
    this.farBase.name = "far";
    const byMaterial = new Map<THREE.Material, Set<THREE.BufferGeometry>>();
    for (const variants of this.kinds.values())
      for (const v of variants)
        for (const p of v.parts) {
          if (!byMaterial.has(p.material)) byMaterial.set(p.material, new Set());
          byMaterial.get(p.material)!.add(p.geometry);
        }
    for (const [m, gs] of byMaterial) {
      const batch = new Batch(m, [...gs], 256);
      this.near.set(m, batch);
      this.group.add(batch.mesh);
    }
  }

  has(key: string): boolean {
    return this.pieces.has(key);
  }

  keys(): string[] {
    return [...this.pieces.keys()];
  }

  add(key: string, d: Drawn): void {
    const piece = new Piece(this, d);
    this.pieces.set(key, piece);
    this.group.add(piece.group);
  }

  remove(key: string): void {
    this.pieces.get(key)?.dispose();
    this.pieces.delete(key);
  }

  /** Swaps boxes for real assets in the tiles in view, a few milliseconds' worth a frame. */
  update(camera: THREE.Camera, close: boolean): void {
    this.frameNo++;
    camera.updateMatrixWorld();
    this.pv.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
    this.frustum.setFromProjectionMatrix(this.pv);
    const budget = performance.now() + 6;
    for (const piece of this.pieces.values())
      piece.update(this.frustum, close, this.frameNo, budget);
  }
}
