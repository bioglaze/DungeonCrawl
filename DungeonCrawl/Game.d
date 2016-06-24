module Game;

import std.stdio;
import core.stdc.stdlib: exit;
import Matrix4x4;
import Renderer;
import SDLWindow;
import Texture;
import Level;
import Player;
import std.typecons;

class Game
{
    this()
    {
    }

    public void Init( Renderer renderer )
    {
        levels[ 0 ] = new Level( renderer );
        heart = new Texture( "assets/heart.tga" );
    }

    public void Simulate( bool[ SDLWindow.KeyboardKey ] keys )
    {
        if (mode == Mode.Ingame)
        {
            if (SDLWindow.KeyboardKey.Escape in keys)
            {
                exit( 0 );
            }
            else if (SDLWindow.KeyboardKey.Space in keys)
            {
            }
            else if (SDLWindow.KeyboardKey.Left in keys && !(SDLWindow.KeyboardKey.Left in lastFrameKeys))
            {
                player.TurnLeft();
            }
            else if (SDLWindow.KeyboardKey.Right in keys && !(SDLWindow.KeyboardKey.Right in lastFrameKeys))
            {
                player.TurnRight();
            }
            else if (SDLWindow.KeyboardKey.Up in keys && !(SDLWindow.KeyboardKey.Up in lastFrameKeys) &&
                     levels[ currentLevel ].CanWalkForward( player ) )
            {
                player.WalkForward();
            }
            else if (SDLWindow.KeyboardKey.Down in keys && !(SDLWindow.KeyboardKey.Down in lastFrameKeys) &&
                     levels[ currentLevel ].CanWalkBackward( player ))
            {
                player.WalkBackward();
            }                
        }
        else if (mode == Mode.Menu)
        {
            if (SDLWindow.KeyboardKey.Space in keys)
            {
                mode = Mode.Ingame;
            }
            else if (SDLWindow.KeyboardKey.Escape in keys)
            {
                exit( 0 );
            }
        }

        lastFrameKeys = keys;
    }

    public void Render( Renderer renderer )
    {
        renderer.ClearScreen();

        if (mode == Mode.Menu)
        {
            renderer.DrawText( "DungeonCrawl\n\nspace - new game\ns - high scores", 100, 70 );
        }
        else if (mode == Mode.Ingame)
        {
            renderer.SetCamera( player.GetWorldPosition(), player.GetWorldDirection() );
            levels[ currentLevel ].Draw( renderer );
            renderer.DrawTexture( heart, 20, 20, 64, 64 );
        }
    }

    private enum Mode { Menu, Ingame }
    
    private Mode mode = Mode.Menu;
    private Level[ 1 ] levels;
    private int currentLevel = 0;
    private Player player = new Player();
    private Texture heart;
    private bool[ SDLWindow.KeyboardKey ] lastFrameKeys;
}

void main()
{
    immutable int width = 640;
    immutable int height = 480;

    auto window = new SDLWindow( width, height );
    auto renderer = new Renderer( width, height );
    auto game = new Game();
    game.Init( renderer );

    while (true)
    {
        bool[ SDLWindow.KeyboardKey ] keys = window.ProcessInput();
        game.Simulate( keys );
        game.Render( renderer );
        window.SwapBuffers();
    }
}
