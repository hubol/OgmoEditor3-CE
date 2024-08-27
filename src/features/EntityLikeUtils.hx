package features;

import modules.entities.Entity;
import modules.decals.Decal;
import util.Matrix;

class EntityLikeUtils {
    static final _matrix = new Matrix();
	static final result = new Vector();

	static function signed(number:Float, factor:Float) {
		if (number >= 0)
			return factor;
		return -factor;
	}

    public static function containsPoint(matrix:Matrix, point:Vector) {
		result.set(point.x, point.y);
		matrix.inverseTransformPoint(result, result);

		return result.x >= -1 && result.x <= 1 && result.y >= -1 && result.y <= 1;
	}
    
    static final _corners: Array<Vector> = [
        new Vector(-1, -1),
        new Vector(1, -1),
        new Vector(-1, 1),
        new Vector(1, 1)
    ];

    public static function getCorners(matrix:Matrix):Array<Vector> {
        _corners[0].set(-1, -1);
        _corners[1].set(1, -1);
        _corners[2].set(-1, 1);
        _corners[3].set(1, 1);

        matrix.transformPoints(_corners);

        return _corners;
    }
}

class EntityLikeMatrix {
    static final instance = new Matrix();

	static function signed(number:Float, factor:Float) {
		if (number >= 0)
			return factor;
		return -factor;
	}

    static function apply(position:Vector, origin:Vector, size:Vector, rotation:Float, padding:Float) {
        instance.setIdentity();
		instance.translate((origin.x * -2) + 1, (origin.y * -2) + 1);

		instance.scale((size.x + signed(size.x, padding)) / 2, (size.y + signed(size.y, padding)) / 2);

		instance.rotate(rotation);
		instance.translate(position.x, position.y);

        return instance;
    }

    static final _size = new Vector();

    public static function fromDecal(decal:Decal, padding = 2.0) {
        return apply(decal.position, decal.origin, _size.set(decal.width * decal.scale.x, decal.height * decal.scale.y), decal.rotation, padding);
    }

    // TODO use it someday maybe
    // public static function fromEntity(entity:Entity, padding:Float) {
    //     final flipX = entity.flippedX && entity.template.flipOnlyScales;
    //     final flipY = entity.flippedY && entity.template.flipOnlyScales;

    //     return apply(entity.position, entity.origin, _size.set(entity.size.x * (flipX ? -1 : 1), entity.size.y * (flipY ? -1 : 1)), entity.rotation, padding);
    // }
}