import { expect, test } from "vite-plus/test";
import { world } from "./world.ts";

// The lab, the minimap and the game each ask for a window of cells. Each cell
// is a function of (seed, i, j), so a cell made inside one window must be the
// cell made inside any other.
test("a cell is the same in every window that holds it", () => {
  const wide = world(7, 0, 0, 3, 3);
  const small = world(7, 1, 2, 2, 1);
  for (const [i, j] of [
    [1, 2],
    [2, 2],
  ]) {
    const key = (w: typeof wide) => w.cells.findIndex((c) => c.i === i && c.j === j);
    const a = key(wide);
    const b = key(small);
    expect(a).toBeGreaterThanOrEqual(0);
    expect(b).toBeGreaterThanOrEqual(0);
    expect(JSON.stringify(small.cells[b])).toBe(JSON.stringify(wide.cells[a]));
    expect(JSON.stringify(small.plans[b])).toBe(JSON.stringify(wide.plans[a]));
  }
});

test("another seed makes another world", () => {
  expect(JSON.stringify(world(7, 0, 0, 1, 1).cells)).not.toBe(
    JSON.stringify(world(8, 0, 0, 1, 1).cells),
  );
});
