module Matrix4x4;
import std.math: tan, PI;
import Vec3;

void Multiply( Matrix4x4 a, Matrix4x4 b, out Matrix4x4 result )
{
    Matrix4x4 tmp;

    for (int i = 0; i < 4; ++i)
    {
        for (int j = 0; j < 4; ++j)
        {
            tmp.m[ i * 4 + j ] = a.m[ i * 4 + 0 ] * b.m[ 0 * 4 + j ] +
                a.m[ i * 4 + 1 ] * b.m[ 1 * 4 + j ] +
                a.m[ i * 4 + 2 ] * b.m[ 2 * 4 + j ] +
                a.m[ i * 4 + 3 ] * b.m[ 3 * 4 + j ];
        }
    }

    result = tmp;
}

struct Matrix4x4
{
    void MakeIdentity()
    {
        m[] = 0;
        m[  0 ] = 1;
        m[  5 ] = 1;
        m[ 10 ] = 1;
        m[ 15 ] = 1;
    }

	void MakeProjection( float left, float right, float bottom, float top, float nearDepth, float farDepth )
	{
		float tx = -((right + left) / (right - left));
		float ty = -((top + bottom) / (top - bottom));
		float tz = -((farDepth + nearDepth) / (farDepth - nearDepth));
		
		m =
		[
			2.0f / (right - left), 0.0f, 0.0f, 0.0f,
			0.0f, 2.0f / (top - bottom), 0.0f, 0.0f,
			0.0f, 0.0f, -2.0f / (farDepth - nearDepth), 0.0f,
			tx, ty, tz, 1.0f
		];
	}
	
    void MakeProjection( float fovDegrees, float aspect, float nearDepth, float farDepth )
    {
        const float top = tan( fovDegrees * PI / 360.0f ) * nearDepth;
        const float bottom = -top;
        const float left = aspect * bottom;
        const float right = aspect * top;

        const float x = (2 * nearDepth) / (right - left);
        const float y = (2 * nearDepth) / (top - bottom);
        const float a = (right + left)  / (right - left);
        const float b = (top + bottom)  / (top - bottom);

        const float c = -(farDepth + nearDepth) / (farDepth - nearDepth);
        const float d = -(2 * farDepth * nearDepth) / (farDepth - nearDepth);

        m =
        [
            x, 0, 0,  0,
            0, y, 0,  0,
            a, b, c, -1,
            0, 0, d,  0
        ];
    }

    void MakeLookAt( Vec3 eye, Vec3 center, Vec3 up )
    {
        Vec3.Vec3 zAxis = Vec3.Vec3( center.x - eye.x, center.y - eye.y, center.z - eye.z );
        Normalize( zAxis );
        Vec3 xAxis = Cross( up, zAxis );
        Normalize( xAxis );
        Vec3 yAxis = Cross( zAxis, xAxis );

        m[  0 ] = xAxis.x; m[  1 ] = xAxis.y; m[  2 ] = xAxis.z; m[  3 ] = -Vec3.Dot( xAxis, eye );
        m[  4 ] = yAxis.x; m[  5 ] = yAxis.y; m[  6 ] = yAxis.z; m[  7 ] = -Vec3.Dot( yAxis, eye );
        m[  8 ] = zAxis.x; m[  9 ] = zAxis.y; m[ 10 ] = zAxis.z; m[ 11 ] = -Vec3.Dot( zAxis, eye );
        m[ 12 ] =       0; m[ 13 ] =       0; m[ 14 ] =       0; m[ 15 ] = 1;
    }

    void Translate( float[ 3 ] v )
    {
        Matrix4x4 translateMatrix;
        translateMatrix.MakeIdentity();

        translateMatrix.m[ 12 ] = v[ 0 ];
        translateMatrix.m[ 13 ] = v[ 1 ];
        translateMatrix.m[ 14 ] = v[ 2 ];

        Multiply( this, translateMatrix, this );
    }

	float[] m = new float[ 16 ];
}

unittest
{
	auto proj = new Matrix4x4();
	proj.MakeProjection( 0, 640, 0, 480, -1, 1 );
	assert( proj.m[ 15 ] == 1 );
}

