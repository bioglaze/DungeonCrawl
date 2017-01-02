module Renderer;

import std.stdio;
import derelict.opengl3.gl3;
import Matrix4x4;
import Vec3;
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

public void CheckGLError( string info )
{
    GLenum errorCode = GL_INVALID_ENUM;
        
    while ((errorCode = glGetError()) != GL_NO_ERROR)
    {
        if (errorCode == 1282)
        {
            writeln( "OpenGL error GL_INVALID_OPERATION in ", info );
        }
        else if (errorCode == 1281)
        {
            writeln( "OpenGL error GL_INVALID_VALUE in ", info );
        }
        else
        {
            writeln( "OpenGL error ", errorCode, " in ", info );
        }
        //assert( false, "" );
    }
}

class Renderer
{
    this( float screenWidth, float screenHeight )
    {
        orthoMat.MakeProjection( 0, screenWidth, screenHeight, 0, -1, 1 );
        perspectiveMat.MakeProjection( 45, screenWidth / cast(float)screenHeight, 1, 300 );

        shader = new Shader( "DungeonCrawl/assets/shader.vert", "DungeonCrawl/assets/shader.frag" );
        shader.Use();
        shader.SetInt( "sTexture", 0 );

        font = new Font( "DungeonCrawl/assets/font.bin" );
        fontTex = new Texture( "DungeonCrawl/assets/font.tga" );

        glEnable( GL_DEPTH_TEST );
        glEnable( GL_CULL_FACE );
        glCullFace( GL_BACK );
        glFrontFace( GL_CCW );

        CheckGLError( "Before generate quad" );

        Vertex[ 6 ] quad;
        quad[ 0 ] = Vertex( [ 0, 0, 0 ], [ 0, 0 ] );
        quad[ 1 ] = Vertex( [ 0, 1, 0 ], [ 0, 1 ] );
        quad[ 2 ] = Vertex( [ 1, 0, 0 ], [ 1, 0 ] );
        quad[ 3 ] = Vertex( [ 1, 0, 0 ], [ 1, 0 ] );
        quad[ 4 ] = Vertex( [ 1, 1, 0 ], [ 1, 1 ] );
        quad[ 5 ] = Vertex( [ 0, 1, 0 ], [ 0, 1 ] );

        Face[ 2 ] quadIndices = [ Face( 0, 1, 2 ), Face( 3, 5, 4 ) ];
        GenerateVAO( quad, quadIndices, quadVAO );        
    }
    
    public void ClearScreen()
    {
        glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT );
    }

    public void DrawVAO( uint vaoID, int elementCount, float[ 4 ] tintColor )
    {
        CheckGLError( "Before DrawVAO" );
        shader.SetFloat4( "tintColor", tintColor[ 0 ], tintColor[ 1 ], tintColor[ 2 ], tintColor[ 3 ] );
        glBindVertexArray( vaoID );
        glDrawElements( GL_TRIANGLES, elementCount, GL_UNSIGNED_SHORT, cast(GLvoid*)0 );
        CheckGLError( "After DrawVAO" );
    }

    public void GenerateVAO( Vertex[] vertices, Face[] faces, out uint vao ) const
    {
        glGenVertexArrays( 1, &vao );
        glBindVertexArray( vao );

        CheckGLError( "GenerateVAO after vao" );

        uint vbo, ibo;
        glGenBuffers( 1, &vbo );
        glBindBuffer( GL_ARRAY_BUFFER, vbo );
        glBufferData( GL_ARRAY_BUFFER, vertices.length * Vertex.sizeof, vertices.ptr, GL_STATIC_DRAW );

        CheckGLError( "GenerateVAO after vertices" );

        glGenBuffers( 1, &ibo );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, ibo );
        glBufferData( GL_ELEMENT_ARRAY_BUFFER, faces.length * Face.sizeof, faces.ptr, GL_STATIC_DRAW );

        CheckGLError( "GenerateVAO after indices" );

        glEnableVertexAttribArray( 0 );
        glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, null );

        glEnableVertexAttribArray( 1 );
        glVertexAttribPointer( 1, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(char*)0 + 3 * 4 );

        CheckGLError( "GenerateVAO end" );
    }

    public void DrawText( string text, float x, float y )
    {        
        if (text != cachedText)
        {     
            Vertex[] vertices;
            Face[] faces;
            font.GetGeometry( text, fontTex.GetWidth(), fontTex.GetHeight(), vertices, faces );
            GenerateVAO( vertices, faces, textVAO );

            cachedText = text;
            textFaceLength = cast(int)faces.length;
        }

        fontTex.Bind();

        shader.Use();

        Matrix4x4 mvp;
        mvp.MakeIdentity();
        //mvp.Scale( xScale, yScale, 1 );
        mvp.Translate( Vec3.Vec3( x, y, 0 ) );
        Matrix4x4.Multiply( mvp, orthoMat, mvp );
        shader.SetMatrix44( "mvp", mvp.m );
        
        DrawVAO( textVAO, textFaceLength * 3, [ 1, 1, 1, 1 ] );
    }

    public void EnableAlphaBlending()
    {
        glEnable( GL_BLEND );
        glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    }

    public void DisableAlphaBlending()
    {
        glDisable( GL_BLEND );
    }

    public void EnableDepthTest()
    {
        glEnable( GL_DEPTH_TEST );
    }

    public void DisableDepthTest()
    {
        glDisable( GL_DEPTH_TEST );
    }
    
    public void DrawTexture( Texture texture, int x, int y, int xScale, int yScale, float[ 4 ] tintColor )
    {
        texture.Bind();

        Matrix4x4 mvp;
        mvp.MakeIdentity();
        mvp.Scale( xScale, yScale, 1 );
        mvp.Translate( Vec3.Vec3( x, y, 0 ) );
        Matrix4x4.Multiply( mvp, orthoMat, mvp );
        
        shader.Use();
        shader.SetMatrix44( "mvp", mvp.m );
        DrawVAO( quadVAO, 2 * 3, tintColor );
        shader.SetFloat4( "tintColor", 1, 1, 1, 1 );
    }
    
    public void SetMVP( Vec3 position, float rotY, float scale )
    {
        Matrix4x4 view;
        view.MakeLookAt( cameraPosition, cameraPosition + cameraDirectionDeg * 50, Vec3.Vec3( 0, 1, 0 ) );
        view.Transpose();

        Matrix4x4 model;
        model.MakeIdentity();

        Matrix4x4 rot;
        rot.MakeRotationXYZ( 0, rotY, 0 );

        model.Scale( scale, scale, scale );
        Matrix4x4.Multiply( model, rot, model );        
        model.Translate( position );

        Matrix4x4 mvp;
        Matrix4x4 mv;
        Matrix4x4.Multiply( model, view, mv );
        Matrix4x4.Multiply( mv, perspectiveMat, mvp );

        shader.Use();
        shader.SetMatrix44( "mvp", mvp.m );
    }

    public void SetCamera( Vec3 aCameraPosition, Vec3 directionDeg )
    {
        cameraPosition = aCameraPosition;
        cameraDirectionDeg = directionDeg;
    }

    private GLuint quadVAO;
    private GLuint textVAO;
    private GLuint textVBO;
    private GLuint textIBO;
    private int textFaceLength;
    private Shader shader;
    private Font font;
    private Texture fontTex;
    private string cachedText;
    private Matrix4x4 orthoMat;
    private Matrix4x4 perspectiveMat;
    private Vec3 cameraPosition;
    private Vec3 cameraDirectionDeg;
}


