package modules.decals;

import features.TextureRepository;
import features.Tintable.TintableTemplate;
import js.node.Path;
import level.editor.Tool;
import level.data.Level;
import level.editor.LayerEditor;
import rendering.Texture;
import project.data.Project;
import project.data.LayerTemplate;
import project.data.LayerDefinition;
import project.data.value.ValueTemplate;
import modules.decals.tools.DecalCreateTool;
import modules.decals.tools.DecalSelectTool;
import modules.decals.tools.DecalResizeTool;
import modules.decals.tools.DecalRotateTool;
import util.Klaw;

typedef Files = 
{
	?name: String,
	?dirname:String,
	?parent: Files,
	?textures: Array<Dynamic>,
	?subdirs: Array<Files>
}

class DecalLayerTemplate extends LayerTemplate
{
	public static function startup()
	{
		var tools:Array<Tool> = [
			new DecalSelectTool(),
			new DecalCreateTool(),
			new DecalResizeTool(),
			new DecalRotateTool(),
		];
		var n = new LayerDefinition(DecalLayerTemplate, DecalLayerTemplateEditor, "decal", "image", "Decal Layer", tools, 4);
		LayerDefinition.definitions.push(n);
	}

	public var folder:String = "";
	public var includeImageSequence:Bool = true;
	public var values:Array<ValueTemplate> = [];
	public var scaleable:Bool;
	public var rotatable:Bool;
	public var tintable = new TintableTemplate();
	public var doRefresh:Void->Void;

	public var textureRepository:TextureRepository;
	public var textureRepositoryPager:TextureRepositoryPager;

	var walker:Walker;

	override function createEditor(id:Int): LayerEditor
	{
		return new DecalLayerEditor(id);
	}

	override function createLayer(level:Level, id:Int):DecalLayer
	{
		return new DecalLayer(level, id);
	}

	override function save():Dynamic
	{
		var data:Dynamic = super.save();
		data.folder = folder;
		data.includeImageSequence = includeImageSequence;
		data.scaleable = scaleable;
		data.rotatable = rotatable;
		tintable.save(data);
		data.values = ValueTemplate.saveList(values);
		return data;
	}

	override function load(data:Dynamic):DecalLayerTemplate
	{
		super.load(data);
		folder = data.folder;
		includeImageSequence = data.includeImageSequence;
		scaleable = data.scaleable;
		rotatable = data.rotatable;
		tintable.load(data);
		values = ValueTemplate.loadList(data.values);
		return this;
	}

	override function projectWasLoaded(project:Project):Void
	{
		// starts reading all directories
		var path = Path.join(Path.dirname(project.path), folder);
		this.textureRepository = TextureRepository.create(path);
		this.textureRepositoryPager = new TextureRepositoryPager(this.textureRepository);
	}

	override function projectWasUnloaded()
	{
		this.textureRepository.destroy();
	}
}
