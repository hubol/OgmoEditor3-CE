package features;

import util.IroJs.IroColorPickerColor;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.Browser;
import js.html.Element;
import util.IroJs.IroComponents;
import util.IroJs.IroColorPicker;

class HubolColorPicker {
  private static var _isInitialized = false;
  private static var _el: Element;
  private static var _picker: IroColorPicker;
  private static var _isOpened = false;
  private static var _targetEl: Element;
  private static var _onChange: (color: IroColorPickerColor) -> Void;
  private static var _onChangeCommit: (color: IroColorPickerColor) -> Void;
  private static var _openedForTicksCount = 0;

  public static function initialize() {
    if (HubolColorPicker._isInitialized)
      return;

    final el = Browser.document.getElementById("hubol-color-picker");

    HubolColorPicker._el = el;
    HubolColorPicker._picker = new IroColorPicker(el, {
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
    HubolColorPicker._picker.on("input:change", (color) -> {
      if (HubolColorPicker._onChange != null)
        HubolColorPicker._onChange(color);
    });
    HubolColorPicker._isInitialized = true;

    Browser.document.addEventListener('mousedown', HubolColorPicker._onDocumentClick);
    Browser.document.addEventListener('keydown', HubolColorPicker._onDocumentKeyDown);
    HubolColorPicker._update();
  }

  public static function open(targetEl: Element, initialColorHex: String, onChange: (color: IroColorPickerColor) -> Void, onChangeCommit: (color: IroColorPickerColor) -> Void) {
    HubolColorPicker._picker.color.hexString = initialColorHex;
    HubolColorPicker._targetEl = targetEl;
    HubolColorPicker._isOpened = true;
    HubolColorPicker._onChange = onChange;
    HubolColorPicker._onChangeCommit = onChangeCommit;
    HubolColorPicker._openedForTicksCount = 0;
    HubolColorPicker._update();
  }

  public static function loop() {
    HubolColorPicker._update();
    if (HubolColorPicker._isOpened)
      HubolColorPicker._openedForTicksCount++;
  }

  private static function _close() {
    if (!HubolColorPicker._isOpened)
      return;

    HubolColorPicker._isOpened = false;
    if (HubolColorPicker._onChangeCommit != null) {
      HubolColorPicker._onChangeCommit(HubolColorPicker._picker.color);
      HubolColorPicker._onChangeCommit = null;
    }
    HubolColorPicker._onChange = null;
    HubolColorPicker._update();
  }

  private static function _onDocumentClick(ev: MouseEvent) {
    if (!HubolColorPicker._isOpened || HubolColorPicker._openedForTicksCount < 2)
      return;

    final rect = HubolColorPicker._el.getBoundingClientRect();

    if (rect.left > ev.clientX || rect.top > ev.clientY || rect.right < ev.clientX || rect.bottom < ev.clientY) {
      HubolColorPicker._close();
    }
  }

  private static function _onDocumentKeyDown(ev: KeyboardEvent) {
    if (!HubolColorPicker._isOpened)
      return;

    if (ev.keyCode == Keys.Enter || ev.keyCode == Keys.Tab || ev.keyCode == Keys.Escape) {
      HubolColorPicker._close();
    }
  }

  private static function _update() {
    HubolColorPicker._el.style.display = HubolColorPicker._isOpened ? "initial" : "none";

    if (HubolColorPicker._targetEl == null)
      return;

    final pickerRect = HubolColorPicker._el.getBoundingClientRect();
    final targetRect = HubolColorPicker._targetEl.getBoundingClientRect();

    final x = Math.max(0, Math.min(Viewport.width - pickerRect.width, targetRect.x));
    final y = targetRect.y - 8 >= pickerRect.height ? (targetRect.y - 8 - pickerRect.height) : (targetRect.bottom + 8);

    HubolColorPicker._el.style.left = '${x}px';
    HubolColorPicker._el.style.top = '${y}px';
  }
}