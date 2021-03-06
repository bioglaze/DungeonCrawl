module Level;
static import std.stdio;
import std.stdio;
import std.random: uniform;
import Mesh;
import Player;
import Renderer;
import Texture;
import Vec3;

public struct Meshes
{
    Mesh.Mesh sword;
    Mesh.Mesh health;
    Mesh.Mesh monster1;
    Mesh.Mesh stairway;
}

public struct Textures
{
    Texture.Texture tex;
    Texture.Texture health;
    Texture.Texture white;
    Texture.Texture damage;
    Texture.Texture floor;
}

private int CalculateDamage( Player.Weapon weapon )
{
    return 1;
}

public struct Monster
{
    public int[ 2 ] levelPosition;
    public bool isAlive = true;
    public int health = 3;
    public int healthMax = 3;

    void TakeDamage( Player.Weapon weapon )
    {
        health -= CalculateDamage( weapon );
        isAlive = health > 0;
    }
}

private enum BlockType
{
    None = 0,
    Wall1,
    Wall2,
}

immutable int blockCount = 7;

byte[ 25 ][ blockCount ] block = [
				  [ 1, 1, 0, 1, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 1,
				    1, 1, 1, 1, 1 ],

				  [ 1, 1, 1, 1, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 1,
				    1, 1, 0, 1, 1 ],

				  [ 1, 1, 1, 1, 1,
				    1, 0, 0, 0, 1,
				    0, 0, 0, 0, 1,
				    1, 0, 0, 0, 1,
				    1, 1, 1, 1, 1 ],

				  [ 1, 1, 1, 1, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 0,
				    1, 0, 0, 0, 1,
				    1, 1, 1, 1, 1 ],

				  [ 1, 1, 0, 1, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 1,
				    1, 1, 0, 1, 1 ],

				  [ 1, 1, 1, 1, 1,
				    1, 0, 0, 0, 1,
				    0, 0, 0, 0, 0,
				    1, 0, 0, 0, 1,
				    1, 1, 1, 1, 1 ],

                  [ 1, 1, 0, 1, 1,
				    1, 0, 0, 0, 1,
				    1, 0, 0, 0, 0,
				    1, 0, 0, 0, 1,
				    1, 1, 0, 1, 1 ],

                         ];

private struct Room
{
    bool exitUp;
    bool exitDown;
    bool exitLeft;
    bool exitRight;
}

Room[ blockCount ] rooms;

private int GetFittingBlock( int row, int col, int[] blockIndices, int dimension )
{
    int tries = 0;

    while (tries < 20)
    {
        // Map edge checks
        if (row == dimension / 5 - 1)
        {
            return 0;
        }
        if (col == dimension / 5 - 1)
        {
            return 0;
        }
        if (row == 0)
        {
            return 1;
        }
        if (col == 0)
        {
            return 6;
        }

        int candidateIndex = uniform( 0, blockCount - 1 );
        int leftRoom = col > 0 ? blockIndices[ row * (dimension / 5) + col - 1 ] : -1;
        int upRoom = row > 0 ? blockIndices[ (row - 1) * (dimension / 5) + col ] : -1;

        if ((rooms[ leftRoom ].exitRight && rooms[ candidateIndex ].exitLeft) ||
            (rooms[ upRoom ].exitDown && rooms[ candidateIndex ].exitUp))
        {
            return candidateIndex;
        }

        ++tries;
    }

    writeln("invalid block index");
    return 0;
}

public class Level
{
    this( Renderer.Renderer renderer, Meshes aMeshes, Textures aTextures, bool aHasStairwayUp, bool aHasStairwayDown )
    {
        rooms[ 0 ].exitUp = true;
        rooms[ 0 ].exitDown = false;
        rooms[ 0 ].exitLeft = false;
        rooms[ 0 ].exitRight = false;

        rooms[ 1 ].exitUp = false;
        rooms[ 1 ].exitDown = true;
        rooms[ 1 ].exitLeft = false;
        rooms[ 1 ].exitRight = false;

        rooms[ 2 ].exitUp = false;
        rooms[ 2 ].exitDown = false;
        rooms[ 2 ].exitLeft = true;
        rooms[ 2 ].exitRight = false;

        rooms[ 3 ].exitUp = false;
        rooms[ 3 ].exitDown = false;
        rooms[ 3 ].exitLeft = false;
        rooms[ 3 ].exitRight = true;

        rooms[ 4 ].exitUp = true;
        rooms[ 4 ].exitDown = true;
        rooms[ 4 ].exitLeft = false;
        rooms[ 4 ].exitRight = false;

        rooms[ 5 ].exitUp = false;
        rooms[ 5 ].exitDown = false;
        rooms[ 5 ].exitLeft = true;
        rooms[ 5 ].exitRight = true;

        rooms[ 6 ].exitUp = true;
        rooms[ 6 ].exitDown = true;
        rooms[ 6 ].exitLeft = false;
        rooms[ 6 ].exitRight = true;

        hasStairwayUp = aHasStairwayUp;
        hasStairwayDown = aHasStairwayDown;

        meshes = aMeshes;
        textures = aTextures;

        GenerateBlocks();
        GenerateGeometry( renderer );
        GeneratePickups();
        GenerateMonsters();
    }

    private bool CanTravelBetweenStairs()
    {
        if (!hasStairwayDown)
        {
            return true;
        }

        return true;
    }

    public int[] GetStairwayDownPosition()
    {
        return stairwayDownPosition;
    }

    public int[] GetStairwayUpPosition()
    {
        return stairwayUpPosition;
    }

    public Monster* GetMonsterInFrontOfPlayer( Player.Player player )
    {
        auto playerForward = player.GetForwardPosition();
        for (int m = 0; m < monsters.length; ++m)
        {
            if (monsters[ m ].levelPosition[ 0 ] == playerForward[ 0 ] &&
                monsters[ m ].levelPosition[ 1 ] == playerForward[ 1 ])
            {
                return &monsters[ m ];
            }
        }

        return null;
    }

    public bool CanWalkForward( Player.Player player ) const
    {
        auto playerForward = player.GetForwardPosition();
        bool isEnemyThere = false;

        for (int m = 0; m < monsters.length; ++m)
        {
            if (monsters[ m ].levelPosition[ 0 ] == playerForward[ 0 ] &&
                monsters[ m ].levelPosition[ 1 ] == playerForward[ 1 ] &&
                monsters[ m ].isAlive)
            {
              isEnemyThere = true;
            }
        }

        return !isEnemyThere && blocks[ playerForward[ 1 ] * dimension + playerForward[ 0 ] ] == BlockType.None;
    }

    public bool CanWalkBackward( Player.Player player ) const
    {
        auto playerBackward = player.GetBackwardPosition();
        return blocks[ playerBackward[ 1 ] * dimension + playerBackward[ 0 ] ] == BlockType.None;
    }

    public bool HasHealthInPosition( int[] position ) const
    {
        for (int i = 0; i < healthPickups.length; ++i)
        {
            if (healthPickups[ i ].isActive && healthPickups[ i ].levelPosition == position)
            {
                return true;
            }
        }

        return false;
    }

    public void RemoveHealth( int[] position )
    {
        for (int i = 0; i < healthPickups.length; ++i)
        {
            if (healthPickups[ i ].levelPosition == position)
            {
                healthPickups[ i ].isActive = false;
            }
        }
    }

    public void Simulate( int[] playerPosition )
    {
        for (int i = 0; i < monsters.length; ++i)
        {
            if (monsters[ i ].isAlive)
            {
                const int moveDirection = uniform( 0, 6 );
                int oldPos0 = monsters[ i ].levelPosition[ 0 ];
                int oldPos1 = monsters[ i ].levelPosition[ 1 ];

                if (moveDirection == 0 && monsters[ i ].levelPosition[ 0 ] > 0 &&
                    blocks[ monsters[ i ].levelPosition[ 1 ] * dimension +
                            (monsters[ i ].levelPosition[ 0 ] - 1) ] == BlockType.None)
                {
                    --monsters[ i ].levelPosition[ 0 ];
                    writeln("move 0");
                }
                else if (moveDirection == 1 && monsters[ i ].levelPosition[ 0 ] < dimension - 1 &&
                         blocks[ monsters[ i ].levelPosition[ 1 ] * dimension +
                                 (monsters[ i ].levelPosition[ 0 ] + 1) ] == BlockType.None)
                {
                    ++monsters[ i ].levelPosition[ 0 ];
                    writeln("move 1");
                }
                else if (moveDirection == 2 && monsters[ i ].levelPosition[ 1 ] > 0 &&
                         blocks[ (monsters[ i ].levelPosition[ 1 ] - 1) * dimension +
                                  monsters[ i ].levelPosition[ 0 ] ] == BlockType.None)
                {
                    --monsters[ i ].levelPosition[ 1 ];
                    writeln("move 2");
                }
                else if (moveDirection == 3 && monsters[ i ].levelPosition[ 1 ] < dimension - 1 &&
                         blocks[ (monsters[ i ].levelPosition[ 1 ] + 1) * dimension +
                                  monsters[ i ].levelPosition[ 0 ] ] == BlockType.None)
                {
                    ++monsters[ i ].levelPosition[ 1 ];
                    writeln("move 3");
                }

                if (monsters[ i ].levelPosition[ 0 ] == playerPosition[ 0 ] && monsters[ i ].levelPosition[ 1 ] == playerPosition[ 1 ])
                {
                    monsters[ i ].levelPosition[ 0 ] = oldPos0;
                    monsters[ i ].levelPosition[ 1 ] = oldPos1;
                }
            }
        }
    }

    public void DebugPrintMonsters()
    {
        for (int i = 0; i < monsters.length; ++i)
        {
            writeln( "monster ", i, " alive: ", monsters[ i ].isAlive, ", pos ", monsters[ i ].levelPosition[ 0 ], ", ", monsters[ i ].levelPosition[ 1 ] );
        }
    }

    public void Draw( Renderer.Renderer renderer, float playerRotY )
    {
        textures.tex.Bind();
        renderer.SetMVP( Vec3.Vec3( 1, 1, 1 ), 0, 1 );
        renderer.DrawVAO( vaoID, elementCount * 3, [ 1, 1, 1, 1 ] );

        // Draws the ceiling. Wasteful, but there aren't a huge amount of tris in the level data.
        textures.floor.Bind();
        renderer.SetMVP( Vec3.Vec3( 1, 40, 1 ), 0, 1 );
        renderer.DrawVAO( vaoID, elementCount * 3, [ 1, 1, 1, 1 ] );

        textures.health.Bind();

        for (int i = 0; i < healthPickups.length; ++i)
        {
            if (healthPickups[ i ].isActive)
            {
                static float rotY = 0;
                ++rotY;
                renderer.SetMVP( Vec3.Vec3( healthPickups[ i ].levelPosition[ 0 ] * dimension * 2 - dimension, 0,
                                            healthPickups[ i ].levelPosition[ 1 ] * dimension * 2 - dimension * 2 ), rotY, 1 );
                renderer.DrawVAO( meshes.health.GetVAO(), meshes.health.GetElementCount() * 3, [ 1, 1, 1, 1 ] );
            }
        }

        textures.white.Bind();

        for (int i = 0; i < monsters.length; ++i)
        {
            if (monsters[ i ].isAlive)
            {
                float x = monsters[ i ].levelPosition[ 0 ] * dimension * 1 - dimension * 2 + dimension * 3 - 20;
                float z = monsters[ i ].levelPosition[ 1 ] * dimension * 1 - dimension * 2 + dimension * 3 - 20;
                //float z = monsters[ i ].levelPosition[ 1 ] * dimension * 2 - dimension * 2;

                //writeln( "monster ", i, " alive: ", monsters[ i ].isAlive, ", level pos ", monsters[ i ].levelPosition[ 0 ], ", ", monsters[ i ].levelPosition[ 1 ],
                //         ", visual pos: ", x, ", ", z, ", dimension: ", dimension );

                renderer.SetMVP( Vec3.Vec3( x, -5, z ), 0, 1.0f );
                float color = monsters[ i ].health / cast(float)monsters[ i ].healthMax;
                renderer.DrawVAO( meshes.monster1.GetVAO(), meshes.monster1.GetElementCount() * 3, [ 1, color, color, 1 ] );
            }
        }

        textures.white.Bind();

        if (hasStairwayUp)
        {
            renderer.SetMVP( Vec3.Vec3( stairwayUpPosition[ 0 ] * dimension * 2 - dimension, 0,
                                        stairwayUpPosition[ 1 ] * dimension * 2 - dimension * 2 ), 0, 8 );
            renderer.DrawVAO( meshes.stairway.GetVAO(), meshes.stairway.GetElementCount() * 3, [ 1, 1, 1, 1 ] );
        }
        if (hasStairwayDown)
        {
            renderer.SetMVP( Vec3.Vec3( stairwayDownPosition[ 0 ] * dimension * 2 - dimension, 0,
                                        stairwayDownPosition[ 1 ] * dimension * 2 - dimension * 2), 0, 8 );
            renderer.DrawVAO( meshes.stairway.GetVAO(), meshes.stairway.GetElementCount() * 3, [ 1, 0, 0, 1 ] );
        }
    }

    public bool CanGoUp( int[] playerPosition )
    {
        return (playerPosition[ 0 ] == stairwayUpPosition[ 0 ] && playerPosition[ 1 ] == stairwayUpPosition[ 1 ]);
    }

    public bool CanGoDown( int[] playerPosition )
    {
        return (playerPosition[ 0 ] == stairwayDownPosition[ 0 ] && playerPosition[ 1 ] == stairwayDownPosition[ 1 ]);
    }

    private void GeneratePickups()
    in
    {
        assert( elementCount > 0, "level geometry must be generated before placing pickups" );
    }
    do
    {
        // Place one pickup directly in front of the player to test pickup.
        healthPickups[ 0 ].levelPosition = [ 1, 2 ];

        int placedHealthPickupCounter = 1;

        int tries = 0;

        while (placedHealthPickupCounter < healthPickups.length && tries < 20)
        {
            ++tries;

            const int posCandidateX = uniform( 1, dimension - 2 );
            const int posCandidateY = uniform( 1, dimension - 2 );

            if (blocks[ posCandidateY * dimension + posCandidateX ] == BlockType.None)
            {
                healthPickups[ placedHealthPickupCounter ].levelPosition = [ posCandidateX, posCandidateY ];
                ++placedHealthPickupCounter;
            }
        }

        bool placedStairwayUp = false;
        bool placedStairwayDown = false;

        tries = 0;

        while ((!placedStairwayUp || !placedStairwayDown) && tries < 20)
        {
            ++tries;

            const int posCandidateUpX = uniform( 1, dimension / 2 );
            const int posCandidateUpZ = uniform( 1, dimension / 2 );

            const int posCandidateDownX = uniform( dimension / 2 + 1, dimension - 2 );
            const int posCandidateDownZ = uniform( dimension / 2 + 1, dimension - 2 );

            if (!placedStairwayUp && blocks[ posCandidateUpZ * dimension + posCandidateUpX ] == BlockType.None)
            {
                stairwayUpPosition = [ posCandidateUpX, posCandidateUpZ ];
                placedStairwayUp = true;
            }
            else if (!placedStairwayDown && blocks[ posCandidateDownZ * dimension + posCandidateDownX ] == BlockType.None &&
                     !(posCandidateDownX == stairwayUpPosition[ 0 ] && posCandidateDownZ == stairwayUpPosition[ 1 ] ) )
            {
                stairwayDownPosition = [ posCandidateDownX, posCandidateDownZ ];
                placedStairwayDown = true;
            }
        }
    }

    private void GenerateMonsters()
    in
    {
        assert( elementCount > 0, "level geometry must be generated before placing monsters" );
    }
    do
    {
        int placedMonsterCounter = 0;

        int tries = 0;

        // TODO: remove after testing
        monsters[ placedMonsterCounter ].levelPosition = [ 1, 2 ];
        ++placedMonsterCounter;
        monsters[ placedMonsterCounter ].levelPosition = [ 2, 2 ];
        ++placedMonsterCounter;

        while (placedMonsterCounter < monsters.length && tries < 20)
        {
            ++tries;

            immutable int posCandidateX = uniform( 1, dimension - 2 );
            immutable int posCandidateY = uniform( 1, dimension - 2 );

            if (blocks[ posCandidateY * dimension + posCandidateX ] == BlockType.None)
            {
                monsters[ placedMonsterCounter ].levelPosition = [ posCandidateX, posCandidateY ];
                ++placedMonsterCounter;
            }
        }
    }

    private void GenerateBlocks()
    {
        for (int i = 0; i < dimension * dimension; ++i)
        {
            blocks[ i ] = BlockType.Wall1;
        }

        int tries = 0;
        int[] blockIndices = new int[ (dimension / 5) * (dimension / 5) ];

        while (tries < 40)
        {
            for (int row = 0; row < dimension / 5; ++row)
            {
                for (int col = 0; col < dimension / 5; ++col)
                {
                    int blockIndex = GetFittingBlock( row, col, blockIndices, dimension );
                    blockIndices[ row * (dimension / 5) + col ] = blockIndex;
                }
            }

            bool success = true;

            for (int i = 0; i < blockIndices.length; ++i)
            {
                if (blockIndices[ i ] == -1)
                {
                    success = false;
                }
            }

            if (success)
            {
                break;
            }

            ++tries;
        }

        // Converts rooms to blocks
        for (int y = 0; y < dimension; y += 5)
        {
            for (int x = 0; x < dimension; x += 5)
            {
                for (int inY = 0; inY < 5; ++inY)
                {
                    for (int inX = 0; inX < 5; ++inX)
                    {
                        int blockIndex = (y + inY) * dimension + x + inX;
                        int innerIndex = inY * 5 + inX;
                        int innerBlockIndex = (y / 5) * (dimension / 5) + x / 5;
                        int b = blockIndices[ innerBlockIndex ];
                        blocks[ blockIndex ] = (block[ b ][ innerIndex ] == 0) ? BlockType.None : BlockType.Wall1;
                    }
                }
            }
        }

        writeln("level:");
        for (int y = 0; y < dimension; ++y)
        {
            for (int x = 0; x < dimension; ++x)
            {
                write( blocks[ y * dimension + x ] != BlockType.None ? "0" : "_" );
            }

            writeln();
        }
        //blocks[ 1 * dimension + 3 ] = BlockType.Wall1;
    }

    private void GenerateGeometry( Renderer.Renderer renderer )
    {
        Renderer.Vertex[] vertices;
        Renderer.Face[] faces;

        immutable int filledBlocks = dimension * dimension;
        immutable int vertexCount = 26;

        vertices = new Renderer.Vertex[ filledBlocks * vertexCount ];
        faces = new Renderer.Face[ filledBlocks * 6 * 2 ];
        elementCount = cast(int)faces.length;

        int vertexCounter = 0;
        int faceCounter = 0;

        for (int r = 0; r < dimension; ++r)
        {
            for (int c = 0; c < dimension; ++c)
            {
                //if (blocks[ r * dimension + c ] != BlockType.None)
                {
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, -1.000000, 1.000000 ], [ 1.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, -1.000000, -1.000000 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, -1.000000, -1.000000 ], [ 0.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, 1.000000, -1.000000 ], [ 1.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, 1.000000, 1.000001 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, 1.000000, -1.000000 ], [ 0.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, 1.000000, -1.00000 ], [ 1.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, -1.000000, 1.000000 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, 1.000000, 1.000001 ], [ 1.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, -1.000000, 1.000000 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, -1.000000, 1.000000 ], [ 0.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, -1.000000, 1.000000 ], [ 0.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, 1.000000, -1.000000 ], [ 1.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, -1.000000, -1.000000 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, -1.000000, -1.000000 ], [ 1.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, 1.000000, -1.000000 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, -1.000000, 1.000000 ], [ 1.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, 1.000000, 1.000000 ], [ 1.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.00000, 1.000000, 1.000001 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, 1.000000, 1.000001 ], [ 1.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ 1.000000, -1.000000, 1.000000 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, -1.000000, 1.000000 ], [ 0.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, 1.000000, 1.000000 ], [ 1.000000, 0.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, 1.000000, -1.000000 ], [ 1.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, -1.000000, -1.000000 ], [ 1.000000, 1.000000 ]);
                    vertices[ vertexCounter++ ] = Renderer.Vertex([ -1.000000, 1.000000, -1.000000 ], [ 0.000000, 1.000000 ]);

                    for (int i = 0; i < vertexCount; ++i)
                    {
                        immutable int s = 10;
                        immutable int s2 = s * 2;
                        const float y = blocks[ r * dimension + c ] != BlockType.None ? 0 : s * 2;

                        vertices[ vertexCounter - i - 1 ].pos[ 0 ] *= s;
                        vertices[ vertexCounter - i - 1 ].pos[ 1 ] *= s;
                        vertices[ vertexCounter - i - 1 ].pos[ 2 ] *= s;

                        vertices[ vertexCounter - i - 1 ].pos[ 0 ] += c * s2;
                        vertices[ vertexCounter - i - 1 ].pos[ 1 ] -= y;
                        vertices[ vertexCounter - i - 1 ].pos[ 2 ] += r * s2;
                    }

                    faces[ faceCounter++ ] = Renderer.Face( 0, 1, 2 );
                    faces[ faceCounter++ ] = Renderer.Face( 3, 4, 5 );
                    faces[ faceCounter++ ] = Renderer.Face( 6, 7, 2 );
                    faces[ faceCounter++ ] = Renderer.Face( 8, 9, 10 );
                    faces[ faceCounter++ ] = Renderer.Face( 11, 12, 13 );
                    faces[ faceCounter++ ] = Renderer.Face( 14, 15, 5 );
                    faces[ faceCounter++ ] = Renderer.Face( 0, 16, 13 );
                    faces[ faceCounter++ ] = Renderer.Face( 3, 17, 18 );
                    faces[ faceCounter++ ] = Renderer.Face( 6, 19, 20 );
                    faces[ faceCounter++ ] = Renderer.Face( 8, 17, 21 );
                    faces[ faceCounter++ ] = Renderer.Face( 11, 22, 23 );
                    faces[ faceCounter++ ] = Renderer.Face( 14, 24, 25 );

                    for (int f = 0; f < 12; ++f)
                    {
                        faces[ faceCounter - f - 1 ].a += vertexCounter - vertexCount;
                        faces[ faceCounter - f - 1 ].b += vertexCounter - vertexCount;
                        faces[ faceCounter - f - 1 ].c += vertexCounter - vertexCount;
                    }
                }
            }
        }

        renderer.GenerateVAO( vertices, faces, vaoID );
    }

    private Textures textures;
    private Meshes meshes;

    private immutable int dimension = 20;
    static assert( dimension % 5 == 0 );

    private BlockType[ dimension * dimension ] blocks = BlockType.None;
    private uint vaoID;
    private int elementCount;
    private int[ 2 ] stairwayUpPosition;
    private int[ 2 ] stairwayDownPosition;
    private bool hasStairwayDown;
    private bool hasStairwayUp;

    private struct HealthPickup
    {
        int[ 2 ] levelPosition;
        bool isActive = true;
    }

    private HealthPickup[ 3 ] healthPickups;
    private Monster[ 3 ] monsters;
}

