module Level;
import Mesh;
import Player;
import Renderer;
import Texture;
import Vec3;
static import std.stdio;
import std.stdio;
import std.random: uniform;

public struct Meshes
{
    Mesh sword;
    Mesh health;
    Mesh monster1;
    Mesh stairway;
}

public struct Textures
{
    Texture tex;
    Texture health;
    Texture white;
}

public struct Monster
{
    int[ 2 ] levelPosition;
    bool isAlive = true;
}

private enum BlockType
{
    None = 0,
    Wall1,
    Wall2,
}

public class Level
{
    this( Renderer renderer, Meshes aMeshes, Textures aTextures, bool aHasStairwayUp, bool aHasStairwayDown )
    {
        hasStairwayUp = aHasStairwayUp;
        hasStairwayDown = aHasStairwayDown;
        
        meshes = aMeshes;
        textures = aTextures;
        
        //blocks[ 2 * dimension + 4 ] = BlockType.Wall1;
        //blocks[ 4 * dimension + 2 ] = BlockType.Wall1;
        blocks[ 1 * dimension + 3 ] = BlockType.Wall1;
        // Fills the edges
        for (int i = 0; i < dimension; ++i)
        {
            blocks[ i ] = BlockType.Wall1;
            blocks[ dimension * dimension - i - 1 ] = BlockType.Wall1;
            blocks[ dimension * i ] = BlockType.Wall1;
            blocks[ dimension * i + dimension - 1 ] = BlockType.Wall1;
        }

        GenerateGeometry( renderer );
        GeneratePickups();
        GenerateMonsters();        
    }

    public int[] GetStairwayDownPosition()
    {
        return stairwayDownPosition;
    }

    public int[] GetStairwayUpPosition()
    {
        return stairwayUpPosition;
    }

    public Monster* GetMonsterInFrontOfPlayer( Player player )
    {
        auto playerForward = player.GetForwardPosition();
        for (int m = 0; m < monsters.length; ++m)
        {
            if (monsters[ m ].levelPosition[ 0 ] == playerForward[ 0 ] &&
                monsters[ m ].levelPosition[ 1 ] == playerForward[ 1 ])
            {
                writeln("monster in front of player");
            }
        }

        return null;
    }
    
    public bool CanWalkForward( Player player ) const
    {
        auto playerForward = player.GetForwardPosition();
        return blocks[ playerForward[ 1 ] * dimension + playerForward[ 0 ] ] == BlockType.None;
    }

    public bool CanWalkBackward( Player player ) const
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

    public void Simulate()
    {
        for (int i = 0; i < monsters.length; ++i)
        {
            if (monsters[ i ].isAlive)
            {
                const int moveDirection = uniform( 0, 4 );

                if (moveDirection == 0 && monsters[ i ].levelPosition[ 0 ] > 0)
                {
                    --monsters[ i ].levelPosition[ 0 ];
                }
                else if (moveDirection == 1 && monsters[ i ].levelPosition[ 0 ] < dimension - 1)
                {
                    ++monsters[ i ].levelPosition[ 0 ];
                }
                else if (moveDirection == 2 && monsters[ i ].levelPosition[ 1 ] > 0)
                {
                    --monsters[ i ].levelPosition[ 1 ];
                }
                else if (moveDirection == 3 && monsters[ i ].levelPosition[ 1 ] < dimension - 1)
                {
                    ++monsters[ i ].levelPosition[ 1 ];
                }
            }
        }
    }
    
    public void Draw( Renderer renderer )
    {
        textures.tex.Bind();
        renderer.SetMVP( Vec3.Vec3( 1, 1, 1 ), 0, 1 );
        renderer.DrawVAO( vaoID, elementCount * 3, [ 1, 1, 1 ] );

        // Draws the ceiling. Wasteful, but there aren't a huge amount of tris in the level data.
        renderer.SetMVP( Vec3.Vec3( 1, 40, 1 ), 0, 1 );
        renderer.DrawVAO( vaoID, elementCount * 3, [ 1, 1, 1 ] );

        textures.health.Bind();

        for (int i = 0; i < healthPickups.length; ++i)
        {
            if (healthPickups[ i ].isActive)
            {
                static float rotY = 0;
                ++rotY;
                renderer.SetMVP( Vec3.Vec3( healthPickups[ i ].levelPosition[ 0 ] * dimension * 2, 0,
                                            healthPickups[ i ].levelPosition[ 1 ] * dimension * 2 ), rotY, 1 );
                renderer.DrawVAO( meshes.health.GetVAO(), meshes.health.GetElementCount() * 3, [ 1, 1, 1 ] );
            }
        }

        textures.white.Bind();

        for (int i = 0; i < monsters.length; ++i)
        {
            if (monsters[ i ].isAlive)
            {
                renderer.SetMVP( Vec3.Vec3( monsters[ i ].levelPosition[ 0 ] * dimension * 2, -5,
                                            monsters[ i ].levelPosition[ 1 ] * dimension * 2 ), 0, 1.5f );
                renderer.DrawVAO( meshes.monster1.GetVAO(), meshes.monster1.GetElementCount() * 3, [ 1, 1, 1 ] );
            }
        }

        textures.white.Bind();

        if (hasStairwayUp)
        {
            renderer.SetMVP( Vec3.Vec3( stairwayUpPosition[ 0 ] * dimension * 2, 0,
                                        stairwayUpPosition[ 1 ] * dimension * 2 ), 0, 8 );
            renderer.DrawVAO( meshes.stairway.GetVAO(), meshes.stairway.GetElementCount() * 3, [ 1, 1, 1 ] );
        }
        if (hasStairwayDown)
        {
            renderer.SetMVP( Vec3.Vec3( stairwayDownPosition[ 0 ] * dimension * 2, 0,
                                        stairwayDownPosition[ 1 ] * dimension * 2 ), 0, 8 );
            renderer.DrawVAO( meshes.stairway.GetVAO(), meshes.stairway.GetElementCount() * 3, [ 1, 0, 0 ] );
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
    body
    {    
        int placedHealthPickupCounter = 0;

        while (placedHealthPickupCounter < healthPickups.length)
        {
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

        while (!placedStairwayUp || !placedStairwayDown)
        {
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
    body
    {    
        int placedMonsterCounter = 0;

        while (placedMonsterCounter < monsters.length)
        {
            int posCandidateX = uniform( 1, dimension - 2 );
            int posCandidateY = uniform( 1, dimension - 2 );

            if (blocks[ posCandidateY * dimension + posCandidateX ] == BlockType.None)
            {
                monsters[ placedMonsterCounter ].levelPosition = [ posCandidateX, posCandidateY ];
                ++placedMonsterCounter;
            }
        }
    }
    
    private void GenerateGeometry( Renderer renderer )
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
    private immutable int dimension = 10;
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

