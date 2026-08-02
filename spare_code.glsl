#version 300 es
precision highp float;

uniform bool circle;
uniform vec2 iResolution;   
uniform float iTime;
uniform bool background;
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
    float sphere = sdSphere(p  - vec3(0,sin(iTime) * 4.0,0),1.0);
    
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
    for (int i = 0; i < 6; ++i) {
        
        seed.z += result*.5;
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

float noise (vec2 p) {
    // improvise 3d seed from 2d coordinates
    vec3 seed = vec3(p, length(p) - iTime * .025);
    
    // make it slide along the sin wave
    return sin(fbm(seed)*7.)*.5+.5;
}
float noise2 (vec2 p,float i) {
    // improvise 3d seed from 2d coordinates
    vec3 seed = vec3(p,i);
    
    // make it slide along the sin wave
    return sin(fbm(seed)*6.)*.5+.5;
}

vec3 gradient(float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    float r = 0.2 + 1.5*t - 0.6*t2 + 0.1*t3;
    float g = 0.05 - 0.4*t + 1.8*t2 - 0.7*t3;
    float b = 0.5 - 1.7*t + 1.9*t2 - 0.6*t3;
    return clamp(vec3(r, g, b), 0.0, 1.0);
}
vec3 gradient2(float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    float r = -0.05 + 1.5*t - 0.4*t2 - 0.1*t3;
    float g = -0.1 + 0.2*t + 1.3*t2 - 0.5*t3;
    float b = 0.1 - 0.3*t + 0.5*t2 + 0.1*t3;
    return clamp(vec3(r, g, b), 0.0, 1.0);
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
        float g = 0.0;
        if (circle == 1 && ray.y == 1.0){
            norm = sdgSphere(p - vec3(0,sin(iTime) * 4.0,0),1.0).gba;
            p -= vec3(0,sin(iTime) * 4.0,0);
            g = fbm(p );
        }
        else{
            norm = sdgTorus(p ,2.0,1.0).gba;
            g = fbm(p);
        }
        norm = normalize(norm);
        
        float dif = clamp(dot(norm,light),0.,0.8);
        
        float amb = 0.5 + 0.5*dot(norm,light);
        
        
        amb = clamp(amb,0.0,0.5);
        vec3 l_color = vec3(0.761, 0.314, 0.118);
        col =  mix(l_color * 0.6,vec3(0.90),g);
        col *= amb * vec3(0.761, 0.314, 0.118) * gradient2(fbm(p)) + dif ;
    }
    else{
        if (background){
             float n = noise(uv);
        float m = noise2(uv,n);
    
        col = vec3(gradient2(m)) * gradient(n);
        }
        else{
            col = vec3(0.15);
        }
       
    }
    
    // col = col *col;
    // Output to screen
    fragColor = vec4(col,1.0);
}