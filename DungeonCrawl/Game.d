import std.stdio;
import Matrix4x4;
import Renderer;
import SDLWindow;
import Texture;

/*
    This is a Dungeon Crawler game by Timo Wiren, 2016

    Build
    -----

    Depends on Derelict libraries derelict-gl3, derelict-util, and derelict-sdl2.
    They are assumed to be in derelict folder next to DungeonCrawler root folder and can be obtained/built
    with the following steps: http://derelictorg.github.io/compiling.html.

    DungeonCrawl.sln is a Xamarin Studio solution configured for OS X.
*/
class Game
{
    this()
    {
        glider = new Texture( "assets/glider.png" );
    }

    public void Render( Renderer renderer )
    {
        renderer.ClearScreen();

        if (mode == Mode.Menu)
        {
            glider.Bind();
            renderer.DrawQuad( 0, 0, 100, 100 );
        }
        else if (mode == Mode.Ingame)
        {

        }
    }

    private enum Mode { Menu, Ingame }
    
    private Mode mode = Mode.Menu;
    private Texture glider;
}

void main()
{
    immutable int width = 640;
    immutable int height = 480;

    auto window = new SDLWindow( width, height );
    auto game = new Game();
    auto renderer = new Renderer( width, height );

    bool quit = false;

    while (!quit)
    {
        quit = window.ProcessInput();
        game.Render( renderer );
        window.SwapBuffers();
    }

    window.Close();
}
