"use strict";
const canvas = document.getElementById("mycanvas");
const gl = canvas.getContext("webgl2");
if (!gl)
    throw new Error("WebGPU not supported");
const vert_src = `#version 300 es
in vec2 a_position;
void main(){
    gl_Position = vec4(a_position,0.0,1.0);
}
`;
const frag_src = `#version 300 es
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
    vec3 light =   normalize(vec3(1,6,-3));
    light.yz = rot2d(iTime) * light.yz;
    light.xy = rot2d(iTime * 2.6) * light.xy;
    float t = raymarch(ro,rd);
    vec3 p = t * rd + ro;
    vec3 col = vec3(0.,0.,0.);
    if (t > 0.0){
        vec3 norm = sdgTorus(p,2.0,1.0).gba;
        
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
`;
function compile_shader(gl, type, src) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, src);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        throw new Error(gl.getShaderInfoLog(shader) ?? "Shader compile error");
    }
    return shader;
}
const vertexShader = compile_shader(gl, gl.VERTEX_SHADER, vert_src);
const fragmentShader = compile_shader(gl, gl.FRAGMENT_SHADER, frag_src);
const program = gl.createProgram();
gl.attachShader(program, vertexShader);
gl.attachShader(program, fragmentShader);
gl.linkProgram(program);
if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    throw new Error(gl.getProgramInfoLog(program) ?? "Program link Error");
}
gl.useProgram(program);
const positions = new Float32Array([
    -1, -1,
    3, -1,
    -1, 3,
]);
const posBuffer = gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, posBuffer);
gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);
const a_position = gl.getAttribLocation(program, "a_position");
gl.enableVertexAttribArray(a_position);
gl.vertexAttribPointer(a_position, 2, gl.FLOAT, false, 0, 0);
const iResolution = gl.getUniformLocation(program, "iResolution");
const iTime = gl.getUniformLocation(program, "iTime");
const button = document.getElementById("pause");
let clicked = false;
button.onclick = (event) => {
    clicked = !clicked;
};
function render(delta) {
    if (!gl)
        throw new Error("WebGPU not supported");
    gl.uniform2f(iResolution, canvas.width, canvas.height);
    if (!clicked) {
        // gl.uniform1f(iTime,  93.5 );
        gl.uniform1f(iTime, delta * 0.001);
    }
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    requestAnimationFrame(render);
}
requestAnimationFrame(render);
