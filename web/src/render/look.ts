import * as THREE from "three";

/**
 * Looks: one city, several art directions. A look restyles every material by
 * its role (toon bands, palette shift, lit windows at night) and sets the
 * light; `Ink` then draws the frame with outlines from a normal-and-depth
 * pass, optional pixelation, and a colour grade. Nothing here is a rule.
 */

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
  /** Outline colour, or null to ink each surface in a darker shade of itself. */
  ink: { colour: number | null; width: number; strength: number } | null;
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
    key: "komik",
    name: "Komik",
    sky: 0x86dcff,
    hemi: [0xe6f6ff, 0x9c8f70, 1.7],
    sun: [0xfff4dc, 2.3],
    sunFrom: [-0.8, 2, 1],
    bands: 3,
    tint: { saturation: 1.1, lightness: 0.02, hue: 0, pastel: 0 },
    ink: { colour: 0x1c2040, width: 1.6, strength: 1 },
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
    ink: { colour: 0x262a33, width: 1, strength: 0.85 },
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
    ink: { colour: 0x5b2c33, width: 1.4, strength: 0.75 },
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
    ink: { colour: null, width: 1.8, strength: 1 },
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
    ink: { colour: 0x0a0d22, width: 1.4, strength: 0.9 },
    pixel: 1,
    grade: { saturation: 1.12, contrast: 1.06, warmth: -0.2, posterize: 0, vignette: 0.35 },
    night: true,
  },
];

export function lookByKey(key: string | null | undefined): Look {
  return looks.find((look) => look.key === key) ?? looks[0]!;
}

// --- materials ----------------------------------------------------------------

const gradients = new Map<number, THREE.DataTexture>();

function gradient(bands: number): THREE.DataTexture {
  const found = gradients.get(bands);
  if (found) return found;
  const steps: Record<number, number[]> = {
    2: [170, 255],
    3: [95, 180, 255],
    4: [80, 145, 205, 255],
  };
  const values = steps[bands] ?? steps[3]!;
  const data = new Uint8Array(values.length * 4);
  values.forEach((value, k) => data.set([value, value, value, 255], k * 4));
  const texture = new THREE.DataTexture(data, values.length, 1, THREE.RGBAFormat);
  texture.minFilter = THREE.NearestFilter;
  texture.magFilter = THREE.NearestFilter;
  texture.needsUpdate = true;
  gradients.set(bands, texture);
  return texture;
}

const styled = new WeakMap<THREE.Material, Map<string, THREE.Material>>();
const hsl = { h: 0, s: 0, l: 0 };
const WHITE = new THREE.Color(0xffffff);
const WINDOW_LIGHT = new THREE.Color(0xffc45e);

function convert(base: THREE.MeshStandardMaterial, look: Look): THREE.Material {
  const colour = base.color.clone();
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
      ? new THREE.MeshToonMaterial({ ...shared, gradientMap: gradient(look.bands) })
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
    varying vec3 vNormal;
    varying float vDepth;
    void main() {
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
        float slope = footprint * width * 2.2 + 0.12;
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
          if (abs(gap) < slope * 3.0) edge = max(edge, smoothstep(0.35, 0.6, turn) * 0.85);
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
