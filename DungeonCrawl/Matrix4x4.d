module Matrix4x4;
import std.math: tan, PI;

struct Matrix4x4
{
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

	float[] m = new float[ 16 ];
}

unittest
{
	auto proj = new Matrix4x4();
	proj.MakeProjection( 0, 640, 0, 480, -1, 1 );
	assert( proj.m[ 15 ] == 1 );
}

