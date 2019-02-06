module editor;

import dagon;


class EditorScene: Scene
{
    FontAsset aFontDroidSans;
    TextureAsset aTexSokoban;
    TextAsset aLevels;

    NuklearGUI gui;
    NkFont* font;

    int width;
    int height;
    char[20][20] map;
    int boxes;
    int score;
    int steps;
    int pushes;
    int levelToLoad;
    char selected;

    bool showLoad;
    bool showSave;

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

        loadMap(levelToLoad = 0);
        selected = 0;
        showLoad = false;
        showSave = false;
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
                case '.':
                case ' ':
                case '@':
                case '+':
                    map[y][x] = ch;
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
    }

    override void onMouseButtonDown(int button)
    {
        gui.inputButtonDown(button);
        if(eventManager.mouseX > 250 && selected != 0)
        {
            int x = (eventManager.mouseX - 250 - 32) / 64;
            int y = (eventManager.mouseY) / 64;
            if(selected == '-')
                map[y][x] = 0;
            else if(selected == '$' && map[y][x] == '.')
                map[y][x] = '*';
            else if(selected == '+' && map[y][x] == '.')
                map[y][x] = '@';
            else
                map[y][x] = selected;
        }
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


    NkImage sprite(int sx, int sy)
    {
        NkImage img = aTexSokoban.texture.toNuklearImage;
        img.region[0] = cast(short)sx;
        img.region[1] = cast(short)sy;
        img.region[2] = 64;
        img.region[3] = 64;
        return img;
    }

    void drawSprite(int x, int y, int sx, int sy)
    {
        NkImage img = sprite(sx, sy);
        gui.drawImage(NkRect(250 + x + 1280/2 - 19*32, y + 720/2 - 11*32, 64, 64), &img, NkColor(255,255,255,255));
    }

    void draw()
    {
        // draw map
        for(int j = 0; j < 11; j++)
        {
            for(int i = 0; i < 15; i++)
            {
                switch(map[j][i])
                {
                    case '#': drawSprite(i*64, j*64,  6*64, 6*64); break;
                    case '.': drawSprite(i*64, j*64, 11*64, 1*64); break;
                    case '$': drawSprite(i*64, j*64,  1*64, 0*64); break;
                    case '*': drawSprite(i*64, j*64,  1*64, 1*64); break;
                    case ' ': drawSprite(i*64, j*64, 11*64, 0*64); break;
                    case '@': 
                        drawSprite(i*64, j*64, 11*64, 0*64); 
                        drawSprite(i*64, j*64,  0*64, 4*64);
                        drawSprite(i*64, j*64, 12*64, 1*64);
                        break;
                    case '+': 
                        drawSprite(i*64, j*64, 11*64, 0*64); 
                        drawSprite(i*64, j*64,  0*64, 4*64);
                        break;
                    default:  drawSprite(i*64, j*64,  0*64, 1*64); break;
                }
            }
        }
        if(selected != 0)
        {
            int x = (eventManager.mouseX - 250 - 32) / 64 * 64;
            int y = (eventManager.mouseY) / 64 * 64;
            switch(selected)
            {
                case '#': drawSprite(x, y,  6*64, 6*64); break;
                case '.': drawSprite(x, y, 11*64, 1*64); break;
                case '$': drawSprite(x, y,  1*64, 0*64); break;
                case ' ': drawSprite(x, y, 11*64, 0*64); break;
                case '@': drawSprite(x, y,  0*64, 4*64); break;
                case '+': drawSprite(x, y,  0*64, 4*64); break;
                default: break;
            }
        }
    }

    override void onLogicsUpdate(double dt)
    {
        if (gui.begin("StatsMenu", NkRect(0, 0, 250, 720), NK_WINDOW_NO_SCROLLBAR))
        {
            gui.layoutRowDynamic(15, 1);
            gui.labelf(NK_TEXT_LEFT, "Level: %d/117", 1);
            gui.labelf(NK_TEXT_LEFT, "Steps: %d", steps);
            gui.labelf(NK_TEXT_LEFT, "Pushes: %d", pushes);

            gui.layoutRowDynamic(50, 2);
            //if(gui.buttonLabel("Load")) showLoad = true;//loadMap(levelToLoad = (--levelToLoad) < 0 ? 116 : levelToLoad);
            //if(gui.buttonLabel("Save")) loadMap(levelToLoad = (++levelToLoad)%117);

            gui.layoutRowDynamic(100, 2);
            if(gui.buttonImage(sprite( 6*64, 6*64))) selected = '#';
            if(gui.buttonImage(sprite(11*64, 1*64))) selected = '.';
            if(gui.buttonImage(sprite( 1*64, 0*64))) selected = '$';
            if(gui.buttonImage(sprite(11*64, 0*64))) selected = ' ';
            if(gui.buttonImage(sprite( 0*64, 4*64))) selected = '+';
            if(gui.buttonLabel("Delete")) selected = '-';

            gui.layoutRowDynamic(50, 1);
            //if(gui.buttonLabel("Play")) sceneManager.goToScene("GameScene", false);         
            if(gui.buttonLabel("Main Menu")) sceneManager.goToScene("MenuScene", false);

            if (showLoad)
            {
                if (gui.popupBegin(NK_POPUP_STATIC, "LoadLevel", 0, NkRect(0, 0, 250, 720)))
                {
                    gui.layoutRowDynamic(25, 1);
                    gui.label("A terrible error as occured", NK_TEXT_LEFT);
                    gui.layoutRowDynamic(25, 2);
                    if (gui.buttonLabel("OK"))
                    {
                        showLoad = false;
                        gui.popupClose();
                    }
                    if (gui.buttonLabel("Cancel"))
                    {
                        showLoad = false;
                        gui.popupClose();
                    }
                    gui.popupEnd();
                }
                else
                {
                    showLoad = false;
                }
            }

            if (showSave)
            {
                if (gui.popupBegin(NK_POPUP_STATIC, "SaveLevel", 0, NkRect(0, 0, 250, 720)))
                {
                    gui.layoutRowDynamic(25, 1);
                    gui.label("A terrible error as occured", NK_TEXT_LEFT);
                    gui.layoutRowDynamic(25, 2);
                    if (gui.buttonLabel("OK"))
                    {
                        showLoad = false;
                        gui.popupClose();
                    }
                    if (gui.buttonLabel("Cancel"))
                    {
                        showLoad = false;
                        gui.popupClose();
                    }
                    gui.popupEnd();
                }
                else
                {
                    showLoad = false;
                }
            }
        }
        gui.end();

        if(gui.canvasBegin("canvas", NkRect(0, 0, 1280, 720), NkColor(0,0,0,0)))
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
