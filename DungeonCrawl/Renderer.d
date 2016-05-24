﻿module Renderer;
import derelict.opengl3.gl3;
import Matrix4x4;
import shader;

class Renderer
{
    this( float screenWidth, float screenHeight )
    {
        glGenVertexArrays( 1, &quadVAO );
        glBindVertexArray( quadVAO );
        
        immutable float[] quad = [ 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1 ];
        
        glGenBuffers( 1, &quadVBO );
        glBindBuffer( GL_ARRAY_BUFFER, quadVBO );
        glBufferData( GL_ARRAY_BUFFER, quad.length * GLfloat.sizeof, quad.ptr, GL_STATIC_DRAW );
        glEnableVertexAttribArray( 0 );
        glVertexAttribPointer( 0, 2, GL_FLOAT, GL_FALSE, 0, null );
        CheckGLError("GenerateQuadBuffers end");

        Matrix4x4 ortho = new Matrix4x4();
        ortho.MakeProjection( 0, screenWidth, screenHeight, 0, -1, 1 );

        uiShader = new Shader( "assets/shader.vert", "assets/shader.frag" );
        uiShader.Use();
        uiShader.SetMatrix44( "projectionMatrix", ortho.m );
    }
    
    public void ClearScreen()
    {
        glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    }

    public void DrawQuad( float x, float y, float width, float height )
    {
        glBindVertexArray( quadVAO );

        uiShader.SetFloat2( "position", x, y );
        uiShader.SetFloat2( "scale", width, height );

        glDrawArrays( GL_TRIANGLES, 0, 6 );
        CheckGLError( "After render" );
    }

    private void CheckGLError( string info )
    {
        GLenum errorCode = GL_INVALID_ENUM;
        
        while ((errorCode = glGetError()) != GL_NO_ERROR)
        {
            //writeln( "OpenGL error in " ~ info ~ ": " ~ to!string(errorCode) );
        }
    }

    private GLuint quadVAO;
    private GLuint quadVBO;
    private Shader uiShader;
    
}


