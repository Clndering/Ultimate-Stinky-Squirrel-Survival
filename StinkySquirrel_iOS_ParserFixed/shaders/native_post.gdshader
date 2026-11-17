shader_type canvas_item;
render_mode unshaded;
// Godot 4.7 CanvasItem screen-reading shader. Runs only when at least one shader FX is enabled.
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float fx_god_rays = 0.0;
uniform float fx_bloom = 0.0;
uniform float fx_fog = 0.0;
uniform float fx_ssao = 0.0;
uniform float fx_color_grade = 0.0;
uniform float fx_vignette = 0.0;
uniform float fx_tonemap = 0.0;
uniform float fx_chromatic = 0.0;
uniform float fx_dof = 0.0;
uniform float fx_motion_blur = 0.0;
uniform float fx_outlines = 0.0;
uniform float fx_lens_flare = 0.0;
uniform float fx_grain = 0.0;
uniform float fx_aa = 0.0;
uniform float u_time = 0.0;
uniform float u_day = 0.25;
uniform float u_weather = 0.0;
uniform vec2 u_motion = vec2(0.0,0.0);

float luminance(vec3 color) { return dot(color,vec3(0.2126,0.7152,0.0722)); }
float random_float(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453); }
vec3 original(vec2 at) { return texture(screen_tex,clamp(at,vec2(0.001),vec2(0.999))).rgb; }
void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 px = SCREEN_PIXEL_SIZE;
    vec3 c = original(uv);
    // FAST PATH: individual conditional branches avoid their texture fetches when off.
    if(fx_outlines > 0.001 || fx_ssao > 0.001) {
        vec3 n = original(uv + vec2(0.0,-px.y));
        vec3 s = original(uv + vec2(0.0,px.y));
        vec3 e = original(uv + vec2(px.x,0.0));
        vec3 w = original(uv + vec2(-px.x,0.0));
        float near_edge = clamp((abs(luminance(c)-luminance(n))+abs(luminance(c)-luminance(s))+abs(luminance(c)-luminance(e))+abs(luminance(c)-luminance(w))) * 2.2,0.0,1.0);
        if(fx_outlines > 0.001) { c *= 1.0 - near_edge * fx_outlines * 0.19; }
        if(fx_ssao > 0.001) { c *= 1.0 - near_edge * fx_ssao * 0.11; }
    }
    if(fx_chromatic > 0.001) {
        vec2 offset = (uv-vec2(0.5)) * px * 4.0 * fx_chromatic;
        c.r = original(uv + offset).r;
        c.b = original(uv - offset).b;
    }
    if(fx_bloom > 0.001) {
        vec3 highlights = vec3(0.0);
        vec2 d = px * 4.0;
        vec3 a = original(uv+vec2(d.x,0.0));
        vec3 b = original(uv-vec2(d.x,0.0));
        vec3 v = original(uv+vec2(0.0,d.y));
        vec3 z = original(uv-vec2(0.0,d.y));
        highlights += a * smoothstep(0.52,0.95,luminance(a));
        highlights += b * smoothstep(0.52,0.95,luminance(b));
        highlights += v * smoothstep(0.52,0.95,luminance(v));
        highlights += z * smoothstep(0.52,0.95,luminance(z));
        c += highlights * 0.08 * fx_bloom;
    }
    if(fx_god_rays > 0.001) {
        // Six occluded samples, not the 40+ samples of an expensive radial shader.
        vec2 sun = vec2(0.16+0.69*u_day,0.04);
        vec2 direction = sun-uv;
        float light = 0.0;
        for(int i=1;i<=6;i++) {
            vec3 sample_color = original(uv + direction * (float(i)/12.0));
            light += smoothstep(0.32,0.84,luminance(sample_color));
        }
        float daytime = smoothstep(0.02,0.21,abs(sin(u_day*6.2831853)));
        c += vec3(1.0,0.81,0.50)*light*(fx_god_rays*0.009)*daytime*(1.0-u_weather*0.7);
    }
    if(fx_fog > 0.001) {
        float fog_depth = pow(1.0-uv.y,1.7);
        float drift = 0.80+0.20*sin(uv.x*11.0+u_time*0.35);
        c = mix(c,vec3(0.50,0.68,0.68),fx_fog*0.14*fog_depth*drift*(1.0+u_weather));
    }
    if(fx_lens_flare > 0.001) {
        vec2 sun = vec2(0.16+0.69*u_day,0.04);
        float halo = exp(-length((uv-sun)*vec2(1.0,1.4))*34.0);
        float ghost = exp(-length((uv-(vec2(1.0)-sun))*vec2(1.0,1.4))*22.0);
        float streak = exp(-abs(uv.y-sun.y)*140.0) * exp(-abs(uv.x-sun.x)*1.8);
        c += vec3(1.0,0.83,0.58)*(halo*.22+ghost*.045+streak*.026)*fx_lens_flare*(1.0-u_weather*0.85);
    }
    if(fx_color_grade > 0.001) {
        float is_night = clamp(0.5+0.5*cos(u_day*6.2831853),0.0,1.0);
        vec3 tint = mix(vec3(1.06,0.99,0.89),vec3(0.75,0.89,1.08),is_night);
        c = mix(c,c*tint,fx_color_grade*0.7);
    }
    if(fx_tonemap > 0.001) {
        vec3 film = clamp((c*(2.51*c+vec3(0.03)))/(c*(2.43*c+vec3(0.59))+vec3(0.14)),vec3(0.0),vec3(1.0));
        c = mix(c,film,fx_tonemap);
    }
    if(fx_vignette > 0.001) {
        float q = smoothstep(0.24,0.76,distance(uv,vec2(0.5,0.49)));
        c *= 1.0-q*fx_vignette*0.35;
    }
    if(fx_grain > 0.001) {
        float noise = random_float(floor(uv/px)+floor(u_time*20.0));
        c += vec3((noise-0.5)*fx_grain*0.065);
    }
    COLOR = vec4(clamp(c,vec3(0.0),vec3(1.0)),1.0);
}
