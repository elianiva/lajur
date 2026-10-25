// Draws the lab's world as flat plans, and checks what a plan cannot show:
// that cells agree whatever order they are made in, that no lot crosses into
// another cell's lot, and how full the built land is.
//
//   vp run plan                   the shipped seed and five more
//   vp run plan -- 1 2 3          those seeds
//
// Each seed writes plan-<seed>.svg (4×4 cells) and plan-zoom-<seed>.svg (one
// cell) to $PLAN_OUT, or to lajur-plan in the system temp directory.
import { mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { buildLogic } from "./bend.ts";
import type { Pt } from "../src/world/cells.ts";

// The world's first layers are the model; compile it before reading it.
const built = buildLogic();
if (!built.ok) {
  console.error(built.output);
  process.exit(1);
}
const { cell, hash, node } = await import("../src/world/cells.ts");
const { Grid, ROAD, area, bbox, inPoly, parcels, pointSeg } =
  await import("../src/world/parcels.ts");
const { planSvg } = await import("../src/world/plan.ts");
const { extent, world } = await import("../src/world/world.ts");

const seeds = process.argv.slice(2).map(Number).filter(Number.isFinite);
if (seeds.length === 0) seeds.push(20261024, 2, 5, 11, 17, 23);
const out = process.env.PLAN_OUT ?? join(tmpdir(), "lajur-plan");
mkdirSync(out, { recursive: true });
const N = 4;

const rows: Record<string, string | number | boolean>[] = [];
let failed = false;
for (const seed of seeds) {
  const t0 = performance.now();
  const w = world(seed, 0, 0, N, N);
  const ms = (performance.now() - t0) / (N * N);

  // Order-free: the same cells, made one by one in a shuffled order.
  const order = [...w.cells.keys()].sort((a, b) => hash(seed, 99, a) - hash(seed, 99, b));
  const strip = (k: number, p = parcels(seed, cell(seed, w.cells[k]!.i, w.cells[k]!.j))) =>
    JSON.stringify([p.lots, p.courts, p.trees]);
  const orderFree = order.every((k) => strip(k) === strip(k, w.plans[k]));

  // No lot reaches into a lot of another cell.
  let crossings = 0;
  const all = new Grid<{ poly: Pt[]; k: number }>(30);
  w.plans.forEach((p, k) => p.lots.forEach((o) => all.add({ poly: o.poly, k }, bbox(o.poly))));
  w.plans.forEach((p, k) =>
    p.lots.forEach((o) => {
      for (const n of all.near(bbox(o.poly)))
        if (n.k > k && o.poly.some((q) => inPoly(q, n.poly))) crossings++;
    }),
  );

  // Built land, sampled every 4 m off the carriageway: a lot, a court, under a
  // canopy, or bare. Sawah is not built land.
  const fill = { lot: 0, court: 0, canopy: 0, bare: 0 };
  const lots = new Grid<Pt[]>(30);
  const courts = new Grid<Pt[]>(30);
  const crowns = new Grid<{ x: number; z: number; r: number }>(30);
  const roads = new Grid<{ a: Pt; b: Pt; kind: number }>(30);
  for (const p of w.plans) {
    for (const o of p.lots) lots.add(o.poly, bbox(o.poly));
    for (const o of p.courts) courts.add(o.poly, bbox(o.poly));
    for (const t of p.trees) crowns.add(t, [t.x - t.r, t.z - t.r, t.x + t.r, t.z + t.r]);
  }
  for (const l of w.lines)
    for (let k = 0; k + 1 < l.pts.length; k++) {
      const s = { a: l.pts[k]!, b: l.pts[k + 1]!, kind: l.river ? 0 : l.kind };
      roads.add(s, bbox([s.a, s.b], 15));
    }
  const land: Record<string, number> = {};
  for (const p of w.plans)
    for (const { b, poly, box } of p.blocks) {
      land[b.type] = (land[b.type] ?? 0) + area(poly);
      if (b.type === "sawah") continue;
      for (let x = box[0]; x < box[2]; x += 4)
        for (let z = box[1]; z < box[3]; z += 4) {
          const q = { x, z };
          if (!inPoly(q, poly)) continue;
          const at: [number, number, number, number] = [x, z, x, z];
          if ([...roads.near(at)].some((s) => pointSeg(q, s.a, s.b) < ROAD[s.kind]!)) continue;
          if ([...lots.near(at)].some((o) => inPoly(q, o))) fill.lot++;
          else if ([...courts.near(at)].some((o) => inPoly(q, o))) fill.court++;
          else if ([...crowns.near(at)].some((t) => Math.hypot(t.x - x, t.z - z) < t.r))
            fill.canopy++;
          else fill.bare++;
        }
    }
  const total = fill.lot + fill.court + fill.canopy + fill.bare;
  const pct = (v: number) => `${Math.round((100 * v) / total)}%`;
  const landTotal = Object.values(land).reduce((a, b) => a + b, 0);
  const row = {
    seed,
    "ms/cell": ms.toFixed(0),
    "order-free": orderFree,
    "lot crossings": crossings,
    lots: w.plans.reduce((s, p) => s + p.lots.length, 0),
    trees: w.plans.reduce((s, p) => s + p.trees.length, 0),
    "built land": `lot ${pct(fill.lot)} court ${pct(fill.court)} canopy ${pct(fill.canopy)} bare ${pct(fill.bare)}`,
    land: Object.entries(land)
      .sort((a, b) => b[1] - a[1])
      .map(([k, v]) => `${k} ${Math.round((100 * v) / landTotal)}%`)
      .join(" "),
  };
  rows.push(row);
  if (!orderFree || crossings > 0) failed = true;

  const label = `seed ${seed} · ${row.lots} lots · ${row.trees} trees · built land: ${row["built land"]}`;
  writeFileSync(
    join(out, `plan-${seed}.svg`),
    planSvg(w, extent(w), { px: 1300, legend: true, label }),
  );
  const a = node(seed, 1, 1);
  const b = node(seed, 2, 2);
  writeFileSync(
    join(out, `plan-zoom-${seed}.svg`),
    planSvg(w, [a.x - 30, a.z - 30, b.x + 30, b.z + 30], { px: 1300, legend: true, label }),
  );
}
console.table(rows);
console.log(`SVGs in ${out}`);
if (failed) process.exitCode = 1;
