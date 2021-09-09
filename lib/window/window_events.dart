import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:win32/win32.dart';

import 'package:win/window.dart';

enum WindowState { destroy, hide, minimize, stayOpen }

abstract class WindowEvents extends Hwnd {
  @override
  late final int handle;

  WindowEvents() {
    WindowsRegistry.beginRegistration(this);
  }

  @protected
  void onCreate(int hWnd, CREATESTRUCT createInfo) {
    handle = hWnd;
  }

  @protected
  void onDestroy() {
    WindowsRegistry.unregister(this);
  }

  @protected
  void onPaint(int hdc, Pointer<RECT> pRect) {}

  @protected
  void onResize(int width, int height) {
    childContent?.rect = Rect(0, 0, width, height);
  }

  @protected
  void onRestore() {

  }

  void onMinimize() {
    if (WindowsRegistry.isMainWindow(handle)) {
      WindowsRegistry.windows.values.skip(1).forEach((window) {
        window.minimize();
      });
    }
  }

  @protected
  void onFontChange() {}

  @protected
  void onDpiChange(Rect newWindowRect) {
    rect = newWindowRect;
  }

  @protected
  void onShow() {}

  @protected
  WindowState onClose() => WindowState.destroy;

  void _closeEvent() {
    final closeAnswer = onClose();
    switch (closeAnswer) {
      case WindowState.destroy:
        destroy();
        break;
      case WindowState.hide:
        hide();
        break;
      case WindowState.minimize:
        minimize();
        break;
      case WindowState.stayOpen:
        break;
    }
  }

  void _onPaint() {
    if (childContent != null) {
      return;
    }

    final ps = calloc<PAINTSTRUCT>();
    final pRect = clientRect.toPRect();
    try {
      final hdc = BeginPaint(handle, ps);
      onPaint(hdc, pRect);
      EndPaint(handle, ps);
    } finally {
      free(ps);
      free(pRect);
    }
  }

  @protected
  int wndProc(int hWnd, int uMsg, int wParam, int lParam) {
    switch (uMsg) {
      case WM_SYSCOMMAND:
        switch(wParam) {
          case SC_RESTORE:
            onRestore();
            break;
          case SC_MINIMIZE:
            onMinimize();
            break;
        }
        return 0;
      case WM_DESTROY:
        onDestroy();
        break;

      case WM_CLOSE:
        _closeEvent();
        return 0;

      case WM_PAINT:
        _onPaint();
        return 0;

      case WM_SIZE:
        onResize(LOWORD(lParam), HIWORD(lParam));
        return 0;

      case WM_FONTCHANGE:
        onFontChange();
        return 0;

      case WM_DPICHANGED:
        onDpiChange(Rect.fromAddress(lParam));
        return 0;

      case WM_SHOWWINDOW:
        onShow();
        return 0;
    }
    return 0;
  }
}
