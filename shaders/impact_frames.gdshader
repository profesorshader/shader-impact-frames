shader_type canvas_item;

#define USE_RADIAL_MODE 0

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable;

uniform float t : hint_range(0.0, 1.0) = 1.0;
uniform float half_position : hint_range(0.1, 0.9) = 0.5;
uniform vec3 flash_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D grad_tex : repeat_disable; // use a gradient textura 1D
uniform sampler2D noise_tex : repeat_enable;
uniform float power = 3.0;
uniform float speed_v = 0.1;
uniform float dist_strength = 1.0; 

#if USE_RADIAL_MODE	
uniform vec2  radial_center = vec2(0.5);
uniform float radial_zoom = 0.01;
uniform float radial_repeat = 10.0;
uniform float radial_min : hint_range(0.0, 1.0) = 0.5; // multiplier for line length at the center
uniform float radial_max : hint_range(0.0, 1.0) = 1.0; // multiplier for line length at the edges
#else
uniform float speed_u = 0.1;
uniform float rot_angle = 0.0;
uniform float scale_u = 0.01;
uniform float scale_v = 4.0;
#endif

#if USE_RADIAL_MODE
// taken from godotshaders.com :) (but, a bit modified)
vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat, float offset)
{
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/TAU;
	return mod(vec2(radius * zoom - offset, angle * repeat), 1.0);
}
#else
vec2 rotate_uv(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}
#endif 

void fragment() {	
	// output
	if (t < half_position)
	{
		// sample screen texture
		vec4 scr = texture(screen_tex, SCREEN_UV);		
		
		// just flash
		COLOR.rgb = mix(scr.rgb, flash_color.rgb, smoothstep(0.0, half_position, t));	
	}
	else 
	{
		float tv = TIME * speed_v;		
		
#if USE_RADIAL_MODE	
		// compute distortion direction
		vec2 dir = -(SCREEN_UV - radial_center);
		// compute noise UVs
		vec2 src_uv = polar_coordinates(vec2(SCREEN_UV.x, UV.y), radial_center, radial_zoom, radial_repeat, tv);	
#else
		// compute distortion direction
		float ang = radians(rot_angle);
		vec2 dir = vec2(sin(ang), -cos(ang));
		// compute noise UVs
		vec2 src_uv = rotate_uv(UV, vec2(0.5), ang);
		src_uv = vec2(src_uv.x * scale_u + TIME * speed_u, src_uv.y * scale_v + tv);	
#endif

		// sample noise texture
		float noi_val = texture(noise_tex, src_uv).r;	

		// convert noise val from 0..1 to -1..1
		noi_val = (noi_val * 2.0) - 1.0;		

		// apply power
		noi_val = sign(noi_val) * pow(abs(noi_val), power);		
		
		// compute distortion vector
#if USE_RADIAL_MODE		
		// apply radial distance adjustment
		float vig_mask = mix(radial_min, radial_max, length(dir));
		float dist_val = noi_val * dist_strength * vig_mask;
#else
		float dist_val = noi_val * dist_strength;
#endif		

		vec2 dist_vec = dir * dist_val;
		vec2 distorted_uvs = SCREEN_UV + dist_vec;

		// sample screen texture
		vec4 scr = texture(screen_tex, distorted_uvs);		
		
		// apply color grad
		float gray = dot(scr.rgb, vec3(0.299, 0.587, 0.114)); // luminance weights
		vec3 final_impact = texture(grad_tex, vec2(gray, 0.5)).rgb; // apply gradient
		
		// flash
		COLOR.rgb = mix(flash_color.rgb, final_impact.rgb, smoothstep(half_position, 1.0, t));			
	}	
}
