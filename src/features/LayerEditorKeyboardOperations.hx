package features;

import js.Browser;
import features.Toast;

typedef LayerItemCommon = {
    function flipX(): Void;
    function flipY(): Void;
    function rotate(delta:Float): Void;
}

typedef LayerEditorKeyboardOperationsContext<TLayerItem:LayerItemCommon> = {
    itemTypeName:String,
    getCanRotate:() -> Bool,
    getClipboard:() -> Array<TLayerItem>,
    getSelection:() -> Array<TLayerItem>,
    setSelection:(items:Array<TLayerItem>) -> Void,
    clone:(item:TLayerItem, gridCellOffsetX:Int, gridCellOffsetY:Int) -> TLayerItem,

    tryAddToLayer:(item:TLayerItem) -> Null<String>,
    deleteSelection:() -> Void,

    onChange:() -> Void,
    onChangeAffectingLayerItemIndices:() -> Void,
}

class LayerEditorKeyboardOperations<TLayerItem:LayerItemCommon> {
    final _ctx:LayerEditorKeyboardOperationsContext<TLayerItem>;

    public function new(ctx:LayerEditorKeyboardOperationsContext<TLayerItem>) {
        this._ctx = ctx;
    }

    public function onKeyPress(key:Int) {
        final ctrl = OGMO.ctrl;
        final shift = OGMO.shift;

        if (ctrl) {
            if (key == Keys.C) {
                this._setClipboardToSelection();
            }
            else if (key == Keys.X) {
                this._cutSelectionToClipboard();
            }
            else if (key == Keys.V) {
                this._pasteFromClipboard();
            }
            else if (key == Keys.D) {
                // Note: Entities had a behavior where shift - ctrl - D
                // would duplicate and add to the existing selection
                //
                // if (OGMO.shift) selection.add(copies);
				// else selection.set(copies);
                
                this._duplicateSelection();
            }
        }
        else {
            if (key == Keys.Backspace || key == Keys.Delete) {
                this._deleteSelection();
            }
            else if (key == Keys.R) {
                final clockwise = !shift;
                this._rotateSelection(clockwise);
            }
            else if (key == Keys.H) {
                this.flipSelectionX();
            }
            else if (key == Keys.V) {
                this.flipSelectionY();
            }
        }
    }

    function _setClipboardToSelection() {
        final selection = this._ctx.getSelection();
        final clipboard = this._ctx.getClipboard();
        clipboard.splice(0, clipboard.length);
        for (item in selection) {
            clipboard.push(this._ctx.clone(item, 0, 0));
        }
    }

    function _cutSelectionToClipboard() {
        final selection = this._ctx.getSelection();
        if (selection.length == 0) {
            return;
        }

        EDITOR.level.store('cut ${this._ctx.itemTypeName}(s)');
        this._setClipboardToSelection();
        this._ctx.deleteSelection();
        this._ctx.onChangeAffectingLayerItemIndices();
    }

    function _pasteFromClipboard() {
        final clipboard = this._ctx.getClipboard();
        if (clipboard.length == 0) {
            return;
        }

        EDITOR.level.store('pasted ${this._ctx.itemTypeName}(s)');
        final items = [for (item in clipboard) this._ctx.clone(item, 0, 0)];
        final result = this._tryAddManyItems(items);

        if (result.errors.length > 0) {
            Toast.show(Warning, '${result.errors.length} ${this._ctx.itemTypeName}(s) could not be pasted. See console for details.', 3000);
            Browser.console.warn('${this._ctx.itemTypeName} paste error(s)', result.errors);
        }

        if (result.addedItems.length > 0) {
            this._ctx.setSelection(result.addedItems);
        }
    }

    function _duplicateSelection() {
        final selection = this._ctx.getSelection();
        if (selection.length == 0) {
            return;
        }

        EDITOR.level.store('duplicate ${this._ctx.itemTypeName}(s)');
        final items = [for (item in selection) this._ctx.clone(item, 2, 2)];
        final result = this._tryAddManyItems(items);

        if (result.errors.length > 0) {
            // Note: Should probably not get here ever...
            Toast.show(Warning, '${result.errors.length} ${this._ctx.itemTypeName}(s) could not be duplicated. See console for details.', 3000);
            Browser.console.warn('${this._ctx.itemTypeName} duplicate error(s)', result.errors);
        }

        if (result.addedItems.length > 0) {
            this._ctx.setSelection(result.addedItems);
        }
    }

    function _tryAddManyItems(items:Array<TLayerItem>) {
        final addedItems = new Array<TLayerItem>();
        final errors = new Array<String>();
        for (item in items) {
            final error = this._ctx.tryAddToLayer(item);
            if (error != null) {
                errors.push(error);
            }
            else {
                addedItems.push(item);
            }
        }

        this._ctx.onChangeAffectingLayerItemIndices();

        return {
            addedItems: addedItems,
            errors: errors,
        };
    }

    function _deleteSelection() {
        EDITOR.level.store('delete ${this._ctx.itemTypeName}(s)');
        this._ctx.deleteSelection();
        this._ctx.onChangeAffectingLayerItemIndices();
    }

    function _rotateSelection(clockwise:Bool) {
        if (!this._ctx.getCanRotate()) {
            return;
        }

        final delta = Math.PI / (clockwise ? 4 : -4);
        EDITOR.level.store('rotate selected ${this._ctx.itemTypeName}(s) by 45 degrees ${ clockwise ? "clockwise" : "counter-clockwise" }');
        for (item in this._ctx.getSelection()) {
            item.rotate(delta);
        }
        this._ctx.onChange();
    }

    public function flipSelectionX() {
        EDITOR.level.store('horizontally flip selected ${this._ctx.itemTypeName}(s)');
        for (item in this._ctx.getSelection()) {
            item.flipX();
        }
        this._ctx.onChange();
    }

    public function flipSelectionY() {
        EDITOR.level.store('vertically flip selected ${this._ctx.itemTypeName}(s)');
        for (item in this._ctx.getSelection()) {
            item.flipY();
        }
        this._ctx.onChange();
    }
}