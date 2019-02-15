module soko;

import dagon;

enum Direction { none, up, down, left, right }

enum Tile { empty, floor, wall, box, socket, boxOnSocket }

struct Undo
{
    ivec2 pos;
    Direction dir;
    int steps;
}

class Sokoban
{
    Tile[20][20] map;
    int mapWidth;
    int mapHeight;

    bool inMove;

    ivec2 playerPos;
    Direction playerDir;

    ivec2 boxPos; // Currently sliding box

    int boxes;
    int score;
    int steps;
    int pushes;

    enum maxUndos = 32;
    Undo[maxUndos] undos;
    int undoStart;
    int undoSize;

    this()
    {
        reset();
    }

    void reset()
    {
        inMove = false;
        playerDir = Direction.down;
        boxPos.x = -1;
        mapWidth = mapHeight = 0;
        boxes = score = steps = pushes = 0;
        undoSize = 0;
        for(int k = 0; k < 20; k++)
            for(int j = 0; j < 20; j++)
                map[k][j] = Tile.empty;
    }

    int loadMap(string txt, int i)
    {
        return loadMap(cast(char*)txt.ptr, txt.length, i);
    }

    int loadMap(char* txt, ulong len, int i)
    {
        reset();
        int x = 0;
        int y = 0;
        char ch = 0;
        int index = 0;
        while(i > 0)
        {
            if((ch = txt[index++]) == ';')
                i--;
            if(index == len)
                return -1;
        }
        if(ch == ';') while((ch = txt[index++]) != '\n') {}
        bool canLoadEmpty = false;
        while(ch != ';')
        {
            ch = txt[index++];
            switch(ch)
            {
                case '\n':
                    if(x > 0)
                    {
                        y++;
                        mapWidth = mapWidth > x ? mapWidth : x;
                        x = 0;
                    }
                    canLoadEmpty = false;
                    continue;
                case '*':
                    score++;
                    boxes++;
                    map[y][x] = Tile.boxOnSocket;
                    canLoadEmpty = true;
                    break;
                case '$':
                    boxes++;
                    map[y][x] = Tile.box;
                    canLoadEmpty = true;
                    break;
                case '#':
                    map[y][x] = Tile.wall;
                    canLoadEmpty = true;
                    break;
                case '.':
                    map[y][x] = Tile.socket;
                    canLoadEmpty = true;
                    break;
                case ' ':
                    if(canLoadEmpty)
                        map[y][x] = Tile.floor;
                    break;
                case '@':
                    playerPos = ivec2(x * 64, y * 64);
                    map[y][x] = Tile.floor;
                    break;
                case '+':
                    playerPos = ivec2(x * 64, y * 64);
                    map[y][x] = Tile.socket;
                    break;
                default:
                    break;
            }
            x++;
        }
        mapHeight = y;
        return 1;
    }

    void addUndo()
    {
        Undo undo = Undo(playerPos, playerDir, steps);
        undos[undoStart] = undo;
        undoStart++;
        undoStart = undoStart % maxUndos;
        if(undoSize < maxUndos)
            undoSize++;
    }

    void doUndo()
    {
        if(undoSize)
        {
            undoSize--;
            undoStart--;
            if(undoStart == -1)
                undoStart = maxUndos - 1;

            Undo u = undos[undoStart];
            playerPos.x = u.pos.x;
            playerPos.y = u.pos.y;
            playerDir = u.dir;
            steps = u.steps;
            pushes--;

            ivec2 vec = dirToVec(playerDir);
            ivec2 o = vec + playerPos / 64;
            ivec2 b = vec + o;

            if(map[b.y][b.x] == Tile.boxOnSocket)
                score--;

            if(map[o.y][o.x] == Tile.socket)
                score++;

            map[b.y][b.x] = map[b.y][b.x] == Tile.boxOnSocket ? Tile.socket : Tile.floor;
            map[o.y][o.x] = map[o.y][o.x] == Tile.socket ? Tile.boxOnSocket : Tile.box;

        }
    }

    ivec2 dirToVec(Direction dir)
    {
        ivec2 vec;
        switch(playerDir)
        {
            case Direction.up:    vec.y--; break;
            case Direction.down:  vec.y++; break;
            case Direction.left:  vec.x--; break;
            case Direction.right: vec.x++; break;
            default: break;
        }
        return vec;
    }

    int step(ivec2 dir, ivec2 pos)
    {
        if(map[pos.y][pos.x] == Tile.wall)
            return 0;
      
        if(map[pos.y][pos.x] == Tile.box || map[pos.y][pos.x] == Tile.boxOnSocket)
        {
            ivec2 b = pos + dir;

            if(map[b.y][b.x] != Tile.floor && map[b.y][b.x] != Tile.socket)
                return 0;

            addUndo();

            if(map[pos.y][pos.x] == Tile.boxOnSocket)
                score--;

            map[pos.y][pos.x] = map[pos.y][pos.x] == Tile.boxOnSocket ? Tile.socket : Tile.floor;

            pushes++;

            boxPos = pos * 64 + dir * 4;
        }

        steps++;
        return 1;
    }

    void logic(Direction dir)
    {
        if(!inMove)
        {
            if(dir != Direction.none)
            {
                playerDir = dir;
                ivec2 vdir = dirToVec(dir);

                if(step(vdir, playerPos / 64 + vdir))
                {
                    playerPos += vdir * 4;
                    inMove = true;
                }
            }
        }
        else
        {
            // player in move
            playerPos += dirToVec(playerDir) * 4;

            if(boxPos.x != -1)
                boxPos += dirToVec(playerDir) * 4;

            if((playerPos.x % 64) == 0 && (playerPos.y % 64) == 0)
            {
                inMove = false;
                if(boxPos.x != -1)
                {
                    ivec2 b = boxPos / 64;

                    if(map[b.y][b.x] == Tile.socket)
                        score++;

                    map[b.y][b.x] = map[b.y][b.x] == Tile.socket ? Tile.boxOnSocket : Tile.box;

                    boxPos.x = -1;
                }
            }
        }
    }
}