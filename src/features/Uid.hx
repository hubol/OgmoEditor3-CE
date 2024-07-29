package features;

import js.lib.Date;

class Uid {
    function new() {

    }

    static var previous = -1;

    public static function next() {
        var value = Math.round(Date.now() * 100);
        if (previous >= value) {
            value = previous + 1;
        }

        previous = value;
        return value;
    }
}