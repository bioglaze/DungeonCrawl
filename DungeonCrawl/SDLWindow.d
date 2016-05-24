module SDLWindow;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3;
import std.stdio: writeln;

class SDLWindow
{
    this( int screenWidth, int screenHeight )
    {	
        DerelictSDL2.load();
        
        if (SDL_Init( SDL_INIT_EVERYTHING ) < 0)
        {
            //throw new Error( "Failed to initialze SDL: " ~ to!string( SDL_GetError() ) );
        }
        
        SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 24 );
        SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 3 );
        SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
        
        win = SDL_CreateWindow("Dungeon Crawler", SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED, screenWidth, screenHeight, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
        DerelictGL3.load();
        auto context = SDL_GL_CreateContext( win );
        
        if (!context)
        {
            throw new Error( "Failed to create GL context!" );
        }
        
        DerelictGL3.reload();
        
        SDL_GL_SetSwapInterval( 1 );
    }
    
    public bool ProcessInput()
    {	
        const Uint8* keyState = SDL_GetKeyboardState( null );    
        
        if (keyState[ SDL_SCANCODE_ESCAPE ] == 1)
        {
            return true;
        }
        
        SDL_Event e;
        
        while (SDL_PollEvent( &e ))
        {
            if (e.type == SDL_WINDOWEVENT)
            {
                if (e.window.event == SDL_WINDOWEVENT_CLOSE)
                {
                    return true;
                }
            }
            else if (e.type == SDL_QUIT)
            {
                return true;
            }
            else
            {
                writeln( "event: ", e.type );
            }
        }
        
        return false;
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
    
    SDL_Window* win;
}

