package level.editor;

class GLayerEditor<TLayer, TLayerTemplate> extends LayerEditor {
    public var layer(get, never):TLayer;
    public var template(get, never):TLayerTemplate;

    function get_layer() {
        return (cast this.rawLayer: TLayer);
    }

    function get_template() {
        return (cast this.rawTemplate: TLayerTemplate);
    }
}