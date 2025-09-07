package features;

import modules.decals.DecalLayer;
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
                this.levelPaths = task.levelPaths.copy();
                this.levelPathsToScreenshot = task.levelPaths.copy();
                return Ogmo.startPage.onOpenProject(task.ogmoProjectPath);
            })
            .then((cast (() -> this.state = Delay): Dynamic));
    }

    var levelPaths: Array<String>;
    var levelPathsToScreenshot: Array<String>;
    var currentLevelPath: Null<String>;
    var remainingScreenshotsCount: Int;
    var delayedCount = 0;

    var visitAllAttempts = 0;
    var mustVisitAllAgain = false;

    public function loop() {
        if (this.state == Delay) {
            if (this.delayedCount++ >= 5) {
                this.delayedCount = 0;
                this.state = VisitAll;
            }
        }
        else if (this.state == VisitAll) {
            if (this.delayedCount < this.levelPaths.length) {
                final path = this.levelPaths[this.delayedCount];
                Ogmo.editor.levelManager.open(path);
                Ogmo.editor.isDirty = true;
                this.delayedCount += 1;

                if (doAnyDecalLayersHaveBrokenTextures()) {
                    if (visitAllAttempts > 2) {
                        Console.log(path, "appears to be poisoned!");
                        levelPathsToScreenshot.remove(path);
                    }
                    else {
                        mustVisitAllAgain = true;
                    }
                }
            }
            else {
                if (!mustVisitAllAgain) {
                    this.state = TakeAndSubmitScreenshots;
                    this.remainingScreenshotsCount = this.levelPathsToScreenshot.length;
                }
                else {
                    this.delayedCount = 0;
                    this.mustVisitAllAgain = false;
                    this.visitAllAttempts += 1;
                }
            }
        }
        else if (this.state == TakeAndSubmitScreenshots) {
            final levelDirectoryPath = OGMO.project.getAbsoluteLevelDirectories()[0];

            if (this.currentLevelPath == null && this.levelPathsToScreenshot.length > 0) {
                this.currentLevelPath = this.levelPathsToScreenshot.pop();
                Ogmo.editor.levelManager.open(this.currentLevelPath);
                Ogmo.editor.saveLevelAsImage((png) -> {
                    TimelapseClient.submitScreenshot(this.currentLevelPath.substring(levelDirectoryPath.length), png)
                        .then((cast (() -> this.remainingScreenshotsCount -= 1): Dynamic));
                    this.currentLevelPath = null;
                });
            }
            else if (this.remainingScreenshotsCount <= 0) {
                complete();
            }
        }
    }

    private static function complete() {
        Browser.window.location.reload();
    }

    private static function doAnyDecalLayersHaveBrokenTextures() {
        for (layer in Ogmo.editor.level.layers) {
            if (layer.isOfType(DecalLayer)) {
                final decalLayer = (cast layer: DecalLayer);
                for (decal in decalLayer.decals) {
                    if (decal.texture.getTexture() == BrokenTexture.instance) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
}