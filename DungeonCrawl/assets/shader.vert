#version 330 core

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inUV;

uniform mat4 projectionMatrix;
uniform vec2 position;
uniform vec2 scale;

out vec2 vUV;

void main()
{
    gl_Position = projectionMatrix * vec4( inPosition.xy * scale + position, 0.0, 1.0 );
	vUV = inUV;
}

