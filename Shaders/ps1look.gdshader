shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture, repeat_disable, filter_nearest; 

uniform vec2 viewport_size = vec2(320,240);
uniform vec2 virtual_res = vec2(320,240);

const float dither[16] = float[16](
	-4.0,  0.0, -3.0,  1.0,
	 2.0, -2.0,  3.0, -1.0,
	-3.0,  1.0, -4.0,  0.0, 
	 3.0, -1.0,  2.0, -2.0
);


void fragment() {
	vec3 screen_color = texture(screen_tex, UV).rgb;
	
	int x = int(FRAGCOORD.x) % 4;
	int y = int(FRAGCOORD.y) % 4;
	int index = y * 4 + x;
	
	float dither_offset = (dither[index] / 8.0);
	
	vec3 quantized_color = floor((screen_color * 255.0) / 8.0 + dither_offset) /31.0;
	
	COLOR = vec4(quantized_color,1);
}
