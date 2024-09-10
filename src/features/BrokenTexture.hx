package features;

import rendering.Texture;

class BrokenTexture {
    public static var instance: Texture;

    public static function create() {
        instance = Texture.fromString("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACaSURBVDhPlZHRDoAgCEW1rbfq9/rGfq9668G8Dhw4MDsbgxCuYCGtc4KFDHsg80DGkom8AsXxeiLMa2SKwEihhzmBBS6hUOPtidg7k5iq57G462z7rXrUR6+xhYWqwJ9mRk1DAqb1zopCe3tWLj7ni2es/PBv9DAn+MPnI/LYjBwfj9hdAc1oYLOoAlCjcIhuPdaB5VAZ5QQhvLOnaS958VHUAAAAAElFTkSuQmCC");
    }
}