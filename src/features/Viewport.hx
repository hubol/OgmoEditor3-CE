package features;

import js.Browser;

class Viewport {
    public static var height(get, null):Float;
    public static var width(get, null):Float;
    public static var min(get, null):Float;
    public static var max(get, null):Float;

    static function get_height() {
        return Math.max(Browser.document.documentElement.clientHeight, Browser.window.innerHeight);
    }
    static function get_width() {
        return Math.max(Browser.document.documentElement.clientWidth, Browser.window.innerWidth);
    }
    static function get_min() {
        return Math.min(Viewport.width, Viewport.height);
    }
    static function get_max() {
        return Math.max(Viewport.width, Viewport.height);
    }
}
