import std.stdio;
import Matrix4x4;
import Renderer;
import SDLWindow;
import Texture;

// This is a Dungeon Crawler game by Timo Wiren, 2016
class Game
{
    this()
    {
        fontTex = new Texture( "assets/font.tga" );
    }

    public void Render( Renderer renderer )
    {
        renderer.ClearScreen();

        if (mode == Mode.Menu)
        {
            fontTex.Bind();
            renderer.DrawQuad( 0, 0, 100, 100 );
        }
        else if (mode == Mode.Ingame)
        {

        }
    }

    private enum Mode { Menu, Ingame }
    
    private Mode mode = Mode.Menu;
    private Texture fontTex;
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
