module Texture;

import derelict.opengl3.gl3;
import std.stdio;
import Renderer;

// Reads a true-color, uncompressed TGA
private void ReadTGA( string path, out int width, out int height, out byte[] pixelData )
{
    try
    {
        auto f = File( path, "r" );
            
        byte[ 1 ] idLength;
        f.rawRead( idLength );

        byte[ 1 ] colorMapType;
        f.rawRead( colorMapType );

        byte[ 1 ] imageType;
        f.rawRead( imageType );

        if (imageType[ 0 ] != 2)
        {
            throw new Exception( "wrong TGA type: must be uncompressed true-color" );
        }

        byte[ 5 ] colorSpec;
        f.rawRead( colorSpec );

        byte[ 10 ] imageSpec;
        byte[ 4 ] specBegin;
        short[ 2 ] specDim;
        f.rawRead( specBegin );
        f.rawRead( specDim );
        width = specDim[ 0 ];
        height = specDim[ 1 ];

        byte[ 2 ] specEnd;
        f.rawRead( specEnd );

        if (idLength[ 0 ] > 0)
        {
            byte[] imageId = new byte[ idLength[ 0 ] ];
            f.rawRead( imageId );
        }

        pixelData = new byte[ width * height * 4 ];
        f.rawRead( pixelData );
    }
    catch (Exception e)
    {
        writeln( "could not open ", path, ":", e );
    } 
}

class Texture
{
    this( string path )
    {
        byte[] pixelData;
        ReadTGA( path, width, height, pixelData );
        
        glGenTextures( 1, &handle );
        glBindTexture( GL_TEXTURE_2D, handle );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, pixelData.ptr );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        Renderer.CheckGLError( "after texture" );
    }

    public void Bind()
    {
        glBindTexture( GL_TEXTURE_2D, handle );
    }

    public int GetWidth()
    {
        return width;
    }

    public int GetHeight()
    {
        return height;
    }

    private int width, height;
    private GLuint handle;
}
