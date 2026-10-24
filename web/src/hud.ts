import { citation, fine, ruleName, type Snapshot } from "./bend.ts";

const rupiah = new Intl.NumberFormat("id-ID");

function need<T extends Element>(selector: string): T {
  const found = document.querySelector<T>(selector);
  if (!found) throw new Error(`missing ${selector}`);
  return found;
}

/** Reads the model's numbers into the overlay. Formats; decides nothing. */
export class Hud {
  private speed = need("#speed");
  private limit = need("#limit");
  private metres = need("#metres");
  private lamps = need<HTMLElement>("#lamps");
  private panel = need<HTMLElement>("#verdict");
  private causes = need("#causes");
  private shown: string | null = null;

  update(state: Snapshot): void {
    this.speed.textContent = String(state.speed);
    this.limit.textContent = String(state.limit);
    this.metres.textContent = rupiah.format(state.metres);

    const speeding = state.charges.includes(21);
    this.speed.classList.toggle("over", speeding);
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
      clean.textContent = "No rule broken";
      this.causes.append(clean);
    }
    for (const id of state.charges) {
      const row = document.createElement("li");
      const name = document.createElement("strong");
      name.textContent = ruleName(id);
      const where = document.createElement("span");
      where.textContent = citation(id);
      const price = document.createElement("em");
      price.textContent = `Rp${rupiah.format(fine(id))}`;
      row.append(name, where, price);
      this.causes.append(row);
    }
    this.panel.hidden = false;
  }

  private dismiss(): void {
    if (this.shown === null) return;
    this.shown = null;
    this.panel.hidden = true;
  }
}
