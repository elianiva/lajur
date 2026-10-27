// Makes the model's slow values off the main thread, with the model's own
// functions: a leg's doors, and the network of a door's block.
import game from "../game.mjs";
import type { Door, Leg } from "../game.mjs";

export type Ask =
  | { kind: "doors"; seed: number; id: number; leg: Leg }
  | { kind: "net"; seed: number; id: number; door: Door };

self.onmessage = (event: MessageEvent<Ask>) => {
  const a = event.data;
  self.postMessage(
    a.kind === "doors"
      ? { ...a, value: game.leg_doors(a.seed, a.leg) }
      : { ...a, value: game.door_net(a.seed, a.door) },
  );
};
