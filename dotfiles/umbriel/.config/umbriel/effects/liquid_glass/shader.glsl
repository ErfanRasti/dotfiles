// Liquid glass window sheen. Tune these:
const float RIM_PX       = 7.0;   // width of the specular rim (logical px)
const float RIM_LIGHT    = 0.22;  // rim brightness on the lit (top-left) side
const float RIM_BASE     = 0.05;  // rim brightness on the far side
const float SHADE        = 0.10;  // inner shade on the bottom-right edge
const float GLOSS        = 0.035; // gloss across the top of the window
const float GLOSS_HEIGHT = 0.30;  // gloss fades out over this fraction of the height
const float EDGE_THIN    = 0.12;  // how much alpha drops at the very edge (blur shows through)
const float EDGE_THIN_PX = 16.0;  // width of that thinning
const vec2  LIGHT_DIR    = vec2(-0.6, -0.8); // light from the top-left

// Signed distance (logical px) to the rounded window edge: negative inside.
float edge_distance(vec2 uv) {
  vec2 half_size = umbriel_size * 0.5;
  vec2 p = uv * umbriel_size - half_size;
  float r = p.y < 0.0 ? (p.x < 0.0 ? umbriel_corner_radius.x : umbriel_corner_radius.y)
                      : (p.x < 0.0 ? umbriel_corner_radius.w : umbriel_corner_radius.z);
  r = min(r, min(half_size.x, half_size.y));
  vec2 q = abs(p) - half_size + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 window(vec2 uv) {
  vec4 c = umbriel_sample(uv);          // premultiplied
  if (c.a <= 0.0) return c;

  float e = max(-edge_distance(uv), 0.0);   // px inside the edge
  vec2 p = uv * umbriel_size - umbriel_size * 0.5;
  // Which side of the window this pixel is on, relative to the light (1 = facing it).
  vec2 n = p / max(umbriel_size * 0.5, vec2(1.0));
  float facing = clamp(dot(normalize(n + 1e-5), normalize(LIGHT_DIR)) * 0.5 + 0.5, 0.0, 1.0);

  float rim = exp(-e / RIM_PX);
  float light = rim * mix(RIM_BASE, RIM_LIGHT, facing * facing)
              + GLOSS * smoothstep(GLOSS_HEIGHT, 0.0, uv.y);
  float shade = rim * SHADE * (1.0 - facing);

  vec3 rgb = c.rgb * (1.0 - shade);
  rgb = mix(rgb, vec3(c.a), clamp(light, 0.0, 1.0));   // lift toward white (premultiplied)

  float thin = 1.0 - EDGE_THIN * exp(-e / EDGE_THIN_PX);
  return vec4(rgb, c.a) * thin;
}
