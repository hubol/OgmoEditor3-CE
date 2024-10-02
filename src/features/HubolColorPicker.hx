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
  }
}