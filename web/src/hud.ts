import { citation, fine, ruleName, type Snapshot } from "./bend.ts";

const rupiah = new Intl.NumberFormat("id-ID");

function need<T extends Element>(selector: string): T {
  const found = document.querySelector<T>(selector);
  if (!found) throw new Error(`missing ${selector}`);
  return found;
}

const SCALE_MAX = 120;
const START = -135;
const SWEEP = 270;
const CENTRE = 112;
const NS = "http://www.w3.org/2000/svg";

const angle = (kmh: number) => START + (SWEEP * Math.min(kmh, SCALE_MAX)) / SCALE_MAX;

function point(deg: number, radius: number): [number, number] {
  const rad = (deg * Math.PI) / 180;
  return [CENTRE + radius * Math.sin(rad), CENTRE - radius * Math.cos(rad)];
}

function svg(name: string, attrs: Record<string, string | number>, text?: string): SVGElement {
  const node = document.createElementNS(NS, name);
  for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, String(value));
  if (text !== undefined) node.textContent = text;
  return node;
}

/** The dial: white ticks on a dark disc, the limit roundel on the tick ring. */
class Dial {
  private needle: SVGElement;
  private readout: SVGElement;
  private roundel: SVGElement;
  private roundelText: SVGElement;
  private shown = { speed: -1, limit: -1 };

  constructor(root: SVGElement) {
    root.append(
      svg("circle", { cx: CENTRE, cy: CENTRE, r: 112, fill: "#10161a", "fill-opacity": 0.6 }),
    );
    for (let v = 0; v <= SCALE_MAX; v += 10) {
      const major = v % 20 === 0;
      const [x1, y1] = point(angle(v), 88);
      const [x2, y2] = point(angle(v), major ? 76 : 82);
      root.append(
        svg("line", {
          x1,
          y1,
          x2,
          y2,
          stroke: "#fff",
          "stroke-width": major ? 2.5 : 1.5,
          "stroke-linecap": "round",
        }),
      );
      if (major) {
        const [x, y] = point(angle(v), 62);
        root.append(
          svg(
            "text",
            {
              x,
              y,
              "font-size": 13,
              "font-weight": 700,
              "text-anchor": "middle",
              "dominant-baseline": "central",
              fill: "#fff",
            },
            String(v),
          ),
        );
      }
    }
    this.roundel = svg("g", {});
    this.roundel.append(
      svg("circle", { r: 12, fill: "#fff", stroke: "#e0392b", "stroke-width": 4 }),
    );
    this.roundelText = svg("text", {
      "font-size": 11,
      "font-weight": 800,
      "text-anchor": "middle",
      "dominant-baseline": "central",
      fill: "#10161a",
    });
    this.roundel.append(this.roundelText);
    this.needle = svg("g", {});
    this.needle.append(
      svg("line", {
        x1: 0,
        y1: 10,
        x2: 0,
        y2: -66,
        stroke: "#fff",
        "stroke-width": 3,
        "stroke-linecap": "round",
      }),
      svg("circle", { r: 5, fill: "#fff" }),
    );
    this.readout = svg("text", {
      x: CENTRE,
      y: CENTRE + 56,
      "font-size": 36,
      "font-weight": 700,
      "letter-spacing": -1.5,
      "text-anchor": "middle",
      fill: "#fff",
    });
    root.append(
      this.roundel,
      this.needle,
      this.readout,
      svg(
        "text",
        {
          x: CENTRE,
          y: CENTRE + 74,
          "font-size": 11,
          "letter-spacing": 1.8,
          "text-anchor": "middle",
          fill: "#fff",
          opacity: 0.75,
        },
        "KM/H",
      ),
    );
  }

  update(speed: number, limit: number): void {
    if (limit !== this.shown.limit) {
      const [x, y] = point(angle(limit), 88);
      this.roundel.setAttribute("transform", `translate(${x} ${y})`);
      this.roundelText.textContent = String(limit);
    }
    if (speed !== this.shown.speed) {
      this.needle.setAttribute(
        "transform",
        `translate(${CENTRE} ${CENTRE}) rotate(${angle(speed)})`,
      );
      this.readout.textContent = String(speed);
    }
    this.shown = { speed, limit };
  }
}

/** Reads the model's numbers into the overlay. Formats; decides nothing. */
export class Hud {
  private dial = new Dial(need<SVGElement>("#dial"));
  private lamps = need<HTMLElement>("#lamps");
  private panel = need<HTMLElement>("#verdict");
  private causes = need("#causes");
  private total = need("#total b");
  private shown: string | null = null;

  update(state: Snapshot): void {
    this.dial.update(state.speed, state.limit);
    this.lamps.dataset.signal = state.signal;

    if (state.crashed) this.verdict(state);
    else this.dismiss();
  }

  private verdict(state: Snapshot): void {
    const key = state.charges.join(",");
    if (this.shown === key) return;
    this.shown = key;

    this.causes.replaceChildren();
    if (state.charges.length === 0) {
      const clean = document.createElement("li");
      clean.className = "clean";
      clean.textContent = "No article broken";
      this.causes.append(clean);
    }
    let sum = 0;
    for (const id of state.charges) {
      const row = document.createElement("li");
      const name = document.createElement("strong");
      name.textContent = ruleName(id);
      const where = document.createElement("span");
      where.textContent = citation(id);
      const price = document.createElement("em");
      price.textContent = rupiah.format(fine(id));
      sum += fine(id);
      row.append(name, where, price);
      this.causes.append(row);
    }
    this.total.textContent = rupiah.format(sum);
    this.panel.hidden = false;
  }

  private dismiss(): void {
    if (this.shown === null) return;
    this.shown = null;
    this.panel.hidden = true;
  }
}
