shader_type spatial;
render_mode blend_mix,
cull_disabled,
depth_prepass_alpha,
shadows_disabled,
specular_disabled,
vertex_lighting;

uniform sampler2D base_tex: source_color ,filter_nearest;
uniform bool use_rAS_ALPHA = false;
uniform vec2 texture_tile = vec2(1,1);

uniform bool snap_enabled = true;
uniform float snap_res : hint_range(60.0, 480.0, 1) = 128; //smaller value more jitter

void vertex() {
	vec4 view_space_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_space_pos = PROJECTION_MATRIX * view_space_pos;
	
	if (snap_enabled){
		vec2 ndc = clip_space_pos.xy / clip_space_pos.w;
		ndc = round(ndc * snap_res) / snap_res;
		clip_space_pos.xy = ndc * clip_space_pos.w;
	}
	POSITION = clip_space_pos;
}

void fragment() {
	vec4 base = texture(base_tex,UV * texture_tile);
	ALBEDO = vec3(0,0,0);
	
	if (use_rAS_ALPHA == true) {
		ALPHA = base.r;
	} else if (use_rAS_ALPHA == false) {
		ALPHA = base.a;
	}
	
}
