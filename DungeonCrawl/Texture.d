module Texture;
import derelict.opengl3.gl3;
import std.stdio;

class Texture
{
    this( string path )
    {
        // Reads a true-color, uncompressed TGA
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
                writeln( "Image type must be uncompressed true-color image" );
                throw new Exception( "wrong TGA type" );
            }

            byte[ 5 ] colorSpec;
            f.rawRead( colorSpec );

            byte[ 10 ] imageSpec;
            f.rawRead( imageSpec );
            
            width = imageSpec[ 4 ];
            width += imageSpec[ 5 ] * 256;
            writeln( "image width: ", width );

            height = imageSpec[ 6 ];
            height += imageSpec[ 7 ] * 256;
            writeln( "image height: ", height );

            writeln( "pixel depth: ", imageSpec[ 9 ] );

            writeln( "id block length: ", idLength[ 0 ] );
            if (idLength[ 0 ] > 0)
            {
                byte[] imageId = new byte[ idLength[ 0 ] ];
                f.rawRead( imageId );
            }

            byte[] pixelData = new byte[ width * height * 4 ];
            f.rawRead( pixelData );

            glGenTextures( 1, &handle );
            glBindTexture( GL_TEXTURE_2D, handle );
            glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelData.ptr );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
            

        }
        catch (Exception e)
        {
            writeln( "Could not open ", path );
            writeln( e );
        }
    }

    public void Bind()
    {
        glBindTexture( GL_TEXTURE_2D, handle );
    }

    private int width, height;
    private GLuint handle;
}
