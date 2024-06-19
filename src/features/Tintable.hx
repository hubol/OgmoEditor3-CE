package features;

import util.Clear;
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

        root.append(Clear.create());

        var container = new JQuery('<div class="tintable-container">');
        root.append(container);

        enabledField = Fields.createCheckbox(template.enabled, "Tintable");
		Fields.createSettingsBlock(container, enabledField, SettingsBlock.Initial);

        var sources = new JQuery('<div class="radios">');

        var rgbRadioButton = disablingRadioButton('rgb', true);
        var levelValuesRadioButton = disablingRadioButton('level', false);

        sources.append(rgbRadioButton, levelValuesRadioButton);

        defaultField = Fields.createRgb(Color.fromHex(template.defaultValue, 1));
		Fields.createSettingsBlock(rgbRadioButton, defaultField, SettingsBlock.Initial, "Default", SettingsBlock.InlineTitle);

        var textField = Fields.createField("#ffffff", "#ffffff");
		Fields.createSettingsBlock(levelValuesRadioButton, textField, SettingsBlock.Initial, "Level Value", SettingsBlock.InlineTitle);

        container.append(sources);
    }

    static function disablingRadioButton(name:String, checked:Bool) {
        var container = new JQuery('<div class="disabling-radio">');
        var input = new JQuery('<input type="radio" name="group">').prop('id', name).prop('checked', checked);
        container.append(input);
        return container;
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

        var tintField = Fields.createRgb(
            Color.fromHex(tintable.tint.substr(1, 6), 1),
            root,
            () -> {
                EDITOR.level.store("Changed Object tint from " + tintable.tint);
            },
            tint -> {
                for (object in tintables)
                    object.tint = tint.toHex();
    
                EDITOR.dirty();
            },
            tint -> {
                for (object in tintables)
                    object.tint = tint.toHex();
    
                EDITOR.level.unsavedChanges = true;
                EDITOR.dirty();
            }
        );

        Fields.createSettingsBlock(root, tintField, SettingsBlock.Full, "Tint", SettingsBlock.OverTitle);
    }
}