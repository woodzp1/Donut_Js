"use strict";
const canvas = document.getElementById("mycanvas");
const gl = canvas.getContext("webgl2");
if (!gl)
    throw new Error("WebGPU not supported");
const vert_src = `#version 300 es;
in vec2 a_position;
void main(){
    gl_Position = vec4(a_position,0.0,1.0);

}
`;
const frag_src = `#version 300 es
presion highp float;

uniform vec2 iResolution;
uniform float iTime;
out vec4 fragColor

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
    return 5000.0;
}
mat2 rot2d(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy *2.0 -1.0;
    uv.x *= iResolution.x / iResolution.y;
    vec3 rd = normalize(vec3(uv,1));
    rd.yz = rot2d(iTime) * rd.yz;
    vec3 ro = vec3(0,0,-4);
    ro.yz = rot2d(iTime) * ro.yz;
    float t = raymarch(ro,rd);

    vec3 col = vec3(1.0/t);

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
gl.attachShader(program, vert_src);
gl.attachShader(program, frag_src);
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
function render(delta) {
    if (!gl)
        throw new Error("WebGPU not supported");
    gl.uniform2f(iResolution, canvas.width, canvas.height);
    gl.uniform1f(iTime, delta * 0.0001);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    requestAnimationFrame(render);
}
requestAnimationFrame(render);
