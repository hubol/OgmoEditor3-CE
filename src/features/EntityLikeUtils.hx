package features;

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

    static function containsPoint(matrix:Matrix, point:Vector) {
		result.set(point.x, point.y);
		matrix.inverseTransformPoint(result, result);

		return result.x >= -1 && result.x <= 1 && result.y >= -1 && result.y <= 1;
	}

    static function prepareMatrix(position:Vector, origin:Vector, scale:Vector, width:Float, height:Float, rotation:Float, padding:Float) {
        _matrix.setIdentity();
		_matrix.translate((origin.x * -2) + 1, (origin.y * -2) + 1);

		final width = scale.x * width;
		final height = scale.y * height;

		_matrix.scale((width + signed(width, padding)) / 2, (height + signed(height, padding)) / 2);

		_matrix.rotate(rotation);
		_matrix.translate(position.x, position.y);

        return _matrix;
    }

    static function decalPrepareMatrix(decal:Decal, padding:Float) {
        return prepareMatrix(decal.position, decal.origin, decal.scale, decal.width, decal.height, decal.rotation, padding);
    }

    static final _corners: Array<Vector> = [
        new Vector(-1, -1),
        new Vector(1, -1),
        new Vector(-1, 1),
        new Vector(1, 1)
    ];

    static function getCorners(matrix:Matrix):Array<Vector> {
        _corners[0].set(-1, -1);
        _corners[1].set(1, -1);
        _corners[2].set(-1, 1);
        _corners[3].set(1, 1);

        matrix.transformPoints(_corners);

        return _corners;
    }

	public static function decalContainsPoint(decal:Decal, point:Vector, padding = 2.0) {
        return containsPoint(decalPrepareMatrix(decal, padding), point);
	}

    public static function decalGetCorners(decal:Decal, padding = 2.0) {
        return getCorners(decalPrepareMatrix(decal, padding));
	}
}
