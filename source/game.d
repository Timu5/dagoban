module game;

import dagon;

class GameScene: Scene
{
    static int levelToLoad = 0;

    FontAsset aFontDroidSans;
    TextureAsset aTexSokoban;
    TextAsset aLevels;

    NuklearGUI gui;
    NkFont* font;

    int width;
    int height;
    char[20][20] map;
    int playerX = 11;
    int playerY = 8;
    int boxes = 0;
    int score = 0;
    int steps = 0;
    int pushes = 0;
    char inputChar = 0;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {    
        aFontDroidSans = addFontAsset("data/font/DroidSans.ttf", 14);
        aTexSokoban = addTextureAsset("data/textures/sokoban_spritesheet.png");
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

        loadMap(levelToLoad);
    }

	override void onStart()
    {
        super.onStart();
    }

    int loadMap(int i)
    {
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
                    continue;
                case '*':
                    score++;
                    goto case;
                case '$':
                    boxes++;
                    goto case;
                case '#':
                case ' ':
                case '.':
                    map[y][x] = ch;
                    break;
                case '@':
                    playerX = x;
                    playerY = y;
                    map[y][x] = ' ';
                    break;
                case '+':
                    playerX = x;
                    playerY = y;
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
    }

    override void onKeyUp(int key)
    {
        if (key == KEY_BACKSPACE)
            gui.inputKeyUp(NK_KEY_BACKSPACE);

        if(key == KEY_UP || key == KEY_W)
            inputChar = 'w';
        if(key == KEY_DOWN || key == KEY_S)
            inputChar = 's';
        if(key == KEY_LEFT || key == KEY_A)
            inputChar = 'a';
        if(key == KEY_RIGHT  || key == KEY_D)
            inputChar = 'd';
        if(key == KEY_N)
            loadMap(levelToLoad = (++levelToLoad)%117);
        if(key == KEY_P)
            loadMap(levelToLoad = (--levelToLoad) < 0 ? 116 : levelToLoad);
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

    void drawSprite(int x, int y, int sx, int sy, int w, int h)
    {
        NkImage img = aTexSokoban.texture.toNuklearImage;
        img.region[0] = cast(short)sx;
        img.region[1] = cast(short)sy;
        img.region[2] = cast(short)w;
        img.region[3] = cast(short)h;
        gui.drawImage(NkRect(x + 1280/2 - width*32, y + 720/2 - width*32 - 64, w, h), &img, NkColor(255,255,255,255));

    }

    void draw()
    {
        for(int j = 0; j < 11; j++)
        {
            for(int i = 0; i < 19; i++)
            {
                switch(map[j][i])
                {
                    case '#': drawSprite(i*64,j*64,0*64,4*64,64,64); break;
                    case '.': drawSprite(i*64, j*64, 1*64, 6*64,64,64); break;
                    case '$':
                    case '*': drawSprite(i*64, j*64,2*64, 1*64, 64,64); break;
                    case ' ': drawSprite(i*64,j*64, 0, 1*64, 64, 64); break;
                    default: break;
                }
            }
        }
        drawSprite(playerX*64+10,playerY*64+5, 8*64, 54, 52, 54);
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
            if(map[by][bx] == '.')
                score++;

            map[by][bx] = map[by][bx] == '.' ? '*' : '$';
            map[y][x] = map[y][x] == '*' ? '.' : ' ';

            pushes++;
        }

        steps++;
        return 1;
    }

    void logic(int ch)
    {
        int x = 0;
        int y = 0;
        {
            switch(ch)
            {
                case 'a': x--; break;
                case 'd': x++; break;
                case 'w': y--; break;
                case 's': y++; break;
                default: return;
            }
            if(step(x, y, playerX + x, playerY + y))
            {
                playerX += x;
                playerY += y;
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
        logic(inputChar);
        inputChar = 0;

        if (gui.begin("StatsMenu", NkRect(0, 0, 130, 92), NK_WINDOW_NO_SCROLLBAR))
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

        if(gui.canvasBegin("canvas", NkRect(0, 0, 1280, 720), NkColor(0,0,255,0)))
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
