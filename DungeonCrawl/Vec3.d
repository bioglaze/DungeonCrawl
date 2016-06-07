module Vec3;
import std.math: abs, sqrt;

Vec3 Cross( Vec3 v1, Vec3 v2 )
{
    return Vec3( v1.y * v2.z - v1.z * v2.y,
                 v1.z * v2.x - v1.x * v2.z,
                 v1.x * v2.y - v1.y * v2.x );
}

float Dot( Vec3 v1, Vec3 v2 )
{
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z; 
}

void Normalize( ref Vec3 v )
{
    const float len = Length( v );
    v.x /= len;
    v.y /= len;
    v.z /= len;
}

float Length( ref Vec3 v )
{
    return sqrt( v.x * v.x + v.y * v.y + v.z * v.z );
}

bool IsAlmost( float f1, float f2 )
{
    return abs( f1 - f2 ) < 0.0001f;
}

bool IsAlmost( Vec3 v1, Vec3 v2 )
{
    return abs( v1.x - v2.x ) < 0.0001f &&
           abs( v1.y - v2.y ) < 0.0001f && 
           abs( v1.z - v2.z ) < 0.0001f;
}

struct Vec3
{
    this( float ax, float ay, float az )
    {
        x = ax;
        y = ay;
        z = az;
    }

    float x, y, z;
}

unittest
{
    Vec3 v = Vec3( 6, 6, 6 );
    Normalize( v );
    assert( IsAlmost( Length( v ), 1 ), "Vec3 Length failed" );

    assert( IsAlmost( Cross( Vec3( 1, 0, 0 ), Vec3( 0, 1, 0 ) ), Vec3( 0, 0, 1 ) ), "Vec3 Cross failed" );
}
