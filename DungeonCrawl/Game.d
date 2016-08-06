module Game;

import std.stdio;
import std.typecons;
import std.format;
import core.stdc.stdlib: exit;
import core.time;
import Matrix4x4;
import Renderer;
import SDLWindow;
import Texture;
import Level;
import Player;
import Vec3;

private enum PlayerLastMoveDirection
{
    None, Forward, Backward
}

public class Game
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
        const long lerp = MonoTime.currTime.ticks - playerMoveTicks;
        if (lerp < moveTime)
            return;

        oldGameTurn = gameTurn;
        
        if (mode == Mode.Ingame)
        {
            if (SDLWindow.KeyboardKey.Escape in keys)
            {
                exit( 0 );
            }
            else if (SDLWindow.KeyboardKey.Space in keys && !(SDLWindow.KeyboardKey.Space in lastFrameKeys))
            {
                ++gameTurn;
                playerMoveTicks = 0;
            }
            else if (SDLWindow.KeyboardKey.Left in keys && !(SDLWindow.KeyboardKey.Left in lastFrameKeys))
            {
                player.TurnLeft();
                lastMoveDir = PlayerLastMoveDirection.None;
            }
            else if (SDLWindow.KeyboardKey.Right in keys && !(SDLWindow.KeyboardKey.Right in lastFrameKeys))
            {
                player.TurnRight();
                lastMoveDir = PlayerLastMoveDirection.None;
            }
            else if (SDLWindow.KeyboardKey.Up in keys && !(SDLWindow.KeyboardKey.Up in lastFrameKeys) &&
                     levels[ currentLevel ].CanWalkForward( player ) )
            {
                player.WalkForward();
                lastMoveDir = PlayerLastMoveDirection.Forward;
                ++gameTurn;
            }
            else if (SDLWindow.KeyboardKey.Down in keys && !(SDLWindow.KeyboardKey.Down in lastFrameKeys) &&
                     levels[ currentLevel ].CanWalkBackward( player ))
            {
                player.WalkBackward();
                lastMoveDir = PlayerLastMoveDirection.Backward;
                ++gameTurn;
            }
            
            if (oldGameTurn != gameTurn)
            {
                if (levels[ currentLevel ].HasHealthInPosition( player.GetLevelPosition() ) &&
                    !player.HasMaxHealth())
                {
                    levels[ currentLevel ].RemoveHealth( player.GetLevelPosition() );
                    player.EatFood( 1 );
                }

                playerMoveTicks = MonoTime.currTime.ticks;
                oldGameTurn = gameTurn;

                levels[ currentLevel ].Simulate();
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
            Vec3 pp = CalculateAnimatedPlayerPosition();
            
            renderer.SetCamera( pp, player.GetWorldDirection() );
            levels[ currentLevel ].Draw( renderer );

            renderer.EnableAlphaBlending();
            
            for (int i = 0; i < player.GetMaxHealth(); ++i)
            {
                const float r = player.GetHealth() > i ? 1.0f : 0.0f;
                
                renderer.DrawTexture( heart, 20 + 74 * i, 20, 64, 64, [ r, r, r ] );
            }

            renderer.DrawText( std.format.format( "turn: %s, score: %s", gameTurn, 70 ), 150, 20 );

            renderer.DisableAlphaBlending();
        }
    }

    private Vec3 CalculateAnimatedPlayerPosition()
    {
        long lerp = MonoTime.currTime.ticks - playerMoveTicks;

        int[ 2 ] playerPosition = player.GetLevelPosition();

        float worldX = playerPosition[ 0 ] * 20;
        float worldZ = playerPosition[ 1 ] * 20;

        if (lastMoveDir == PlayerLastMoveDirection.Forward && player.GetWorldDirection().z == -1 && lerp < moveTime)
        {
            worldZ += cast(float)lerp / moveTime * 20 - 20;
        }
        else if (lastMoveDir == PlayerLastMoveDirection.Forward && player.GetWorldDirection().z == 1 && lerp < moveTime)
        {
            worldZ -= cast(float)lerp / moveTime * 20 - 20;
        }
        else if (lastMoveDir == PlayerLastMoveDirection.Forward && player.GetWorldDirection().x == 1 && lerp < moveTime)
        {
            worldX -= cast(float)lerp / moveTime * 20 - 20;
        }
        else if (lastMoveDir == PlayerLastMoveDirection.Forward && player.GetWorldDirection().x == -1 && lerp < moveTime)
        {
            worldX += cast(float)lerp / moveTime * 20 - 20;
        }
        else if (lastMoveDir == PlayerLastMoveDirection.Backward && player.GetWorldDirection().z == -1 && lerp < moveTime)
        {
            worldZ -= cast(float)lerp / moveTime * 20 - 20;
        }
        else if (lastMoveDir == PlayerLastMoveDirection.Backward && player.GetWorldDirection().z == 1 && lerp < moveTime)
        {
            worldZ += cast(float)lerp / moveTime * 20 - 20;
        }
        else if (lastMoveDir == PlayerLastMoveDirection.Backward && player.GetWorldDirection().x == 1 && lerp < moveTime)
        {
            worldX += cast(float)lerp / moveTime * 20 - 20;
        }
        else if (lastMoveDir == PlayerLastMoveDirection.Backward && player.GetWorldDirection().x == -1 && lerp < moveTime)
        {
            worldX -= cast(float)lerp / moveTime * 20 - 20;
        }

        return Vec3.Vec3( worldX, 0, worldZ );
    }

    private enum Mode { Menu, Ingame }
    
    private Mode mode = Mode.Menu;
    private Level[ 1 ] levels;
    private int currentLevel = 0;
    private Player player = new Player();
    private Texture heart;
    private bool[ SDLWindow.KeyboardKey ] lastFrameKeys;
    private int gameTurn = 0, oldGameTurn = 0;
    private long playerMoveTicks = 0;
    private PlayerLastMoveDirection lastMoveDir = PlayerLastMoveDirection.None;
    //long moveTime = 333553789;
    private immutable long moveTime = 3335537 / 4;
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
