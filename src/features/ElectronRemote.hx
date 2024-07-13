package features;

import electron.remote.BrowserWindow;

class ElectronRemote {
    function new() {

    }

    static var module = js.Lib.require('@electron/remote');
    public static var app = module.app;
    public static var dialog = module.dialog;
    public static function getCurrentWindow(): BrowserWindow {
        return module.getCurrentWindow();
    }
}