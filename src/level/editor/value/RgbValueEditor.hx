package level.editor.value;

import modules.entities.EntityLayer;
import features.Tintable.ITintable;
import modules.decals.DecalLayerTemplate;
import modules.decals.DecalLayer;
import util.Fields;
import project.data.value.ValueTemplate;
import level.data.Value;
import js.jquery.JQuery;

class RgbValueEditor extends ValueEditor
{
	public var title:String;
	public var element:JQuery = null;

	static function isCurrentLevelTemplate(template:ValueTemplate) {
		if (EDITOR.level == null)
			return false;
		for (value in EDITOR.level.values) {
			if (value.template == template)
				return true;
		}
		return false;
	}

	static function updateTintsOnLevelTemplateChange(template:ValueTemplate, previous:String, next:String) {
		if (EDITOR.level == null)
			return;

		var tintables: Array<ITintable> = [];

		for (layer in EDITOR.level.layers) {
			var decalLayer = layer.downcast(DecalLayer);
			var entityLayer = layer.downcast(EntityLayer);
			if (decalLayer != null) {
				var decalLayerTemplate: DecalLayerTemplate = cast decalLayer.template;
				var tintable = decalLayerTemplate.tintable;

				if (tintable.receivesFromLevelValue(template)) {
					for (decal in decalLayer.decals) {
						tintables.push(decal);
					}
				}
			}
			else if (entityLayer != null) {
				for (entity in entityLayer.entities.list) {
					var tintable = entity.template.tintable;
					if (tintable.receivesFromLevelValue(template)) {
						tintables.push(entity);
					}
				}
			}
		}

		for (tintable in tintables) {
			if (tintable.tint == previous)
				tintable.tint = next;
		}
	}

	override function load(template:ValueTemplate, values:Array<Value>):Void
	{
		title = template.name;

		// check if values conflict
		var value = values[0].value;
		var conflict = false;
		var i = 1;
		while (i < values.length && !conflict)
		{
			if (values[i].value != value)
			{
				conflict = true;
				value = ValueEditor.conflictString();
			}
			i++;
		}

		var previousHexValue = value;
		var _isCurrentLevelTemplate = isCurrentLevelTemplate(template);

		function updateDecalsToNewColor(color: Color) {
			if (_isCurrentLevelTemplate) {
				var nextHexValue = color.toHex();
				updateTintsOnLevelTemplateChange(template, previousHexValue, nextHexValue);
				previousHexValue = nextHexValue;
				EDITOR.dirty();
			}
		}

		var color = conflict ? Color.black : Color.fromHex(value, 1);
		element = Fields.createRgb(
			color,
			null,
			() -> {
				var description = "Changed " + template.name + " Value from '" + value + "'";
				if (_isCurrentLevelTemplate)
					EDITOR.level.storeFull(false, false, description);
				else
					EDITOR.level.store(description);
			},
			color -> {
				updateDecalsToNewColor(color);
			},
			color -> {
				updateDecalsToNewColor(color);
				for (i in 0...values.length) values[i].value = color.toHex();
			}
		);
	}

	override function display(into:JQuery):Void
	{
		ValueEditor.createWrapper(title, element, into);
	}
}
