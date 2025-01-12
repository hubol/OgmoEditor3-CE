package modules.grid;

import level.editor.GLayerEditor;
import level.editor.LayerEditor;

class GridLayerEditor extends GLayerEditor<GridLayer, GridLayerTemplate>
{
	public var brushLeft: String;
	public var brushRight: String;

	public function new(id:Int)
	{
		super(id);

		//Default brushes
		brushLeft = this.template.firstSolid;
		brushRight = this.template.transparent;
	}

	override function draw():Void
	{
		for (y in 0...this.layer.data[0].length)
		{
			var last:String = null;
			var range:Int = 0;

			for (x in 0...this.layer.data.length + 1)
			{
			var at:String = null;
			if (x < this.layer.data.length) at = this.layer.data[x][y];

			if (at != last)
			{
				if (range > 0 && last != null)
				{
				var startX = x - range;
				var c = this.template.legend[last];
				if (c != null && !c.equals(Color.transparent))
					EDITOR.draw.drawRect(
						layer.offset.x + startX * template.gridSize.x,
						layer.offset.y + y * template.gridSize.y,
						template.gridSize.x * range,
						template.gridSize.y,
						c);
				}
				range = 0;
				last = at;
			}
			range++;
			}
		}
	}

	override function createPalettePanel()
	{
		return new GridPalettePanel(this);
	}

	override public function afterUndoRedo()
	{
		EDITOR.toolBelt.current.activated();
	}
}
