package features;

import haxe.Json;
import js.Browser;

typedef HubolClientMessage = {
    type: String,
    data: Dynamic,
}

class HubolClient {
    function new() {

    }

    public static function sendMessage(url: String, message: HubolClientMessage) {
        return Browser.window.fetch(url, { method: 'POST', body: Json.stringify(message) })
            .then(response -> response.json());
    }
}