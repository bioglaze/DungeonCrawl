module Level;

enum BlockType
{
    None = 0,
    Wall,
}

class Level
{
    this()
    {
    }

    private BlockType[ 10 * 10 ] blocks;
}

