shader_type canvas_item;

// --- PARÁMETROS AJUSTABLES DEL MAESTRO CRISTAL ---

// -- 1. Capa de Desenfoque (Blur) --
uniform float blur_radius : hint_range(0.0, 64.0) = 32.0; // Nivel de esmerilado
uniform float depth_of_field : hint_range(0.0, 2.0) = 0.3; // Simula que el fondo está más lejos

// -- 2. Capa de Tinte y Profundidad --
uniform vec4 glass_tint : source_color = vec4(0.7, 0.85, 1.0, 0.25); // Tinte azulado/blanco translúcido

// -- 3. Efectos de Luz y Bisel (El alma de Aero) --
uniform float reflection_intensity : hint_range(0.0, 3.0) = 1.8; // Brillo del reflejo principal
uniform float bevel_strength : hint_range(0.0, 1.0) = 0.5; // Fuerza del bisel 3D
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.015; // Dispersión de luz en bordes

// -- 4. Máscaras de Forma --
uniform float corner_radius : hint_range(0.0, 0.5) = 0.1; // Redondez de esquinas (ajustar según tamaño del nodo)

// Texturas
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// --- FUNCIONES DE SOPORTE ---

// Función de Desenfoque Gaussiano de 9 muestras (Optimizada para 1 pasada)
vec4 fast_gaussian_blur(sampler2D tex, vec2 uv, vec2 resolution, float radius) {
    vec2 pixel_size = (vec2(1.0) / resolution) * radius;
    vec4 sum = vec4(0.0);
    vec2 offsets[9];
    offsets[0] = vec2(-1, -1); offsets[1] = vec2(0, -1); offsets[2] = vec2(1, -1);
    offsets[3] = vec2(-1,  0); offsets[4] = vec2(0,  0); offsets[5] = vec2(1,  0);
    offsets[6] = vec2(-1,  1); offsets[7] = vec2(0,  1); offsets[8] = vec2(1,  1);
    
    float weights[9];
    weights[0] = 1.0; weights[1] = 2.0; weights[2] = 1.0;
    weights[3] = 2.0; weights[4] = 4.0; weights[5] = 2.0;
    weights[6] = 1.0; weights[7] = 2.0; weights[8] = 1.0;
    
    float total_weight = 16.0;
    
    for(int i = 0; i < 9; i++) {
        sum += textureLod(tex, uv + offsets[i] * pixel_size, 0.0) * weights[i];
    }
    
    return sum / total_weight;
}

// Máscara de rectángulo redondeado (Para los bordes biselados 3D)
float rounded_box_mask(vec2 p, vec2 b, float r) {
    vec2 q = abs(p - 0.5) * 2.0 - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 screen_res = vec2(1.0) / SCREEN_PIXEL_SIZE;
    vec2 node_size = vec2(1.0) / TEXTURE_PIXEL_SIZE; // Tamaño del nodo ColorRect
    
    // --- 1. COMPOSICIÓN DE LA TEXTURA DE FONDO (Profundidad + Desenfoque) ---
    // Calculamos un offset de profundidad: el centro está menos desenfocado que los bordes.
    vec2 depth_offset = (UV - 0.5) * depth_of_field;
    
    // Refracción Cromática: separamos los canales R y B según la distancia al centro.
    vec2 red_uv = uv - depth_offset - vec2(chromatic_aberration, 0.0);
    vec2 blue_uv = uv - depth_offset + vec2(chromatic_aberration, 0.0);
    vec2 green_uv = uv - depth_offset; // El canal G se mantiene en el centro de refracción.
    
    // Muestreamos el desenfoque para cada canal
    vec3 blurred_color;
    blurred_color.r = fast_gaussian_blur(screen_texture, red_uv, screen_res, blur_radius).r;
    blurred_color.g = fast_gaussian_blur(screen_texture, green_uv, screen_res, blur_radius).g;
    blurred_color.b = fast_gaussian_blur(screen_texture, blue_uv, screen_res, blur_radius).b;
    
    // --- 2. APLICACIÓN DE CRISTAL (Tinte y Profundidad) ---
    vec3 glass_pass = mix(blurred_color, glass_tint.rgb, glass_tint.a);
    
    // --- 3. MÁSCARAS DE LUZ Y BISEL (El efecto volumétrico 3D) ---
    
    // A. Bisel 3D: Usamos la máscara de rectángulo redondeado para crear un brillo perimetral
    float box_dist = rounded_box_mask(UV, vec2(1.0), corner_radius);
    
    // Borde brillante exterior (un bisel muy fino)
    float outer_bevel = 1.0 - smoothstep(0.0, 0.015, box_dist);
    // Borde interior de sombra (para dar profundidad)
    float inner_shadow = smoothstep(-0.1, 0.1, box_dist);
    
    // C. Reflejo Central Curvado (El destello Aero principal)
    // Simulamos una curva de luz que se intensifica en el centro superior.
    // Usamos abs() y pow() para crear una curvatura convexa.
    float curve_intensity = 1.0 - pow(abs(UV.x - 0.5) * 2.0, 3.0);
    curve_intensity *= max(0.0, 1.0 - UV.y * 2.0); // La luz se desvanece rápidamente hacia abajo
    curve_intensity *= reflection_intensity;
    
    // --- 4. COMPOSICIÓN FINAL ---
    
    // Mezclamos el reflejo central con el cristal
    glass_pass = mix(glass_pass, vec3(1.0), curve_intensity * 0.5);
    
    // Añadimos los bordes del bisel
    vec3 final_color = glass_pass;
    
    // Brillo exterior del bisel
    final_color += outer_bevel * vec3(1.0) * bevel_strength * 0.5;
    // Oscurecemos ligeramente el borde interior para mayor volumen
    final_color *= (1.0 - (1.0 - inner_shadow) * 0.2);

    // Asignamos el color final y la transparencia global
    COLOR.rgb = final_color;
    COLOR.a = glass_tint.a * (1.0 + outer_bevel * bevel_strength);
}