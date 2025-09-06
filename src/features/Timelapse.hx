package features;

import js.Browser;
import js.node.Path;
import level.editor.ui.LevelsPanel.PanelItem;
import js.lib.Uint8Array;

typedef ScreenshotData = {
    data: Uint8Array,
    width: Int,
    height: Int,
}

enum State {
    NotReady;
    Delay;
    WaitForLevelsPanelItems;
    TakeAndSubmitScreenshots;
}

class Timelapse {
    public static final singleton = new Timelapse();

    function new() {

    }

    var state = State.NotReady;

    public function initialize() {
        TimelapseClient.getTask()
            .then(task -> Ogmo.startPage.onOpenProject(task.ogmoProjectPath))
            .then((cast (() -> this.state = Delay): Dynamic));
    }

    var levelPaths: Array<String>;
    var currentLevelPath: Null<String>;
    var remainingScreenshotsCount: Int;
    var delayedCount = 0;

    public function loop() {
        if (this.state == Delay) {
            if (this.delayedCount++ >= 60) {
                this.state = WaitForLevelsPanelItems;
            }
        }
        else if (this.state == WaitForLevelsPanelItems) {
            final levelPaths = findLevelPaths(Ogmo.editor.levelsPanel.items, []);
            if (Ogmo.editor.levelsPanel.items.length > 0 && levelPaths.length > 0) {
                this.levelPaths = levelPaths;
                this.remainingScreenshotsCount = this.levelPaths.length;
                this.state = TakeAndSubmitScreenshots;
            }
        }
        else if (this.state == TakeAndSubmitScreenshots) {
            if (this.currentLevelPath == null && this.levelPaths.length > 0) {
                final levelDirectoryPath = OGMO.project.getAbsoluteLevelDirectories()[0];
                final levelPath = this.levelPaths.pop();
                this.currentLevelPath = levelPath;
                Ogmo.editor.levelManager.open(levelPath);
                Ogmo.editor.saveLevelAsImage((png) -> {
                    this.currentLevelPath = null;
                    TimelapseClient.submitScreenshot(levelPath.substring(levelDirectoryPath.length), png)
                        .then((cast (() -> this.remainingScreenshotsCount -= 1): Dynamic));
                });
            }
            else if (this.remainingScreenshotsCount <= 0) {
                Browser.window.location.reload();
            }
        }
    }

    static function findLevelPaths(items:Array<PanelItem>, levelPaths:Array<String>) {
        for (item in items) {
            if (item.children != null) {
                findLevelPaths(item.children, levelPaths);
            }
            else if (Path.extname(item.path) == ".json") {
                levelPaths.push(item.path);
            }
        }

        return levelPaths;
    }
}