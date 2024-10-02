package features;

import js.html.MouseEvent;
import js.Browser;
import js.html.Element;
import util.IroJs.IroComponents;
import util.IroJs.IroColorPicker;

class HubolColorPicker {
  private static var _isInitialized = false;
  private static var _el: Element;
  private static var _picker: IroColorPicker;
  private static var _isOpened = true;
  private static var _targetEl: Element;

  public static function initialize() {
    if (HubolColorPicker._isInitialized)
      return;

    final el = Browser.document.getElementById("hubol-color-picker");

    HubolColorPicker._el = el;
    HubolColorPicker._picker = new IroColorPicker(el, {
      width: 200,
      color: "rgb(255, 0, 0)",
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
    HubolColorPicker._isInitialized = true;

    Browser.document.addEventListener('mousedown', HubolColorPicker._onDocumentClick);
    HubolColorPicker._update();

    open(Browser.document.querySelector(".start_logo"), "#00ff00");
  }

  public static function open(targetEl: Element, initialColorHex: String) {
    HubolColorPicker._picker.color.hexString = initialColorHex;
    HubolColorPicker._targetEl = targetEl;
    HubolColorPicker._isOpened = true;
    HubolColorPicker._update();
  }

  public static function loop() {
    HubolColorPicker._update();
  }

  private static function _onDocumentClick(ev: MouseEvent) {
    if (!HubolColorPicker._isOpened)
      return;

    final rect = HubolColorPicker._el.getBoundingClientRect();

    if (rect.left > ev.clientX || rect.top > ev.clientY || rect.right < ev.clientX || rect.bottom < ev.clientY) {
      HubolColorPicker._isOpened = false;
      HubolColorPicker._update();
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