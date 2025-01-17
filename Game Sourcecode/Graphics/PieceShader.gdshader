shader_type canvas_item;

uniform vec4 new_color : source_color;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    if (tex_color.rgb == vec3(1.0, 1.0, 1.0) && tex_color.a > 0.0) {
        COLOR = vec4(new_color.rgb, tex_color.a);
    } else {
        COLOR = tex_color;
    }
}
