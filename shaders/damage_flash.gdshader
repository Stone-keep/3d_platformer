shader_type spatial;

render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec3 flash_color : source_color = vec3(1.0, 0.25, 0.15);
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = flash_color;
	ALPHA = flash_strength;
}
