package features;

import js.lib.Promise;

class Prompt {
    private static var _id = 0;

    public static function show(question:String, placeholder:String, value:String): Promise<String> {
        if (placeholder == null) {
            placeholder = '';
        }

        if (value == null) {
            value = '';
        }

        final id = 'prompt_' + Prompt._id++;

        return new Promise((resolve, reject) -> {
            final el = new JQuery('<dialog>
        <form>
            <label for=${id}>${question}</label>
            <input type="text" placeholder="${placeholder}" value="${value}" />
        </form>
</dialog>');

            new JQuery(".prompt-container").append(el);

            el.submit((ev) -> {
                ev.preventDefault();
                resolve(el.find('input').val());
                el.remove();
            });

            el.find('input').focus().select();

            final domEl: Dynamic = el.get(0);
            domEl.showModal();
        });
    }
}