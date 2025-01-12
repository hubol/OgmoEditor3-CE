package level.data;

import project.data.LayerTemplate;

class GLayer<TLayerTemplate:LayerTemplate> extends Layer {
    public var template(get, never):TLayerTemplate;

    function get_template() {
        return (cast this.rawTemplate: TLayerTemplate);
    }
}