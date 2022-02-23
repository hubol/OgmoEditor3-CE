package hacks;

import modules.entities.Entity;
import level.data.Value;
import modules.decals.Decal;

class TintHack {
    public static function getTintForDecal(decal: Decal) {
        return getTint(decal.values);
    }

    public static function getTintForEntity(entity: Entity) {
        return getTint(entity.values);
    }

    public static function getColorForShapeEntity(entity: Entity) {
        var tint = getTint(entity.values);
        if (tint == defaultTint)
            return entity.color;
        return new Color(tint[0], tint[1], tint[2], 1);
    }

    static var defaultTint = [1.0, 1.0, 1.0];

    static function getTint(values: Array<Value>) {
        var tintValues = values.filter(x -> x.template.name == 'tint');
        if (tintValues.length > 0) {
            var value = tintValues[0].value;
            return toFloatArray(value);
        }
        return defaultTint;
    }

    public static function toFloatArray(rgbaHex: String) {
        var withoutHash = rgbaHex.substr(1, 6);
        var int = Std.parseInt('0x' + withoutHash);
        var red = (int >>> 16) / 255.0;
        var green = ((int & 0x00ff00) >>> 8) / 255.0;
        var blue = (int & 0x0000ff) / 255.0;
        return [red, green, blue];
    }
}