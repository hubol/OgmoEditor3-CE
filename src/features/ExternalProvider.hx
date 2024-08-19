package features;

import js.lib.Date;
import js.html.IFrameElement;
import js.Browser;

class ExternalProvider {
    final iframe: IFrameElement;
    var url:String;

    public function new() {
        iframe = Browser.window.document.createIFrameElement();

        new JQuery('.external-provider').append(iframe);

        var window = iframe.contentWindow;

        Browser.window.addEventListener('message', (event) -> {
            if (event.source == window) {
                this.onData(event.data);
            }
        });
    }

    public function setUrl(nextUrl:String) {
        if (nextUrl == null)
            nextUrl = '';

        if (nextUrl == url)
            return;
        
        iframe.src = nextUrl;
        url = nextUrl;
    }

    function onData(data: ExternalProviderData) {
        trace(data);

        if (data == null) {
            Toast.show(ExternalUpdate, 'Got null data', 5000);
            return;
        }

        final result = OGMO.project.externalEnums.load(data.enums);

        final addedNames = result.addedEnumNames.join(', ');
        final removedNames = result.removedEnumNames.join(', ');
        final addedValues = [for (pair in result.addedEnumValues) '${pair.enumName}.${pair.value}'].join(', ');
        final removedValues = [for (pair in result.removedEnumValues) '${pair.enumName}.${pair.value}'].join(', ');
        final errors = [for (error in result.errors) '<div>$error</div>'].join('');

        final message = '
${addedNames.length > 0 ? '<div>Added enums: $addedNames</div>' : ""}
${addedValues.length > 0 ? '<div>Added values: $addedValues</div>' : ""}
${removedNames.length > 0 ? '<div>Removed enums: $removedNames</div>' : ""}
${removedValues.length > 0 ? '<div>Removed values: $removedValues</div>' : ""}
${errors.length > 0 ? "<div>Errors:</div>" : ""}$errors';

        Toast.show(ExternalUpdate, message, 5000);
    }
}

typedef ExternalProviderData = {
    enums: Array<{ name:String, values:Array<String> }>,
}