package level.data;

import io.Imports;
import io.Export;
import util.Vector;
import util.Calc;

class LevelData
{
	public var size:Vector;
	public var offset:Vector;
	public var values:Array<Value>;
	public var backgroundColor:Color;

	public function new(backgroundColor:Color) {
		size = new Vector();
		offset = new Vector();
		values = [];
		this.backgroundColor = backgroundColor.clone();
	}

	public function clone():LevelData
	{
		var data = new LevelData(backgroundColor);
		data.size = size.clone();
		data.offset = offset.clone();
		data.values = [for (value in values) value.clone()];

		return data;
	}

	public function saveInto(data:Dynamic):Void
	{
		size.saveInto(data, "width", "height");
		offset.saveInto(data, "offsetX", "offsetY");
		Export.values(data, values);
		data.backgroundColor = Export.color(backgroundColor, false);
	}

	public function loadFrom(data:Dynamic):Void
	{
		size = Imports.vector(data, "width", "height", OGMO.project.levelDefaultSize);
		offset = Imports.vector(data, "offsetX", "offsetY");
		values = Imports.values(data, OGMO.project.levelValues);
		backgroundColor = Imports.color(data.backgroundColor, false, backgroundColor);
	}
}