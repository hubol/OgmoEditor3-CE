package modules.decals;

import features.TextureRef;
import features.EntityLikeUtils;
import features.Tintable.ITintable;
import level.data.Value;

class Decal implements ITintable
{
	private static var _nextId = 0;

	public var internalId = Decal._nextId++;

	public var position:Vector;
	public var scale:Vector;
	public var origin:Vector;
	public var rotation:Float;
	public var tint:Color;
	public var texture:TextureRef;
	public var path:String;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var values:Array<Value>;
	public var groupName:String;

	public function new(position:Vector, path:String, texture:TextureRef, ?origin:Vector, ?scale:Vector, ?rotation:Float, ?tint:Color, ?values:Array<Value>, ?groupName:String)
	{
		this.position = position.clone();
		this.texture = texture;
		this.path = path;
		this.scale = scale == null ? new Vector(1, 1) : scale.clone();
		this.rotation = rotation == null ? 0 : OGMO.project.anglesRadians ? rotation : rotation * Calc.DTR;
		this.tint = tint;
		this.values = values == null ? [] : values;
		this.origin = origin == null ? new Vector(0.5, 0.5) : origin.clone();
		this.groupName = groupName;
	}

	public function save(template: DecalLayerTemplate):Dynamic
	{
		var data:Dynamic = {};
		data._name = "decal";
		data.x = position.x;
		data.y = position.y;
		if (template.scaleable)
		{
			data.scaleX = scale.x;
			data.scaleY = scale.y;
		}
		if (template.rotatable) data.rotation = OGMO.project.anglesRadians ? rotation : rotation * Calc.RTD;
		template.tintable.saveObjectTint(this, data);
		data.texture = FileSystem.normalize(path);
		data.originX = origin.x;
		data.originY = origin.y;
		Export.values(data, values);
		data.groupName = this.groupName;

		return data;
	}

	public function clone(?inheritInternalId = false):Decal
	{
		final decal = new Decal(position, path, texture, origin, scale, 0, tint == null ? null : tint.clone(), [for (value in values) value.clone()], this.groupName);
		decal.rotation = rotation;
		if (inheritInternalId) {
			decal.internalId = this.internalId;
		}
		return decal;
	}

	function get_width():Int
	{
		return texture != null ? texture.width : 32;
	}

	function get_height():Int
	{
		return texture != null ? texture.height : 32;
	}

	public function rotate(diff:Float)
	{
		rotation = rotation + diff;
	}

	public function resize(diff:Vector)
	{
		diff.scale(0.1);

		scale.set(
			Calc.roundTo(scale.x + diff.x, 3),
			Calc.roundTo(scale.y + diff.y, 3)
		);
		// TODO - there's probably a more elegant way of doing this! -01010111
		if (OGMO.ctrl) return;
		scale.x = Calc.snap(scale.x, 1);
		scale.y = Calc.snap(scale.y, 1);
	}

	public function drawSelectionBox(origin:Bool)
	{
		var corners = getCorners(2);
		EDITOR.overlay.drawLine(corners[0], corners[1], Color.green);
		EDITOR.overlay.drawLine(corners[1], corners[3], Color.green);
		EDITOR.overlay.drawLine(corners[2], corners[3], Color.green);
		EDITOR.overlay.drawLine(corners[2], corners[0], Color.green);
		if (!origin) return;
		EDITOR.overlay.drawLine(
			Vector.midPoint(corners[0], corners[1]),
			Vector.midPoint(corners[2], corners[3]),
			Color.white
		);
		EDITOR.overlay.drawLine(
			Vector.midPoint(corners[0], corners[2]),
			Vector.midPoint(corners[1], corners[3]),
			Color.white
		);
		EDITOR.overlay.drawRect(position.x - 2, position.y - 2, 4, 4, Color.white);
	}

	public function getCorners(pad:Float):Array<Vector>
	{
		return EntityLikeUtils.getCorners(EntityLikeMatrix.fromDecal(this, pad));
	}

}