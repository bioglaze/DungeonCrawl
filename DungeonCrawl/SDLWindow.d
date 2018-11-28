module SDLWindow;

import derelict.sdl2.sdl;
import derelict.opengl;
import derelict.util.exception;
import std.stdio: writeln;
import core.stdc.stdlib: exit;
import std.string;

public enum KeyboardKey
{
    Space,
    Left,
    Right,
    Up,
    Down,
    Escape,
    S,
    H,
    A,
}

class SDLWindow
{
    this( int screenWidth, int screenHeight )
    {	
        DerelictSDL2.load();
        
        if (SDL_Init( SDL_INIT_VIDEO ) < 0)
        {
            const(char)* message = SDL_GetError();
            writeln( "Failed to initialize SDL: ", message );
        }
        
        SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 24 );
        SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 3 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
        
        win = SDL_CreateWindow("Dungeon Crawler", SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED, screenWidth, screenHeight, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);

        ShouldThrow missingSymFunc( string symName )
        {
            if (symName == "glGetSubroutineUniformLocation")
                return ShouldThrow.No;
            
            if (symName == "glVertexAttribL1d")
                return ShouldThrow.No;

            return ShouldThrow.Yes;
        }

        DerelictGL3.missingSymbolCallback = &missingSymFunc;

        DerelictGL3.load();
        const auto context = SDL_GL_CreateContext( win );
        
        if (!context)
        {
            throw new Error( "Failed to create GL context!" );
        }
        
        // If you get an unresolved symbol message here, try selecting "continue" or "ignore" in Visual Studio debugger.
        DerelictGL3.reload();
        
        SDL_GL_SetSwapInterval( 1 );
    }
    
    public bool[ KeyboardKey ] ProcessInput()
    {	
        bool[ KeyboardKey ] outKeys;
        const Uint8* keyState = SDL_GetKeyboardState( null );    
        
        if (keyState[ SDL_SCANCODE_ESCAPE ] == 1)
        {
            outKeys[ KeyboardKey.Escape ] = true;
        }

        if (keyState[ SDL_SCANCODE_SPACE ] == 1)
        {
            outKeys[ KeyboardKey.Space ] = true;
        }
        
        if (keyState[ SDL_SCANCODE_LEFT ] == 1)
        {
            outKeys[ KeyboardKey.Left ] = true;
        }

        if (keyState[ SDL_SCANCODE_RIGHT ] == 1)
        {
            outKeys[ KeyboardKey.Right ] = true;
        }

        if (keyState[ SDL_SCANCODE_UP ] == 1)
        {
            outKeys[ KeyboardKey.Up ] = true;
        }
        
        if (keyState[ SDL_SCANCODE_DOWN ] == 1)
        {
            outKeys[ KeyboardKey.Down ] = true;
        }

        if (keyState[ SDL_SCANCODE_H ] == 1)
        {
            outKeys[ KeyboardKey.H ] = true;
        }

        if (keyState[ SDL_SCANCODE_A ] == 1)
        {
            outKeys[ KeyboardKey.A ] = true;
        }
        
        SDL_Event e;
        
        while (SDL_PollEvent( &e ))
        {
            if (e.type == SDL_WINDOWEVENT)
            {
                if (e.window.event == SDL_WINDOWEVENT_CLOSE)
                {
                    Close();
                    exit( 0 );

                }
            }
            else if (e.type == SDL_QUIT)
            {
                Close();
                exit( 0 );
            }
            else
            {
                //writeln( "event: ", e.type );
            }
        }
        
        return outKeys;
    }
    
    public void SwapBuffers()
    {
        SDL_GL_SwapWindow( win );
    }
    
    public void Close()
    {
        SDL_DestroyWindow( win );
        SDL_Quit();
    }
    
    private SDL_Window* win;
}

