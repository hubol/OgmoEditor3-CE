package features;

import js.Browser;
import js.lib.Promise;

class Promises {
    function new() {

    }

    public static function wait(predicate: () -> Bool): Promise<Bool> {
        return new Promise((resolve, reject) -> {
            var interval;
            interval = Browser.window.setInterval(() -> {
                try {
                    if (predicate()) {
                        Browser.window.clearInterval(interval);
                        resolve(true);
                    }
                }
                catch (e) {
                    Browser.window.clearInterval(interval);
                    reject(e);
                }
            });
        });
    }
}