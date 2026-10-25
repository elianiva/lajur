import { ART, COL, LOK, hash, type Pt } from "./cells.ts";
import { framePoly, type CourtUse, type Species, type Use } from "./parcels.ts";
import type { World } from "./world.ts";

/**
 * The world as a flat plan: every lot coloured by the asset it holds, every
 * canopy a disc. Returns SVG text and touches nothing else, so a page can use
 * it for a minimap or a preview and a script can write it to a file.
 */

export const COLOUR: Record<Use | CourtUse, string> = {
  rumah: "#f4a582",
  petak: "#e7826a",
  kos: "#c8524a",
  warung: "#fdd84e",
  ruko: "#c2185b",
  minimarket: "#2b7bbd",
  bengkel: "#7f6fb8",
  gudang: "#8d8d8d",
  kantor: "#2f4f80",
  apartemen: "#5f86c4",
  rusun: "#9fb3d6",
  mal: "#8a4fb0",
  masjid: "#169a55",
  gereja: "#f27fbf",
  klenteng: "#e3221c",
  sekolah: "#45b5d8",
  puskesmas: "#ffffff",
  spbu: "#ff7f00",
  pasar: "#fb9a3c",
  pendopo: "#a8732a",
  lapangan: "#a6d96a",
  alun: "#e9e2c4",
};
const GROUND: Record<string, string> = {
  tree: "#ece2cc",
  comb: "#ece2cc",
  grid: "#e6dccb",
  shops: "#e8dcc6",
  ring: "#ece2cc",
  kebun: "#c9dc9b",
};
const CANOPY: Record<Species, [string, string]> = {
  mangga: ["#4f8f3c", "#2f5f24"],
  beringin: ["#2c6634", "#173e1d"],
  flamboyan: ["#e3683d", "#9c3a1b"],
  bambu: ["#93b94a", "#5d7f26"],
};
const ROADS: Record<number, [string, number]> = {
  [ART]: ["#3a3a3a", 14],
  [COL]: ["#626262", 9],
  [LOK]: ["#8c8072", 4],
};
const LEGEND: [string, (Use | CourtUse)[]][] = [
  ["Homes", ["rumah", "petak", "kos", "warung"]],
  ["Shops", ["ruko", "minimarket", "bengkel", "spbu", "pasar"]],
  ["City", ["kantor", "apartemen", "rusun", "mal", "gudang"]],
  [
    "Civic",
    ["masjid", "gereja", "klenteng", "sekolah", "puskesmas", "pendopo", "lapangan", "alun"],
  ],
];

export interface PlanOptions {
  /** Width of the map in pixels. */
  px: number;
  /** Add a key of every colour, with counts, to the right of the map. */
  legend?: boolean;
  /** A line of text above the map. */
  label?: string;
  /** Skip canopies narrower than this many pixels: a minimap wants few. */
  minCanopyPx?: number;
}

/** Draw the part of `w` inside x0..x1, z0..z1 (metres). */
export function planSvg(
  w: World,
  [x0, z0, x1, z1]: [number, number, number, number],
  options: PlanOptions,
): string {
  const sc = options.px / (x1 - x0);
  const width = x1 - x0;
  const height = z1 - z0;
  const P = (p: Pt) => `${p.x.toFixed(1)},${p.z.toFixed(1)}`;
  const points = (pts: Pt[]) => pts.map(P).join(" ");
  const inView = (poly: Pt[]) =>
    poly.some((p) => p.x > x0 - 80 && p.x < x1 + 80 && p.z > z0 - 80 && p.z < z1 + 80);
  const sw = Math.max(0.25, 0.6 / sc);
  const parts: string[] = [];

  // The window's outline: the river and its banks stay inside it.
  const outline = w.cells.map(
    (c) => `<polygon points="${points(framePoly(c.frame, 0, 1, 0, 1, 24))}"/>`,
  );
  parts.push(
    `<defs><clipPath id="land">${outline.join("")}</clipPath>` +
      `<pattern id="paddy" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(${Math.round(hash(w.seed, 7) * 90)})">` +
      `<rect width="9" height="9" fill="#d7e8a8"/><rect width="9" height="1.4" fill="#b9d17c"/><rect width="1.2" height="9" fill="#c6db8f"/></pattern></defs>`,
  );
  const rivers = w.lines.filter((l) => l.river);
  const water = (stroke: string, widthM: number) =>
    rivers
      .map(
        (l) =>
          `<polyline points="${points(l.pts)}" stroke="${stroke}" stroke-width="${widthM}" fill="none"/>`,
      )
      .join("");
  parts.push(`<g clip-path="url(#land)">${water("#a9c97a", 240)}</g>`);
  for (const plan of w.plans)
    for (const { b, poly } of plan.blocks)
      if (inView(poly))
        parts.push(
          `<polygon points="${points(poly)}" fill="${b.type === "sawah" ? "url(#paddy)" : GROUND[b.type]}"/>`,
        );
  parts.push(`<g clip-path="url(#land)">${water("#7fb8d8", 28)}</g>`);
  for (const kind of [LOK, COL, ART])
    for (const l of w.lines)
      if (l.kind === kind && !l.river)
        parts.push(
          `<polyline points="${points(l.pts)}" stroke="${ROADS[kind]![0]}" stroke-width="${ROADS[kind]![1]}" fill="none" stroke-linejoin="round" stroke-linecap="round"/>`,
        );

  const counts: Partial<Record<Use | CourtUse, number>> = {};
  for (const plan of w.plans) {
    for (const o of plan.courts) {
      // A sekolah's yard and the school in it are one sekolah.
      if (!o.yard || o.use === "alun") counts[o.use] = (counts[o.use] ?? 0) + 1;
      if (inView(o.poly))
        parts.push(
          `<polygon points="${points(o.poly)}" fill="${o.use === "gudang" ? "#b5b5b5" : COLOUR[o.use]}" stroke="#00000055" stroke-width="${sw}"/>`,
        );
    }
    for (const o of plan.lots) {
      counts[o.use] = (counts[o.use] ?? 0) + 1;
      if (!inView(o.poly)) continue;
      const clinic = o.use === "puskesmas";
      parts.push(
        `<polygon points="${points(o.poly)}" fill="${COLOUR[o.use]}" stroke="${clinic ? "#e3221c" : "#00000066"}" stroke-width="${clinic ? sw * 3 : sw}"/>`,
      );
    }
  }
  const minR = (options.minCanopyPx ?? 0) / sc / 2;
  for (const plan of w.plans)
    for (const t of plan.trees) {
      if (t.r < minR || t.x < x0 - 10 || t.x > x1 + 10 || t.z < z0 - 10 || t.z > z1 + 10) continue;
      const [fill, stroke] = CANOPY[t.sp];
      parts.push(
        `<circle cx="${t.x.toFixed(1)}" cy="${t.z.toFixed(1)}" r="${t.r.toFixed(1)}" fill="${fill}" stroke="${stroke}" stroke-width="${sw * 1.2}" fill-opacity="0.93"/>`,
      );
    }

  // The key, in screen units, to the right of the map.
  const fs = 13 / sc;
  const legend: string[] = [];
  const keyWidth = options.legend ? 190 / sc : 0;
  if (options.legend) {
    const lx = x1 + 14 / sc;
    const box = 12 / sc;
    let ly = z0 + 20 / sc;
    const swatch = (fill: string, text: string, ring = "#00000066") => {
      legend.push(
        `<rect x="${lx}" y="${ly - box}" width="${box}" height="${box}" fill="${fill}" stroke="${ring}" stroke-width="${1 / sc}"/>` +
          `<text x="${lx + box * 1.5}" y="${ly - box * 0.15}" font-size="${fs}" font-family="sans-serif">${text}</text>`,
      );
      ly += fs * 1.4;
    };
    const title = (text: string) => {
      legend.push(
        `<text x="${lx}" y="${ly}" font-size="${fs}" font-family="sans-serif" font-weight="bold">${text}</text>`,
      );
      ly += fs * 1.5;
    };
    for (const [name, uses] of LEGEND) {
      title(name);
      for (const use of uses)
        swatch(
          COLOUR[use],
          `${use} ${counts[use] ?? 0}`,
          use === "puskesmas" ? "#e3221c" : undefined,
        );
      ly += fs * 0.6;
    }
    title("Ground and trees");
    swatch("#c6db8f", "sawah");
    swatch(GROUND.kebun!, "kebun");
    swatch(GROUND.tree!, "kampung");
    for (const sp of Object.keys(CANOPY) as Species[]) swatch(CANOPY[sp][0], sp);
  }

  const top = options.label ? 30 / sc : 0;
  const label = options.label
    ? `<text x="${x0 + 8 / sc}" y="${z0 - 10 / sc}" font-size="${fs}" font-family="monospace">${options.label}</text>`
    : "";
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${x0} ${z0 - top} ${width + keyWidth} ${height + top}" ` +
    `width="${Math.round((width + keyWidth) * sc)}" height="${Math.round((height + top) * sc)}">` +
    `<rect x="${x0}" y="${z0 - top}" width="${width + keyWidth}" height="${height + top}" fill="#f6f3ea"/>` +
    `<svg x="${x0}" y="${z0}" width="${width}" height="${height}" viewBox="${x0} ${z0} ${width} ${height}">${parts.join("")}</svg>` +
    `${legend.join("")}${label}</svg>`
  );
}
