package features;

import js.Browser;

class EyeDropper {
    public static function open(onResult:(result: EyeDropperResult) -> Void) {
        // Haxe sucks!
        final window:Dynamic = Browser.window;
        final eyeDropper = window.eval("new EyeDropper();");
        eyeDropper.open().then(onResult);
    }
}

typedef EyeDropperResult = {
    sRGBHex:String,
}