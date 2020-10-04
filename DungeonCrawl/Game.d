/**
  DungeonCrawl by Timo Wirén
  Modified: 2020-10-04

  Tested on dmd 2.089.1, Lubuntu 19.10, MacBook Pro 2010, Core 2 Duo 2.4 GHz, GeForce GT 320 M, Nouveau Mesa 19.2.1

  Bug: Monster visual position does not match gameplay position, player can hit it if it's one square off.
 */
module Game;

import std.stdio;
import std.typecons;
import std.format;
import core.stdc.stdlib: exit;
import core.time;
import Level;
import Matrix4x4;
import Mesh;
import Player;
import Renderer;
import SDLWindow;
import bindbc.sdl;
import Texture;
import Vec3;

immutable int width = 960;
immutable int height = 540;

private enum PlayerLastMoveDirection
{
    None, Forward, Backward
}

private enum PlayerLastRotateDirection
{
    None, Left, Right
}

float lerp( float t01, float a, float b )
{
    return (1 - t01) * a + t01 * b;
}

private struct Particle
{
    public Vec3 position;
    public Vec3 velocity;
}

private struct DamageEffect
{
    public void Start()
    {
        startTimeMs = MonoTime.currTime.ticks;
    }

    public float GetOpacity()
    {
        immutable long elapsedMs = MonoTime.currTime.ticks - startTimeMs;

        if (elapsedMs > durationMs)
        {
            return 0;
        }

        float res = lerp( elapsedMs / cast( float )durationMs, 1, 0 );
        return res;
    }

    private long startTimeMs;
    private immutable long durationMs = 200000000;
}

public class Game
{
    public void Init( Renderer renderer )
    {
        heart = new Texture( "DungeonCrawl/assets/heart.tga" );

        textures.tex = new Texture( "DungeonCrawl/assets/wall1.tga" );
        textures.health = new Texture( "DungeonCrawl/assets/health.tga" );
        textures.white = new Texture( "DungeonCrawl/assets/white.tga" );
        textures.damage = new Texture( "DungeonCrawl/assets/damage.tga" );
        textures.floor = new Texture( "DungeonCrawl/assets/floor.tga" );

        meshes.sword = new Mesh( "DungeonCrawl/assets/sword.obj", renderer );
        meshes.health = new Mesh( "DungeonCrawl/assets/health.obj", renderer );
        meshes.monster1 = new Mesh( "DungeonCrawl/assets/monster1.obj", renderer );
        meshes.stairway = new Mesh( "DungeonCrawl/assets/stairway.obj", renderer );

        for (int i = 0; i < levels.length; ++i)
        {
            levels[ i ] = new Level( renderer, meshes, textures, i != 0, i != levels.length - 1 );
        }

        SDL_LoadWAV( "DungeonCrawl/assets/click.wav", &wavClickSpec, &wavClickBuffer, &wavClickLength );
        SDL_AudioDeviceID deviceId = SDL_OpenAudioDevice( null, 0, &wavClickSpec, null, 0 );
        //int success = SDL_QueueAudio( deviceId, wavClickBuffer, wavClickLength );
        SDL_PauseAudioDevice( deviceId, 0 );
    }

    public void Simulate( bool[ SDLWindow.KeyboardKey ] keys )
    {
        const long lerp = MonoTime.currTime.ticks - playerMoveTicks;
        const bool isPlayerRotating = ((MonoTime.currTime.ticks - playerRotateTicks) / rotDem) < rotComp;

        if (lerp < moveTime || isPlayerRotating)
        {
            return;
        }

        if (mode == Mode.Ingame)
        {
            if (levels[ currentLevel ].HasHealthInPosition( player.GetLevelPosition() ) )
            {
                player.EatFood( 1 );
                levels[ currentLevel ].RemoveHealth( player.GetLevelPosition() );
            }

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
                lastRotateDir = PlayerLastRotateDirection.None;
            }
            else if (SDLWindow.KeyboardKey.A in keys && !(SDLWindow.KeyboardKey.A in lastFrameKeys))
            {
                swordOffset = 1;

                Level.Monster* monster = levels[ currentLevel ].GetMonsterInFrontOfPlayer( player );
                if (monster != null)
                {
                    monster.TakeDamage( player.GetWeapon() );
                }

                hitTicks = MonoTime.currTime.ticks;
                lastMoveDir = PlayerLastMoveDirection.None;
                lastRotateDir = PlayerLastRotateDirection.None;
                ++gameTurn;
            }
            else if (SDLWindow.KeyboardKey.Left in keys && !(SDLWindow.KeyboardKey.Left in lastFrameKeys))
            {
                player.TurnLeft();
                lastMoveDir = PlayerLastMoveDirection.None;
                lastRotateDir = PlayerLastRotateDirection.Left;
                playerRotateTicks = MonoTime.currTime.ticks;
            }
            else if (SDLWindow.KeyboardKey.Right in keys && !(SDLWindow.KeyboardKey.Right in lastFrameKeys))
            {
                player.TurnRight();
                lastMoveDir = PlayerLastMoveDirection.None;
                lastRotateDir = PlayerLastRotateDirection.Right;
                playerRotateTicks = MonoTime.currTime.ticks;
            }
            else if (SDLWindow.KeyboardKey.Up in keys && !(SDLWindow.KeyboardKey.Up in lastFrameKeys) &&
                     levels[ currentLevel ].CanWalkForward( player ) )
            {
                player.WalkForward();
                levels[ currentLevel ].DebugPrintMonsters();
                lastMoveDir = PlayerLastMoveDirection.Forward;
                lastRotateDir = PlayerLastRotateDirection.None;
                ++gameTurn;
            }
            else if (SDLWindow.KeyboardKey.Down in keys && !(SDLWindow.KeyboardKey.Down in lastFrameKeys) &&
                     levels[ currentLevel ].CanWalkBackward( player ))
            {
                player.WalkBackward();
                lastMoveDir = PlayerLastMoveDirection.Backward;
                lastRotateDir = PlayerLastRotateDirection.None;
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
                levels[ currentLevel ].Simulate( player.GetLevelPosition() );
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
            if (SDLWindow.KeyboardKey.Q in keys)
            {
                mode = Mode.Menu;
            }
        }

        lastFrameKeys = keys;
    }

    private void PlayParticles( Renderer renderer )
    {
        immutable long lerp = MonoTime.currTime.ticks - hitTicks;
        immutable float f = cast(float)lerp / particleDurationMs;
        immutable int dimension = cast( int )(128.0f * f);
        //writeln("hitTicks: ", hitTicks, ", lerp: ", lerp, ", f: ", f, ", dimension: ", dimension );

        particles[ 0 ].position.x = (width / 2 - 64) - dimension / 2;
        particles[ 0 ].position.y = (height / 2 - 64) - dimension / 2;

        for (int i = 0; i < 1; ++i)
        {
            renderer.DrawTexture( textures.damage, cast(int)particles[ 0 ].position.x, cast(int)particles[ 0 ].position.y, dimension, dimension, [ 1, 1, 1, 1 - f / 2 ] );
        }
    }

    public void Render( Renderer renderer, double deltaTimeMs )
    {
        renderer.ClearScreen();

        if (mode == Mode.Menu)
        {
            renderer.DrawText( "DungeonCrawl\n\nspace - new game\nh - help", 100, 70 );
        }
        if (mode == Mode.Help)
        {
            renderer.DrawText( "arrows - move\na - attack\nspace - rest, use stairs\nq - back to menu", 60, 70 );
        }
        else if (mode == Mode.Ingame)
        {
            Vec3 playerPos = CalculateAnimatedPlayerPosition();
            immutable float playerRotY = CalculateAnimatedPlayerRotation();
            Matrix4x4 rot;
            rot.MakeRotationXYZ( 0, playerRotY, 0 );
            Vec3 rotatedDir;
            Matrix4x4.TransformPoint( player.GetWorldDirection(), rot, rotatedDir );
            renderer.SetCamera( playerPos, rotatedDir );
            levels[ currentLevel ].Draw( renderer, playerRotY );

            renderer.DisableDepthTest();

            swordOffset -= deltaTimeMs;
            if (swordOffset < 0)
            {
                swordOffset = 0;
            }

            textures.white.Bind();
            Vec3 swordPosition = playerPos - rotatedDir/*player.GetWorldDirection()*/ * 10;
            swordPosition.y -= 5;
            swordPosition.y += swordOffset;
            renderer.SetMVP( swordPosition, playerRotY, 0.7f );
            renderer.DrawVAO( meshes.sword.GetVAO(), meshes.sword.GetElementCount() * 3, [ 1, 1, 1, 1 ] );

            renderer.EnableAlphaBlending();

            for (int i = 0; i < player.GetMaxHealth(); ++i)
            {
                const float r = player.GetHealth() > i ? 1.0f : 0.0f;

                renderer.DrawTexture( heart, 20 + 74 * i, 20, 64, 64, [ r, 0, 0, 1 ] );
            }

            if (!levels[ currentLevel ].CanWalkForward( player ))
            {
                PlayParticles( renderer );
            }

            renderer.DrawText( std.format.format( "turn: %d, score: %d, dlevel %d", gameTurn, 70, currentLevel ), 150, 20 );

            renderer.DisableAlphaBlending();
            renderer.EnableDepthTest();
        }
    }

    private Vec3 CalculateAnimatedPlayerPosition()
    {
        immutable long lerp = MonoTime.currTime.ticks - playerMoveTicks;

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

    private float CalculateAnimatedPlayerRotation()
    {
        long lerp = MonoTime.currTime.ticks - playerRotateTicks;
        lerp /= 2;
        float rotY = 0;

        if (lastRotateDir == PlayerLastRotateDirection.Left && lerp < moveTime)
        {
            rotY = 90 -(cast(float)lerp / moveTime) * 90;
        }
        else if (lastRotateDir == PlayerLastRotateDirection.Right && lerp < moveTime)
        {
            rotY = -90 + (cast(float)lerp / moveTime) * 90;
        }

        return rotY;
    }

    private enum Mode { Menu, Ingame, Help }

    private Mode mode = Mode.Menu;
    private Level[ 1 ] levels;
    private int currentLevel = 0;
    private Player player = new Player();
    private Texture heart;
    private Level.Textures textures;
    private Level.Meshes meshes;
    private bool[ SDLWindow.KeyboardKey ] lastFrameKeys;
    private int gameTurn = 0, oldGameTurn = 0;
    private long playerMoveTicks = 0;
    private long playerRotateTicks = 0;
    private long enemyMoveTicks = 0;
    private long hitTicks = 0;
    private PlayerLastMoveDirection lastMoveDir = PlayerLastMoveDirection.None;
    private PlayerLastRotateDirection lastRotateDir = PlayerLastRotateDirection.None;
    private DamageEffect damageEffect;
    private float swordOffset = 0;
    private Particle[ 100 ] particles;
    private SDL_AudioSpec wavClickSpec;
    private Uint32 wavClickLength;
    private Uint8* wavClickBuffer;

    version( linux )
    {
        private immutable long moveTime = 333553789;
        private immutable long particleDurationMs = 200000000;
        private immutable long rotDem = 100000;
        private immutable long rotComp = 8000;
    }
    version( OSX )
    {
        private immutable long moveTime = 333553789;
        private immutable long particleDurationMs = 200000000;
        private immutable long rotDem = 100000;
        private immutable long rotComp = 8000;
    }
    version( Windows )
    {
        private immutable long moveTime = 3335537 / 4;
        private immutable long particleDurationMs = 2000000;
        private immutable long rotDem = 1000;
        private immutable long rotComp = 6000;
    }
}

void main()
{
    auto window = new SDLWindow( width, height );
    auto renderer = new Renderer( width, height );
    auto game = new Game();
    game.Init( renderer );

    long lastTick = 0;

    while (true)
    {
        bool[ SDLWindow.KeyboardKey ] keys = window.ProcessInput();
        game.Simulate( keys );
        long deltaTicks = MonoTime.currTime.ticks - lastTick;
        version( Windows )
        {
            double deltaMs = deltaTicks / 1000.0;
        }
        else
        {
            double deltaMs = deltaTicks / 1000000.0;
        }

        game.Render( renderer, deltaMs );
        window.SwapBuffers();
        lastTick = MonoTime.currTime.ticks;
    }
}
