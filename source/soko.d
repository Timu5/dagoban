module soko;

import dagon;

enum Direction { none, up, down, left, right }

struct Undo
{
    ivec2 pos;
    Direction dir;
    int steps;
}

class Sokoban
{
    char[20][20] map;
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

    enum maxUndos = 20;
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
        mapWidth = 0;
        mapHeight = 0;
        boxes = 0;
        score = 0;
        steps = 0;
        pushes = 0;
        undoSize = 0;
        for(int k = 0; k < 20; k++)
            for(int j = 0; j < 20; j++)
                map[k][j] = 0;
    }


    int loadMap(string txt, int i)
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
            if(index == txt.length)
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
                    goto case;
                case '$':
                    boxes++;
                    goto case;
                case '#':
                case '.':
                    map[y][x] = ch;
                    canLoadEmpty = true;
                    break;
                case ' ':
                    if(canLoadEmpty)
                        map[y][x] = ch;
                    break;
                case '@':
                    playerPos = ivec2(x * 64, y * 64);
                    map[y][x] = ' ';
                    break;
                case '+':
                    playerPos = ivec2(x * 64, y * 64);
                    map[y][x] = '.';
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

            int x = 0;
            int y = 0;
            switch(playerDir)
            {
                case Direction.up:    y--; break;
                case Direction.down:  y++; break;
                case Direction.left:  x--; break;
                case Direction.right: x++; break;
                default: break;
            }
            int ox = x + playerPos.x/64;
            int oy = y + playerPos.y/64;
            int bx = x + ox;
            int by = y + oy;

            if(map[by][bx] == '*')
                score--;

            if(map[oy][ox] == '.')
                score++;

            map[by][bx] = map[by][bx] == '*' ? '.' : ' ';
            map[oy][ox] = map[oy][ox] == '.' ? '*' : '$';

        }
    }

    int step(ivec2 dir, ivec2 pos)
    {
        if(map[pos.y][pos.x] == '#')
            return 0;
      
        if(map[pos.y][pos.x] == '$' || map[pos.y][pos.x] == '*')
        {
            ivec2 b = pos + dir;

            if(map[b.y][b.x] != ' ' && map[b.y][b.x] != '.')
                return 0;

            addUndo();

            if(map[pos.y][pos.x] == '*')
                score--;

            map[pos.y][pos.x] = map[pos.y][pos.x] == '*' ? '.' : ' ';

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
                // player idle
                ivec2 vdir;
                playerDir = dir;
                switch(dir)
                {
                    case Direction.left:  vdir.x--; break;
                    case Direction.right: vdir.x++; break;
                    case Direction.up:    vdir.y--; break;
                    case Direction.down:  vdir.y++; break;
                    default: return;
                }
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
            switch(playerDir)
            {
                case Direction.up:    playerPos.y -= 4; if(boxPos.x != -1) boxPos.y -= 4; break;
                case Direction.down:  playerPos.y += 4; if(boxPos.x != -1) boxPos.y += 4; break;
                case Direction.left:  playerPos.x -= 4; if(boxPos.x != -1) boxPos.x -= 4; break;
                case Direction.right: playerPos.x += 4; if(boxPos.x != -1) boxPos.x += 4; break;
                default: break;
            }
            if((playerPos.x % 64) == 0 && (playerPos.y % 64) == 0)
            {
                inMove = false;
                if(boxPos.x != -1)
                {
                    //int bx = boxPos.x / 64;
                    //int by = boxPos.y / 64;
                    ivec2 b = boxPos / 64;

                    if(map[b.y][b.x] == '.')
                        score++;

                    map[b.y][b.x] = map[b.y][b.x] == '.' ? '*' : '$';

                    boxPos.x = -1;
                }
            }
        }
    }
}