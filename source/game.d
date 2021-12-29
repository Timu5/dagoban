module game;

import dagon;
import dagon.ext.ftfont;
import dagon.ext.nuklear;
import soko;
import main;
import std.stdio;

class GameScene: Scene
{
    Dagoban game;

    FontAsset aFontDroidSans;
    TextureAsset aTexSokoban;
    TextAsset aLevels;

    NuklearGUI gui;
    NKFont* font;

    Sokoban sokoban;

    short tile; // 32, 64 or 128 pixels

    this(Dagoban game)
    {
        super(game);
        this.game = game;
        sokoban = New!Sokoban();
    }

    ~this()
    {
        Delete(sokoban);
    }

    override void beforeLoad()
    {    
        aFontDroidSans = this.addFontAsset("data/font/DroidSans.ttf", 14);
        aTexSokoban = addTextureAsset("data/textures/tilesheet@2.png");
        aLevels =  addTextAsset("data/levels/Csoko.txt");
    }

    override void afterLoad()
    {
        gui = New!NuklearGUI(eventManager, assetManager);
        font = gui.addFont(aFontDroidSans, 20);

        auto eNuklear = addEntityHUD();
        eNuklear.drawable = gui;

        setScale();
    }
    
    override void onUserEvent(int code)
    {
        if (code == EventCode.LoadMap)
        {
            if (!game.fromEditor)
                loadMap(game.levelToLoad);
        }
    }

    void loadMap(int i)
    {
        sokoban.loadMap(aLevels.text, i);
        setScale();
        game.levelToLoad = i;
    }

    void setScale()
    {
        int a = (eventManager.windowWidth - 20) / sokoban.mapWidth;
        int b = (eventManager.windowHeight - 20) / sokoban.mapHeight;
        tile = cast(short)(a > b ? b : a);
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
        img.region[0] = cast(short)(sx * 128);
        img.region[1] = cast(short)(sy * 128);
        img.region[2] = cast(short)128;
        img.region[3] = cast(short)128;
        gui.drawImage(NKRect(x + (eventManager.windowWidth - sokoban.mapWidth * tile) / 2, y + (eventManager.windowHeight - sokoban.mapHeight * tile) / 2, tile, tile), &img, NKColor(255,255,255,255));
    }

    void draw()
    {
        // draw map
        for(int j = 0; j < 20; j++)
        {
            for(int i = 0; i < 20; i++)
            {
                switch(sokoban.map[j][i])
                {
                    case Tile.wall:        drawSprite(i * tile, j * tile,  6, 6); break;
                    case Tile.socket:      drawSprite(i * tile, j * tile, 11, 1); break;
                    case Tile.box:         drawSprite(i * tile, j * tile,  1, 0); break;
                    case Tile.boxOnSocket: drawSprite(i * tile, j * tile,  1, 1); break;
                    case Tile.floor:       drawSprite(i * tile, j * tile, 11, 0); break;
                    default: break;
                }
            }
        }

        // draw player
        int frame = (sokoban.playerPos.x % 64) / 21 +  (sokoban.playerPos.y % 64) / 21;
        switch(sokoban.playerDir)
        {
            case Direction.up:    drawSprite(sokoban.playerPos.x * tile / 64, sokoban.playerPos.y * tile / 64, 3 + frame, 4); break;
            case Direction.down:  drawSprite(sokoban.playerPos.x * tile / 64, sokoban.playerPos.y * tile / 64, 0 + frame, 4); break;
            case Direction.left:  drawSprite(sokoban.playerPos.x * tile / 64, sokoban.playerPos.y * tile / 64, 3 + frame, 6); break;
            case Direction.right: drawSprite(sokoban.playerPos.x * tile / 64, sokoban.playerPos.y * tile / 64, 0 + frame, 6); break;
            default: break;
        }

        if(sokoban.boxPos.x != -1)
        {
            int x = (sokoban.boxPos.x + 32) / 64;
            int y = (sokoban.boxPos.y + 32) / 64;
            if(sokoban.map[y][x] == Tile.socket)
                drawSprite(sokoban.boxPos.x * tile / 64, sokoban.boxPos.y * tile / 64, 1, 1);
            else
                drawSprite(sokoban.boxPos.x * tile / 64, sokoban.boxPos.y * tile / 64, 1, 0);
        }
    }

    override void onUpdate(Time t)
    {
        float vertical   = inputManager.getAxis("vertical");
        float horizontal = inputManager.getAxis("horizontal");

        Direction dir = Direction.none;

        if(vertical > 0.1f)
            dir = Direction.down;
        else if(vertical < -0.1f)
            dir = Direction.up;

        if(horizontal > 0.1f)
            dir = Direction.right;
        else if(horizontal < -0.1f)
            dir = Direction.left;    

        if(inputManager.getButtonDown("next") && !game.fromEditor)
            loadMap((++game.levelToLoad) % 50);
        
        if(inputManager.getButtonDown("prev") && !game.fromEditor)
            loadMap((--game.levelToLoad) < 0 ? 49 : game.levelToLoad);
        
        if(inputManager.getButtonDown("undo") && !sokoban.inMove)
            sokoban.doUndo();

        sokoban.logic(dir);

        if(sokoban.score == sokoban.boxes)
        {
            // we are done
            if(game.fromEditor)
                game.goToScene("EditorScene", false);   
            else
                loadMap((++game.levelToLoad)%50); // load next level
        }
        
        gui.update(t);

        if (gui.begin("StatsMenu", NKRect(0, 0, 130, 130), NK_WINDOW_NO_SCROLLBAR))
        {
            if(!game.fromEditor)
            {
                gui.layoutRowDynamic(10, 1);
                gui.labelf(NK_TEXT_LEFT, "Level: %d/50", game.levelToLoad + 1);
                gui.labelf(NK_TEXT_LEFT, "Steps: %d", sokoban.steps);
                gui.labelf(NK_TEXT_LEFT, "Pushes: %d", sokoban.pushes);

                gui.layoutRowDynamic(20, 2);
                if(gui.buttonLabel("Prev")) loadMap((--game.levelToLoad) < 0 ? 49 : game.levelToLoad);
                if(gui.buttonLabel("Next")) loadMap((++game.levelToLoad) % 50); 

                gui.layoutRowDynamic(20, 1);
                if(gui.buttonLabel("Main Menu")) game.goToScene("MenuScene", false);   
            }
            else
            {
                gui.layoutRowDynamic(30, 1);
                if(gui.buttonLabel("Back to Editor")) game.goToScene("EditorScene", false);   
            }

            gui.layoutRowDynamic(30, 1);
            if(sokoban.undoSize && gui.buttonLabel("Undo") && !sokoban.inMove) sokoban.doUndo();
        }
        gui.end();

        debug
        {
            if (gui.begin("FPS Chart", NKRect(eventManager.windowWidth - 230, eventManager.windowHeight - 220, 230, 220), NK_WINDOW_BORDER | NK_WINDOW_TITLE))
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
                        int index = (fpsTableIndex + i * 2) % 60;
                        int index2 = (fpsTableIndex % 2 == 1) ? (index + 1) % 60 : (index - 1) < 0 ? 59 : index - 1;
                        float value = (fpsTable[index] + fpsTable[index2]) / 2;
                        gui.chartPush(value);

                        if(value > max) max = value;
                        if(value < min) min = value;
                    }
                    gui.chartEnd();
                }
                gui.layoutRowDynamic(15, 1);
                gui.labelf(NK_TEXT_LEFT, "Max FPS: %.2f", cast(double)max);
                gui.labelf(NK_TEXT_LEFT, "Min FPS: %.2f", cast(double)min);
                gui.labelf(NK_TEXT_LEFT, "Avg FPS: %d", 1.0 / eventManager.deltaTime);
            }
            gui.end();
        }

        if(gui.canvasBegin("canvas", NKRect(0, 0, eventManager.windowWidth, eventManager.windowHeight), NKColor(45,45,45,255)))
        {
            draw();
        }
        gui.canvasEnd();
    }
}
