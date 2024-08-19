package project.editor.value;

import js.jquery.JQuery;
import project.data.value.EnumValueTemplate;
import util.Fields;

class EnumValueTemplateEditor extends ValueTemplateEditor
{
	public var choicesField:JQuery;
	public var useExternalEnumField:JQuery;
	public var externalEnumNameField:JQuery;

	override function importInto(into:JQuery)
	{
		var enumTemplate:EnumValueTemplate = cast template;

		// choices
		useExternalEnumField = Fields.createCheckbox(enumTemplate.useExternalEnum, 'Use External Enum', into);

		final externalEnumNameOptions = new Map<String, String>();
		for (name in OGMO.project.externalEnums.getNames())
			externalEnumNameOptions.set(name, name);
		externalEnumNameField = Fields.createOptions(externalEnumNameOptions, into);

		var choices = enumTemplate.values.join('\n');
		choicesField = Fields.createTextarea("...", choices);
		Fields.createSettingsBlock(into, choicesField, SettingsBlock.Full, "Choices (one per line; ignored if external enum is enabled)");
	}

	override function save()
	{
		var enumTemplate:EnumValueTemplate = cast template;
		var values = Fields.getField(choicesField);
		enumTemplate.values = values.split("\n");
		enumTemplate.useExternalEnum = Fields.getCheckbox(useExternalEnumField);
		enumTemplate.externalEnumName = Fields.getField(externalEnumNameField);
	}
}
