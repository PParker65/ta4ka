import * as THREE from 'three';

/** CRT look: scanlines, noise, barrel warp, green phosphor. */
export const CRTShader = {
  uniforms: {
    tDiffuse: { value: null },
    uTime: { value: 0 },
    uResolution: { value: new THREE.Vector2(176, 120) },
  },
  vertexShader: /* glsl */ `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: /* glsl */ `
    uniform sampler2D tDiffuse;
    uniform float uTime;
    uniform vec2 uResolution;
    varying vec2 vUv;

    float hash(vec2 p) {
      return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
    }

    vec2 barrel(vec2 uv) {
      vec2 c = uv * 2.0 - 1.0;
      float r2 = dot(c, c);
      c *= 1.0 + 0.12 * r2;
      return c * 0.5 + 0.5;
    }

    void main() {
      vec2 uv = barrel(vUv);
      if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.02, 0.0, 1.0);
        return;
      }
      float chroma = 0.0028;
      float r = texture2D(tDiffuse, uv + vec2(chroma, 0.0)).r;
      float g = texture2D(tDiffuse, uv).g;
      float b = texture2D(tDiffuse, uv - vec2(chroma, 0.0)).b;
      vec3 col = vec3(r, g, b);
      float luma = dot(col, vec3(0.299, 0.587, 0.114));
      col = mix(vec3(luma), col, 0.25);
      col = vec3(col.g * 0.35, luma * 1.15, col.g * 0.28);
      float scan = 0.82 + 0.18 * sin(uv.y * uResolution.y * 3.14159);
      float roll = 0.92 + 0.08 * sin(uv.y * 28.0 + uTime * 6.0);
      float n = hash(vec2(uv.x * 240.0, uv.y * 180.0 + uTime * 18.0)) * 0.14;
      float vig = smoothstep(1.15, 0.25, length(vUv - 0.5));
      col *= scan * roll * vig;
      col += n;
      gl_FragColor = vec4(col, 1.0);
    }
  `,
};

export function createCrtMaterial(map) {
  const mat = new THREE.ShaderMaterial({
    uniforms: THREE.UniformsUtils.clone(CRTShader.uniforms),
    vertexShader: CRTShader.vertexShader,
    fragmentShader: CRTShader.fragmentShader,
  });
  mat.uniforms.tDiffuse.value = map;
  mat.toneMapped = false;
  return mat;
}
