package features;

class LayerEditorMainPanelElement {
    private final _el:JQuery;

    private var _visible = true;

    public function new(html:String) {
        this._el = new JQuery(html);
        new JQuery(".editor_panel-main").append(this._el);
    }

    public function setVisible(visible:Bool) {
        if (this._visible == visible) {
            return;
        }

        this._el.css("display", visible ? "" : "none");
        this._visible = visible;
    }
}