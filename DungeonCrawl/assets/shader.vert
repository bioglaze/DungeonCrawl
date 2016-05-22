#version 330 core

layout(location = 0) in vec2 inPosition;

uniform mat4 projectionMatrix;
uniform vec2 position;
uniform vec2 scale;

void main()
{
    gl_Position = projectionMatrix * vec4( inPosition * scale + position, 0.0, 1.0 );
}

