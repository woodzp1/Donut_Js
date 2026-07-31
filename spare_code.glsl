#version 300 es
precision highp float;

uniform vec2 iResolution;   
uniform float iTime;
out vec4 fragColor;

float SDF(vec3 p, vec2 t){
     vec2 q = vec2(length(p.xz)-t.x,p.y);
     return length(q)-t.y;
}


float raymarch(vec3 ro, vec3 rd){
    float t = 0.0;
    float d = 0.0;
    for(int i = 0;i <120;i++)
    {
        vec3 p = ro + rd * t;
        d = SDF(p,vec2(2.0,1.0));
        if (d < 0.001) return t;
        if (d > 100.) return t;
        t += d;
    
    
    }
    return -1.0;
}
mat2 rot2d(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}
vec4 sdgTorus( vec3 p, float ra, float rb )
{
    float h = length(p.xz);
    return vec4( length(vec2(h-ra,p.y))-rb,
                 normalize(p*vec3(h-ra,h,h-ra)) );
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy *2.0 -1.0;
    uv.x *= iResolution.x / iResolution.y;
    vec3 rd = normalize(vec3(uv,1));
    rd.yz = rot2d(iTime) * rd.yz;
    rd.xy = rot2d(iTime * 2.6) * rd.xy;
    vec3 ro = vec3(0,0,-4);
    ro.yz = rot2d(iTime) * ro.yz;
    ro.xy = rot2d(iTime * 2.6) * ro.xy;
    float t = raymarch(ro,rd);
    vec3 p = t * rd + ro;
    vec3 col = vec3(0.,0.,0.);
    if (t != -1.0){
        vec3 norm = sdgTorus(p,2.0,1.0).gba;
        col = vec3(norm);
        col = abs(col);
    }
    
    // Output to screen
    fragColor = vec4(col,1.0);
}
