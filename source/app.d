module main;

import dagon;

import game;
import menu;
import editor;
import dlib.container.dict;

enum EventCode
{
    LoadMap = 1,
    LoadEditor = 2,
    ExitToMenu = 3
}

class Dagoban: Game
{
    Dict!(Scene, string) scenes;
    int levelToLoad = 0;
    bool fromEditor = false;
    
    this(uint w, uint h, bool fullscreen, string[] args)
    {
        super(w, h, fullscreen, "DagoBan", args);

        auto menu = New!MenuScene(this);
        auto game = New!GameScene(this);
        auto editor = New!EditorScene(this);
        
        scenes = New!(Dict!(Scene, string))();
        scenes["MenuScene"] = menu;
        scenes["GameScene"] = game;
        scenes["EditorScene"] = editor;

        currentScene = menu;
    }
    
    ~this()
    {
        Delete(scenes);
    }
    
    void goToScene(string name, bool reload)
    {
        currentScene = scenes[name];
        if (name == "GameScene")
            generateUserEvent(EventCode.LoadMap);
        else if (name == "MenuScene")
            generateUserEvent(EventCode.ExitToMenu);
        else if (name == "EditorScene")
            generateUserEvent(EventCode.LoadEditor);
    }
}

void main(string[] args)
{
    debug enableMemoryProfiler(true);
    Dagoban game = New!Dagoban(1280, 720, false, args);
    game.run();
    Delete(game);
    debug printMemoryLeaks();
}