import type { Controls } from "./game.mjs";

const KEYS = {
  left: ["ArrowLeft", "KeyA"],
  right: ["ArrowRight", "KeyD"],
  up: ["ArrowUp", "KeyW"],
  down: ["ArrowDown", "KeyS", "Space"],
} as const;

type Field = keyof typeof KEYS;
type Held = Record<Field, boolean>;

/** Keys that act once per press rather than while held. */
export type Command = "start" | "any" | "pause" | "restart" | "menu" | "mute";

const COMMANDS: Record<string, Command> = {
  Enter: "start",
  KeyN: "any",
  Escape: "pause",
  KeyP: "pause",
  KeyR: "restart",
  KeyQ: "menu",
  KeyM: "mute",
};

const none = (): Held => ({ left: false, right: false, up: false, down: false });

/**
 * Keyboard and touch pads to the model's input record. Nothing here decides
 * what a key means beyond which field of `Controls` it sets, or which screen
 * command it names.
 */
export class Keyboard {
  private held = none();
  private touched = none();
  private commands: Command[] = [];

  constructor(target: Window) {
    target.addEventListener("keydown", this.press);
    target.addEventListener("keyup", this.release);
    target.addEventListener("blur", this.forget);
    for (const pad of document.querySelectorAll<HTMLElement>("[data-pad]")) this.bind(pad);
    if (matchMedia("(pointer: coarse)").matches) document.body.dataset.touch = "";
    target.addEventListener("pointerdown", (event) => {
      if (event.pointerType === "touch") document.body.dataset.touch = "";
    });
  }

  controls(): Controls {
    const on = (f: Field) => this.held[f] || this.touched[f];
    return { $: "Controls", left: on("left"), right: on("right"), up: on("up"), down: on("down") };
  }

  /** The commands pressed since the last call, oldest first. */
  take(): Command[] {
    return this.commands.splice(0);
  }

  /** A button on screen that names a command. */
  send(command: Command): void {
    this.commands.push(command);
  }

  private bind(pad: HTMLElement): void {
    const field = pad.dataset.pad as Field;
    const set = (on: boolean) => (event: PointerEvent) => {
      event.preventDefault();
      this.touched[field] = on;
      pad.classList.toggle("on", on);
    };
    pad.addEventListener("pointerdown", set(true));
    for (const name of ["pointerup", "pointercancel", "pointerleave"] as const)
      pad.addEventListener(name, set(false));
  }

  private press = (event: KeyboardEvent) => {
    const command = COMMANDS[event.code];
    if (command && !event.repeat) {
      this.commands.push(command);
      event.preventDefault();
      return;
    }
    for (const [field, codes] of Object.entries(KEYS)) {
      if (codes.includes(event.code as never)) {
        this.held[field as Field] = true;
        event.preventDefault();
      }
    }
  };

  private release = (event: KeyboardEvent) => {
    for (const [field, codes] of Object.entries(KEYS)) {
      if (codes.includes(event.code as never)) this.held[field as Field] = false;
    }
  };

  private forget = () => {
    this.held = none();
    this.touched = none();
  };
}
