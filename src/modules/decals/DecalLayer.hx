package modules.decals;

import features.TextureRef;
import features.EntityLikeUtils;
import util.Matrix;
import rendering.Texture;
import js.node.Path;
import level.data.Layer;

class DecalLayer extends Layer
{
	public var decals:Array<Decal> = [];

	override function save():Dynamic
	{
		var data = super.save();
		data._contents = "decals";
		data.decals = [];
		for (decal in decals) data.decals.push(decal.save((cast template : DecalLayerTemplate)));
		data.folder = (cast template : DecalLayerTemplate).folder;

		return data;
	}

	override function load(data:Dynamic):Void
	{
		super.load(data);

		final template = (cast this.template : DecalLayerTemplate);
		var decals = Imports.contentsArray(data, "decals");

		for (decal in decals)
		{
			
			var position = Imports.vector(decal, "x", "y");
			var path = haxe.io.Path.normalize(decal.texture);
			var texture:Texture = null;
			var origin = Imports.vector(decal, "originX", "originY", new Vector(0.5, 0.5));
			var scale = Imports.vector(decal, "scaleX", "scaleY", new Vector(1, 1));
			var rotation = Imports.float(decal.rotation, 0);
			var tint = (cast template:DecalLayerTemplate).tintable.loadObjectTint(decal);

			var values = Imports.values(decal, (cast template:DecalLayerTemplate).values);

			var groupName = Imports.string(decal.groupName, null);

			this.decals.push(new Decal(position, path, new TextureRef(template.textureRepository, path), origin, scale, rotation, tint, values, groupName));
		}
	}

	public function getFirstAt(pos:Vector):Array<Decal>
	{
		var i = decals.length - 1;
		while (i >= 0)
		{
			var decal = decals[i];
			if (EntityLikeUtils.containsPoint(EntityLikeMatrix.fromDecal(decal), pos))
				return [decal];
			i--;
		}
		return [];
	}

	public function getAt(pos:Vector):Array<Decal>
	{
		var list:Array<Decal> = [];
		var i = decals.length - 1;
		while (i >= 0)
		{
			var decal = decals[i];
			if (EntityLikeUtils.containsPoint(EntityLikeMatrix.fromDecal(decal), pos))
				list.push(decal);
			i--;
		}
		return list;
	}

	public function getRect(rect:Rectangle):Array<Decal>
	{
		var list:Array<Decal> = [];
		var i = decals.length - 1;
		while (i >= 0)
		{
			var decal = decals[i];
			if (rect.right > decal.position.x - decal.width * decal.origin.x && rect.bottom > decal.position.y - decal.height * decal.origin.y &&
				rect.left < decal.position.x + decal.width * (1-decal.origin.x) && rect.top < decal.position.y + decal.height * (1-decal.origin.y))
				list.push(decal);
			i--;
		}
		return list;
	}

	override function clone():DecalLayer
	{
		var layer = new DecalLayer(level, id);
		for (decal in decals) layer.decals.push(decal.clone(true));
		return layer;
	}

	override function resize(newSize:Vector, shiftBy:Vector):Void
	{
		shift(shiftBy);
	}

	override function shift(amount:Vector):Void
	{
		for (decal in decals)
		{
			decal.position.x += amount.x;
			decal.position.y += amount.y;
		}
	}
}
