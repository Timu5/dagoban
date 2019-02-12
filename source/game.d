module game;

import dagon;
import soko;
import std.stdio;

class GameScene: Scene
{
    static int levelToLoad = 0;

    FontAsset aFontDroidSans;
    TextureAsset aTexSokoban;
    TextAsset aLevels;

    NuklearGUI gui;
    NKFont* font;

    Sokoban sokoban;

    this(SceneManager smngr)
    {
        super(smngr);
        sokoban = New!Sokoban();
    }

    override void onAssetsRequest()
    {    
        aFontDroidSans = addFontAsset("data/font/DroidSans.ttf", 14);
        aTexSokoban = addTextureAsset("data/textures/tilesheet.png");
        aLevels =  addTextAsset("data/levels/Csoko.txt");
    }

    override void onAllocate()
    {
        super.onAllocate();

        gui = New!NuklearGUI(eventManager, assetManager);
        font = gui.addFont(aFontDroidSans, 20);

        auto eNuklear = createEntity2D();
        eNuklear.drawable = gui;
    }

    override void onStart()
    {
        super.onStart();

        sokoban.loadMap(aLevels.text, levelToLoad);
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
        gui.drawImage(NKRect(x + 1280/2 - sokoban.mapWidth*32, y + 720/2 - sokoban.mapHeight*32, 64, 64), &img, NKColor(255,255,255,255));
    }

    void draw()
    {
        // draw map
        for(int j = 0; j < 11; j++)
        {
            for(int i = 0; i < 19; i++)
            {
                switch(sokoban.map[j][i])
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
        int frame = (sokoban.playerPos.x % 64) / 21 +  (sokoban.playerPos.y % 64) / 21;
        switch(sokoban.playerDir)
        {
            case Direction.up:    drawSprite(sokoban.playerPos.x, sokoban.playerPos.y, (3 + frame) * 64, 4*64); break;
            case Direction.down:  drawSprite(sokoban.playerPos.x, sokoban.playerPos.y, (0 + frame) * 64, 4*64); break;
            case Direction.left:  drawSprite(sokoban.playerPos.x, sokoban.playerPos.y, (3 + frame) * 64, 6*64); break;
            case Direction.right: drawSprite(sokoban.playerPos.x, sokoban.playerPos.y, (0 + frame) * 64, 6*64); break;
            default: break;
        }

        if(sokoban.boxPos.x != -1)
        {
            drawSprite(sokoban.boxPos.x, sokoban.boxPos.y, 1*64, 0*64);
        }
    }

    override void onLogicsUpdate(double dt)
    {
        Direction dir = Direction.none;

        if(inputManager.getButton("UP"))
            dir = Direction.up;

        if(inputManager.getButton("DOWN"))
            dir = Direction.down;

        if(inputManager.getButton("LEFT"))
            dir = Direction.left;

        if(inputManager.getButton("RIGHT"))
            dir = Direction.right;       

        if(inputManager.getButtonDown("NEXT"))
            sokoban.loadMap(aLevels.text, levelToLoad = (++levelToLoad)%50);
        
        if(inputManager.getButtonDown("PREV"))
            sokoban.loadMap(aLevels.text, levelToLoad = (--levelToLoad) < 0 ? 49 : levelToLoad);
        
        if(inputManager.getButtonDown("UNDO") && !sokoban.inMove)
            sokoban.doUndo();

        sokoban.logic(dir);

        if(sokoban.score == sokoban.boxes)
        {
            // we are done
            sokoban.loadMap(aLevels.text, levelToLoad=(++levelToLoad)%50);
        }

        if (gui.begin("StatsMenu", NKRect(0, 0, 130, 200), NK_WINDOW_NO_SCROLLBAR))
        {
            gui.layoutRowDynamic(10, 1);
            gui.labelf(NK_TEXT_LEFT, "Level: %d/50", levelToLoad + 1);
            gui.labelf(NK_TEXT_LEFT, "Steps: %d", sokoban.steps);
            gui.labelf(NK_TEXT_LEFT, "Pushes: %d", sokoban.pushes);

            gui.layoutRowDynamic(20, 2);
            if(gui.buttonLabel("Prev")) sokoban.loadMap(aLevels.text, levelToLoad = (--levelToLoad) < 0 ? 116 : levelToLoad);
            if(gui.buttonLabel("Next")) sokoban.loadMap(aLevels.text, levelToLoad = (++levelToLoad)%117); 

            gui.layoutRowDynamic(20, 1);
            if(gui.buttonLabel("Main Menu")) sceneManager.goToScene("MenuScene", false);   

            gui.layoutRowDynamic(30, 1);
            if(sokoban.undoSize && gui.buttonLabel("Undo") && !sokoban.inMove) sokoban.doUndo();  
        }
        gui.end();

        debug
        {
            if (gui.begin("FPS Chart", NKRect(1020, 500, 230, 220), NK_WINDOW_BORDER | NK_WINDOW_TITLE))
            {
                static float[60] fpsTable;
                static int fpsTableIndex = 0;

                fpsTable[fpsTableIndex] = 1 / eventManager.deltaTime;
                fpsTableIndex = (++fpsTableIndex) % 60;

                gui.layoutRowDynamic(100, 1);
                auto bounds = gui.widgetBounds();
                float max = -1000;
                float min = 1000;
                if (gui.chartBegin(NK_CHART_LINES, 30, 0, 70.0f))
                {
                    for (int i = 0; i < 30; i++)
                    {
                        int index = (fpsTableIndex + i*2) % 60;
                        int index2 = (fpsTableIndex % 2 == 1) ? (index+1) % 60 : (index-1) < 0 ? 59 : index - 1;
                        float value = (fpsTable[index] + fpsTable[index2])/2;
                        gui.chartPush(value);

                        if(value > max) max = value;
                        if(value < min) min = value;
                    }
                    gui.chartEnd();
                }
                gui.layoutRowDynamic(15, 1);
                gui.labelf(NK_TEXT_LEFT, "Max FPS: %.2f", cast(double)max);
                gui.labelf(NK_TEXT_LEFT, "Min FPS: %.2f", cast(double)min);
                gui.labelf(NK_TEXT_LEFT, "Avg FPS: %d", eventManager.fps);
            }
            gui.end();
        }

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
