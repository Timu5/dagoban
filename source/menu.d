module menu;

import dagon;
import game;

class MenuScene: Scene
{
    enum Menu { mainMenu, levelMenu, about }

    FontAsset aFontDroidSans;
    TextureAsset aDagonLogo;
    
    NuklearGUI gui;
    NKFont* fontTitle;
    NKFont* fontNormal;

    Menu current;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {    
        aFontDroidSans = addFontAsset("data/font/DroidSans.ttf", 14);
        aDagonLogo =  addTextureAsset("data/textures/dagon-logo.png");
    }

    override void onAllocate()
    {
        super.onAllocate();

        gui = New!NuklearGUI(eventManager, assetManager);
        fontTitle = gui.addFont(aFontDroidSans, 40);
        fontNormal = gui.addFont(aFontDroidSans, 20, gui.fontLatinExtendedAGlyphRanges); // inlcude utf glyph range with polish characters

        auto eNuklear = createEntity2D();
        eNuklear.drawable = gui;
    }

    override void onStart()
    {
        super.onStart();
        current = Menu.mainMenu;
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

    override void onLogicsUpdate(double dt)
    {
        int w = 400;
        int h = 400;
        auto rect = NKRect((1280-w)/2, (720-h)/2, w, h); // calculate rectancle in center

        if(current == Menu.mainMenu)
        {
            if (gui.begin("MainMenu", rect, NK_WINDOW_NO_SCROLLBAR))
            {
                gui.layoutRowDynamic(50, 1);
                gui.styleSetFont(fontTitle);
                gui.labelColored("DagoBan", NK_TEXT_CENTERED, NKColor(254,50,50,200));

                gui.styleSetFont(fontNormal);
                if(gui.buttonLabel("New game")) current = Menu.levelMenu;
                if(gui.buttonLabel("Level editor")) sceneManager.goToScene("EditorScene", false);
                if(gui.buttonLabel("About")) current = Menu.about;
                gui.layoutRowDynamic(100, 1); // make empty space
                gui.layoutRowDynamic(50, 1);
                if(gui.buttonLabel("Exit")) exitApplication();
            }
            gui.end();
        }
        else if(current == Menu.levelMenu)
        {
            if (gui.begin("LevelMenu", rect, NK_WINDOW_NO_SCROLLBAR))
            {
                gui.layoutRowDynamic(25, 1);
                gui.label("Select level:", NK_TEXT_ALIGN_LEFT);

                gui.layoutRowDynamic(300, 1);
                if(gui.groupBegin("LevelsGroup", NK_WINDOW_BORDER))
                {
                    char[255] buffer;
                    gui.layoutRowDynamic(50, 5);
                    for(int i = 0; i < 50; i++)
                    {
                        import core.stdc.stdio;
                        snprintf(buffer.ptr, 255, "%d", i+1);
                        if(gui.buttonLabel(buffer.ptr)) 
                        {
                            GameScene.levelToLoad = i;
                            sceneManager.goToScene("GameScene", false);
                        }
                    }
                    gui.groupEnd();
                }
                gui.layoutRowDynamic(50, 1);
                if(gui.buttonLabel("Back")) current = Menu.mainMenu;
            }
            gui.end();
        }
        else if(current == Menu.about)
        {
            if (gui.begin("About", rect, NK_WINDOW_NO_SCROLLBAR))
            {
                gui.layoutRowDynamic(30, 1);
                gui.label("Programmer: Mateusz Muszyński", NK_TEXT_ALIGN_LEFT);
                gui.label("Graphics: kenney.nl", NK_TEXT_ALIGN_LEFT);
                gui.label("This game is built on top of Dagon Engine!", NK_TEXT_ALIGN_LEFT);

                gui.layoutRowStatic(66, 200, 1);
                gui.image(aDagonLogo.texture.toNKImage);

                gui.layoutRowDynamic(160, 1); // make empty space
                gui.layoutRowDynamic(50, 1);
                if(gui.buttonLabel("Back")) current = Menu.mainMenu;
            }
            gui.end();
        }

        gui.canvasBegin("canvas", NKRect(0,0,1280,720), NKColor(45,45,45,255));
        // empty canvas just to fill background
        gui.canvasEnd();
    }
}
