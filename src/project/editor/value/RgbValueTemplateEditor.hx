package project.editor.value;

import project.data.value.RgbValueTemplate;
import js.jquery.JQuery;
import util.Fields;

class RgbValueTemplateEditor extends ValueTemplateEditor
{
	public var defaultField:JQuery;

	override function importInto(into:JQuery)
	{
		var rgbTemplate:RgbValueTemplate = cast template;

		trace('RgbValueTemplateEditor.importInto');
		trace(rgbTemplate.defaults);

		// default val
		defaultField = Fields.createRgb(rgbTemplate.defaults);
		Fields.createSettingsBlock(into, defaultField, SettingsBlock.Half, "Default", SettingsBlock.InlineTitle);
	}

	override function save()
	{
		var rgbTemplate:RgbValueTemplate = cast template;

		rgbTemplate.defaults = Fields.getRgb(defaultField);
		trace('RgbValueTemplateEditor.save');
		trace(rgbTemplate.defaults);
	}
}
