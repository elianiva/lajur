import * as THREE from "three";

/**
 * Looks: one city, several art directions. A look restyles every material by
 * its role (toon bands with a shadow stain and a rim, palette shift, lit
 * windows at night) and sets the light; `Ink` then draws the frame with
 * outlines from a normal-and-depth pass, optional pixelation, and a colour
 * grade. Nothing here is a rule.
 */

/** Toon shading beyond the band count: how soft its steps are, what colour
 * sits in the dark ones, and the light that wraps the turned-away edge. */
export interface Shade {
  /** 0 for a hard cel edge, 1 for a smooth ramp between the bands. */
  softness: number;
  /** Colour stained into the dark bands, or null to leave them neutral. */
  shadow: number | null;
  /** How much of the dark band that colour takes, 0..1. */
  stain: number;
  /** Rim light: its strength, its colour, and how tightly it hugs the edge. */
  rim: number;
  rimColour: number;
  rimPower: number;
  /** How far the light wraps into the shade: 0 cuts at the terminator. */
  wrap?: number;
}

export interface InkStyle {
  /** Outline colour, or null to ink each surface in a darker shade of itself. */
  colour: number | null;
  /** Width in art pixels. */
  width: number;
  strength: number;
  /** How much of a depth gap counts as a silhouette; 1 is the reference. */
  silhouette: number;
  /** Lines where a surface turns away, 0 to drop them. */
  crease: number;
}

/**
 * A paintbox: every material colour is pulled toward its nearest anchor hue
 * and squeezed into one band of saturation and value, so twelve asset
 * palettes read as one hand-mixed set of paints.
 */
export interface Palette {
  /** Hue anchors, in turns. */
  hues: number[];
  /** How far a colour moves toward its nearest anchor, 0..1. */
  pull: number;
  /** The band saturation is squeezed into. */
  saturation: [number, number];
  /** The band lightness is squeezed into. */
  lightness: [number, number];
}

export interface Look {
  key: string;
  name: string;
  sky: number;
  hemi: [sky: number, ground: number, intensity: number];
  sun: [colour: number, intensity: number];
  /** Where the sun sits relative to what it lights, unnormalised. */
  sunFrom: [number, number, number];
  /** 0 for physically shaded; otherwise the number of toon bands. */
  bands: number;
  /** Palette shift applied to every material colour, in HSL. */
  tint: { saturation: number; lightness: number; hue: number; pastel: number };
  /** A colour for a material role, painted under the tint: a pale road, say. */
  roles?: Record<string, number>;
  /** The paintbox every material colour is mixed from, before the tint. */
  palette?: Palette;
  /** Band edges, shadow stain and rim. Absent means plain bands. */
  shade?: Shade;
  ink: InkStyle | null;
  /** Screen pixels per art pixel; 1 for none. */
  pixel: number;
  grade: {
    saturation: number;
    contrast: number;
    warmth: number;
    posterize: number;
    vignette: number;
  };
  night: boolean;
}

export const looks: Look[] = [
  {
    // What ships: a model on a table. Warm paper behind it, pale stone
    // underfoot, one smooth ramp wrapped round every form, no ink. The palette
    // is mixed from a few anchors so twelve asset palettes read as one set.
    key: "maket",
    name: "Maket",
    sky: 0xf4ecdd,
    hemi: [0xfff6e6, 0x9a9288, 0.65],
    sun: [0xffe6bd, 3.6],
    sunFrom: [-0.56, 0.74, 0.37],
    bands: 8,
    tint: { saturation: 0.98, lightness: 0, hue: 0.004, pastel: 0.06 },
    palette: {
      hues: [0.02, 0.1, 0.3, 0.55],
      pull: 0.5,
      saturation: [0.2, 0.55],
      lightness: [0.34, 0.86],
    },
    roles: {
      asphalt: 0x8f8578,
      concrete: 0xdcd2be,
      plinth: 0xd9bd93,
      water: 0x4fb4d4,
    },
    shade: {
      softness: 1,
      shadow: 0x7c7186,
      stain: 0.45,
      rim: 0,
      rimColour: 0xfff4e0,
      rimPower: 2.4,
      wrap: 0.15,
    },
    ink: { colour: null, width: 1.2, strength: 0, silhouette: 1, crease: 0.5 },
    pixel: 1,
    grade: { saturation: 1.12, contrast: 1.18, warmth: 0.1, posterize: 0, vignette: 0.04 },
    night: false,
  },
  {
    key: "komik",
    name: "Komik",
    sky: 0x86dcff,
    hemi: [0xe6f6ff, 0x9c8f70, 1.7],
    sun: [0xfff4dc, 2.3],
    sunFrom: [-0.8, 2, 1],
    bands: 3,
    tint: { saturation: 1.1, lightness: 0.02, hue: 0, pastel: 0 },
    ink: { colour: 0x1c2040, width: 1.6, strength: 1, silhouette: 1, crease: 0.85 },
    pixel: 1,
    grade: { saturation: 1.06, contrast: 1.04, warmth: 0.2, posterize: 0, vignette: 0 },
    night: false,
  },
  {
    key: "diorama",
    name: "Diorama",
    sky: 0xcfe6dc,
    hemi: [0xe9f3ff, 0x7c7a5c, 1.25],
    sun: [0xfff0d4, 2.8],
    sunFrom: [-0.9, 2, 0.8],
    bands: 0,
    tint: { saturation: 0.92, lightness: -0.04, hue: 0, pastel: 0 },
    ink: { colour: 0x262a33, width: 1, strength: 0.85, silhouette: 1, crease: 0.85 },
    pixel: 3,
    grade: { saturation: 1.05, contrast: 1.1, warmth: 0.1, posterize: 22, vignette: 0 },
    night: false,
  },
  {
    key: "senja",
    name: "Senja",
    sky: 0xffc8a0,
    hemi: [0xffd9be, 0x6c4f86, 1.15],
    sun: [0xffb070, 3.1],
    sunFrom: [-1.7, 0.85, 0.5],
    bands: 4,
    tint: { saturation: 1.1, lightness: 0, hue: -0.012, pastel: 0 },
    ink: { colour: 0x5b2c33, width: 1.4, strength: 0.75, silhouette: 1, crease: 0.85 },
    pixel: 1,
    grade: { saturation: 1.08, contrast: 1.05, warmth: 1, posterize: 0, vignette: 0.45 },
    night: false,
  },
  {
    key: "mainan",
    name: "Mainan",
    sky: 0xc4f2e6,
    hemi: [0xffffff, 0xb8b0d8, 2.0],
    sun: [0xffffff, 1.7],
    sunFrom: [-0.6, 2, 1.1],
    bands: 2,
    tint: { saturation: 0.9, lightness: 0.04, hue: 0, pastel: 0.3 },
    ink: { colour: null, width: 1.8, strength: 1, silhouette: 1, crease: 0.85 },
    pixel: 1,
    grade: { saturation: 1, contrast: 0.97, warmth: 0, posterize: 0, vignette: 0 },
    night: false,
  },
  {
    key: "malam",
    name: "Malam",
    sky: 0x1d2552,
    hemi: [0x7484e0, 0x221a3a, 1.0],
    sun: [0xa8b8ff, 0.9],
    sunFrom: [1, 2, 0.6],
    bands: 3,
    tint: { saturation: 0.9, lightness: -0.1, hue: 0.02, pastel: 0 },
    ink: { colour: 0x0a0d22, width: 1.4, strength: 0.9, silhouette: 1, crease: 0.85 },
    pixel: 1,
    grade: { saturation: 1.12, contrast: 1.06, warmth: -0.2, posterize: 0, vignette: 0.35 },
    night: true,
  },
];

export function lookByKey(key: string | null | undefined): Look {
  return looks.find((look) => look.key === key) ?? looks[0]!;
}

// --- materials ----------------------------------------------------------------

// One band ramp, shared by every toon material. The band count and the softness
// of its steps are redrawn in place, so the sliders in the lab change the light
// on every surface without rebuilding a single material.
const RAMP = 256;
const ramp = new THREE.DataTexture(new Uint8Array(RAMP * 4), RAMP, 1, THREE.RGBAFormat);
ramp.minFilter = THREE.NearestFilter;
ramp.magFilter = THREE.NearestFilter;
ramp.needsUpdate = true;
let rampShape = "";

function smoothstep(a: number, b: number, t: number): number {
  const x = Math.min(1, Math.max(0, (t - a) / (b - a)));
  return x * x * (3 - 2 * x);
}

function setRamp(bands: number, softness: number): void {
  const key = `${bands}:${softness}`;
  if (key === rampShape) return;
  rampShape = key;
  const data = ramp.image.data as Uint8Array;
  for (let i = 0; i < RAMP; i += 1) {
    const at = (i / (RAMP - 1)) * bands;
    const step = Math.min(Math.floor(at), bands - 1);
    const within = Math.min(at - step, 1);
    // A hard edge sits at the top of each band; a soft one fills it.
    const rise = softness > 0 ? smoothstep(1 - softness, 1, within) : 1;
    const value = Math.round(Math.min(1, (step + rise) / bands) * 255);
    data.set([value, value, value, 255], i * 4);
  }
  ramp.needsUpdate = true;
}

// Mixed into the dark bands, and added where a surface turns from the camera.
// Shared with every toon shader: changing a value needs no recompile.
const toon = {
  shadowInk: { value: new THREE.Color() },
  stain: { value: 0 },
  rim: { value: new THREE.Color() },
  rimPower: { value: 3 },
  wrap: { value: 0 },
};

const PLAIN: Shade = {
  softness: 0,
  shadow: null,
  stain: 0,
  rim: 0,
  rimColour: 0xffffff,
  rimPower: 3,
};

/** Push a look's toon shading into the shared ramp and uniforms. */
function applyShade(look: Look): void {
  const shade = look.shade ?? PLAIN;
  setRamp(Math.max(1, Math.round(look.bands)), shade.softness);
  (toon.shadowInk.value as THREE.Color).set(shade.shadow ?? 0xffffff);
  toon.stain.value = shade.shadow === null ? 0 : shade.stain;
  (toon.rim.value as THREE.Color).set(shade.rimColour).multiplyScalar(shade.rim);
  toon.rimPower.value = Math.max(0.5, shade.rimPower);
  toon.wrap.value = shade.wrap ?? 0;
}

const TOON_PARS = /* glsl */ `
  uniform sampler2D gradientMap;
  uniform vec3 shadowInk;
  uniform float stain;
  uniform vec3 rim;
  uniform float rimPower;
  uniform float wrap;

  vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
    float dotNL = dot( normal, lightDirection );
    // Clay wraps the light round the terminator; a band look cuts it there.
    float lit = wrap > 0.0 ? clamp( ( dotNL + wrap ) / ( 1.0 + wrap ), 0.0, 1.0 ) : dotNL * 0.5 + 0.5;
    float band = texture2D( gradientMap, vec2( lit, 0.0 ) ).r;
    return mix( vec3( band ), shadowInk * band, stain * ( 1.0 - band ) );
  }
`;

const TOON_RIM = /* glsl */ `
  float facing = 1.0 - saturate( dot( normalize( normal ), normalize( vViewPosition ) ) );
  outgoingLight += rim * pow( facing, rimPower );
`;

/** Teach a toon material the shadow stain and the rim light. */
function toonify(material: THREE.MeshToonMaterial): void {
  material.onBeforeCompile = (shader) => {
    Object.assign(shader.uniforms, toon);
    shader.fragmentShader = shader.fragmentShader
      .replace("#include <gradientmap_pars_fragment>", TOON_PARS)
      .replace(
        "vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;",
        `vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;${TOON_RIM}`,
      );
  };
}

function toonMaterial(params: THREE.MeshToonMaterialParameters): THREE.MeshToonMaterial {
  const material = new THREE.MeshToonMaterial(params);
  toonify(material);
  return material;
}

const styled = new WeakMap<THREE.Material, Map<string, THREE.Material>>();
const hsl = { h: 0, s: 0, l: 0 };
const WHITE = new THREE.Color(0xffffff);
const WINDOW_LIGHT = new THREE.Color(0xffc45e);

/** The signed way round the wheel from one hue to another, in [-0.5, 0.5). */
function turn(from: number, to: number): number {
  return ((to - from + 1.5) % 1) - 0.5;
}

/** Mix a colour out of the paintbox: nearest anchor, then one band. */
function painted(colour: THREE.Color, palette: Palette): void {
  colour.getHSL(hsl);
  let nearest = palette.hues[0] ?? hsl.h;
  let shortest = 1;
  for (const hue of palette.hues) {
    const gap = Math.abs(turn(hsl.h, hue));
    if (gap < shortest) {
      shortest = gap;
      nearest = hue;
    }
  }
  colour.setHSL(
    (hsl.h + turn(hsl.h, nearest) * palette.pull + 1) % 1,
    Math.min(palette.saturation[1], Math.max(palette.saturation[0], hsl.s)),
    Math.min(palette.lightness[1], Math.max(palette.lightness[0], hsl.l)),
  );
}

function convert(base: THREE.MeshStandardMaterial, look: Look): THREE.Material {
  const colour = new THREE.Color(look.roles?.[base.name] ?? base.color);
  if (look.palette) painted(colour, look.palette);
  colour.getHSL(hsl);
  colour.setHSL(
    (hsl.h + look.tint.hue + 1) % 1,
    Math.min(1, hsl.s * look.tint.saturation),
    Math.min(1, Math.max(0, hsl.l + look.tint.lightness)),
  );
  colour.lerp(WHITE, look.tint.pastel);

  const emissive = base.emissive.clone();
  let emissiveIntensity = base.emissiveIntensity;
  if (look.night && (base.name === "glow" || base.name === "lamp")) {
    colour.copy(WINDOW_LIGHT);
    emissive.copy(WINDOW_LIGHT);
    emissiveIntensity = base.name === "lamp" ? 2.2 : 1.1;
  }

  const shared = {
    color: colour,
    map: base.map,
    side: base.side,
    emissive,
    emissiveIntensity,
  };
  const material =
    look.bands > 0
      ? toonMaterial({ ...shared, gradientMap: ramp })
      : new THREE.MeshStandardMaterial({
          ...shared,
          roughness: base.roughness,
          metalness: base.metalness,
          flatShading: base.flatShading,
        });
  material.name = base.name;
  return material;
}

/**
 * Swap every mesh's material for the look's version of it. The original stays
 * on `userData.base`, so restyling again (or to another look) never compounds.
 * Cheap to call every frame: meshes already in the look are skipped.
 */
export function restyle(root: THREE.Object3D, look: Look): void {
  // Bands and rim live in shared state, so they land even when no mesh changes.
  applyShade(look);
  root.traverse((node) => {
    if (!(node instanceof THREE.Mesh) || node.userData.look === look.key) return;
    const base = (node.userData.base ??= node.material) as THREE.Material;
    if (!(base instanceof THREE.MeshStandardMaterial)) return;
    let byLook = styled.get(base);
    if (!byLook) {
      byLook = new Map();
      styled.set(base, byLook);
    }
    let material = byLook.get(look.key);
    if (!material) {
      material = convert(base, look);
      byLook.set(look.key, material);
    }
    node.material = material;
    node.userData.look = look.key;
  });
}

/** Point the scene's sky, hemisphere and sun at the look. */
export function light(
  scene: THREE.Scene,
  hemi: THREE.HemisphereLight,
  sun: THREE.DirectionalLight,
  look: Look,
): void {
  scene.background = new THREE.Color(look.sky);
  if (scene.fog) scene.fog.color.set(look.sky);
  hemi.color.set(look.hemi[0]);
  hemi.groundColor.set(look.hemi[1]);
  hemi.intensity = look.hemi[2];
  sun.color.set(look.sun[0]);
  sun.intensity = look.sun[1];
}

// --- the frame ----------------------------------------------------------------

const surface = new THREE.ShaderMaterial({
  uniforms: { near: { value: 0 }, range: { value: 1 } },
  side: THREE.DoubleSide,
  vertexShader: /* glsl */ `
    #include <common>
    #include <batching_pars_vertex>
    varying vec3 vNormal;
    varying float vDepth;
    void main() {
      #include <batching_vertex>
      #include <beginnormal_vertex>
      #include <defaultnormal_vertex>
      #include <begin_vertex>
      #include <project_vertex>
      vNormal = normalize(transformedNormal);
      vDepth = -mvPosition.z;
    }
  `,
  fragmentShader: /* glsl */ `
    uniform float near;
    uniform float range;
    varying vec3 vNormal;
    varying float vDepth;
    void main() {
      vec3 n = normalize(vNormal);
      if (!gl_FrontFacing) n = -n;
      gl_FragColor = vec4(n * 0.5 + 0.5, (vDepth - near) / range);
    }
  `,
});

const composite = new THREE.ShaderMaterial({
  uniforms: {
    tColour: { value: null },
    tSurface: { value: null },
    size: { value: new THREE.Vector2(1, 1) },
    range: { value: 1 },
    footprint: { value: 0.1 },
    width: { value: 1 },
    strength: { value: 0 },
    inkColour: { value: new THREE.Color() },
    selfInk: { value: 0 },
    silhouette: { value: 1 },
    crease: { value: 0.85 },
    saturation: { value: 1 },
    contrast: { value: 1 },
    warmth: { value: 0 },
    posterize: { value: 0 },
    vignette: { value: 0 },
  },
  depthTest: false,
  depthWrite: false,
  vertexShader: /* glsl */ `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = vec4(position.xy, 0.0, 1.0);
    }
  `,
  fragmentShader: /* glsl */ `
    uniform sampler2D tColour;
    uniform sampler2D tSurface;
    uniform vec2 size;
    uniform float range;
    uniform float footprint;
    uniform float width;
    uniform float strength;
    uniform vec3 inkColour;
    uniform float selfInk;
    uniform float silhouette;
    uniform float crease;
    uniform float saturation;
    uniform float contrast;
    uniform float warmth;
    uniform float posterize;
    uniform float vignette;
    varying vec2 vUv;

    vec3 toSRGB(vec3 c) {
      c = max(c, vec3(0.0));
      return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
    }

    vec3 fromSRGB(vec3 c) {
      return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
    }

    void main() {
      // Snap to the art pixel, so a pixelated look samples one texel per block.
      vec2 uv = (floor(vUv * size) + 0.5) / size;
      vec3 colour = texture2D(tColour, uv).rgb;
      vec4 here = texture2D(tSurface, uv);
      vec3 normal = here.xyz * 2.0 - 1.0;
      float depth = here.w * range;

      float edge = 0.0;
      if (strength > 0.0) {
        // A neighbour farther than the ground's own slope means a silhouette;
        // a turned normal at the same depth means a crease.
        float slope = (footprint * width * 2.2 + 0.12) * silhouette;
        vec2 step = width / size;
        vec2 offsets[4];
        offsets[0] = vec2(step.x, 0.0);
        offsets[1] = vec2(-step.x, 0.0);
        offsets[2] = vec2(0.0, step.y);
        offsets[3] = vec2(0.0, -step.y);
        for (int k = 0; k < 4; k++) {
          vec4 there = texture2D(tSurface, uv + offsets[k]);
          float gap = there.w * range - depth;
          edge = max(edge, smoothstep(slope, slope * 1.6, gap));
          float turn = 1.0 - dot(normal, there.xyz * 2.0 - 1.0);
          if (crease > 0.0 && abs(gap) < slope * 3.0) edge = max(edge, smoothstep(0.35, 0.6, turn) * crease);
        }
      }

      vec3 ink = mix(inkColour, colour * vec3(0.32, 0.3, 0.36), selfInk);
      colour = mix(colour, ink, edge * strength);

      vec3 c = toSRGB(colour);
      float luma = dot(c, vec3(0.299, 0.587, 0.114));
      c = mix(vec3(luma), c, saturation);
      c = (c - 0.5) * contrast + 0.5;
      c *= vec3(1.0 + warmth * 0.06, 1.0 + warmth * 0.01, 1.0 - warmth * 0.07);
      if (posterize > 0.0) c = floor(c * posterize + 0.5) / posterize;
      vec2 centred = vUv - 0.5;
      c *= 1.0 - vignette * dot(centred, centred) * 1.6;
      gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
    }
  `,
});

/**
 * Draws a scene in a look: colour and normal-depth passes into render targets,
 * then one composite to the screen. Orthographic cameras only; both the game
 * and the lab use one.
 */
export class Ink {
  private renderer: THREE.WebGLRenderer;
  private colour: THREE.WebGLRenderTarget;
  private surface: THREE.WebGLRenderTarget;
  private quad: THREE.Mesh;
  private screen = new THREE.Scene();
  private flat = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  private look: Look = looks[0]!;

  constructor(renderer: THREE.WebGLRenderer) {
    this.renderer = renderer;
    this.colour = new THREE.WebGLRenderTarget(1, 1, { type: THREE.HalfFloatType, samples: 4 });
    this.surface = new THREE.WebGLRenderTarget(1, 1, {
      type: THREE.FloatType,
      minFilter: THREE.NearestFilter,
      magFilter: THREE.NearestFilter,
    });
    this.quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), composite);
    this.quad.frustumCulled = false;
    this.screen.add(this.quad);
  }

  setLook(look: Look): void {
    this.look = look;
    const ink = look.ink;
    const uniforms = composite.uniforms;
    uniforms.strength!.value = ink ? ink.strength : 0;
    uniforms.selfInk!.value = ink && ink.colour === null ? 1 : 0;
    if (ink && ink.colour !== null) (uniforms.inkColour!.value as THREE.Color).set(ink.colour);
    uniforms.silhouette!.value = ink ? ink.silhouette : 1;
    uniforms.crease!.value = ink ? ink.crease : 0;
    uniforms.saturation!.value = look.grade.saturation;
    uniforms.contrast!.value = look.grade.contrast;
    uniforms.warmth!.value = look.grade.warmth;
    uniforms.posterize!.value = look.grade.posterize;
    uniforms.vignette!.value = look.grade.vignette;
    const filter = look.pixel > 1 ? THREE.NearestFilter : THREE.LinearFilter;
    this.colour.texture.minFilter = this.colour.texture.magFilter = filter;
    this.colour.texture.needsUpdate = true;
    this.colour.samples = look.pixel > 1 ? 0 : 4;
    this.resize();
  }

  /** Match the targets to the canvas; call after `renderer.setSize`. */
  resize(): void {
    const buffer = this.renderer.getDrawingBufferSize(new THREE.Vector2());
    const block = this.look.pixel > 1 ? this.look.pixel * this.renderer.getPixelRatio() : 1;
    const width = Math.max(1, Math.floor(buffer.x / block));
    const height = Math.max(1, Math.floor(buffer.y / block));
    if (this.colour.width !== width || this.colour.height !== height) {
      this.colour.dispose();
      this.surface.dispose();
      this.colour.setSize(width, height);
      this.surface.setSize(width, height);
    }
    (composite.uniforms.size!.value as THREE.Vector2).set(width, height);
    const ink = this.look.ink;
    const scale = this.look.pixel > 1 ? 1 : this.renderer.getPixelRatio();
    composite.uniforms.width!.value = ink ? Math.max(1, ink.width * scale) : 1;
  }

  render(scene: THREE.Scene, camera: THREE.OrthographicCamera): void {
    const renderer = this.renderer;
    renderer.setRenderTarget(this.colour);
    renderer.render(scene, camera);

    if (this.look.ink) {
      const background = scene.background;
      const fog = scene.fog;
      const clear = renderer.getClearColor(new THREE.Color());
      const alpha = renderer.getClearAlpha();
      scene.background = null;
      scene.fog = null;
      scene.overrideMaterial = surface;
      renderer.shadowMap.autoUpdate = false;
      renderer.setClearColor(0x8080ff, 1);
      surface.uniforms.near!.value = camera.near;
      surface.uniforms.range!.value = camera.far - camera.near;
      renderer.setRenderTarget(this.surface);
      renderer.render(scene, camera);
      renderer.shadowMap.autoUpdate = true;
      renderer.setClearColor(clear, alpha);
      scene.overrideMaterial = null;
      scene.background = background;
      scene.fog = fog;
    }

    const uniforms = composite.uniforms;
    uniforms.tColour!.value = this.colour.texture;
    uniforms.tSurface!.value = this.surface.texture;
    uniforms.range!.value = camera.far - camera.near;
    uniforms.footprint!.value = (camera.top - camera.bottom) / camera.zoom / this.colour.height;
    renderer.setRenderTarget(null);
    renderer.render(this.screen, this.flat);
  }
}
