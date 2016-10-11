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
import Mesh;

private enum PlayerLastMoveDirection
{
    None, Forward, Backward
}

public class Game
{
    public void Init( Renderer renderer )
    {        
        heart = new Texture( "assets/heart.tga" );

        textures.tex = new Texture( "assets/wall1.tga" );
        textures.health = new Texture( "assets/health.tga" );
        textures.white = new Texture( "assets/white.tga" );

        meshes.sword = new Mesh( "assets/sword.obj", renderer );
        meshes.health = new Mesh( "assets/health.obj", renderer );
        meshes.monster1 = new Mesh( "assets/monster1.obj", renderer );
        meshes.stairway = new Mesh( "assets/stairway.obj", renderer );

        for (int i = 0; i < levels.length; ++i)
        {
            levels[ i ] = new Level( renderer, meshes, textures, i != 0, i != levels.length - 1 );
        }
    }

    public void Simulate( bool[ SDLWindow.KeyboardKey ] keys )
    {
        const long lerp = MonoTime.currTime.ticks - playerMoveTicks;

        if (lerp < moveTime)
        {
            return;
        }        
        
        if (mode == Mode.Ingame)
        {
            if (SDLWindow.KeyboardKey.Escape in keys)
            {
                exit( 0 );
            }
            else if (SDLWindow.KeyboardKey.Space in keys && !(SDLWindow.KeyboardKey.Space in lastFrameKeys))
            {
                if (levels[ currentLevel ].CanGoUp( player.GetLevelPosition() ) )
                {
                    --currentLevel;
                    player.TeleportTo( levels[ currentLevel ].GetStairwayDownPosition() );
                }
                else if (levels[ currentLevel ].CanGoDown( player.GetLevelPosition() ) )
                {
                    ++currentLevel;
                    player.TeleportTo( levels[ currentLevel ].GetStairwayUpPosition() );
                }
                else
                {
                    ++gameTurn;
                }

                lastMoveDir = PlayerLastMoveDirection.None;
            }
            else if (SDLWindow.KeyboardKey.A in keys && !(SDLWindow.KeyboardKey.A in lastFrameKeys))
            {
                Level.Monster* monster = levels[ currentLevel ].GetMonsterInFrontOfPlayer( player );
                //player.Attack();
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
            
            if (oldGameTurn != gameTurn && MonoTime.currTime.ticks - enemyMoveTicks > moveTime)
            {
                if (levels[ currentLevel ].HasHealthInPosition( player.GetLevelPosition() ) &&
                    !player.HasMaxHealth())
                {
                    levels[ currentLevel ].RemoveHealth( player.GetLevelPosition() );
                    player.EatFood( 1 );
                }

                playerMoveTicks = MonoTime.currTime.ticks;
                enemyMoveTicks = MonoTime.currTime.ticks;
                oldGameTurn = gameTurn;
                //writeln("lerp: ", lerp, ", playerMove: ", playerMoveTicks);
                levels[ currentLevel ].Simulate();
            }
        }
        else if (mode == Mode.Menu)
        {
            if (SDLWindow.KeyboardKey.Space in keys)
            {
                mode = Mode.Ingame;
            }
            else if (SDLWindow.KeyboardKey.H in keys)
            {
                mode = Mode.Help;
            }
            else if (SDLWindow.KeyboardKey.Escape in keys)
            {
                exit( 0 );
            }
        }
        else if (mode == Mode.Help)
        {
            if (SDLWindow.KeyboardKey.Escape in keys)
            {
                mode = Mode.Menu;
            }
        }
        
        lastFrameKeys = keys;
    }

    public void Render( Renderer renderer )
    {
        renderer.ClearScreen();

        if (mode == Mode.Menu)
        {
            renderer.DrawText( "DungeonCrawl\n\nspace - new game\nh - help", 100, 70 );
        }
        if (mode == Mode.Help)
        {
            renderer.DrawText( "arrows - move\na - attack\nspace - rest, use stairs", 60, 70 );
        }
        else if (mode == Mode.Ingame)
        {
            Vec3 pp = CalculateAnimatedPlayerPosition();
            
            renderer.SetCamera( pp, player.GetWorldDirection() );
            levels[ currentLevel ].Draw( renderer );

            textures.white.Bind();
            Vec3 swordPosition = pp - player.GetWorldDirection() * 10;
            swordPosition.y -= 5;
            renderer.SetMVP( swordPosition, 0, 0.7f );
            renderer.DrawVAO( meshes.sword.GetVAO(), meshes.sword.GetElementCount() * 3, [ 1, 1, 1 ] );

            renderer.EnableAlphaBlending();
            
            for (int i = 0; i < player.GetMaxHealth(); ++i)
            {
                const float r = player.GetHealth() > i ? 1.0f : 0.0f;
                
                renderer.DrawTexture( heart, 20 + 74 * i, 20, 64, 64, [ r, r, r ] );
            }

            renderer.DrawText( std.format.format( "turn: %d, score: %d, dlevel %d", gameTurn, 70, currentLevel ), 150, 20 );

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

    private enum Mode { Menu, Ingame, Help }
    
    private Mode mode = Mode.Menu;
    private Level[ 3 ] levels;
    private int currentLevel = 0;
    private Player player = new Player();
    private Texture heart;
    private Level.Textures textures;
    private Level.Meshes meshes;
    private bool[ SDLWindow.KeyboardKey ] lastFrameKeys;
    private int gameTurn = 0, oldGameTurn = 0;
    private long playerMoveTicks = 0;
    private long enemyMoveTicks = 0;
    private PlayerLastMoveDirection lastMoveDir = PlayerLastMoveDirection.None;
	
	version( OSX )
	{
		long moveTime = 333553789;
	}
	version( Windows )
	{
		private immutable long moveTime = 3335537 / 4;
	}
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
