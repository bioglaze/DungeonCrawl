module Game;

import std.stdio;
import Matrix4x4;
import Renderer;
import SDLWindow;
import Texture;
import Level;

enum FacingDirection
{
    North = 0, East, South, West
}

class Player
{
    public void TurnRight()
    {
        facingDirection = cast(FacingDirection)((cast(int)facingDirection + 1) % 4);
    }
    
    public void TurnLeft()
    {
        if (facingDirection == FacingDirection.North)
        {
            facingDirection = FacingDirection.West;
            return;
        }

        --facingDirection;
    }
    
    private FacingDirection facingDirection = FacingDirection.South;
}

class Game
{
    this()
    {
    }

    public void Simulate( SDLWindow.KeyboardKey[] keys )
    {
        if (mode == Mode.Ingame)
        {
            foreach (key; keys)
            {
                if (key == SDLWindow.KeyboardKey.Space)
                {
                    writeln( "game got space" );
                }
                if (key == SDLWindow.KeyboardKey.Left)
                {
                    writeln( "game got left" );
                    player.TurnLeft();
                }
                if (key == SDLWindow.KeyboardKey.Right)
                {
                    writeln( "game got right" );
                    player.TurnRight();
                }
                if (key == SDLWindow.KeyboardKey.Up)
                {
                    writeln( "game got up" );
                }
                if (key == SDLWindow.KeyboardKey.Down)
                {
                    writeln( "game got down" );
                }                
            }
        }
        else if (mode == Mode.Menu)
        {
            foreach (key; keys)
            {
                if (key == SDLWindow.KeyboardKey.Space)
                {
                    writeln( "menu got space" );
                    mode = Mode.Ingame;
                }
            }
        }
    }

    public void Render( Renderer renderer )
    {
        renderer.ClearScreen();

        if (mode == Mode.Menu)
        {
            //renderer.DrawQuad( 0, 0, 256, 256 );
            renderer.DrawText( "DungeonCrawl\n\nspace - new game\ns - high scores", 200, 70 );
        }
        else if (mode == Mode.Ingame)
        {
            //Renderer.DrawVAO( levels[ currentLevel ].GetVAO() );
        }
    }

    private enum Mode { Menu, Ingame }
    
    private Mode mode = Mode.Menu;
    private Level[ 1 ] levels;
    private int currentLevel = 0;
    private Player player = new Player();
}

void main()
{
    immutable int width = 640;
    immutable int height = 480;

    auto window = new SDLWindow( width, height );
    auto game = new Game();
    auto renderer = new Renderer( width, height );

    while (true)
    {
        SDLWindow.KeyboardKey[] keys = window.ProcessInput();
        game.Simulate( keys );
        game.Render( renderer );
        window.SwapBuffers();
    }
}
