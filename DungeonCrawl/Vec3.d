module Vec3;
import std.math: sqrt;

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
    float len = sqrt( v.x * v.x + v.y * v.y + v.z * v.z );
    v.x /= len;
    v.y /= len;
    v.z /= len;
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
