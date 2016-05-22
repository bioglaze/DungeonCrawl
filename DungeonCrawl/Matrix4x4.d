module Matrix4x4;

class Matrix4x4
{
	this()
	{
		// Constructor code
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
	
	float[] m = new float[ 16 ];
}

unittest
{
	auto proj = new Matrix4x4();
	proj.MakeProjection( 0, 640, 0, 480, -1, 1 );
	assert( proj.m[ 15 ] == 1 );
}

