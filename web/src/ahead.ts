// Hands the model the values the worker made ahead: the doors of the legs
// around the car and the network of the door armed. The model takes each
// only where it is the value it would make itself, and makes its own when
// none has come, so this file decides nothing.
import graph from "./game.mjs";
import type { BendList, Door, Game, Leg, Way, World } from "./game.mjs";
import type { Ask } from "./world/ahead-worker.ts";

const game = graph as Game;

/** Legs whose doors are kept; a crossing needs four. */
const KEEP = 16;

export class Ahead {
  private worker = new Worker(new URL("./world/ahead-worker.ts", import.meta.url), {
    type: "module",
  });
  private doors = new Map<number, { leg: Leg; value: BendList<Door> | null }>();
  private nets = new Map<number, BendList<Way> | null>();

  constructor() {
    this.worker.onmessage = (event: MessageEvent<Ask & { value: never }>) => {
      const a = event.data;
      if (a.kind === "doors") this.doors.set(a.id, { leg: a.leg, value: a.value });
      else this.nets.set(a.id, a.value);
    };
  }

  /** Asks for the doors of the leg the car is on and of each leg it may take next. */
  prefetch(world: World): void {
    const seed = game.seed_of(world);
    for (let l = game.legs_ahead(world); l.$ === "Con"; l = l.tail) {
      const id = game.leg_id(l.head);
      if (this.doors.has(id)) continue;
      this.doors.set(id, { leg: l.head, value: null });
      this.worker.postMessage({ kind: "doors", seed, id, leg: l.head } satisfies Ask);
    }
    while (this.doors.size > KEEP) this.doors.delete(this.doors.keys().next().value!);
  }

  /** The world with whatever the model still wants and the worker has made. */
  fill(world: World): World {
    if (game.needs_doors(world)) {
      const got = this.doors.get(game.leg_key(world));
      if (got?.value) world = game.with_doors(world, got.leg, got.value);
      else if (!got) this.prefetch(world);
    }
    if (game.wants_net(world)) {
      const door = game.armed(world);
      const id = game.door_key(door);
      const net = this.nets.get(id);
      if (net) world = game.with_net(world, door, net);
      else if (net === undefined) {
        this.nets.clear();
        this.nets.set(id, null);
        this.worker.postMessage({ kind: "net", seed: game.seed_of(world), id, door } satisfies Ask);
      }
    }
    return world;
  }
}
