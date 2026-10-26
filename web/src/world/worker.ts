// Makes cells off the main thread, so the town ahead of the car is ready
// before the car reaches it without the drive stalling while it is made.
import { drawn, world } from "./world.ts";

self.onmessage = (event: MessageEvent<{ seed: number; i: number; j: number }>) => {
  const { seed, i, j } = event.data;
  self.postMessage({ i, j, drawn: drawn(world(seed, i, j, 1, 1)) });
};
