package util;

import js.html.Element;

typedef IroColorPickerLayoutItemOptions = {
	?id:String,
	?sliderType:String,
	?boxHeight:Int,
}

typedef IroColorPickerLayoutItem = {
	component:Dynamic,
	?options:IroColorPickerLayoutItemOptions,
}

typedef IroColorPickerOptions = {
	width:Int,
	color:String,
	?handleRadius:Int,
	?borderWidth:Int,
	?borderColor:String,
	layout:Array<IroColorPickerLayoutItem>,
}

typedef IroColorPickerColor = {
	hexString:String,
}

@:jsRequire("@jaames/iro", "default.ColorPicker")
extern class IroColorPicker
{
	@:overload(function(el:String, ?options:IroColorPickerOptions):Void {})
	public function new(el:Element, ?options:IroColorPickerOptions):Void;

	public function on(event:String, listener:String->Void):Void;

	public final color:IroColorPickerColor;
}

@:jsRequire("@jaames/iro", "default.ui")
extern class IroComponents
{
	public static final Box:Dynamic;
	public static final Slider:Dynamic;
}