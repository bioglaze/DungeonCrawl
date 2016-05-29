module Renderer;

import std.stdio;
import derelict.opengl3.gl3;
import Matrix4x4;
import shader;
import Font;
import Texture;

public align(1) struct Vertex
{
    float[ 3 ] pos;
    float[ 2 ] uv;
}

public align(1) struct Face
{
    ushort a, b, c;
}

class Renderer
{
    this( float screenWidth, float screenHeight )
    {
        glGenVertexArrays( 1, &quadVAO );
        glBindVertexArray( quadVAO );
        
        Vertex[ 6 ] quad;
        quad[ 0 ] = Vertex( [ 0, 0, 0 ], [ 0, 0 ] );
        quad[ 1 ] = Vertex( [ 0, 1, 0 ], [ 0, 1 ] );
        quad[ 2 ] = Vertex( [ 1, 0, 0 ], [ 1, 0 ] );
        quad[ 3 ] = Vertex( [ 1, 0, 0 ], [ 1, 0 ] );
        quad[ 4 ] = Vertex( [ 1, 1, 0 ], [ 1, 1 ] );
        quad[ 5 ] = Vertex( [ 0, 1, 0 ], [ 0, 1 ] );

        glGenBuffers( 1, &quadVBO );
        glBindBuffer( GL_ARRAY_BUFFER, quadVBO );
        glBufferData( GL_ARRAY_BUFFER, quad.length * Vertex.sizeof, quad.ptr, GL_STATIC_DRAW );
        
        glEnableVertexAttribArray( 0 );
        glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, null );

        glEnableVertexAttribArray( 1 );
        glVertexAttribPointer( 1, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(char*)0 + 3 * 4 );
        
        CheckGLError("GenerateQuadBuffers end");

        Matrix4x4 ortho = new Matrix4x4();
        ortho.MakeProjection( 0, screenWidth, screenHeight, 0, -1, 1 );

        uiShader = new Shader( "assets/shader.vert", "assets/shader.frag" );
        uiShader.Use();
        uiShader.SetMatrix44( "projectionMatrix", ortho.m );
        uiShader.SetInt( "sTexture", 0 );

        font = new Font( "assets/font.bin" );
        fontTex = new Texture( "assets/font.tga" );
        
        CheckGLError("Renderer constructor end");
    }
    
    public void ClearScreen()
    {
        glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    }

    public void DrawQuad( float x, float y, float width, float height )
    {
        glBindVertexArray( quadVAO );

        uiShader.Use();
        uiShader.SetFloat2( "position", x, y );
        uiShader.SetFloat2( "scale", width, height );

        glDrawArrays( GL_TRIANGLES, 0, 6 );
        CheckGLError( "After render" );
    }

    void DrawText( string text, float x, float y )
    {        
        if (text != cachedText)
        {
            glGenVertexArrays( 1, &textVAO );
            glBindVertexArray( textVAO );
     
            Vertex[] vertices;
            Face[] faces;
            font.GetGeometry( text, fontTex.GetWidth(), fontTex.GetHeight(), vertices, faces );
            cachedText = text;
            textFaceLength = cast(int)faces.length;
            std.stdio.writeln( "vertices: ", vertices.length, ", faces: ", faces.length );

            glGenBuffers( 1, &textVBO );
            glBindBuffer( GL_ARRAY_BUFFER, textVBO );
            glBufferData( GL_ARRAY_BUFFER, vertices.length * Vertex.sizeof, vertices.ptr, GL_STATIC_DRAW );

            glGenBuffers( 1, &textIBO );
            glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, textIBO );
            glBufferData( GL_ELEMENT_ARRAY_BUFFER, faces.length * Face.sizeof, faces.ptr, GL_STATIC_DRAW );
            
            glEnableVertexAttribArray( 0 );
            glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, null );
            
            glEnableVertexAttribArray( 1 );
            glVertexAttribPointer( 1, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(char*)0 + 3 * 4 );
            
            CheckGLError("GenerateQuadBuffers end");
        }

        fontTex.Bind();
        
        glBindVertexArray( textVAO );
        
        uiShader.Use();
        uiShader.SetFloat2( "position", x, y );
        uiShader.SetFloat2( "scale", 1, 1 );
        
        glDrawElements( GL_TRIANGLES, textFaceLength * 3, GL_UNSIGNED_SHORT, cast(GLvoid*)0 );

        CheckGLError("DrawText end");
    }

    private void CheckGLError( string info )
    {
        GLenum errorCode = GL_INVALID_ENUM;
        
        while ((errorCode = glGetError()) != GL_NO_ERROR)
        {
            //writeln( "OpenGL error in " ~ info ~ ": " ~ to!string(errorCode) );
            writeln( "OpenGL error ", errorCode );
        }
    }

    private GLuint quadVAO;
    private GLuint quadVBO;
    private GLuint textVAO;
    private GLuint textVBO;
    private GLuint textIBO;
    private int textFaceLength;
    private Shader uiShader;
    private Font font;
    private Texture fontTex;
    private string cachedText;
}


