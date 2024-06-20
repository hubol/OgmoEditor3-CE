package project.data.value;

import level.editor.value.RgbValueEditor;
import project.editor.value.RgbValueTemplateEditor;
import level.data.Value;
import util.Color;

class RgbValueTemplate extends ValueTemplate
{
	public static function startup()
	{
		var n = new ValueDefinition(RgbValueTemplate, RgbValueTemplateEditor, "value-rgb", "RGB");
		ValueDefinition.definitions.push(n);
	}

	public var defaults:Color = new Color();

	override function getHashCode():String
	{
		return name + ":rgb";
	}

	override function getDefault():String
	{
		return defaults.toHex();
	}

	override function validate(val:Dynamic):Int
	{
		//TODO!!
		return cast val;
	}

	override function createEditor(values:Array<Value>):Null<RgbValueEditor>
	{
		var editor = new RgbValueEditor();
		editor.load(this, values);
		return editor;
	}

	override function load(data:Dynamic):Void
	{
		super.load(data);
		defaults = Color.fromHex(data.defaults, 1);
	}

	override function save():Dynamic
	{
		var data:Dynamic = super.save();
		data.defaults = defaults.toHex();
		return data;
	}
}
