import { looks, type Look, type Shade, type InkStyle } from "../render/look.ts";

/**
 * The lab's NPR shelf: the look the game drives, then five to take apart.
 *
 * A preset is a whole `Look`; the knobs write into it, and `look.ts` puts the
 * result on screen without rebuilding a single material.
 */

export interface NprState {
  look: Look;
  /** Sun bearing in degrees: 0 from +z, 90 from +x. */
  azimuth: number;
  /** Sun height in degrees. */
  elevation: number;
}

export interface Knob {
  /** Short name in the URL. */
  key: string;
  label: string;
  min: number;
  max: number;
  step: number;
  digits: number;
  get(state: NprState): number;
  set(state: NprState, value: number): void;
}

export interface Swatch {
  key: string;
  label: string;
  get(state: NprState): number;
  set(state: NprState, value: number): void;
}

const DEFAULT_SHADE: Shade = {
  softness: 0,
  shadow: null,
  stain: 0,
  rim: 0,
  rimColour: 0xffffff,
  rimPower: 3,
};

const DEFAULT_INK: InkStyle = {
  colour: null,
  width: 1.5,
  strength: 1,
  silhouette: 1,
  crease: 0.85,
};

const shade = (state: NprState): Shade => (state.look.shade ??= { ...DEFAULT_SHADE });
const ink = (state: NprState): InkStyle => (state.look.ink ??= { ...DEFAULT_INK });

/** The look the game drives with; the city is built around it, so it opens here. */
const maket = looks.find((look) => look.key === "maket") ?? looks[0]!;

export const nprLooks: Look[] = [
  maket,
  {
    key: "sel",
    name: "Sel",
    sky: 0x9bd8ff,
    hemi: [0xeaf6ff, 0x8d90b8, 1.5],
    sun: [0xfff3d8, 2.6],
    sunFrom: [-0.85, 1.6, 1],
    bands: 3,
    tint: { saturation: 1.16, lightness: 0.02, hue: -0.004, pastel: 0 },
    shade: {
      softness: 0.02,
      shadow: 0x4d5ea8,
      stain: 0.5,
      rim: 0.18,
      rimColour: 0xfff2cf,
      rimPower: 3.2,
    },
    ink: { colour: 0x171b30, width: 3.2, strength: 1, silhouette: 1, crease: 0.7 },
    pixel: 1,
    grade: { saturation: 1.1, contrast: 1.06, warmth: 0.15, posterize: 0, vignette: 0 },
    night: false,
  },
  {
    key: "tinta",
    name: "Tinta",
    sky: 0xf3ecdc,
    hemi: [0xfffaf0, 0x9a9484, 1.45],
    sun: [0xffffff, 2.7],
    sunFrom: [-1.15, 1.6, 0.55],
    bands: 2,
    tint: { saturation: 0.35, lightness: 0.04, hue: 0, pastel: 0.08 },
    shade: { softness: 0, shadow: 0x2a2c44, stain: 0.6, rim: 0, rimColour: 0xffffff, rimPower: 3 },
    ink: { colour: 0x14131c, width: 2.6, strength: 1, silhouette: 1.1, crease: 0.9 },
    pixel: 1,
    grade: { saturation: 0.9, contrast: 1.22, warmth: 0.15, posterize: 0, vignette: 0.2 },
    night: false,
  },
  {
    key: "cat",
    name: "Cat air",
    sky: 0xd8eef7,
    hemi: [0xfdf7ff, 0xa8a0c8, 1.95],
    sun: [0xfff6ea, 2.1],
    sunFrom: [-0.7, 1.9, 1.2],
    bands: 4,
    tint: { saturation: 1.02, lightness: 0.06, hue: 0.008, pastel: 0.28 },
    shade: {
      softness: 0.75,
      shadow: 0x9a8fc0,
      stain: 0.35,
      rim: 0.3,
      rimColour: 0xffffff,
      rimPower: 2.4,
    },
    ink: { colour: null, width: 1.2, strength: 0.55, silhouette: 1.4, crease: 0.25 },
    pixel: 1,
    grade: { saturation: 1.02, contrast: 1, warmth: 0.25, posterize: 0, vignette: 0.15 },
    night: false,
  },
  {
    key: "sablon",
    name: "Sablon",
    sky: 0xf1e3c2,
    hemi: [0xfff1d8, 0x8f8a76, 1.4],
    sun: [0xffeccc, 3],
    sunFrom: [-1.3, 1.15, 0.6],
    bands: 3,
    tint: { saturation: 1.2, lightness: 0, hue: 0.01, pastel: 0.05 },
    shade: {
      softness: 0,
      shadow: 0x6b3f6f,
      stain: 0.55,
      rim: 0.12,
      rimColour: 0xfff0d0,
      rimPower: 4,
    },
    ink: { colour: 0x2a1a2e, width: 2, strength: 1, silhouette: 0.9, crease: 0.5 },
    pixel: 3,
    grade: { saturation: 1.15, contrast: 1.12, warmth: 0.3, posterize: 8, vignette: 0.25 },
    night: false,
  },
  {
    key: "malam",
    name: "Malam",
    sky: 0x141a36,
    hemi: [0x6b7ad8, 0x1a1430, 1.25],
    sun: [0xa9bcff, 1.6],
    sunFrom: [0.9, 1.4, 0.8],
    bands: 3,
    tint: { saturation: 1.05, lightness: -0.08, hue: 0.02, pastel: 0 },
    shade: {
      softness: 0.05,
      shadow: 0x1d2a63,
      stain: 0.5,
      rim: 0.5,
      rimColour: 0x9fd0ff,
      rimPower: 2.6,
    },
    ink: { colour: 0x060814, width: 2.2, strength: 1, silhouette: 1, crease: 0.75 },
    pixel: 1,
    grade: { saturation: 1.15, contrast: 1.1, warmth: -0.3, posterize: 0, vignette: 0.4 },
    night: true,
  },
];

export const nprKeys = nprLooks.map((look) => look.key);

const bearing = (from: [number, number, number]) => {
  const [x, y, z] = from;
  const flat = Math.hypot(x, z) || 1;
  const degrees = (radians: number) => (radians * 180) / Math.PI;
  return {
    azimuth: (degrees(Math.atan2(x, z)) + 360) % 360,
    elevation: degrees(Math.atan2(y, flat)),
  };
};

/** A fresh, independent state for a preset. */
export function nprState(key: string): NprState {
  const look = nprLooks.find((option) => option.key === key) ?? nprLooks[0]!;
  const state: NprState = { look: structuredClone(look), ...bearing(look.sunFrom) };
  aim(state);
  return state;
}

/** Where the sun sits, from the two sliders. */
function aim(state: NprState): void {
  const rad = Math.PI / 180;
  const flat = Math.cos(state.elevation * rad);
  state.look.sunFrom = [
    flat * Math.sin(state.azimuth * rad),
    Math.sin(state.elevation * rad),
    flat * Math.cos(state.azimuth * rad),
  ];
}

export const knobs: Knob[] = [
  {
    key: "bands",
    label: "Bands",
    min: 2,
    max: 6,
    step: 1,
    digits: 0,
    get: (state) => state.look.bands,
    set: (state, value) => (state.look.bands = Math.round(value)),
  },
  {
    key: "soft",
    label: "Softness",
    min: 0,
    max: 1,
    step: 0.01,
    digits: 2,
    get: (state) => shade(state).softness,
    set: (state, value) => (shade(state).softness = value),
  },
  {
    key: "stain",
    label: "Stain",
    min: 0,
    max: 1,
    step: 0.01,
    digits: 2,
    get: (state) => shade(state).stain,
    set: (state, value) => (shade(state).stain = value),
  },
  {
    key: "rim",
    label: "Rim strength",
    min: 0,
    max: 1,
    step: 0.01,
    digits: 2,
    get: (state) => shade(state).rim,
    set: (state, value) => (shade(state).rim = value),
  },
  {
    key: "rimPower",
    label: "Rim power",
    min: 1,
    max: 8,
    step: 0.1,
    digits: 1,
    get: (state) => shade(state).rimPower,
    set: (state, value) => (shade(state).rimPower = value),
  },
  {
    key: "wrap",
    label: "Wrap",
    min: 0,
    max: 1,
    step: 0.01,
    digits: 2,
    get: (state) => shade(state).wrap ?? 0,
    set: (state, value) => (shade(state).wrap = value),
  },
  {
    key: "width",
    label: "Ink width",
    min: 0.5,
    max: 6,
    step: 0.1,
    digits: 1,
    get: (state) => ink(state).width,
    set: (state, value) => (ink(state).width = value),
  },
  {
    key: "strength",
    label: "Ink strength",
    min: 0,
    max: 1,
    step: 0.01,
    digits: 2,
    get: (state) => ink(state).strength,
    set: (state, value) => (ink(state).strength = value),
  },
  {
    key: "silhouette",
    label: "Silhouette",
    min: 0.2,
    max: 3,
    step: 0.01,
    digits: 2,
    get: (state) => ink(state).silhouette,
    set: (state, value) => (ink(state).silhouette = value),
  },
  {
    key: "crease",
    label: "Crease",
    min: 0,
    max: 1,
    step: 0.01,
    digits: 2,
    get: (state) => ink(state).crease,
    set: (state, value) => (ink(state).crease = value),
  },
  {
    key: "sunPower",
    label: "Sun",
    min: 0,
    max: 4,
    step: 0.05,
    digits: 2,
    get: (state) => state.look.sun[1],
    set: (state, value) => (state.look.sun[1] = value),
  },
  {
    key: "ambient",
    label: "Ambient",
    min: 0,
    max: 3,
    step: 0.05,
    digits: 2,
    get: (state) => state.look.hemi[2],
    set: (state, value) => (state.look.hemi[2] = value),
  },
  {
    key: "azimuth",
    label: "Sun bearing",
    min: 0,
    max: 360,
    step: 1,
    digits: 0,
    get: (state) => state.azimuth,
    set: (state, value) => {
      state.azimuth = value;
      aim(state);
    },
  },
  {
    key: "elevation",
    label: "Sun height",
    min: 5,
    max: 90,
    step: 1,
    digits: 0,
    get: (state) => state.elevation,
    set: (state, value) => {
      state.elevation = value;
      aim(state);
    },
  },
  {
    key: "saturation",
    label: "Saturation",
    min: 0,
    max: 2,
    step: 0.01,
    digits: 2,
    get: (state) => state.look.grade.saturation,
    set: (state, value) => (state.look.grade.saturation = value),
  },
  {
    key: "contrast",
    label: "Contrast",
    min: 0.5,
    max: 1.8,
    step: 0.01,
    digits: 2,
    get: (state) => state.look.grade.contrast,
    set: (state, value) => (state.look.grade.contrast = value),
  },
  {
    key: "warmth",
    label: "Warmth",
    min: -1,
    max: 1,
    step: 0.05,
    digits: 2,
    get: (state) => state.look.grade.warmth,
    set: (state, value) => (state.look.grade.warmth = value),
  },
  {
    key: "posterize",
    label: "Posterize",
    min: 0,
    max: 12,
    step: 1,
    digits: 0,
    get: (state) => state.look.grade.posterize,
    set: (state, value) => (state.look.grade.posterize = Math.round(value)),
  },
  {
    key: "vignette",
    label: "Vignette",
    min: 0,
    max: 1,
    step: 0.01,
    digits: 2,
    get: (state) => state.look.grade.vignette,
    set: (state, value) => (state.look.grade.vignette = value),
  },
  {
    key: "pixel",
    label: "Pixel",
    min: 1,
    max: 4,
    step: 1,
    digits: 0,
    get: (state) => state.look.pixel,
    set: (state, value) => (state.look.pixel = Math.round(value)),
  },
];

export const swatches: Swatch[] = [
  {
    key: "inkColour",
    label: "Ink",
    get: (state) => ink(state).colour ?? 0x000000,
    set: (state, value) => (ink(state).colour = value),
  },
  {
    key: "shadow",
    label: "Shadow",
    get: (state) => shade(state).shadow ?? 0x000000,
    set: (state, value) => (shade(state).shadow = value),
  },
  {
    key: "rimColour",
    label: "Rim colour",
    get: (state) => shade(state).rimColour,
    set: (state, value) => (shade(state).rimColour = value),
  },
  {
    key: "sky",
    label: "Sky",
    get: (state) => state.look.sky,
    set: (state, value) => (state.look.sky = value),
  },
  {
    key: "sunColour",
    label: "Sunlight",
    get: (state) => state.look.sun[0],
    set: (state, value) => (state.look.sun[0] = value),
  },
];

/** Groups of knobs, in the order the panel shows them. */
export const sections: { title: string; keys: string[] }[] = [
  { title: "Toon", keys: ["bands", "soft"] },
  { title: "Shade", keys: ["wrap", "stain", "shadow", "rim", "rimColour", "rimPower"] },
  {
    title: "Outline",
    keys: ["width", "strength", "silhouette", "crease", "inkColour"],
  },
  {
    title: "Light",
    keys: ["sunPower", "ambient", "sunColour", "sky", "azimuth", "elevation"],
  },
  { title: "Grade", keys: ["saturation", "contrast", "warmth", "posterize", "vignette", "pixel"] },
];

const hex = (value: number) => `#${value.toString(16).padStart(6, "0").slice(-6)}`;

/** Everything that leaves the preset's own values, as a query. */
function params(state: NprState): URLSearchParams {
  const preset = nprState(state.look.key);
  const out = new URLSearchParams();
  out.set("npr", state.look.key);
  for (const knob of knobs) {
    const value = knob.get(state);
    if (Math.abs(value - knob.get(preset)) > 1e-6) out.set(knob.key, String(value));
  }
  for (const swatch of swatches) {
    const value = swatch.get(state);
    if (value !== swatch.get(preset)) out.set(swatch.key, hex(value).slice(1));
  }
  return out;
}

/** The state as a query string. */
export function query(state: NprState): string {
  return params(state).toString();
}

/** Read a state back from a query string, clamped to what the knobs allow. */
export function decode(search: URLSearchParams): NprState {
  const state = nprState(search.get("npr") ?? nprLooks[0]!.key);
  for (const knob of knobs) {
    const raw = search.get(knob.key);
    const value = Number(raw);
    if (raw !== null && Number.isFinite(value)) {
      knob.set(state, Math.min(knob.max, Math.max(knob.min, value)));
    }
  }
  for (const swatch of swatches) {
    const raw = search.get(swatch.key);
    if (raw !== null) swatch.set(state, Number.parseInt(raw, 16));
  }
  return state;
}

/** ?npr= in the address wins, then the last state this browser settled on. */
export function initialState(search: URLSearchParams): NprState {
  if (search.has("npr")) return decode(search);
  const saved = localStorage.getItem("lajur.npr");
  return saved ? decode(new URLSearchParams(saved)) : nprState(nprLooks[0]!.key);
}

/** The state as a whole URL, so a look can be handed to someone else. */
export function share(state: NprState, at?: string | null): string {
  const out = params(state);
  if (at) out.set("at", at);
  return `${location.pathname}?${out}${location.hash}`;
}
