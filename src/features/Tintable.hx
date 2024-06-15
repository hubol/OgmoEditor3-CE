package features;

import util.Fields;

class TintableTemplate {
    public var enabled:Bool;
    public var defaultValue:String;

    public function new() {
        enabled = false;
        defaultValue = '#ffffff';
    }

    // TODO naming??
    public function createField(root: JQuery) {
        return new TintableTemplateField(root, this);
    }

    public function load(data: Dynamic) {
        enabled = data.tintable != null ? data.tintable : false;
        defaultValue = data.defaultTint != null ? data.defaultTint : '';
    }

    public function save(data: Dynamic) {
        data.tintable = enabled;
        data.defaultTint = defaultValue;
    }

    public function loadObjectTint(data: Dynamic):String {
        if (!enabled)
            return null;
        return data.tint != null ? data.tint : getDefault();
    }

    public function saveObjectTint(tint: String, data: Dynamic) {
        if (!enabled)
            return;
        data.tint = tint;
    }

    public function getDefault() {
        if (!enabled)
            return '#ffffffff';
        if (defaultValue.charAt(0) == '#') {
            var result = defaultValue;
            while (result.length < 9)
                result = result + 'f';
            return result;
        }
        else if (EDITOR.level == null) {
            Sys.println('Attempting to resolve default for TintableTemplate, but EDITOR.level is null!');
            return '#ffffffff';
        }
        for (value in EDITOR.level.values) {
            if (value.template.name == defaultValue)
                return value.value;
        }
        Sys.println('Could not find Editor level value with name ${defaultValue}');
        return '#ffffffff';
    }
}

class TintableTemplateField {
    private var enabledField:JQuery;
    private var defaultField:JQuery;
    private var template: TintableTemplate;

    public function new(root: JQuery, template: TintableTemplate) {
        this.template = template;
        enabledField = Fields.createCheckbox(template.enabled, "Tintable");
		Fields.createSettingsBlock(root, enabledField, SettingsBlock.Fourth);

        // TODO free text entry
        // enabledField = Fields.createCheckbox(template.enabled, "Tint default");
		// Fields.createSettingsBlock(root, enabledField, SettingsBlock.Fourth);
    }

    public function save() {
        template.enabled = Fields.getCheckbox(enabledField);
    }
}

class TintableObject {

}