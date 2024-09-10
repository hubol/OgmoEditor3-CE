package features;

class TextureRef {
    final repository:TextureRepository;
    public final path:String;

    public var center(get, null):Vector;
	public var width(get, null):Int;
	public var height(get, null):Int;

    static final defaultCenter = new Vector(0.5, 0.5);

    inline function get_center() {
        final texture = this.repository.getTexture(path);
        if (texture == null)
            return TextureRef.defaultCenter;
        return texture.center;
    }

	inline function get_width() {
        final texture = this.repository.getTexture(path);
        if (texture == null)
            return 16;
        return texture.width;
    }

    inline function get_height() {
        final texture = this.repository.getTexture(path);
        if (texture == null)
            return 16;
        return texture.height;
    }

    public function getTexture() {
        final texture = this.repository.getTexture(path);
        if (texture == null)
            return BrokenTexture.instance;
        return texture;
    }

    public function new(repository:TextureRepository, path:String) {
        this.repository = repository;
        this.path = path;
    }


}