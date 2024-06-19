package features;

import util.Fields;

interface ITintable {
    public var tint:String;
}

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

    public function createObjectField<T:ITintable>(root: JQuery, tintables: Array<T>) {
        if (!enabled)
            return;
        new TintableObjectField(root, tintables);
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
            trace('Attempting to resolve default for TintableTemplate, but EDITOR.level is null!');
            return '#ffffffff';
        }
        for (value in EDITOR.level.values) {
            if (value.template.name == defaultValue)
                return value.value;
        }
        trace('Could not find Editor level value with name ${defaultValue}');
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

        defaultField = Fields.createField("#ffffff", template.defaultValue);
		Fields.createSettingsBlock(root, defaultField, SettingsBlock.Fourth, "Default Tint", SettingsBlock.InlineTitle);
    }

    public function save() {
        template.enabled = Fields.getCheckbox(enabledField);
        template.defaultValue = Fields.getField(defaultField);
    }
}

class TintableObjectField<T:ITintable> {
    public function new(root: JQuery, tintables: Array<T>) {
        if (tintables.length == 0) {
            trace('TintableObjectField.new got tintables array with 0 items!');
            return;
        }
            
        var tintable = tintables[0];
        var expectingChangeInput = false;

        var tintField = Fields.createColor("Tint", Color.fromHex(tintable.tint.substr(1, 6), 1), root, tint -> {
            if (!FeatureFlags.colorInputV2)
                EDITOR.level.store("Changed Object tint from '" + tintable.tint + "'	to '" + tint + "'");

            expectingChangeInput = false;
            
            for (object in tintables)
                object.tint = tint.toHex();

            EDITOR.level.unsavedChanges = true;
            EDITOR.dirty();
        }, FeatureFlags.colorInputV2 ? tint -> {
            if (!expectingChangeInput) {
                EDITOR.level.store("Changed Object tint from '" + tintable.tint);
                expectingChangeInput = true;
            }

            for (object in tintables)
                object.tint = tint.toHex();

            EDITOR.dirty();
        } : null);

        Fields.createSettingsBlock(root, tintField, SettingsBlock.Full, "Tint", SettingsBlock.OverTitle);
    }
}