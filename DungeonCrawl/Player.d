module Player;
import std.typecons;
import std.math;
import std.algorithm;
import std.stdio;
import Vec3;

enum FacingDirection
{
    North = 0, East, South, West
}

class Player
{
    public void WalkForward()
    {
        if (facingDirection == FacingDirection.North)
        {
            --levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.South)
        {
            ++levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.East)
        {
            ++levelPosition[ 0 ];
        }
        else if (facingDirection == FacingDirection.West)
        {
            --levelPosition[ 0 ];
        }
    }

    public void WalkBackward()
    {
        if (facingDirection == FacingDirection.North)
        {
            ++levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.South)
        {
            --levelPosition[ 1 ];
        }
        else if (facingDirection == FacingDirection.East)
        {
            --levelPosition[ 0 ];
        }
        else if (facingDirection == FacingDirection.West)
        {
            ++levelPosition[ 0 ];
        }
    }

    public void TurnRight()
    {
        facingDirection = cast(FacingDirection)((cast(int)facingDirection + 1) % 4);
    }

    public void TurnLeft()
    {
        final switch (facingDirection)
        {
            case FacingDirection.North: facingDirection = FacingDirection.West; break;
            case FacingDirection.South: facingDirection = FacingDirection.East; break;
            case FacingDirection.East: facingDirection = FacingDirection.North; break;
            case FacingDirection.West: facingDirection = FacingDirection.South; break;
        }
    }

    public Tuple!(int, int) GetForwardPosition()
    {
        final switch (facingDirection)
        {
            case FacingDirection.North: return tuple( levelPosition[ 0 ], levelPosition[ 1 ] - 1 );
            case FacingDirection.South: return tuple( levelPosition[ 0 ], levelPosition[ 1 ] + 1);
            case FacingDirection.East: return tuple( levelPosition[ 0 ] + 1, levelPosition[ 1 ]  );
            case FacingDirection.West: return tuple( levelPosition[ 0 ] - 1, levelPosition[ 1 ]  );
        }
    }

    public Tuple!(int, int) GetBackwardPosition()
    {
        final switch (facingDirection)
        {
            case FacingDirection.North: return tuple( levelPosition[ 0 ], levelPosition[ 1 ] + 1 );
            case FacingDirection.South: return tuple( levelPosition[ 0 ], levelPosition[ 1 ] - 1 );
            case FacingDirection.East: return tuple( levelPosition[ 0 ] - 1, levelPosition[ 1 ]  );
            case FacingDirection.West: return tuple( levelPosition[ 0 ] + 1, levelPosition[ 1 ]  );
        }
    }

    public Vec3 GetWorldPosition() const
    {
        return Vec3.Vec3( levelPosition[ 0 ] * 20, 0, levelPosition[ 1 ] * 20 );
    }

    public Vec3 GetWorldDirection() const
    {
        final switch (facingDirection)
        {
            case FacingDirection.South: return Vec3.Vec3( 0, 0, -1 );
            case FacingDirection.North: return Vec3.Vec3( 0, 0, 1 );
            case FacingDirection.East: return Vec3.Vec3( -1, 0, 0 );
            case FacingDirection.West: return Vec3.Vec3( 1, 0, 0 );
        }
    }

    public int GetHealth() const
    {
        return health;
    }
    
    public void EatFood( int healthGain )
    {
        health = min( health + healthGain, healthMax );
    }
    
    private int[ 2 ] levelPosition = [ 1, 1 ];
    private FacingDirection facingDirection = FacingDirection.South;
    private int health = 2;
    private int healthMax = 2;
}
