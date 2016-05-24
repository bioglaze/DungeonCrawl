module Texture;
import derelict.opengl3.gl3;

class Texture
{
    this( string path )
    {
        glGenTextures( 1, &handle );
        glBindTexture( GL_TEXTURE_2D, handle );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    }

    public void Bind()
    {
        glBindTexture( GL_TEXTURE_2D, handle );
    }

    private int width, height;
    private GLuint handle;
}
