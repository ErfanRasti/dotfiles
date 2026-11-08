// Liquid glass border.
// The compositor supplies main(), precision, uniforms and the helpers:
//   umbriel_sample(uv)          -> the native border ring (premultiplied, focused/unfocused colour)
//   umbriel_border_distance(uv) -> signed distance in logical px to the window rect (<0 inside)
// The window's own pixels are cut out of the result, so contents stay untouched.
//
// Border effects apply to the focused window, and this effect paints the padded area around it,
// where the drop shadow falls. So only the 2 px ring gets the glass look; outside it the native
// pixels pass through unchanged, and if that area is empty a matching soft shadow is drawn
// (a tight soft shadow in colors.shadow's strength), so focused windows keep their shadow.

// ---- tunables -------------------------------------------------------------
const float RING_W       = 2.0;   // px: border width (appearance.border_width)
const float RING_LIFT    = 0.45;  // how much the lit side of the ring brightens toward white
const float RING_BASE    = 0.12;  // brightening on the side away from the light
const float SPEC_WIDTH   = 1.1;   // px: specular hairline at the window edge
const float SPEC_GAIN    = 0.55;  // hairline strength
const vec2  LIGHT_DIR    = vec2(-0.6, -0.8); // light from the top-left
const float SHADOW_ALPHA = 0.44;  // colors.shadow alpha (#00000070)
const float SHADOW_SOFT  = 6.0;   // px: how far the shadow fades out
const vec2  SHADOW_OFF   = vec2(0.0, 3.0); // px: shadow offset (down)

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

  vec4 native = umbriel_sample(uv);        // premultiplied

  // Outside the ring: keep the native pixels (the shadow), or draw a matching one if empty.
  if (d > RING_W + 0.5) {
    if (native.a > 0.01) return native;
    float ds = umbriel_border_distance(uv - SHADOW_OFF / umbriel_size);
    float s = clamp(1.0 - max(ds, 0.0) / SHADOW_SOFT, 0.0, 1.0);
    return vec4(0.0, 0.0, 0.0, SHADOW_ALPHA * s * s);
  }

  // The ring itself: lift toward white on the lit side, plus a specular hairline.
  vec2 n = outward_normal(uv);
  float facing = clamp(dot(n, normalize(LIGHT_DIR)), 0.0, 1.0);
  float lift = RING_BASE + RING_LIFT * facing;
  vec4 c = vec4(mix(native.rgb, vec3(native.a), lift), native.a);
  float spec = exp(-d / SPEC_WIDTH) * SPEC_GAIN * (0.25 + 0.75 * facing);
  return vec4(vec3(spec) + c.rgb * (1.0 - spec), spec + c.a * (1.0 - spec));
}
