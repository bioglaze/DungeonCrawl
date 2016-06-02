﻿module Level;
import Renderer;
static import std.stdio;

enum BlockType
{
    None = 0,
    Wall,
}

class Level
{
    this( Renderer renderer )
    {
        // Fills the edges
        for (int i = 0; i < dimension; ++i)
        {
            blocks[ i ] = BlockType.Wall;
            blocks[ (dimension - 1) * dimension + i ] = BlockType.Wall;
            blocks[ (dimension - 1) * i ] = BlockType.Wall;
            blocks[ (dimension - 1) * i + dimension - 1 ] = BlockType.Wall;
        }

        GenerateGeometry( renderer );
    }

	public void GenerateGeometry( Renderer renderer )
	{
	    Renderer.Vertex[] vertices;
        Renderer.Face[] faces;

        int filledBlocks = 0;

        for (int i = 0; i < dimension * dimension; ++i)
        {
            if (blocks[ i ] != BlockType.None)
            {
                ++filledBlocks;
            }
        }

        vertices = new Renderer.Vertex[ filledBlocks * 8 ];
        faces = new Renderer.Face[ filledBlocks * 6 * 2 ];
        elementCount = faces.length;

        int vertexCounter = 0;
        int faceCounter = 0;

        for (int r = 0; r < dimension; ++r)
        {
            for (int c = 0; c < dimension; ++c)
            {
                if (blocks[ r * dimension + c ] != BlockType.None)
                {
                    int s = 10;
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [ -s, -s, s ], [ 0, 0 ] );
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [  s, -s, s ], [ 0, 0 ] );
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [  s, -s,-s ], [ 0, 0 ] );
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [ -s, -s,-s ], [ 0, 0 ] );
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [ -s,  s, s ], [ 0, 0 ] );
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [  s,  s, s ], [ 0, 0 ] );
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [  s,  s,-s ], [ 0, 0 ] );
                    vertices[ vertexCounter++ ] = Renderer.Vertex( [ -s,  s,-s ], [ 0, 0 ] );

                    faces[ faceCounter++ ] = Renderer.Face( 0, 4, 1 );
                    faces[ faceCounter++ ] = Renderer.Face( 4, 5, 1 );
                    faces[ faceCounter++ ] = Renderer.Face( 1, 5, 2 );
                    faces[ faceCounter++ ] = Renderer.Face( 2, 5, 6 );
                    faces[ faceCounter++ ] = Renderer.Face( 2, 6, 3 );
                    faces[ faceCounter++ ] = Renderer.Face( 3, 6, 7 );
                    faces[ faceCounter++ ] = Renderer.Face( 3, 7, 0 );
                    faces[ faceCounter++ ] = Renderer.Face( 0, 7, 4 );
                    faces[ faceCounter++ ] = Renderer.Face( 4, 7, 5 );
                    faces[ faceCounter++ ] = Renderer.Face( 5, 7, 6 );
                    faces[ faceCounter++ ] = Renderer.Face( 3, 0, 2 );
                    faces[ faceCounter++ ] = Renderer.Face( 2, 0, 1 );
                }
            }
        }

        renderer.GenerateVAO( vertices, faces, vaoID );
        //std.stdio.writeln( "vertexCounter: ", vertexCounter );
        //std.stdio.writeln( "faceCounter: ", faceCounter );
	}

    public uint GetVAO() const
    {
        return vaoID;
    }

    public int GetElementCount() const
    {
        return elementCount;
    }

    private immutable int dimension = 10;
    private BlockType[ dimension * dimension ] blocks;
    private uint vaoID;
    private int elementCount;
}
