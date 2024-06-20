package features;

import project.data.value.RgbValueTemplate;
import util.Clear;
import util.Fields;

interface ITintable {
    public var tint:String;
}

class TintableTemplate {
    public var enabled:Bool;
    public var defaultTint:String;
    public var rgbLevelValueName:String;
    public var useDefaultTint:Bool;

    public function new() {
        enabled = false;
        defaultTint = "#ffffff";
        rgbLevelValueName = "";
        useDefaultTint = true;
    }

    public function clone() {
        var template = new TintableTemplate();
        template.enabled = enabled;
        template.defaultTint = defaultTint;
        template.rgbLevelValueName = rgbLevelValueName;
        template.useDefaultTint = useDefaultTint;

        return template;
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
        var tintable: Dynamic = data.tintable == null ? {} : data.tintable;

        enabled = tintable.enabled != null ? tintable.enabled : false;
        defaultTint = tintable.defaultTint != null ? tintable.defaultTint : '#ffffff';
        rgbLevelValueName = tintable.rgbLevelValueName != null ? tintable.rgbLevelValueName : '';
        useDefaultTint = tintable.useDefaultTint != null ? tintable.useDefaultTint : true;
    }

    public function save(data: Dynamic) {
        data.tintable = {
            enabled: enabled,
            defaultTint: defaultTint,
            rgbLevelValueName: rgbLevelValueName,
            useDefaultTint: useDefaultTint,
        };
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
            return '#ffffff';
        if (useDefaultTint)
            return defaultTint;
        else if (EDITOR.level == null) {
            trace('Attempting to resolve default for TintableTemplate, but EDITOR.level is null!');
            return '#ffffff';
        }
        for (value in EDITOR.level.values) {
            if (value.template.name == rgbLevelValueName)
                return value.value;
        }
        trace('Could not find Editor level value with name ${rgbLevelValueName}');
        return '#ffffff';
    }
}

class TintableTemplateField {
    private var enabledField:JQuery;
    private var defaultTintField:JQuery;
    private var levelOptionField:JQuery;
    private var radioButtons:JQuery;
    private var template: TintableTemplate;

    public function new(root: JQuery, template: TintableTemplate) {
        this.template = template;

        root.append(Clear.create());

        var container = new JQuery('<div class="tintable-container">');
        root.append(container);

        enabledField = Fields.createCheckbox(template.enabled, "Tintable");
		Fields.createSettingsBlock(container, enabledField, SettingsBlock.Initial);

        container.append('<div>Default tint from...</div>');

        radioButtons = new JQuery('<div class="radios">');

        var rgbRadioButton = disablingRadioButton('rgb', template.useDefaultTint);
        var levelValuesRadioButton = disablingRadioButton('level', !template.useDefaultTint);

        radioButtons.append(rgbRadioButton, levelValuesRadioButton);

        defaultTintField = Fields.createRgb(Color.fromHex(template.defaultTint, 1), rgbRadioButton);

        var options = buildLevelValueOptions();

        levelOptionField = Fields.createOptions(options);
        levelOptionField.val(template.rgbLevelValueName);
		Fields.createSettingsBlock(levelValuesRadioButton, levelOptionField, SettingsBlock.Initial, "RGB Level Value", SettingsBlock.InlineTitle);

        container.append(radioButtons);
    }

    static function buildLevelValueOptions() {
        var map = new Map<String, String>();

        for (levelValue in OGMO.project.levelValues) {
            if (levelValue.definition.type == RgbValueTemplate)
                map.set(levelValue.name, levelValue.name);
        }

        return map;
    }

    static function disablingRadioButton(name:String, checked:Bool) {
        var container = new JQuery('<div class="disabling-radio">');
        var input = new JQuery('<input type="radio" name="group">').prop('value', name).prop('checked', checked);
        container.append(input);
        return container;
    }

    public function save() {
        template.enabled = Fields.getCheckbox(enabledField);
        template.defaultTint = Fields.getRgb(defaultTintField).toHex();
        template.rgbLevelValueName = Fields.getField(levelOptionField);
        var checkedValue = radioButtons.find("input:checked").val();
        template.useDefaultTint = checkedValue == 'rgb';
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