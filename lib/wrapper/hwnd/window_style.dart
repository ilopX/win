import 'package:win32/win32.dart';

class WindowStyle {
  WindowStyle([this._style = 0]);

  int _style;

  int get flags => _style;

  set visibleButtons(bool visible) {
    if (visible) {
      _style |= WS_SYSMENU;
    } else {
      _style &= ~WS_SYSMENU;
    }
  }

  bool get visibleButtons => (_style & WS_SYSMENU) == WS_SYSMENU;

  set enableResize(bool enable) {
    if (enable) {
      _style |= WS_THICKFRAME;
    } else {
      _style &= ~WS_THICKFRAME;
    }
  }

  bool get enableResize => (_style & WS_THICKFRAME) == WS_THICKFRAME;

  set enableMinimize(bool enable) {
    if (enable) {
      _style |= WS_MINIMIZEBOX;
    } else {
      _style &= ~WS_MINIMIZEBOX;
    }
  }

  bool get enableMinimize => (_style & WS_MINIMIZEBOX) == WS_MINIMIZEBOX;

  set enableMaximize(bool enable) {
    if (enable) {
      _style |= WS_MAXIMIZEBOX;
    } else {
      _style &= ~WS_MAXIMIZEBOX;
    }
  }

  bool get enableMaximize => (_style & WS_MAXIMIZEBOX) == WS_MAXIMIZEBOX;

  bool enableClose = true;

  set visibleTitle(bool enable) {
    if (enable) {
      _style |= WS_CAPTION;
    } else {
      _style &= ~WS_CAPTION;
    }
  }

  bool get visibleTitle => (_style & WS_CAPTION) == WS_CAPTION;

  set isPopup(bool enable) {
    if (enable) {
      _style |= WS_POPUPWINDOW;
    } else {
      _style &= ~WS_POPUPWINDOW;
    }
  }

  bool get isPopup => (_style & WS_POPUPWINDOW) == WS_POPUPWINDOW;

  set isChild(bool enable) {
    if (enable) {
      _style |= WS_CHILD;
    } else {
      _style &= ~WS_CHILD;
    }
  }

  bool get isChild => (_style & WS_CHILD) == WS_CHILD;
}
