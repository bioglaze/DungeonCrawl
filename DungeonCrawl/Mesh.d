module Mesh;
import std.stdio;
import std.string;
import std.format;
import std.math: abs;
import Vec3;
import Renderer;

struct ObjFace
{
    ushort v1, v2, v3;
    ushort t1, t2, t3;
    ushort n1, n2, n3;
}

class Mesh
{
    this( string path, Renderer renderer )
    {
        Vec3[] vertices;
        Vec3[] normals;
        Vec3[] texcoords;
        ObjFace[] faces;
        
        LoadObj( path, vertices, normals, texcoords, faces );
        Interleave( vertices, normals, texcoords, faces );
        renderer.GenerateVAO( interleavedVertices, indices, vao );
    }

    public void GetVaoAndFaceCount( out uint vaoId, out uint faceCount )
    {
        vaoId = vao;
        faceCount = cast( uint )indices.length;
    }
    
    // Tested only with models exported from Blender. File must contain one mesh only,
    // exported with triangulation, texcoords and normals.
    private void LoadObj( string path, ref Vec3[] vertices, ref Vec3[] normals, ref Vec3[] texcoords, ref ObjFace[] faces )
    {
        auto file = File( path, "r" );

        if (!file.isOpen())
        {
            writeln( "Could not open ", path );
            return;
        }

        while (!file.eof())
        {
            string line = strip( file.readln() );
            
            if (line.length > 1 && line[ 0 ] == 'v' && line[ 1 ] != 'n' && line[1] != 't')
            {
                Vec3 vertex;
                string v;
                uint items = formattedRead( line, "%s %f %f %f", &v, &vertex.x, &vertex.y, &vertex.z );
                assert( items == 4, "parse error readin .obj file" );
                vertices ~= vertex;
            }
            else if (line.length > 0 && line[ 0..2 ] == "vn")
            {
                Vec3 normal;
                string v;
                uint items = formattedRead( line, "%s %f %f %f", &v, &normal.x, &normal.y, &normal.z );
                assert( items == 4, "parse error readin .obj file" );
                normals ~= normal;
            }
            else if (line.length > 0 && line[ 0..2 ] == "vt")
            {
                Vec3 texcoord;
                string v;
                uint items = formattedRead( line, "%s %f %f", &v, &texcoord.x, &texcoord.y );
                assert( items == 3, "parse error readin .obj file" );
                texcoords ~= texcoord;
            }
        }

        file.seek( 0 );

        while (!file.eof())
        {
            string line = strip( file.readln() );
            
            if (line.length > 0 && line[ 0 ] == 'f')
            {
                ObjFace face;
                string v;
                uint items = formattedRead( line, "%s %d/%d/%d %d/%d/%d %d/%d/%d", &v, &face.v1, &face.t1, &face.n1,
                                            &face.v2, &face.t2, &face.n2,
                                            &face.v3, &face.t3, &face.n3 );
                // OBJ faces are 1-indexed, convert to 0-indexed.
                --face.v1;
                --face.v2;
                --face.v3;

                --face.n1;
                --face.n2;
                --face.n3;

                --face.t1;
                --face.t2;
                --face.t3;

                faces ~= face;
            }
        }
    }

    private bool AlmostEquals( float[ 3 ] v1, Vec3 v2 ) const
    {
        if (abs( v1[ 0 ] - v2.x ) > 0.0001f) { return false; }
        if (abs( v1[ 1 ] - v2.y ) > 0.0001f) { return false; }
        if (abs( v1[ 2 ] - v2.z ) > 0.0001f) { return false; }
        return true;
    }

    private bool AlmostEquals( float[ 2 ] v1, Vec3 v2 ) const
    {
        if (abs( v1[ 0 ] - v2.x ) > 0.0001f) { return false; }
        if (abs( v1[ 1 ] - v2.y ) > 0.0001f) { return false; }
        return true;
    }
    
    private void Interleave( ref Vec3[] vertices, ref Vec3[] normals, ref Vec3[] texcoords, ObjFace[] faces )
    {
        Renderer.Face face;

        for (int f = 0; f < faces.length; ++f)
        {
            Vec3 tvertex = vertices[ faces[ f ].v1 ];
            Vec3 tnormal = normals[ faces[ f ].n1 ];
            Vec3 ttcoord = texcoords[ faces[ f ].t1 ];

            // Searches vertex from vertex list and adds it if not found.

            // Vertex 1
            bool found = false;

            for (int i = 0; i < indices.length; ++i)
            {
                if (AlmostEquals( interleavedVertices[ indices[ i ].a ].pos, tvertex ) &&
                    AlmostEquals( interleavedVertices[ indices[ i ].a ].uv, ttcoord ))
                {
                    found = true;
                    face.a = indices[ i ].a;
                    break;
                }
            }

            if (!found)
            {
                Renderer.Vertex vertex;
                vertex.pos = [ tvertex.x, tvertex.y, tvertex.z ];
                vertex.uv = [ ttcoord.x, ttcoord.y ];

                interleavedVertices ~= vertex;
                face.a = cast( ushort )(interleavedVertices.length - 1);
            }

            // Vertex 2
            tvertex = vertices[ faces[ f ].v2 ];
            tnormal = normals[ faces[ f ].n2 ];
            ttcoord = texcoords[ faces[ f ].t2 ];

            found = false;

            for (int i = 0; i < indices.length; ++i)
            {
                if (AlmostEquals( interleavedVertices[ indices[ i ].b ].pos, tvertex ) &&
                    AlmostEquals( interleavedVertices[ indices[ i ].b ].uv, ttcoord ))
                {
                    found = true;
                    face.b = indices[ i ].b;
                    break;
                }
            }

            if (!found)
            {
                Renderer.Vertex vertex;
                vertex.pos = [ tvertex.x, tvertex.y, tvertex.z ];
                vertex.uv = [ ttcoord.x, ttcoord.y ];

                interleavedVertices ~= vertex;
                face.b = cast( ushort )(interleavedVertices.length - 1);
            }

            // Vertex 3
            tvertex = vertices[ faces[ f ].v3 ];
            tnormal = normals[ faces[ f ].n3 ];
            ttcoord = texcoords[ faces[ f ].t3 ];

            found = false;

            for (int i = 0; i < indices.length; ++i)
            {
                if (AlmostEquals( interleavedVertices[ indices[ i ].c ].pos, tvertex ) &&
                    AlmostEquals( interleavedVertices[ indices[ i ].c ].uv, ttcoord ))
                {
                    found = true;
                    face.c = indices[ i ].c;
                    break;
                }
            }

            if (!found)
            {
                Renderer.Vertex vertex;
                vertex.pos = [ tvertex.x, tvertex.y, tvertex.z ];
                vertex.uv = [ ttcoord.x, ttcoord.y ];

                interleavedVertices ~= vertex;
                face.c = cast( ushort )(interleavedVertices.length - 1);
            }

            indices ~= face;
        }
    }

    public uint GetVAO() const
    {
        return vao;
    }

    public uint GetElementCount() const
    {
        return cast( uint )indices.length;
    }
    
    private Renderer.Vertex[] interleavedVertices;
    private Renderer.Face[] indices;
    private uint vao;
}
