package modules.decals;

import features.DecalGroups.UiDecalGroupsList;
import features.TextureRef;
import level.editor.ui.SidePanel;
import level.editor.LayerEditor;

class DecalLayerEditor extends LayerEditor
{
	public var brush:TextureRef;
	public var selected:Array<Decal> = [];
	public var hovered:Array<Decal> = [];
	public var selectedChanged:Bool = true;

	private var _hoveredGroupName:String;
	
	function _onGroupNameMouseEnter(name:String) {
		EDITOR.overlayDirty();
		this._hoveredGroupName = name;
	}

	function _onGroupNameMouseLeave(name:String) {
		if (this._hoveredGroupName == name) {
			EDITOR.overlayDirty();
			this._hoveredGroupName = null;
		}
	}

	function _onGroupNameClick(name:String) {
		if (!OGMO.shift) {
			this.selected.resize(0);
		}
		
		for (decal in (cast this.layer : DecalLayer).decals) {
			if (decal.groupName == name) {
				this.selected.push(decal);
			}
		}
	}

	private final _uiDecalGroupsList: UiDecalGroupsList;

	public function new(id:Int) {
		super(id);
		this._uiDecalGroupsList = new UiDecalGroupsList(
			this._onGroupNameMouseEnter,
			this._onGroupNameMouseLeave,
			this._onGroupNameClick);
	}

	public function toggleSelected(list:Array<Decal>):Void
	{
		var removing:Array<Decal> = [];
		for (decal in list)
		{
			if (selected.indexOf(decal) >= 0) removing.push(decal);
			else selected.push(decal);
		}
		for (decal in removing) selected.remove(decal);
		selectedChanged = true;
	}

	public function selectedContainsAny(list:Array<Decal>):Bool
	{
		for (decal in list) if (selected.indexOf(decal) >= 0) return true;
		return false;
	}

	public function remove(decal:Decal):Void
	{
		(cast layer : DecalLayer).decals.remove(decal);
		hovered.remove(decal);
		selected.remove(decal);
	}

	override function draw(): Void
	{
		// draw decals
		for (decal in (cast layer : DecalLayer).decals)
		{
			if (decal.texture != null){
				var originInPixels = new Vector(decal.width * decal.origin.x, decal.height * decal.origin.y);
				EDITOR.draw.drawTexture(decal.position.x, decal.position.y, decal.texture.getTexture(), originInPixels, decal.scale, decal.rotation,
					null, null, null, null, decal.tint);
			}
			else
			{
				var ox = decal.position.x;
				var oy = decal.position.y;
				var w = decal.width;
				var h = decal.height;
				var originx = decal.origin.x * w;
				var originy = decal.origin.y * h;
				EDITOR.draw.drawRect(ox - originx, oy - originy, w, 1, Color.red);
				EDITOR.draw.drawRect(ox - originx, oy - originy, 1, h, Color.red);
				EDITOR.draw.drawRect(ox + originx - 1, oy - originy, 1, h, Color.red);
				EDITOR.draw.drawRect(ox - originx, oy + originy - 1, w, 1, Color.red);
				EDITOR.draw.drawLine(new Vector(ox - originx, oy - originy), new Vector(ox + originx, oy + originy), Color.red);
				EDITOR.draw.drawLine(new Vector(ox + originx, oy - originy), new Vector(ox - originx, oy + originy), Color.red);
			}
		}

		if (active) for (decal in hovered) decal.drawSelectionBox(false);
	}
	
	override function drawOverlay()
	{
		if (this._hoveredGroupName != null) {
			for (decal in (cast layer : DecalLayer).decals) {
				if (decal.groupName == this._hoveredGroupName) {
					decal.drawSelectionBox(true);
				}
			}
			return;
		}
		if (selected.length <= 0) return;
		for (decal in selected) decal.drawSelectionBox(true);
	}

	override function drawHighlight() {
		for (decal in (cast this.layer : DecalLayer).decals)
			decal.drawSelectionBox(false);
	}

	override function loop() {
		final template:DecalLayerTemplate = cast this.template;
		final textureRepositoryPagerHasChanges = template.textureRepositoryPager.isOutdated() == HasChanges;

		if (textureRepositoryPagerHasChanges) {
			this.decalPalettePanel.refresh();
		}

		if (selectedChanged) {
			selectedChanged = false;
			selectionPanel.refresh();
		}

		if (selectedChanged || textureRepositoryPagerHasChanges) {
			EDITOR.dirty();
		}
	}

	override function refresh() {
		selected.resize(0);
		selectedChanged = true;
	}

	var decalPalettePanel:DecalPalettePanel;

	override function createPalettePanel():SidePanel
	{
		this.decalPalettePanel = new DecalPalettePanel(this, cast this.template);
		return this.decalPalettePanel;
	}

	override function createSelectionPanel():Null<SidePanel> 
	{
		return new DecalSelectionPanel(this);
	}

	override function afterUndoRedo():Void
	{
		final previousSelectedDecals = this.selected;
		this.selected = [];
		this.hovered = [];

		if (previousSelectedDecals.length == 0)
			return;

		final decals = (cast this.layer : DecalLayer).decals;
		final decalsByInternalId = new Map<Int,Decal>();

		for (decal in decals) {
			decalsByInternalId.set(decal.internalId, decal);
		}

		for (previousDecal in previousSelectedDecals) {
			final decal = decalsByInternalId.get(previousDecal.internalId);
			if (decal != null)
				this.selected.push(decal);
		}
	}

	override public function onEditorCleaned() {
		this._uiDecalGroupsList.onEditorCleaned((cast this.layer : DecalLayer));
	}
}
