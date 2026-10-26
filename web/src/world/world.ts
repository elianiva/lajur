import { along, cell, segCurve, segExists, segKind, type Cell, type Line } from "./cells.ts";
import { framePoly, parcels, type Plan } from "./parcels.ts";
import type { Pt } from "./cells.ts";

/**
 * A window of cells, i0 ≤ i < i0 + cols and j0 ≤ j < j0 + rows, with their
 * parcels. Any window of the same seed agrees with any other where they
 * overlap, so a minimap, a preview and the lab all draw the same world.
 */
export interface World {
  seed: number;
  cells: Cell[];
  plans: Plan[];
  /** Every road and river, the window's own east and north edges included. */
  lines: Line[];
}

export function world(seed: number, i0: number, j0: number, cols: number, rows: number): World {
  const cells: Cell[] = [];
  for (let j = j0; j < j0 + rows; j++)
    for (let i = i0; i < i0 + cols; i++) cells.push(cell(seed, i, j));
  const plans = cells.map((c) => parcels(seed, c));
  // A cell owns its south and west roads; the window's east and north edges
  // belong to cells outside it.
  const lines = cells.flatMap((c) => c.lines);
  for (let i = i0; i < i0 + cols; i++)
    if (segExists(seed, i, j0 + rows, "E"))
      lines.push({
        kind: segKind(i, j0 + rows, "E"),
        pts: along(segCurve(seed, i, j0 + rows, "E"), 64),
      });
  for (let j = j0; j < j0 + rows; j++)
    if (segExists(seed, i0 + cols, j, "S"))
      lines.push({
        kind: segKind(i0 + cols, j, "S"),
        pts: along(segCurve(seed, i0 + cols, j, "S"), 64),
      });
  return { seed, cells, plans, lines };
}

/** The window's extent on the ground: x0, z0, x1, z1 in metres. */
export function extent(w: World): [number, number, number, number] {
  let x0 = Infinity;
  let z0 = Infinity;
  let x1 = -Infinity;
  let z1 = -Infinity;
  for (const l of w.lines)
    if (!l.river)
      for (const p of l.pts) {
        x0 = Math.min(x0, p.x);
        z0 = Math.min(z0, p.z);
        x1 = Math.max(x1, p.x);
        z1 = Math.max(z1, p.z);
      }
  return [x0, z0, x1, z1];
}

/**
 * What a window draws, as plain data: no frames, so a worker can make it and
 * post it. A river cell is two blocks, one each side of the water; its bank
 * is the strip of the frame between them.
 */
export interface Drawn {
  seed: number;
  plans: Plan[];
  lines: Line[];
  banks: Pt[][];
}

export function drawn(w: World): Drawn {
  const banks: Pt[][] = [];
  w.cells.forEach((c, k) => {
    const blocks = w.plans[k]!.blocks;
    for (const south of blocks)
      for (const north of blocks)
        if (
          south.b.u0 === north.b.u0 &&
          !south.b.roads.N &&
          !north.b.roads.S &&
          south.b.v1 < north.b.v0
        )
          banks.push(framePoly(c.frame, south.b.u0, south.b.u1, south.b.v1, north.b.v0, 12));
  });
  return { seed: w.seed, plans: w.plans, lines: w.lines, banks };
}
