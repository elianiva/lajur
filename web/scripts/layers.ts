// Reads the town one layer at a time, straight from the model, with no
// renderer in the way: a table of numbers across seeds, and a flat top-down SVG
// of each seed.
//
//   vp run layers                 the shipped seed and nine more
//   vp run layers -- 1 2 3        those seeds
//
// The SVGs go to $LAYERS_OUT, or to lajur-layers in the system temp directory.
import { mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { buildLogic } from "./bend.ts";

const built = buildLogic();
if (!built.ok) {
  console.error(built.output);
  process.exit(1);
}
const T = (await import("../src/town.mjs")).default;

type Pt = { x: number; z: number };
const yes = (b: unknown) => b === true || (b as { $?: string })?.$ === "True";
const dir = ($: "North" | "East" | "South" | "West") => ({ $ });
const COLS = T.cols();
const ROWS = T.rows();
const STEPS = T.cut_steps();
const KINDS = ["", "through", "gang", "stub"];

const seeds = process.argv.slice(2).map(Number).filter(Number.isFinite);
if (seeds.length === 0) seeds.push(T.seed_of_town(), 1, 2, 3, 4, 5, 6, 7, 8, 9);
const out = process.env.LAYERS_OUT ?? join(tmpdir(), "lajur-layers");
mkdirSync(out, { recursive: true });

// The street on each edge of the block's frame: v = 0, u = 1024, v = 1024, u = 0.
const edgeOpen = (i: number, j: number) => ({
  v0: yes(T.has(i, j, dir("East"))),
  u1: yes(T.has(i + 1, j, dir("South"))),
  v1: yes(T.has(i, j + 1, dir("East"))),
  u0: yes(T.has(i, j, dir("South"))),
});

interface Cut {
  code: number;
  line: Pt[];
}

function layer3(seed: number) {
  const degree = new Map<number, number>();
  const bump = (n: number, by = 1) => degree.set(n, (degree.get(n) ?? 0) + by);
  for (let i = 0; i < COLS; i += 1) {
    for (let j = 0; j < ROWS; j += 1) {
      const n = (["North", "East", "South", "West"] as const).filter((d) =>
        yes(T.has(i, j, dir(d))),
      ).length;
      if (n !== 2 && n > 0) bump(n);
    }
  }
  const kinds = [0, 0, 0, 0];
  let dangling = 0;
  const cuts: Cut[] = [];
  const leaves: Pt[][] = [];
  for (let i = 0; i + 1 < COLS; i += 1) {
    for (let j = 0; j + 1 < ROWS; j += 1) {
      if (!yes(T.block_exists(i, j))) continue;
      const open = edgeOpen(i, j);
      const walk = (p: number): void => {
        const code = T.split_code(i, j, p, seed);
        const r = T.rect_of(i, j, p, seed);
        if (code === 0 || code === 3) leaves.push(outline(i, j, r, seed));
        if (code === 0) return;
        kinds[code] += 1;
        const line: Pt[] = [];
        for (let k = 0; k <= STEPS; k += 1) line.push(T.split_point(i, j, p, k, seed));
        cuts.push({ code, line });
        // An end on the edge of the block meets that edge's street, if it has one.
        // A cut across u leaves its first child narrower in u, and runs along v.
        const alongV = T.rect_of(i, j, 2 * p, seed).u1 !== r.u1;
        const ends = alongV
          ? [r.v0 === 0 && !open.v0, r.v1 === 1024 && !open.v1 && code !== 3]
          : [r.u0 === 0 && !open.u0, r.u1 === 1024 && !open.u1 && code !== 3];
        dangling += ends.filter(Boolean).length;
        if (code !== 3) {
          walk(2 * p);
          walk(2 * p + 1);
        }
      };
      walk(1);
    }
  }
  bump(3, 2 * (kinds[1]! + kinds[2]!) + kinds[3]!);
  bump(1, kinds[3]!);
  const nodes = [...degree.values()].reduce((a, b) => a + b, 0);
  const share = (n: number) => `${Math.round((100 * (degree.get(n) ?? 0)) / nodes)}%`;
  const areas = leaves.map(area).sort((a, b) => a - b);
  const at = (f: number) => Math.round(areas[Math.floor(f * (areas.length - 1))]!);
  return {
    numbers: {
      seed,
      through: kinds[1],
      gang: kinds[2],
      stub: kinds[3],
      "4-way": share(4),
      "3-way": share(3),
      "dead end": share(1),
      dangling,
      blocks: leaves.length,
      "m² p10": at(0.1),
      "m² p50": at(0.5),
      "m² p90": at(0.9),
    },
    cuts,
    leaves,
  };
}

// A leaf of the cut tree on the ground: its rectangle's edges, through the frame.
function outline(
  i: number,
  j: number,
  r: { u0: number; u1: number; v0: number; v1: number },
  seed: number,
): Pt[] {
  const ring: Pt[] = [];
  const n = 4;
  const lerp = (a: number, b: number, k: number) => Math.round(a + ((b - a) * k) / n);
  for (let k = 0; k < n; k += 1) ring.push(T.patch(i, j, lerp(r.u0, r.u1, k), r.v0, seed));
  for (let k = 0; k < n; k += 1) ring.push(T.patch(i, j, r.u1, lerp(r.v0, r.v1, k), seed));
  for (let k = 0; k < n; k += 1) ring.push(T.patch(i, j, lerp(r.u1, r.u0, k), r.v1, seed));
  for (let k = 0; k < n; k += 1) ring.push(T.patch(i, j, r.u0, lerp(r.v1, r.v0, k), seed));
  return ring;
}

function area(ring: Pt[]): number {
  let s = 0;
  ring.forEach((p, k) => {
    const q = ring[(k + 1) % ring.length]!;
    s += p.x * q.z - q.x * p.z;
  });
  return Math.abs(s) / 2 / 1e4;
}

const xy = (p: Pt) => `${(p.x / 100).toFixed(1)},${(p.z / 100).toFixed(1)}`;

function svg(seed: number, title: string, cuts: Cut[], leaves: Pt[][]): string {
  const parts: string[] = [];
  const all: Pt[] = [];
  for (const ring of leaves) {
    parts.push(
      `<polygon points="${ring.map(xy).join(" ")}" fill="#e8efe2" stroke="#9a9" stroke-width="0.5"/>`,
    );
  }
  for (let i = 0; i < COLS; i += 1) {
    for (let j = 0; j < ROWS; j += 1) {
      for (const d of ["East", "South"] as const) {
        if (!yes(T.has(i, j, dir(d)))) continue;
        const line: Pt[] = [];
        for (let l = T.samples(i, j, dir(d), seed); l.$ === "Con"; l = l.tail) line.push(l.head);
        all.push(...line);
        parts.push(
          `<polyline points="${line.map(xy).join(" ")}" stroke="#333" stroke-width="8" fill="none"/>`,
        );
      }
    }
  }
  const colour = ["", "#2a6fdb", "#e08a00", "#d0302f"];
  const width = [0, 6, 3, 3];
  for (const cut of cuts) {
    parts.push(
      `<polyline points="${cut.line.map(xy).join(" ")}" stroke="${colour[cut.code]}" stroke-width="${width[cut.code]}" fill="none"/>`,
    );
  }
  const xs = all.map((p) => p.x / 100);
  const zs = all.map((p) => p.z / 100);
  const [x0, z0] = [Math.min(...xs) - 20, Math.min(...zs) - 30];
  const [w, h] = [Math.max(...xs) + 20 - x0, Math.max(...zs) + 20 - z0];
  const legend = KINDS.slice(1)
    .map((k, n) => `<tspan fill="${colour[n + 1]}">■ ${k}</tspan>`)
    .join(" ");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${x0} ${z0} ${w} ${h}" width="${Math.round(w * 1.5)}" height="${Math.round(h * 1.5)}">
<rect x="${x0}" y="${z0}" width="${w}" height="${h}" fill="#fff"/>
${parts.join("\n")}
<text x="${x0 + 8}" y="${z0 + 16}" font-size="12" font-family="monospace">seed ${seed}  ${title}  ${legend}</text>
</svg>`;
}

const table = [];
for (const seed of seeds) {
  const { numbers, cuts, leaves } = layer3(seed);
  table.push(numbers);
  const title = `4-way ${numbers["4-way"]}  3-way ${numbers["3-way"]}  dead end ${numbers["dead end"]}`;
  writeFileSync(join(out, `layer3-${seed}.svg`), svg(seed, title, cuts, leaves));
}
console.log("Layer 3: the streets inside the blocks");
console.table(table);
console.log(`SVGs in ${out}`);
