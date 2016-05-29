module shader;

import std.exception;
import std.file;
import std.stdio;
import std.string;
import derelict.opengl3.gl3;

class Shader
{
    this( string vertexPath, string fragmentPath )
    {
        try
        {
            program = glCreateProgram();
            Compile( cast(string)read( vertexPath ), GL_VERTEX_SHADER );
            Compile( cast(string)read( fragmentPath ), GL_FRAGMENT_SHADER );
            Link();
        }
        catch (Exception e)
        {
            writeln( "Could not open or compile " ~ vertexPath ~ " or " ~ fragmentPath );
        }
    }

    public void SetFloat( string name, float value )
    {
        immutable char* nameCstr = toStringz( name );
        glUniform1f( glGetUniformLocation( program, nameCstr ), value );
    }

    public void SetInt( string name, int value )
    {
        immutable char* nameCstr = toStringz( name );
        glUniform1i( glGetUniformLocation( program, nameCstr ), value );
    }
    
    public void SetFloat2( string name, float value1, float value2 )
    {
        immutable char* nameCstr = toStringz( name );
        glUniform2f( glGetUniformLocation( program, nameCstr ), value1, value2 );
    }

    public void SetMatrix44( string name, float[] matrix )
    {
        immutable char* nameCstr = toStringz( name );
        glUniformMatrix4fv( glGetUniformLocation( program, nameCstr ), 1, GL_FALSE, matrix.ptr );
    }

    public void Use()
    {
        glUseProgram( program );
    }

    public void Delete()
    {
        glDeleteProgram( program );
    }

    private void Link()
    {
        glLinkProgram( program );
        PrintInfoLog( program, GL_LINK_STATUS );
    }

    private void PrintInfoLog( GLuint shader, GLenum status )
    {
        assert( status == GL_LINK_STATUS || status == GL_COMPILE_STATUS, "Wrong status!" );

        GLint shaderCompiled = GL_FALSE;

        if (status == GL_COMPILE_STATUS)
        {
            glGetShaderiv( shader, GL_COMPILE_STATUS, &shaderCompiled );
        }
        else
        {
            glGetProgramiv( shader, GL_LINK_STATUS, &shaderCompiled );
        }

        if (shaderCompiled != GL_TRUE)
        {
            writeln("Shader could not be " ~ (status == GL_LINK_STATUS ? "linked!" : "compiled!"));

            char[1000] errorLog;
            auto info = errorLog.ptr;

            if (status == GL_COMPILE_STATUS)
            {
                glGetShaderInfoLog( shader, 1000, null, info );
            }
            else
            {
                glGetProgramInfoLog( program, 1000, null, info );
            }

            writeln( errorLog );
        }
    }

    private void Compile( string source, GLenum shaderType )
    {
        assert( shaderType == GL_VERTEX_SHADER || shaderType == GL_FRAGMENT_SHADER, "Wrong shader type!" );

        immutable char* sourceCstr = toStringz( source );
        GLuint shader = glCreateShader( shaderType );
        glShaderSource( shader, 1, &sourceCstr, null );

        glCompileShader( shader );
        PrintInfoLog( shader, GL_COMPILE_STATUS );
        glAttachShader( program, shader );
    }

    private GLuint program;
}

