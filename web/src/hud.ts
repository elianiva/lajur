import { citation, fine, points, ruleName, type Snapshot } from "./bend.ts";

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

/** The licence: one pip per point up to the count that holds it. */
class Licence {
  private pips = need<HTMLOListElement>("#pips");
  private shown = -1;

  update(points: number, heldAt: number): void {
    if (this.pips.childElementCount !== heldAt) {
      this.pips.replaceChildren(
        ...Array.from({ length: heldAt }, () => document.createElement("li")),
      );
      this.shown = -1;
    }
    if (points === this.shown) return;
    this.shown = points;
    [...this.pips.children].forEach((pip, k) => pip.classList.toggle("on", k < points));
  }
}

const SLIP_MS = 3200;

function ticketRow(id: number, count = 1): HTMLLIElement {
  const row = document.createElement("li");
  const name = document.createElement("strong");
  name.textContent = count > 1 ? `${ruleName(id)} ×${count}` : ruleName(id);
  const where = document.createElement("span");
  where.textContent = citation(id);
  const cost = document.createElement("em");
  const pts = points(id) * count;
  cost.textContent = pts > 0 ? `+${pts} poin` : "Warning";
  row.append(name, where, cost);
  return row;
}

const ENDINGS: Record<Snapshot["phase"], string> = {
  Running: "Tilang",
  Over: "Shift over",
  Held: "SIM held",
  Wrecked: "Crashed",
};

/** Reads the model's numbers into the overlay. Formats; decides nothing. */
export class Hud {
  private dial = new Dial(need<SVGElement>("#dial"));
  private licence = new Licence();
  private lamps = need<HTMLElement>("#lamps");
  private light = need<HTMLElement>("#light");
  private slips = need<HTMLOListElement>("#slips");
  private panel = need<HTMLElement>("#verdict");
  private ending = need("#ending");
  private causes = need("#causes");
  private total = need("#total b");
  private tally = need("#tally b");
  private clock = need("#clock");
  private earned = need("#earned");
  private order = need<HTMLElement>("#order");
  private task = need("#task");
  private far = need("#far");
  private due = need("#due");
  private fares = need("#fares b");
  private seen = 0;
  private ended = false;

  update(state: Snapshot, car: { x: number; z: number }): void {
    const left = Math.ceil(state.clock);
    this.clock.textContent = `${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`;
    this.earned.textContent = `Rp${rupiah.format(state.earned)}`;
    const o = state.order;
    this.order.dataset.aboard = String(o.aboard);
    this.task.textContent = o.aboard ? `Drop-off · Rp${rupiah.format(o.fare)}` : "Pickup";
    this.far.textContent = `${Math.round(Math.hypot(o.x - car.x, o.z - car.z) / 10) * 10} m`;
    const due = Math.ceil(o.dueIn);
    this.due.textContent = o.aboard ? (due >= 0 ? `${due} s` : "Late") : "";
    this.due.classList.toggle("late", due < 0);

    this.dial.update(state.speed, state.limit);
    this.licence.update(state.points, state.heldAt);
    this.lamps.dataset.signal = state.signal;
    // The light ahead, once it is near enough to matter.
    this.light.dataset.state = String(state.light.ahead < 160 ? state.light.state : 3);

    // Tickets arrive newest first; each new one gets its own slip.
    const fresh = state.tickets.length - this.seen;
    for (const ticket of state.tickets.slice(0, Math.max(fresh, 0)).reverse()) this.slip(ticket.id);
    this.seen = state.tickets.length;

    if (state.phase !== "Running" && !this.ended) this.verdict(state);
  }

  /** A new shift: no slips, no verdict. */
  reset(): void {
    this.seen = 0;
    this.ended = false;
    this.slips.replaceChildren();
    this.panel.hidden = true;
  }

  private slip(id: number): void {
    const row = ticketRow(id);
    this.slips.prepend(row);
    setTimeout(() => row.remove(), SLIP_MS);
  }

  private verdict(state: Snapshot): void {
    this.ended = true;
    this.ending.textContent = ENDINGS[state.phase];
    this.causes.replaceChildren();
    const counts = new Map<number, number>();
    for (const t of [...state.tickets].reverse()) counts.set(t.id, (counts.get(t.id) ?? 0) + 1);
    if (counts.size === 0) {
      const clean = document.createElement("li");
      clean.className = "clean";
      clean.textContent = "No article broken";
      this.causes.append(clean);
    }
    let sum = 0;
    for (const [id, count] of counts) {
      this.causes.append(ticketRow(id, count));
      sum += fine(id) * count;
    }
    this.total.textContent = rupiah.format(sum);
    this.tally.textContent = `${state.points} / ${state.heldAt}`;
    this.fares.textContent = `${state.served} · Rp${rupiah.format(state.earned)}`;
    this.panel.hidden = false;
  }
}
