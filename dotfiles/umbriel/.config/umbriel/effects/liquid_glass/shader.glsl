// Liquid glass border.
// The compositor supplies main(), precision, uniforms and the helpers:
//   umbriel_sample(uv)          -> the native border ring (premultiplied, focused/unfocused colour)
//   umbriel_border_distance(uv) -> signed distance in logical px to the window rect (<0 inside)
// The window's own pixels are cut out of the result, so contents stay untouched.

// ---- tunables -------------------------------------------------------------
const float RING_LIFT    = 0.45;  // how much the lit side of the ring brightens toward white
const float RING_BASE    = 0.12;  // brightening on the side away from the light
const float SPEC_WIDTH   = 1.1;   // px: specular hairline just outside the edge
const float SPEC_GAIN    = 0.55;  // hairline strength
const float HALO_WIDTH   = 5.0;   // px: falloff of the soft outer halo
const float HALO_GAIN    = 0.16;  // halo strength
const vec2  LIGHT_DIR    = vec2(-0.6, -0.8); // light from the top-left

vec2 outward_normal(vec2 uv) {
  vec2 e = vec2(1.0) / umbriel_size;
  vec2 g = vec2(umbriel_border_distance(uv + vec2(e.x, 0.0)) - umbriel_border_distance(uv - vec2(e.x, 0.0)),
                umbriel_border_distance(uv + vec2(0.0, e.y)) - umbriel_border_distance(uv - vec2(0.0, e.y)));
  float len = length(g);
  return len > 1e-4 ? g / len : vec2(0.0);
}

vec4 border(vec2 uv) {
  float d = umbriel_border_distance(uv);   // > 0 outside the window
  if (d < 0.0) return vec4(0.0);           // never draw over the window itself

  vec4 ring = umbriel_sample(uv);          // native ring, premultiplied
  vec2 n = outward_normal(uv);
  float facing = clamp(dot(n, normalize(LIGHT_DIR)), 0.0, 1.0);

  // Glass ring: lift the native colour toward white, more on the lit side.
  float lift = RING_BASE + RING_LIFT * facing;
  vec3 rim = mix(ring.rgb, vec3(ring.a), lift);

  // Specular hairline right at the window edge on the lit side.
  float spec = exp(-d / SPEC_WIDTH) * SPEC_GAIN * (0.25 + 0.75 * facing);

  // Soft halo fading into the padding (only outside the ring).
  float halo = exp(-d / HALO_WIDTH) * HALO_GAIN * (0.4 + 0.6 * facing) * (1.0 - ring.a);

  float add = spec + halo;
  vec4 c = vec4(rim, ring.a);
  // Premultiplied "over": light on top of the ring.
  c = vec4(vec3(add) + c.rgb * (1.0 - add), add + c.a * (1.0 - add));
  return c;
}
