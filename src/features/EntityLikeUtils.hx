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

    public static function containsPoint(matrix:Matrix, point:Vector) {
		result.set(point.x, point.y);
		matrix.inverseTransformPoint(result, result);

		return result.x >= -1 && result.x <= 1 && result.y >= -1 && result.y <= 1;
	}

    static final topLeft = new Vector();
    static final topRight = new Vector();
    static final bottomRight = new Vector();
    static final bottomLeft = new Vector();

    static final unitRectangleVectors = [ new Vector(-1, -1), new Vector(1, -1), new Vector(1, 1), new Vector(-1, 1) ];

    public static function overlapsRectangle(matrix:Matrix, rectangle:Rectangle) {
        // Are the corners of the rectangle inside of the shape?
		topLeft.set(rectangle.left, rectangle.top);
		matrix.inverseTransformPoint(topLeft, topLeft);

        // if (topLeft.x >= -1 && topLeft.x <= 1 && topLeft.y >= -1 && topLeft.y <= 1) {
        //     return true;
        // }

        topRight.set(rectangle.right, rectangle.top);
        matrix.inverseTransformPoint(topRight, topRight);

        // if (topRight.x >= -1 && topRight.x <= 1 && topRight.y >= -1 && topRight.y <= 1) {
        //     return true;
        // }

        bottomRight.set(rectangle.right, rectangle.bottom);
        matrix.inverseTransformPoint(bottomRight, bottomRight);

        // if (bottomRight.x >= -1 && bottomRight.x <= 1 && bottomRight.y >= -1 && bottomRight.y <= 1) {
        //     return true;
        // }

        bottomLeft.set(rectangle.left, rectangle.bottom);
        matrix.inverseTransformPoint(bottomLeft, bottomLeft);

        // if (bottomLeft.x >= -1 && bottomLeft.x <= 1 && bottomLeft.y >= -1 && bottomLeft.y <= 1) {
        //     return true;
        // }

		return !unitRectangleHasSeparationLineAgainstQuadrilateral() && !quadrilateralHasSeparationLineAgainstUnitRectangle();
	}

    static final unitRectangleCorners: Array<Vector> = [
        new Vector(-1, -1),
        new Vector(1, -1),
        new Vector(1, 1),
        new Vector(-1, 1)
    ];

    static final unitRectangleTangents: Array<Vector> = [
        new Vector(2, 0),
        new Vector(0, 2),
        new Vector(-2, 0),
        new Vector(0, -2)
    ];

    static final quadCornerVectors = [
        topLeft,
        topRight,
        bottomRight,
        bottomLeft,
    ];

    static final quadNextCornerVectors = [
        topRight,
        bottomRight,
        bottomLeft,
        topLeft,
    ];

    static final offset = new Vector();
    static final quadTangent = new Vector();

    // Check tangents of unit rectangle against quadrilateral
    static function unitRectangleHasSeparationLineAgainstQuadrilateral() {
        for (i in 0...4) {
            final unitCorner = unitRectangleCorners[i];
            final unitTangent = unitRectangleTangents[i];

            for (j in 0...4) {
                final quadCorner = quadCornerVectors[j];
                offset.set(quadCorner.x, quadCorner.y).sub(unitCorner);
                if (wedge(unitTangent, offset) > 0) {
                    // This is not a separating line,
                    // But we need to check for others
                    break;
                }
                else if (j == 3) {
                    // This is a separating line,
                    // All the quadrilateral corners failed
                    return true;
                }
            }
        }

		return false;
    }

    // Check tangents of quadrilateral against unit rectangle
    static function quadrilateralHasSeparationLineAgainstUnitRectangle() {
        for (i in 0...4) {
            final quadCorner = quadCornerVectors[i];
            final nextQuadCorner = quadNextCornerVectors[i];
            quadTangent.set(nextQuadCorner.x, nextQuadCorner.y).sub(quadCorner);

            for (j in 0...4) {
                final unitCorner = unitRectangleCorners[j];
                offset.set(unitCorner.x, unitCorner.y).sub(quadCorner);
                if (wedge(quadTangent, offset) > 0) {
                    // This is not a separating line,
                    // But we need to check for others
                    break;
                }
                else if (j == 3) {
                    // This is a separating line,
                    // All the quadrilateral corners failed
                    return true;
                }
            }
        }

		return false;
    }

    // dot product but rotated
    // a thing to mind is it is anticommutative
    // wedge(a,b) == -wedge(b,a)
    static function wedge(v:Vector, other:Vector) {
        return v.x * other.y - v.y * other.x;
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