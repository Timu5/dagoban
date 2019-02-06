module main;

import dagon;

import game;
import menu;
import editor;

class MyApplication: SceneApplication
{
    this(string[] args)
    {
        super("DagoBan", args);

        MenuScene menu = New!MenuScene(sceneManager);
        GameScene game = New!GameScene(sceneManager);
        EditorScene editor = New!EditorScene(sceneManager);
        sceneManager.addScene(menu, "MenuScene");
        sceneManager.addScene(game, "GameScene");
        sceneManager.addScene(editor, "EditorScene");
        sceneManager.goToScene("MenuScene");
    }
}

void main(string[] args)
{
    MyApplication app = New!MyApplication(args);
    app.run();
    Delete(app);
}