// A locked island's picture in 섬 고르기 (IslandCards, #75): its colours to grey, a little of `tint`
// (a cool blue-grey) mixed in.
shader_type canvas_item;

uniform vec4 tint : source_color;
uniform float tint_share = 0.35;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(g), tint.rgb, tint_share), c.a);
}
