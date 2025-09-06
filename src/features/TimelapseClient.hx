package features;

import js.lib.Promise;
import js.lib.Uint8Array;

typedef TimelapseApi_GetTask_Response = {
    ogmoProjectPath: String,
}

typedef TimelapseApi_MarkTaskComplete_Response = {
    ogmoProjectPath: String,
}

typedef ScreenshotRequest = {
    data: Uint8Array,
    width: Int,
    height: Int,
}

class TimelapseClient {
    static final url = "http://localhost:9999";

    private function new() {

    }

    public static function getTask(): Promise<TimelapseApi_GetTask_Response> {
        return HubolClient.sendMessage(url, { type: 'getTask', data: {} });
    }

    public static function submitScreenshot(levelPath: String, pngBase64: String) {
        return HubolClient.sendMessage(url, { type: 'submitScreenshot', data: { levelPath: levelPath, pngBase64: pngBase64 } });
    }
}