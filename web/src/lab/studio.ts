import { knobs, nprLooks, sections, swatches, type NprState } from "./npr.ts";

/**
 * The knob panel for the NPR shelf: a button per variation, then a slider for
 * every value that can move. Nothing is applied here — the lab asks for a
 * state and redraws the frame.
 */

export interface Studio {
  element: HTMLElement;
  /** Put every control back in step with the state. */
  sync(): void;
}

interface Options {
  state(): NprState;
  preset(key: string): void;
  change(): void;
}

const hex = (value: number) => `#${value.toString(16).padStart(6, "0").slice(-6)}`;

export function studio(options: Options): Studio {
  const element = document.createElement("section");
  element.id = "studio";
  element.setAttribute("aria-label", "NPR");

  const presets = document.createElement("nav");
  presets.className = "presets";
  presets.setAttribute("aria-label", "Variation");
  element.append(presets);

  const buttons = new Map<string, HTMLButtonElement>();
  for (const look of nprLooks) {
    const button = document.createElement("button");
    button.textContent = look.name;
    button.dataset.npr = look.key;
    button.addEventListener("click", () => {
      options.preset(look.key);
      sync();
    });
    buttons.set(look.key, button);
    presets.append(button);
  }

  const rows = document.createElement("div");
  rows.className = "sliders";
  element.append(rows);

  const redraw = new Map<string, () => void>();

  const label = (text: string): HTMLSpanElement => {
    const span = document.createElement("span");
    span.textContent = text;
    return span;
  };

  for (const section of sections) {
    const title = document.createElement("h3");
    title.textContent = section.title;
    rows.append(title);

    for (const key of section.keys) {
      const knob = knobs.find((entry) => entry.key === key);
      if (knob) {
        const row = document.createElement("label");
        row.className = "knob";
        const value = document.createElement("b");
        const slider = document.createElement("input");
        slider.type = "range";
        slider.min = String(knob.min);
        slider.max = String(knob.max);
        slider.step = String(knob.step);
        slider.setAttribute("aria-label", knob.label);

        const show = () => (value.textContent = knob.get(options.state()).toFixed(knob.digits));
        slider.addEventListener("input", () => {
          knob.set(options.state(), Number(slider.value));
          show();
          options.change();
        });

        row.append(label(knob.label), value, slider);
        rows.append(row);
        redraw.set(key, () => {
          slider.value = String(knob.get(options.state()));
          show();
        });
        continue;
      }

      const swatch = swatches.find((entry) => entry.key === key)!;
      const row = document.createElement("label");
      row.className = "swatch";
      const input = document.createElement("input");
      input.type = "color";
      input.setAttribute("aria-label", swatch.label);
      input.addEventListener("input", () => {
        swatch.set(options.state(), Number.parseInt(input.value.slice(1), 16));
        options.change();
      });
      row.append(label(swatch.label), input);
      rows.append(row);
      redraw.set(key, () => (input.value = hex(swatch.get(options.state()))));
    }
  }

  function sync(): void {
    const state = options.state();
    for (const [key, button] of buttons) {
      button.setAttribute("aria-pressed", String(key === state.look.key));
    }
    for (const redrawOne of redraw.values()) redrawOne();
  }

  return { element, sync };
}
