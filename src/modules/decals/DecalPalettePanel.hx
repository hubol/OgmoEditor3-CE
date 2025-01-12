package modules.decals;

import js.node.Path;
import features.TextureRef;
import rendering.Texture;
import js.Browser;
import level.editor.ui.SidePanel;

class DecalPalettePanel extends SidePanel
{
	public var layerEditor: DecalLayerEditor;
	public var holder:JQuery;

	final template:DecalLayerTemplate;

	public function new(layerEditor:DecalLayerEditor, template:DecalLayerTemplate)
	{
		super();
		this.layerEditor = layerEditor;
		this.template = template;
	}

	override function populate(into: JQuery): Void
	{
		holder = new JQuery('<div class="decalPalette">');
		into.append(holder);
		// TODO remove, this does nothing:
		layerEditor.template.doRefresh = refresh;
		refresh();
	}

	public override function refresh():Void
	{
		holder.empty();

		final page = template.textureRepositoryPager.update();

		// add parent link
		if (page.parent != null)
		{
			var button = new JQuery('<span class="decal-folder">&larr; ' + page.parent + '</div>');
			button.on("click", function()
			{
				template.textureRepositoryPager.navigateOut();
				refresh();
			});
			holder.append(button);
		}

		// add subdirectories
		var subdirs:Array<String> = page.subdirectoryNames;
		for (subdir in subdirs)
		{
			var button = new JQuery('<span class="decal-folder">' + subdir + '</div>');
			button.on("click", function()
			{
				template.textureRepositoryPager.navigateInto(subdir);
				refresh();
			});
			holder.append(button);
		}

		final brush = layerEditor.brush == null ? null : layerEditor.brush.path;

		// add files
		var textures:Array<String> = page.texturePaths;
		for (texturePath in textures)
		{
			final baseName = Path.basename(texturePath);
			final texture = template.textureRepository.getTexture(texturePath);
			final textureRef = new TextureRef(template.textureRepository, texturePath);

			var img = new JQuery('<img src="${texture.image.src}"/>');
			var button = new JQuery('<div class="decal" data-tooltip="${baseName}"/>');
			button.append(img);

			Browser.window.setTimeout(function()
			{
				if (img.width() / img.height() > 1) img.width(button.width());
				else img.height(button.height());
			}, 10);

			button.on("click", function(ev)
			{
				layerEditor.brush = textureRef;
				holder.find(".decal").removeClass("selected");
				button.addClass("selected");
				EDITOR.toolBelt.setTool(1);
				if (OGMO.ctrl) {
					layerEditor.selectDecalsWithTexture(textureRef);
				}
			});
			button.on("contextmenu", function(ev)
				{
					layerEditor.updateSelectedDecals(textureRef);
				});
			if (brush == texturePath) button.addClass("selected");
			holder.append(button);
		}
	}
}
