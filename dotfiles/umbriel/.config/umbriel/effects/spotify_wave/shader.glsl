// Source: https://gist.github.com/acous/0e3ae193232cdaffbdeb1ea34c652e50 (by acous).
// Local changes: waves on the left/right edges only, along a band shifted up from the middle
// (top/bottom are covered by the bar and dock), line resting on the border with waves pushing
// outward only, and
// the trace is clamped so it stays inside the effect padding; keeps the window shadow.
// 64-band additive standing-wave border oscilloscope for Umbriel compositor.

const vec4  EDGE_MASK    = vec4(0.0, 0.0, 1.0, 1.0); // (bottom, top, left, right)
const float BASELINE_PX  = 1.0;   // resting line: flush against the border, no gap
const float MAX_PX       = 11.0;  // never draw the line further out than this
const float AMPLITUDE_PX = 2.8;   // waves push outward from the border
const float V_SHIFT      = 0.15;  // side-wave band centre, as a fraction above the middle
const float V_SPAN       = 0.70;  // side-wave band half-height, as a fraction of the window

vec4 border(vec2 uv) {
  float d = max(umbriel_border_distance(uv), 0.0);
  vec4 native = umbriel_sample(uv);
  // Keep the window shadow when the native border area comes in empty.
  if (native.a <= 0.01) {
    float ds = max(umbriel_border_distance(uv - vec2(0.0, 3.0) / umbriel_size), 0.0);
    float s = clamp(1.0 - ds / 6.0, 0.0, 1.0);
    native = vec4(0.0, 0.0, 0.0, 0.44 * s * s);
  }

  // Inner window half-extents and center-relative fragment coords in logical px
  vec2 win_half = max(umbriel_border_hole.zw * umbriel_size * 0.5, vec2(1.0));
  vec2 p = (uv - (umbriel_border_hole.xy + umbriel_border_hole.zw * 0.5)) * umbriel_size;

  // Raised-cosine-like bell envelopes (1 - x^2)^2 along horizontal and vertical spans
  vec2 uv_norm = clamp(p / win_half, -1.0, 1.0);
  vec2 bell = 1.0 - uv_norm * uv_norm;
  bell *= bell;

  // Side waves: only along a band shifted up from the middle, so they stay clear of the bar
  // (top) and the dock (bottom). V_SHIFT moves the band up, V_SPAN sets its height.
  float vy = clamp((uv_norm.y + V_SHIFT) / V_SPAN, -1.0, 1.0);
  bell.y = (1.0 - vy * vy) * (1.0 - vy * vy);

  // Vectorized edge masks: (bottom, top, left, right)
  vec4 edge_step_masks = smoothstep(win_half.yyxx - 4.0, win_half.yyxx, vec4(p.y, -p.y, -p.x, p.x));
  float edge_envelope = clamp(dot(EDGE_MASK, edge_step_masks * bell.xxyy), 0.0, 1.0);

  // Early-out for static border segments: skip 64-band synthesis loop completely
  // when the envelope is zero (e.g. top, left, right edges & corners) or audio is idle.
  float trace_d = BASELINE_PX;
  float edge_slope = 0.0;
  float local_loudness = 0.0;
  float high_mod = 0.0;

  if (edge_envelope > 1e-3 && umbriel_audio_available() > 0.5) {
    bool is_horiz = (abs(p.y) - win_half.y) >= (abs(p.x) - win_half.x);
    float px_coord = is_horiz ? p.x : p.y;
    float t = umbriel_time;

    float wave_sum   = 0.0;
    float slope_sum  = 0.0;
    float energy_sum = 0.0;
    float high_sum   = 0.0;
    float peak_band  = 0.0;

    // Strength-reduced recurrence for k_i = 0.024 * exp(i/63 * 4.828) -> 1 MUL/iter instead of exp()
    float k_i = 0.024;
    const float K_STEP = 1.0796488; // exp(4.828 / 63.0)
    const float INV_63 = 1.0 / 63.0;

    for (int i = 0; i < 64; i++) {
      float fi = float(i);
      float norm_i = fi * INV_63;
      float root_n = sqrt(norm_i);

      float raw = umbriel_audio_entry(fi);
      float tilt = 2.0 + 0.8 * (norm_i * norm_i);
      float x = clamp((raw * tilt - 0.035) * 1.25, 0.0, 1.5);

      // Algebraic x^2.125 (x^2 * x^0.125) and norm_i^1.5 -> avoids two pow() (exp2/log2) calls per iter
      float x2 = x * x;
      float amp = x2 * sqrt(sqrt(sqrt(x)));
      float a = amp * (1.15 - 0.70 * root_n);

      float w_i = 8.0 + 57.0 * norm_i * root_n;
      float s_pos  = k_i * px_coord + fi * 2.3999632;
      float c_time = cos(w_i * t + fi * 1.6180339);

      wave_sum   += a * sin(s_pos) * c_time;
      slope_sum  += a * k_i * cos(s_pos) * c_time;
      energy_sum += a * a;
      high_sum   += a * norm_i;
      peak_band   = max(peak_band, a);

      k_i *= K_STEP;
    }

    // Hardware rsqrt (`inversesqrt`) replaces 1.0 / sqrt(...)
    float rms_env = edge_envelope * inversesqrt(max(energy_sum * 0.4225, 1.0));
    trace_d = clamp(trace_d + abs(wave_sum * rms_env) * AMPLITUDE_PX, BASELINE_PX, MAX_PX);
    edge_slope = slope_sum * rms_env * 1.25;
    local_loudness = clamp(max(peak_band, sqrt(energy_sum) * 0.42), 0.0, 1.35) * edge_envelope;
    high_mod = high_sum * 0.06 * edge_envelope;
  }

  float line_dist = abs(d - trace_d);
  float corrected_dist = line_dist * clamp(inversesqrt(1.0 + edge_slope * edge_slope), 0.2857, 1.0);

  float trace = smoothstep(1.75, 0.30, corrected_dist);
  float glow  = exp(-line_dist / (3.0 + 5.0 * local_loudness))
              * (0.15 + 0.85 * min(local_loudness, 1.0));

  float palette_pos = clamp(local_loudness * 0.35 + high_mod, 0.0, 0.70);
  vec4 base_palette = umbriel_palette_count > 0
      ? umbriel_palette_at(palette_pos)
      : vec4(0.60, 0.71, 0.95, 1.0);

  vec3 beam_rgb = mix(base_palette.rgb, vec3(1.0), trace * (0.25 + 0.50 * min(local_loudness, 1.0)));
  float intensity = min(trace + glow, 1.0);
  return mix(native, vec4(beam_rgb, 1.0), intensity) * max(native.a, intensity);
}

