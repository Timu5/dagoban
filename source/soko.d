module soko;

enum Direction { up, down, left, right }

struct Undo
{
    int playerX;
    int playerY;
    int playerDirection;
    int steps;
}

class Sokoban
{
    int width;
    int height;
    char[20][20] map;
    bool playerInMove;
    int playerX;
    int playerY;
    int playerDirection;
    int boxX;
    int boxY;
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
        playerInMove = false;
        playerDirection = Direction.down;
        boxX = -1;
        width = 0;
        height = 0;
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
                        width = width > x ? width : x;
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
                    playerX = x * 64;
                    playerY = y * 64;
                    map[y][x] = ' ';
                    break;
                case '+':
                    playerX = x * 64;
                    playerY = y * 64;
                    map[y][x] = '.';
                    break;
                default:
                    break;
            }
            x++;
        }
        height = y;
        return 1;
    }

    void addUndo()
    {
        Undo undo = Undo(playerX, playerY, playerDirection, steps);
        undos[undoStart] = undo;
        undoStart++;
        undoStart = undoStart % 10;
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
            playerX = u.playerX;
            playerY = u.playerY;
            playerDirection = u.playerDirection;
            steps = u.steps;
            pushes--;

            int x = 0;
            int y = 0;
            switch(playerDirection)
            {
                case Direction.up:    y--; break;
                case Direction.down:  y++; break;
                case Direction.left:  x--; break;
                case Direction.right: x++; break;
                default: break;
            }
            int ox = x + playerX/64;
            int oy = y + playerY/64;
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

    int step(int rx, int ry, int x, int y)
    {
        if(map[y][x] == '#')
            return 0;

        int bx = x + rx;
        int by = y + ry;
        if(map[y][x] == '$' || map[y][x] == '*')
        {
            if(map[by][bx] != ' ' && map[by][bx] != '.')
                return 0;

            addUndo();

            if(map[y][x] == '*')
                score--;

            map[y][x] = map[y][x] == '*' ? '.' : ' ';

            pushes++;

            boxX = x * 64 + rx * 4;
            boxY = y * 64 + ry * 4;
        }

        steps++;
        return 1;
    }

    void logic(int ch)
    {
        if(!playerInMove)
        {
            // player idle
            int x = 0;
            int y = 0;
            switch(ch)
            {
                case 'a': x--; playerDirection = Direction.left; break;
                case 'd': x++; playerDirection = Direction.right; break;
                case 'w': y--; playerDirection = Direction.up; break;
                case 's': y++; playerDirection = Direction.down;  break;
                default: return;
            }
            if(step(x, y, playerX/64 + x, playerY/64 + y))
            {
                playerX += x * 4;
                playerY += y * 4;
                playerInMove = true;
            }
        }
        else
        {
            // player in move
            switch(playerDirection)
            {
                case Direction.up:    playerY -= 4; if(boxX != -1) boxY -= 4; break;
                case Direction.down:  playerY += 4; if(boxX != -1) boxY += 4; break;
                case Direction.left:  playerX -= 4; if(boxX != -1) boxX -= 4; break;
                case Direction.right: playerX += 4; if(boxX != -1) boxX += 4; break;
                default: break;
            }
            if((playerX % 64) == 0 && (playerY % 64) == 0)
            {
                playerInMove = false;
                if(boxX != -1)
                {
                    int bx = boxX / 64;
                    int by = boxY / 64;

                    if(map[by][bx] == '.')
                        score++;

                    map[by][bx] = map[by][bx] == '.' ? '*' : '$';

                    boxX = -1;
                }
            }
        }

        if(score == boxes)
        {
            // we are done
            //loadMap(levelToLoad=(++levelToLoad)%117);
            // fix me!
        }
    }



}