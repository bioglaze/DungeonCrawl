module Level;
import Mesh;
import Player;
import Renderer;
import Texture;
import Vec3;
static import std.stdio;
import std.stdio;
import std.random: uniform;

private enum BlockType
{
    None = 0,
    Wall1,
    Wall2,
}

public class Level
{
    this( Renderer renderer )
    {
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
        
        tex = new Texture( "assets/wall1.tga" );

        meshes.sword = new Mesh( "assets/sword.obj", renderer );
        meshes.health = new Mesh( "assets/sword.obj", renderer );
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

    public void Draw( Renderer renderer )
    {
        BindTextures();
        renderer.SetMVP( Vec3.Vec3( 1, 1, 1 ), 1 );
        renderer.DrawVAO( vaoID, elementCount * 3 );

        renderer.SetMVP( Vec3.Vec3( 20, 0, 40 ), 10 ); // 20, 0, 20 is tile 1, 1
        renderer.DrawVAO( meshes.sword.GetVAO(), meshes.sword.GetElementCount() * 3 );
    }
    
    public void BindTextures()
    {
        tex.Bind();
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
            int posCandidateX = uniform( 1, 8 );
            int posCandidateY = uniform( 1, 8 );

            if (blocks[ posCandidateY * dimension + posCandidateX ] == BlockType.None)
            {
                healthPickups[ placedHealthPickupCounter ].levelPosition = [ posCandidateX, posCandidateY ];
                ++placedHealthPickupCounter;
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
            int posCandidateX = uniform( 1, 8 );
            int posCandidateY = uniform( 1, 8 );

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

    private struct Meshes
    {
        Mesh sword;
        Mesh health;
    };

    private Meshes meshes;
    private immutable int dimension = 10;
    private BlockType[ dimension * dimension ] blocks = BlockType.None;
    private uint vaoID;
    private int elementCount;
    private Texture tex;

    private struct HealthPickup
    {
        int[ 2 ] levelPosition;
        bool isActive = false;
    }

    private struct Monster
    {
        int[ 2 ] levelPosition;
        bool isAlive = true;
    }
    
    private HealthPickup[ 3 ] healthPickups;
    private Monster[ 3 ] monsters;
}

