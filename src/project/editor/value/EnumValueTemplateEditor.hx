package project.editor.value;

import js.jquery.JQuery;
import project.data.value.EnumValueTemplate;
import util.Fields;

class EnumValueTemplateEditor extends ValueTemplateEditor
{
	public var choicesField:JQuery;

	override function importInto(into:JQuery)
	{
		var enumTemplate:EnumValueTemplate = cast template;

		var choices = "";

		final length = enumTemplate.choices == null ? 0 : enumTemplate.choices.length;
		for (i in 0...length) choices += (i > 0 ? "\n" : "") + enumTemplate.choices[i];

		// choices
		choicesField = Fields.createTextarea("...", choices);
		Fields.createSettingsBlock(into, choicesField, SettingsBlock.Full, "Choices (one per line)");
	}

	override function save()
	{
		var enumTemplate:EnumValueTemplate = cast template;
		var choices = Fields.getField(choicesField);
		enumTemplate.choices = choices.split("\n");
	}
}
