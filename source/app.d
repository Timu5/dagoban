module main;

import dagon;

import game;
import menu;

class MyApplication: SceneApplication
{
    this(string[] args)
    {
        super("DagoBan", args);

        MenuScene menu = New!MenuScene(sceneManager);
        GameScene game = New!GameScene(sceneManager);
        sceneManager.addScene(menu, "MenuScene");
        sceneManager.addScene(game, "GameScene");
        sceneManager.goToScene("MenuScene");
    }
}

void main(string[] args)
{
    MyApplication app = New!MyApplication(args);
    app.run();
    Delete(app);
}