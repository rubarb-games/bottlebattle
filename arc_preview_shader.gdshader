shader_type canvas_item;

uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform float progress_2 : hint_range(0.0,1.0) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.0);
uniform vec4 secondary_color : source_color = vec4(1.0);
uniform vec4 tint_color : source_color = vec4(1.0);
uniform bool invert = false;

uniform float start_angle = 0.0;

bool do_slice(vec2 uv,float p) {
vec2 uv_remap = uv * 2.0 - 1.0;
	
	//Polar coordinates
	float angle = atan(uv_remap.y, uv_remap.x);
	float radius = length(uv_remap);
	
	if (angle < 0.0) {
		angle += 6.2831853;
	}
	
	float half_arc = p * 3.141519265;
	float base = mod(start_angle,6.2831853);
	float diff = abs(angle - base);
	
	if (diff > 3.14151926535897) {
		diff = 6.2831853 - diff;
	}
	
	if (diff <= half_arc) {
		return true;
	} else {
		return false;
	}
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV * 2.0 - 1.0;
	
	//Polar coordinates
	float angle = atan(uv.y, uv.x);
	float radius = length(uv);
	
	bool main_slice = do_slice(UV,progress);
	bool secondary_slice = do_slice(UV,progress_2);
	
	if (main_slice) {
		COLOR = texture(TEXTURE,UV) * tint_color;
		if (secondary_slice) {
		COLOR *= secondary_color;
		}
	} else {
		COLOR = wipe_color;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
