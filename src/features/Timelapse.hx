package features;

import js.html.Console;
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
    VisitAll;
    TakeAndSubmitScreenshots;
}

class Timelapse {
    public static final singleton = new Timelapse();

    function new() {

    }

    var state = State.NotReady;

    public function initialize() {
        TimelapseClient.getTask()
            .then(task -> {
                this.levelPaths = task.levelPaths;
                this.remainingScreenshotsCount = this.levelPaths.length;
                return Ogmo.startPage.onOpenProject(task.ogmoProjectPath);
            })
            .then((cast (() -> this.state = Delay): Dynamic));
    }

    var levelPaths: Array<String>;
    var currentLevelPath: Null<String>;
    var remainingScreenshotsCount: Int;
    var delayedCount = 0;

    public function loop() {
        if (this.state == Delay) {
            if (this.delayedCount++ >= 5) {
                this.delayedCount = 0;
                this.state = VisitAll;
            }
        }
        else if (this.state == VisitAll) {
            if (this.delayedCount < this.levelPaths.length) {
                Ogmo.editor.levelManager.open(this.levelPaths[this.delayedCount]);
                this.delayedCount += 1;
            }
            else {
                this.state = TakeAndSubmitScreenshots;
            }
        }
        else if (this.state == TakeAndSubmitScreenshots) {
            final levelDirectoryPath = OGMO.project.getAbsoluteLevelDirectories()[0];
            
            if (this.currentLevelPath == null && this.levelPaths.length > 0) {
                this.delayedCount = 0;
                this.currentLevelPath = this.levelPaths.pop();
                Ogmo.editor.levelManager.open(this.currentLevelPath);
            }
            else if (this.delayedCount++ == 5) {
                final struggle = (_:String) -> Ogmo.editor.saveLevelAsImage((png) -> {
                    TimelapseClient.submitScreenshot(this.currentLevelPath.substring(levelDirectoryPath.length), png)
                        .then((cast (() -> this.remainingScreenshotsCount -= 1): Dynamic));
                    this.currentLevelPath = null;
                });

                Ogmo.editor.saveLevelAsImage(struggle);
            }
            else if (this.remainingScreenshotsCount <= 0) {
                Browser.window.location.reload();
            }
            else {
                Ogmo.editor.isDirty = true;
            }
        }
    }
}