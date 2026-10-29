import type { Snapshot } from "./bend.ts";

/**
 * The shift's sounds, made from oscillators: the engine by the speed, the
 * indicator's tick, a police whistle for each ticket, a chime when a
 * passenger boards or is set down, and a thud for a crash. It reads the
 * snapshot and decides nothing.
 */
export class Sound {
  private ctx: AudioContext | null = null;
  private master: GainNode | null = null;
  private engine: OscillatorNode | null = null;
  private engineGain: GainNode | null = null;
  private muted = localStorage.getItem("lajur.muted") === "1";
  private last = { tickets: 0, served: 0, aboard: false, phase: "Running", signal: "Off" };
  private blink = 0;

  /** Browsers start audio only after a gesture; call this from one. */
  wake(): void {
    if (this.ctx) {
      void this.ctx.resume();
      return;
    }
    const ctx = new AudioContext();
    this.ctx = ctx;
    this.master = ctx.createGain();
    this.master.gain.value = this.muted ? 0 : 0.5;
    this.master.connect(ctx.destination);
    this.engine = ctx.createOscillator();
    this.engine.type = "sawtooth";
    const low = ctx.createBiquadFilter();
    low.type = "lowpass";
    low.frequency.value = 420;
    this.engineGain = ctx.createGain();
    this.engineGain.gain.value = 0;
    this.engine.connect(low).connect(this.engineGain).connect(this.master);
    this.engine.start();
  }

  get isMuted(): boolean {
    return this.muted;
  }

  toggle(): void {
    this.muted = !this.muted;
    localStorage.setItem("lajur.muted", this.muted ? "1" : "0");
    if (this.master) this.master.gain.value = this.muted ? 0 : 0.5;
  }

  /** A new shift: forget what the last one had heard. */
  reset(): void {
    this.last = { tickets: 0, served: 0, aboard: false, phase: "Running", signal: "Off" };
  }

  /** `live` is false while paused or on a menu: the engine falls silent. */
  update(state: Snapshot, live: boolean, dt: number): void {
    const ctx = this.ctx;
    if (!ctx || !this.engine || !this.engineGain) return;
    const now = ctx.currentTime;
    const running = live && state.phase === "Running";
    this.engine.frequency.setTargetAtTime(38 + state.speed * 1.6, now, 0.08);
    this.engineGain.gain.setTargetAtTime(running ? 0.09 + state.speed / 900 : 0, now, 0.1);
    if (!live) return;

    if (state.signal !== "Off" && running) {
      this.blink -= dt;
      if (this.blink <= 0) {
        this.blink = 0.35;
        this.tone(1800, 0.03, 0.12, "square");
      }
    } else this.blink = 0;

    if (state.tickets.length > this.last.tickets) {
      const pts = state.tickets[0]?.points ?? 0;
      if (pts > 0) this.whistle();
      else this.tone(520, 0.12, 0.2, "triangle");
    }
    if (state.order.aboard !== this.last.aboard) {
      if (state.order.aboard) this.chime([660, 880]);
      else if (state.served > this.last.served) this.chime([880, 1100, 1320]);
    }
    if (state.phase !== this.last.phase && state.phase === "Wrecked") this.thud();
    if (state.phase !== this.last.phase && state.phase === "Over") this.chime([660, 990, 1320]);

    this.last = {
      tickets: state.tickets.length,
      served: state.served,
      aboard: state.order.aboard,
      phase: state.phase,
      signal: state.signal,
    };
  }

  private tone(freq: number, length: number, level: number, type: OscillatorType, at = 0): void {
    const ctx = this.ctx!;
    const t = ctx.currentTime + at;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = type;
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(level, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + length);
    osc.connect(gain).connect(this.master!);
    osc.start(t);
    osc.stop(t + length + 0.02);
  }

  /** Two short blasts, trilled. */
  private whistle(): void {
    const ctx = this.ctx!;
    for (const at of [0, 0.22]) {
      const t = ctx.currentTime + at;
      const osc = ctx.createOscillator();
      const trill = ctx.createOscillator();
      const depth = ctx.createGain();
      const gain = ctx.createGain();
      osc.frequency.value = 2900;
      trill.frequency.value = 38;
      depth.gain.value = 140;
      trill.connect(depth).connect(osc.frequency);
      gain.gain.setValueAtTime(0.18, t);
      gain.gain.setValueAtTime(0.18, t + 0.15);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.19);
      osc.connect(gain).connect(this.master!);
      for (const o of [osc, trill]) {
        o.start(t);
        o.stop(t + 0.2);
      }
    }
  }

  private chime(notes: number[]): void {
    notes.forEach((f, k) => this.tone(f, 0.35, 0.16, "sine", k * 0.09));
  }

  private thud(): void {
    const ctx = this.ctx!;
    const length = 0.5;
    const buffer = ctx.createBuffer(1, ctx.sampleRate * length, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let k = 0; k < data.length; k++)
      data[k] = (Math.random() * 2 - 1) * (1 - k / data.length) ** 3;
    const noise = ctx.createBufferSource();
    noise.buffer = buffer;
    const low = ctx.createBiquadFilter();
    low.type = "lowpass";
    low.frequency.value = 600;
    const gain = ctx.createGain();
    gain.gain.value = 0.7;
    noise.connect(low).connect(gain).connect(this.master!);
    noise.start();
    this.tone(70, 0.4, 0.5, "sine");
  }
}
