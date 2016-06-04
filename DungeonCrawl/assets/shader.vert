#version 330 core

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inUV;

uniform mat4 mvp;

out vec2 vUV;

void main()
{
    gl_Position = mvp * vec4( inPosition, 1.0 );
    vUV = inUV;
}

