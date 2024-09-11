package features;

import js.html.Element;
import js.Browser;

class Tooltip {
    var lastMessage:String;
    final tooltipEl:Element;

    public function new() {
        this.tooltipEl = Browser.window.document.querySelector('.global .tooltip');
        Browser.window.document.addEventListener('mousemove', (event) -> {
            final width = this.tooltipEl.clientWidth;
            final x = Math.min(Browser.window.innerWidth - width, event.clientX + 16);
            this.tooltipEl.style.left = x + 'px';
            this.tooltipEl.style.top = (event.clientY + 20) + 'px';
        });
    }

    public function loop() {
        final el = Browser.window.document.querySelector('[data-tooltip]:hover');
        final message = el == null ? '' : el.dataset.tooltip;

        if (this.lastMessage != message) {
            tooltipEl.style.display = message.length > 0 ? 'initial' : 'none';
            tooltipEl.textContent = message;
            this.lastMessage = message;
        }
    }
}