"use strict";
const canvas = document.getElementById("mycanvas");
const ctx = canvas.getContext("2d");
if (!ctx)
    throw new Error("Could not get canvas context");
const width = canvas.width;
const height = canvas.height;
const img = ctx.createImageData(width, height);
const data = img.data;
class vec3 {
    x;
    y;
    z;
    constructor(x, y, z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    add(v) { return new vec3(this.x + v.x, this.y + v.y, this.z + v.z); }
    a(v) { return new vec3(this.x + v, this.y + v, this.z + v); }
    sub(v) { return new vec3(this.x - v.x, this.y - v.y, this.z - v.z); }
    s(v) { return new vec3(this.x - v, this.y - v, this.z - v); }
    mul(v) { return new vec3(this.x * v.x, this.y * v.y, this.z * v.z); }
    m(v) { return new vec3(this.x * v, this.y * v, this.z * v); }
    div(v) { return new vec3(this.x / v.x, this.y / v.y, this.z / v.z); }
    d(v) { return new vec3(this.x / v, this.y / v, this.z / v); }
    dot(v) { return this.x * v.x + this.y * v.y + this.z * v.z; }
    length() { return Math.sqrt(this.dot(this)); }
    normalize() { const l = this.length(); return new vec3(this.x / l, this.y / l, this.z / l); }
    cross(v) {
        return new vec3(this.y * v.z - this.z * v.y, this.z * v.x - this.x * v.z, this.x * v.y - this.y * v.x);
    }
    rotate(a, w) {
        a = a.normalize();
        const half = w / 2;
        const qw = Math.cos(half);
        const qxqz = a.m(Math.sin(half));
        const v = this;
        const t = qxqz.cross(v).add(v.m(qw));
        return v.add(qxqz.cross(t).m(2));
    }
}
class vec2 {
    x;
    y;
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
    add(v) { return new vec2(this.x + v.x, this.y + v.y); }
    a(v) { return new vec2(this.x + v, this.y + v); }
    sub(v) { return new vec2(this.x - v.x, this.y - v.y); }
    s(v) { return new vec2(this.x - v, this.y - v); }
    mul(v) { return new vec2(this.x * v.x, this.y * v.y); }
    m(v) { return new vec2(this.x * v, this.y * v); }
    div(v) { return new vec2(this.x / v.x, this.y / v.y); }
    d(v) { return new vec2(this.x / v, this.y / v); }
    dot(v) { return this.x * v.x + this.y * v.y; }
    length() { return Math.sqrt(this.dot(this)); }
    normalize() { const l = this.length(); return new vec2(this.x / l, this.y / l); }
}
function setPixel(c, color) {
    const i = (c.y * width + c.x) * 4;
    data[i] = color.x * 255;
    data[i + 1] = color.y * 255;
    data[i + 2] = color.z * 255;
    data[i + 3] = 255;
}
function SDF(p, t) {
    let q = new vec2(new vec2(p.x, p.z).length() - t.x, p.y);
    return q.length() - t.y;
}
function map(p) {
    return SDF(p, new vec2(2, 1));
}
function rayMarch(ro, rd) {
    let t = 0, d = 0;
    for (let i = 0; i < 60; i++) {
        let p = rd.m(t).add(ro);
        d = map(p);
        if (d < 0.001) {
            return t;
        }
        ;
        if (d > 100) {
            return d;
        }
        ;
        t += d;
    }
    return 500;
}
let time = 0;
function render() {
    if (ctx == null)
        return;
    for (let x = 0; x < width; x++) {
        for (let y = 0; y < height; y++) {
            let c = new vec2(x, y);
            let uv = c.m(2).sub(new vec2(width, height)).div(new vec2(height, height));
            // uv = uv.m(2).s(1);
            let rd = new vec3(uv.x, uv.y, 1).normalize();
            rd = rd.rotate(new vec3(1, 10, -2), time);
            rd = rd.rotate(new vec3(0, -1, 1), time * 0.5);
            let ro = new vec3(0, 0, -5);
            ro = ro.rotate(new vec3(1, 10, -2), time);
            ro = ro.rotate(new vec3(0, -1, 1), time * 0.5);
            let d = rayMarch(ro, rd);
            d = 1 / d;
            let col = new vec3(d, d, d);
            setPixel(c, col);
        }
    }
    ctx.putImageData(img, 0, 0);
    time += 0.12;
    requestAnimationFrame(render);
}
requestAnimationFrame(render);
