module Game;

import std.stdio;
import core.stdc.stdlib: exit;
import Matrix4x4;
import Vec3;
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
    public void WalkForward()
    {
        if (facingDirection == FacingDirection.North)
        {
            --levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.South)
        {
            ++levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.East)
        {
            ++levelPosition[ 0 ];
        }
        else if (facingDirection == FacingDirection.West)
        {
            --levelPosition[ 0 ];
        }
    }

    public void WalkBackward()
    {
        if (facingDirection == FacingDirection.North)
        {
            ++levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.South)
        {
            --levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.East)
        {
            --levelPosition[ 0 ];
        }
        else if (facingDirection == FacingDirection.West)
        {
            ++levelPosition[ 0 ];
        }
    }
    
    public void TurnRight()
    {
        facingDirection = cast(FacingDirection)((cast(int)facingDirection + 1) % 4);
    }
    
    public void TurnLeft()
    {
        final switch (facingDirection)
        {
        case FacingDirection.North: facingDirection = FacingDirection.West; break;
        case FacingDirection.South: facingDirection = FacingDirection.East; break;
        case FacingDirection.East: facingDirection = FacingDirection.North; break;
        case FacingDirection.West: facingDirection = FacingDirection.South; break;
        }
    }
    
    Vec3 GetWorldPosition() const
    {
        return Vec3.Vec3( levelPosition[ 0 ] * 10, 0, levelPosition[ 1 ] * 10 );
    }

    Vec3 GetWorldDirection() const
    {
        final switch (facingDirection)
        {
        case FacingDirection.South: return Vec3.Vec3( 0, 0, 0 );
        case FacingDirection.North: return Vec3.Vec3( 0, 180, 0 );
        case FacingDirection.East: return Vec3.Vec3( 0, 90, 0 );
        case FacingDirection.West: return Vec3.Vec3( 0, -90, 0 );
        }
    }

    private float[ 3 ] levelPosition = [ -2, -3, 0 ];
    private FacingDirection facingDirection = FacingDirection.South;
}

class Game
{
    this()
    {
    }

    public void CreateLevels( Renderer renderer )
    {
        levels[ 0 ] = new Level( renderer );
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
            else if (SDLWindow.KeyboardKey.Up in keys && !(SDLWindow.KeyboardKey.Up in lastFrameKeys))
            {
                player.WalkForward();
            }
            else if (SDLWindow.KeyboardKey.Down in keys && !(SDLWindow.KeyboardKey.Down in lastFrameKeys))
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
        }

        lastFrameKeys = keys;
    }

    public void Render( Renderer renderer )
    {
        renderer.ClearScreen();

        if (mode == Mode.Menu)
        {
            //renderer.DrawQuad( 0, 0, 256, 256 );
            renderer.DrawText( "DungeonCrawl\n\nspace - new game\ns - high scores", 100, 70 );
        }
        else if (mode == Mode.Ingame)
        {
            renderer.LookAt( player.GetWorldPosition(), player.GetWorldDirection() );
            levels[ currentLevel ].Draw( renderer );
        }
    }

    private enum Mode { Menu, Ingame }
    
    private Mode mode = Mode.Menu;
    private Level[ 1 ] levels;
    private int currentLevel = 0;
    private Player player = new Player();
    private bool[ SDLWindow.KeyboardKey ] lastFrameKeys;
}

void main()
{
    immutable int width = 640;
    immutable int height = 480;

    auto window = new SDLWindow( width, height );
    auto renderer = new Renderer( width, height );
    auto game = new Game();
    game.CreateLevels( renderer );

    while (true)
    {
        bool[ SDLWindow.KeyboardKey ] keys = window.ProcessInput();
        game.Simulate( keys );
        game.Render( renderer );
        window.SwapBuffers();
    }
}
