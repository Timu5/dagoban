module game;

import dagon;

enum Direction { up, down, left, right }

class GameScene: Scene
{
    static int levelToLoad = 0;

    FontAsset aFontDroidSans;
    TextureAsset aTexSokoban;
    TextAsset aLevels;

    NuklearGUI gui;
    NKFont* font;

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

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {    
        aFontDroidSans = addFontAsset("data/font/DroidSans.ttf", 14);
        aTexSokoban = addTextureAsset("data/textures/tilesheet.png");
        aLevels =  addTextAsset("data/levels/Zone_26.txt");
    }

    override void onAllocate()
    {
        super.onAllocate();

        gui = New!NuklearGUI(eventManager, assetManager);
        font = gui.addFont(aFontDroidSans, 20);
        gui.generateFontAtlas();

        auto eNuklear = createEntity2D();
        eNuklear.drawable = gui;
    }

    override void onStart()
    {
        super.onStart();

        loadMap(levelToLoad);
    }

    int loadMap(int i)
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
        for(int k = 0; k < 20; k++)
            for(int j = 0; j < 20; j++)
                map[k][j] = 0;

        int x = 0;
        int y = 0;
        char ch = 0;
        int index = 0;
        while(i > 0)
        {
            if((ch = aLevels.text[index++]) == ';')
                i--;
            if(index == aLevels.text.length)
                return -1;
        }
        if(ch == ';') while((ch = aLevels.text[index++]) != '\n') {}
        bool canLoadEmpty = false;
        while(ch != ';')
        {
            ch = aLevels.text[index++];
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

    override void onKeyDown(int key)
    {
        if (key == KEY_BACKSPACE)
            gui.inputKeyDown(NK_KEY_BACKSPACE);

        if(key == KEY_N)
            loadMap(levelToLoad = (++levelToLoad)%117);
        if(key == KEY_P)
            loadMap(levelToLoad = (--levelToLoad) < 0 ? 116 : levelToLoad);
    }

    override void onKeyUp(int key)
    {
        if (key == KEY_BACKSPACE)
            gui.inputKeyUp(NK_KEY_BACKSPACE);
    }

    override void onMouseButtonDown(int button)
    {
        gui.inputButtonDown(button);
    }

    override void onMouseButtonUp(int button)
    {
        gui.inputButtonUp(button);
    }

    override void onTextInput(dchar unicode)
    {
        gui.inputUnicode(unicode);
    }

    override void onMouseWheel(int x, int y)
    {
        gui.inputScroll(x, y);
    }

    void drawSprite(int x, int y, int sx, int sy)
    {
        NKImage img = aTexSokoban.texture.toNKImage;
        img.region[0] = cast(short)sx;
        img.region[1] = cast(short)sy;
        img.region[2] = 64;
        img.region[3] = 64;
        gui.drawImage(NKRect(x + 1280/2 - width*32, y + 720/2 - height*32, 64, 64), &img, NKColor(255,255,255,255));
    }

    void draw()
    {
        // draw map
        for(int j = 0; j < 11; j++)
        {
            for(int i = 0; i < 19; i++)
            {
                switch(map[j][i])
                {
                    case '#': drawSprite(i*64, j*64,  6*64, 6*64); break;
                    case '.': drawSprite(i*64, j*64, 11*64, 1*64); break;
                    case '$': drawSprite(i*64, j*64,  1*64, 0*64); break;
                    case '*': drawSprite(i*64, j*64,  1*64, 1*64); break;
                    case ' ': drawSprite(i*64, j*64, 11*64, 0*64); break;
                    default: break;
                }
            }
        }

        // draw player
        int frame = (playerX % 64) / 21 +  (playerY % 64) / 21;
        switch(playerDirection)
        {
            case Direction.up:    drawSprite(playerX, playerY, (3 + frame) * 64, 4*64); break;
            case Direction.down:  drawSprite(playerX, playerY, (0 + frame) * 64, 4*64); break;
            case Direction.left:  drawSprite(playerX, playerY, (3 + frame) * 64, 6*64); break;
            case Direction.right: drawSprite(playerX, playerY, (0 + frame) * 64, 6*64); break;
            default: break;
        }

        if(boxX != -1)
        {
            drawSprite(boxX, boxY, 1*64, 0*64);
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
            loadMap(levelToLoad=(++levelToLoad)%117);
        }
    }

    override void onLogicsUpdate(double dt)
    {
        char input = 0;
        if(eventManager.keyPressed[KEY_UP] || eventManager.keyPressed[KEY_W])
            input = 'w';
        if(eventManager.keyPressed[KEY_DOWN] || eventManager.keyPressed[KEY_S])
            input = 's';
        if(eventManager.keyPressed[KEY_LEFT] || eventManager.keyPressed[KEY_A])
            input = 'a';
        if(eventManager.keyPressed[KEY_RIGHT] || eventManager.keyPressed[KEY_D])
            input = 'd';
        logic(input);

        if (gui.begin("StatsMenu", NKRect(0, 0, 130, 92), NK_WINDOW_NO_SCROLLBAR))
        {
            gui.layoutRowDynamic(10, 1);
            gui.labelf(NK_TEXT_LEFT, "Level: %d/117", levelToLoad + 1);
            gui.labelf(NK_TEXT_LEFT, "Steps: %d", steps);
            gui.labelf(NK_TEXT_LEFT, "Pushes: %d", pushes);

            gui.layoutRowDynamic(20, 2);
            if(gui.buttonLabel("Prev")) loadMap(levelToLoad = (--levelToLoad) < 0 ? 116 : levelToLoad);
            if(gui.buttonLabel("Next")) loadMap(levelToLoad = (++levelToLoad)%117); 

            gui.layoutRowDynamic(20, 1);
            if(gui.buttonLabel("Main Menu")) sceneManager.goToScene("MenuScene", false);         
        }
        gui.end();

        if(gui.canvasBegin("canvas", NKRect(0, 0, 1280, 720), NKColor(45,45,45,255)))
        {
            draw();
        }
        gui.canvasEnd();
    }

    override void onRelease()
    {
        super.onRelease();
    }
}
