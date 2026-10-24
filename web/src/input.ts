import type { Controls } from "./game.mjs";

const KEYS = {
  left: ["ArrowLeft", "KeyA"],
  right: ["ArrowRight", "KeyD"],
  up: ["ArrowUp", "KeyW"],
  down: ["ArrowDown", "KeyS", "Space"],
} as const;

type Held = Record<keyof typeof KEYS, boolean>;

/**
 * Keyboard to the model's input record. Nothing here decides what a key means
 * beyond which field of `Controls` it sets.
 */
export class Keyboard {
  private held: Held = { left: false, right: false, up: false, down: false };
  private restarting = false;

  constructor(target: Window) {
    target.addEventListener("keydown", this.press);
    target.addEventListener("keyup", this.release);
    target.addEventListener("blur", this.forget);
  }

  controls(): Controls {
    return {
      $: "Controls",
      left: this.held.left,
      right: this.held.right,
      up: this.held.up,
      down: this.held.down,
    };
  }

  takeRestart(): boolean {
    const was = this.restarting;
    this.restarting = false;
    return was;
  }

  private press = (event: KeyboardEvent) => {
    if (event.code === "KeyR") {
      this.restarting = true;
      return;
    }
    for (const [field, codes] of Object.entries(KEYS)) {
      if (codes.includes(event.code as never)) {
        this.held[field as keyof Held] = true;
        event.preventDefault();
      }
    }
  };

  private release = (event: KeyboardEvent) => {
    for (const [field, codes] of Object.entries(KEYS)) {
      if (codes.includes(event.code as never)) {
        this.held[field as keyof Held] = false;
      }
    }
  };

  private forget = () => {
    this.held = { left: false, right: false, up: false, down: false };
  };
}
