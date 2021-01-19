#version 300 es
precision mediump float;
precision highp int;

uniform highp usampler2D state;
uniform sampler2D materials;
uniform vec2 resolution;
uniform float t;
uniform vec2 offset;
uniform float zoom;
out vec4 outputColor;

void main() {
    outputColor = vec4(1.0, 0.5, 0.5, 1);
}