#version 300 es
precision highp float;

uniform bool circle;
uniform vec2 iResolution;   
uniform float iTime;
out vec4 fragColor;
float sdSphere( vec3 p, float r )
{
  return length(p) - r;
}
float SDF(vec3 p, vec2 t){
     vec2 q = vec2(length(p.xz)-t.x,p.y);
     return length(q)-t.y;
}
vec2 map(vec3 p){
    float donut = SDF(p,vec2(2.0,1.0));
    float sphere = sdSphere(p  - vec3(0,sin(iTime),0),1.0);
    
    vec2 shape = vec2(donut,0.0);
    shape = sphere < donut ? vec2(sphere,1.0) : vec2(donut,0.0);
    if (!circle){
        shape = vec2(donut,0.0);
    }
    return shape;
}


vec2 raymarch(vec3 ro, vec3 rd){
    float t = 0.0;
    vec2 d = vec2(0);
    for(int i = 0;i <120;i++)
    {
        vec3 p = ro + rd * t;
        d = map(p);
        if (d.x < 0.001) return vec2(t,d.y);
        if (d.x > 100.) return vec2(-1.0);
        t += d.x;
    
    
    }
    return vec2(-1.0);
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
vec4 sdgSphere( in vec3 p, in float r )
{
    float l = length(p);
    return vec4(l-r, p/l);
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
        vec2 h = map(ro + rd*t);
        if( h.x < 0.001 )
            return 0.0;
        res = min( res, k*h.x/t );
        t += h.x;
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
    vec3 light =   normalize(vec3(1,6,-3));
    light.yz = rot2d(iTime) * light.yz;
    light.xy = rot2d(iTime * 2.6) * light.xy;
    vec2 ray = raymarch(ro,rd);
    float t = ray.x;
    vec3 p = t * rd + ro;
    vec3 col = vec3(0.,0.,0.);
    if (t > 0.0){
        vec3 norm;
        if (circle && ray.y == 1.0){
            norm = sdgSphere(p,1.0).gba;
        }
        else{
            norm = sdgTorus(p,2.0,1.0).gba;
        }
        norm = normalize(norm);
        float dif = clamp(dot(norm,light),0.,0.8);
        float amb = 0.5 + 0.5*dot(norm,vec3(0.0,1.0,0.0));
        amb = clamp(amb,0.0,0.5);
        vec3 l_color = vec3(0.8,0.7,0.5);
        col =  mix(l_color * 0.6,vec3(0.90),fbm(p));
        col *= amb * vec3(0.45,0.6,0.75) + dif ;
    }
    else{
        col = vec3(0.15);
    }
    
    // col = col *col;
    // Output to screen
    fragColor = vec4(col,1.0);
}