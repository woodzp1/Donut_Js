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
        if (d > 100.) return -1.0;
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
float gyroid (vec3 seed) {
    return dot(sin(seed),cos(seed.yzx));
}
float fbm (vec3 seed) {
        float result = 0., a = .5;
    for (int i = 0; i < 7; ++i) {
        // extra spicy twist
        seed.z += result*.5;

        // bounce it with abs
        result += abs(gyroid(seed/a))*a;

        a /= 2.;
    }
    return result;
}
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = SDF(ro + rd*t,vec2(2,1));
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
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
    vec3 ro = vec3(0,0,-5.5);
    ro.yz = rot2d(iTime) * ro.yz;
    ro.xy = rot2d(iTime * 2.6) * ro.xy;
    vec3 light = vec3(6,0,-1);
    light.yz = rot2d(iTime) * light.yz;
    light.xy = rot2d(iTime * 2.6) * light.xy;
    float t = raymarch(ro,rd);
    vec3 p = t * rd + ro;
    vec3 col = vec3(0.,0.,0.);
    if (t > 0.0){
        vec3 norm = sdgTorus(p,2.0,1.0).gba;
        float dif = clamp( dot(norm,normalize(light)), 0.0, 1.0 );
        float amb = 0.5 + 0.5*dot(norm,vec3(0.0,1.0,0.0));
        col = vec3(0.25,0.4,0.55)*amb * fbm(p) * 0.5+ vec3(0.8,0.7,0.5)*dif * softshadow(p,light,0.1,3.0,0.1);
    }
    else{
        col = vec3(step(vec3(0.9),vec3(dot(light,rd) * 0.2 )));
    }
    
    // Output to screen
    fragColor = vec4(col,1.0);
}