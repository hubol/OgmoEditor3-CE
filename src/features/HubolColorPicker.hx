package features;

import util.IroJs.IroColorPickerColor;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.Browser;
import js.html.Element;
import util.IroJs.IroComponents;
import util.IroJs.IroColorPicker;

class HubolColorPicker {
  public static final singleton = new HubolColorPicker();

  private var _isInitialized = false;
  private var _el: Element;
  private var _picker: IroColorPicker;
  private var _isOpened = false;
  private var _targetEl: Element;
  private var _onChange: (color: IroColorPickerColor) -> Void;
  private var _onChangeCommit: (color: IroColorPickerColor) -> Void;
  private var _openedForTicksCount = 0;

  private function new() {
    
  }

  public function initialize() {
    if (this._isInitialized)
      return;

    final el = Browser.document.getElementById("hubol-color-picker");

    this._el = el;
    this._picker = new IroColorPicker(el, {
      width: 200,
      handleRadius: 6,
      layout: [
        {
          component: IroComponents.Box,
          options: {
            boxHeight: 100,
          }
        },
        {
          component: IroComponents.Slider,
          options: {
            id: 'hue-slider',
            sliderType: 'hue'
          }
        }
      ]
    });
    this._picker.on("input:change", (color) -> {
      if (this._onChange != null)
        this._onChange(color);
    });
    this._isInitialized = true;

    Browser.document.addEventListener('mousedown', this._onDocumentClick);
    Browser.document.addEventListener('keydown', this._onDocumentKeyDown);
    this._update();
  }

  public function open(targetEl: Element, initialColorHex: String, onChange: (color: IroColorPickerColor) -> Void, onChangeCommit: (color: IroColorPickerColor) -> Void) {
    this._picker.color.hexString = initialColorHex;
    this._targetEl = targetEl;
    this._isOpened = true;
    this._onChange = onChange;
    this._onChangeCommit = onChangeCommit;
    this._openedForTicksCount = 0;
    this._update();
  }

  public function loop() {
    this._update();
    if (this._isOpened)
      this._openedForTicksCount++;
  }

  private function _close() {
    if (!this._isOpened)
      return;

    this._isOpened = false;
    if (this._onChangeCommit != null) {
      this._onChangeCommit(this._picker.color);
      this._onChangeCommit = null;
    }
    this._onChange = null;
    this._update();
  }

  private function _onDocumentClick(ev: MouseEvent) {
    if (!this._isOpened || this._openedForTicksCount < 2)
      return;

    final rect = this._el.getBoundingClientRect();

    if (rect.left > ev.clientX || rect.top > ev.clientY || rect.right < ev.clientX || rect.bottom < ev.clientY) {
      this._close();
    }
  }

  private function _onDocumentKeyDown(ev: KeyboardEvent) {
    if (!this._isOpened)
      return;

    this._close();
  }

  private function _update() {
    this._el.style.display = this._isOpened ? "initial" : "none";

    if (this._targetEl == null)
      return;

    final pickerRect = this._el.getBoundingClientRect();
    final targetRect = this._targetEl.getBoundingClientRect();

    final x = Math.max(0, Math.min(Viewport.width - pickerRect.width, targetRect.x));
    final y = targetRect.y - 8 >= pickerRect.height ? (targetRect.y - 8 - pickerRect.height) : (targetRect.bottom + 8);

    this._el.style.left = '${x}px';
    this._el.style.top = '${y}px';
  }
}