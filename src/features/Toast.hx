package features;

import js.Browser;

class Toast {
    static function getClassSuffix(type: ToastType) {
        if (type == ToastType.Undo)
            return 'undo';
        // if (type == ToastType.Redo)
            return 'redo';
        // return 'external-update';
    }

    static var timeoutId: Int;

    public static function show(type: ToastType, description: String, activeMs = 1000) {
        final suffix = getClassSuffix(type);
        final html = '<div class="icon icon-$suffix"></div><div class="label $suffix">$description</div>';

        final container = new JQuery('.global .toast');

		container.html(html).addClass('active');

		if (timeoutId != null) Browser.window.clearTimeout(timeoutId);

		timeoutId = Browser.window.setTimeout(() -> container.removeClass('active'), activeMs);
    }
}

enum ToastType {
    Undo;
    Redo;
    // ExternalUpdate;
}