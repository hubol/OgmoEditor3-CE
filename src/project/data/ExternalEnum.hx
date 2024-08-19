package project.data;

import haxe.ds.ReadOnlyArray;
import js.lib.Set;

class ExternalEnum {
    public final name:String;
    public final values:Array<String> = [];

    public function new(name:String) {
        this.name = name;
    }

    public function has(value:String) {
        return values.indexOf(value) != -1;
    }

    public function update(newValues:Set<String>) {
        this.values.resize(0);
        for (value in newValues)
            this.values.push(value);
    }
}

class ExternalEnums {
    final externalEnums = new Map<String, ExternalEnum>();

    public function new() {

    }

    public function getNames(): ReadOnlyArray<String> {
        return [for (externalEnum in externalEnums) externalEnum.name];
    }

    public function getValues(enumName:String): ReadOnlyArray<String> {
        final externalEnum = externalEnums.get(enumName);
        if (externalEnum == null)
            return null;
        return externalEnum.values;
    }

    public function checkValue(enumName:String, value:String): Bool {
        final externalEnum = externalEnums.get(enumName);
        if (externalEnum == null)
            return false;

        return externalEnum.has(value);
    }

    static function loadValues(item:Dynamic) {
        try {
            return new Set<String>(item.values);
        }
        catch (e) {
            trace("Error while loading external enum values");
            trace(e);
            return null;
        }
    }

    public function load(items:Array<Dynamic>) {
        if (items == null)
            items = [];

        final result = {
            removedEnumNames: new Array<String>(),
            addedEnumNames: new Array<String>(),
            removedEnumValues: new Array<{ enumName:String, value:String }>(),
            addedEnumValues: new Array<{ enumName:String, value:String }>(),
            errors: new Array<String>(),
        };

        final incomingNames = new Set<String>();

        for (item in items) {
            if (item == null) {
                result.errors.push('external enums must not be null');
                continue;
            }

            final name:String = item.name;
            final values = loadValues(item);

            if (name == null && values == null) {
                result.errors.push('name and values properties are required for external enums');
                continue;
            }
            if (name == null) {
                result.errors.push('name property is required for external enums');
                continue;
            }
            if (incomingNames.has(name)) {
                result.errors.push('duplicate external enum name: ' + name);
                continue;
            }
            if (values == null) {
                result.errors.push('values property is required for external enums, missing for enum: ' + name);
                continue;
            }
            if (values.size == 0) {
                result.errors.push('values property must be a non-empty array, empty for enum: ' + name);
                continue;
            }

            incomingNames.add(name);

            if (!this.externalEnums.exists(name)) {
                final externalEnum = new ExternalEnum(name);
                result.addedEnumNames.push(name);
                this.externalEnums.set(name, externalEnum);
            }

            final externalEnum:ExternalEnum = this.externalEnums.get(name);

            for (previousValue in externalEnum.values) {
                if (!values.has(previousValue))
                    result.removedEnumValues.push({ enumName: name, value: previousValue });
            }

            for (value in values) {
                if (!externalEnum.has(value))
                    result.addedEnumValues.push({ enumName: name, value: value });
            }

            externalEnum.update(values);
        }

        for (name in this.externalEnums.keys()) {
            if (!incomingNames.has(name))
                result.removedEnumNames.push(name);
        }

        for (removedEnumName in result.removedEnumNames) {
            this.externalEnums.remove(removedEnumName);
        }

        return result;
    }

    public function save() {
        final result = [for (externalEnum in externalEnums) ({ name: externalEnum.name, values: externalEnum.values })];
        result.sort((a, b) -> Sort.sortAlphabetically(a.name, b.name));
        return result;
    }
}

class Sort {
    // Thanks
    // https://ashes999.github.io/learnhaxe/sorting-an-array-of-strings-in-haxe.html
    public static function sortAlphabetically(a:String, b:String):Int {
        a = a.toUpperCase();
        b = b.toUpperCase();

        if (a < b) {
            return -1;
        }
        else if (a > b) {
            return 1;
        } else {
            return 0;
        }
    }
}