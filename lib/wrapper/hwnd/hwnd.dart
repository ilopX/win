import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:win/window.dart';

class _Hwnd extends Hwnd {
  @override
  final int handle;

  _Hwnd(this.handle);
}

abstract class Hwnd {
  int get handle;

  Hwnd();

  factory Hwnd.fomHandle(int handle) {
    return _Hwnd(handle);
  }

  static Hwnd? fromProcessID(int processId, {bool wait = false}) {
    final data = calloc<EnumWindowsData>()
      ..ref.hwnd = 0
      ..ref.process_id = processId;

    final callback = Pointer.fromFunction<EnumWindowsProc>(
      _enumWindowsCallback,
      0,
    );

    try {
       do {
        EnumWindows(callback, data.address);
      } while (wait && data.ref.hwnd == 0);
    } finally {
      free(data);
    }
    return data.ref.hwnd == 0 ? null : Hwnd.fomHandle(data.ref.hwnd);
  }

  static int _enumWindowsCallback(int hwnd, int lParam) {
    final data = Pointer<EnumWindowsData>.fromAddress(lParam);

    final process_id = calloc<Uint32>();
    try {
      GetWindowThreadProcessId(hwnd, process_id);

      if (process_id.value != data.ref.process_id) {
        return TRUE;
      }
    } finally {
      free(process_id);
    }

    final own = GetWindow(hwnd, GW_OWNER);
    if (own != 0) {
      return TRUE;
    }

    data.ref.hwnd = hwnd;
    return FALSE; // stop enums
  }

  void destroy() => DestroyWindow(handle);

  void hide() => ShowWindowAsync(handle, SW_HIDE);

  void show() => ShowWindowAsync(handle, SW_SHOW);

  void minimize() => ShowWindowAsync(handle, SW_SHOWMINIMIZED);

  void maximize() => ShowWindowAsync(handle, SW_SHOWMAXIMIZED);

  void restore() => ShowWindowAsync(handle, SW_RESTORE);

  void focused() => SetFocus(handle);

  bool get isMaximized {
    final place = calloc<WINDOWPLACEMENT>()
      ..ref.length = sizeOf<WINDOWPLACEMENT>();
    try {
      GetWindowPlacement(handle, place);
      return place.ref.showCmd == SW_SHOWMAXIMIZED;
    } finally  {
      free(place);
    }
  }

  String get text {
    final pText = calloc.allocate<Utf16>(MAX_PATH * 2);
    try {
      GetWindowText(handle, pText, MAX_PATH);
      return pText.toDartString();
    } finally {
      free(pText);
    }
  }

  set text(String newText) {
    final pTitle = newText.toNativeUtf16();
    try {
      SetWindowText(handle, pTitle);
    } finally {
      free(pTitle);
    }
  }

  Rect get rect {
    final pRect = calloc<RECT>();
    try {
      GetWindowRect(handle, pRect);
      return Rect.fromPRect(pRect);
    } finally {
      free(pRect);
    }
  }

  set rect(Rect newRect) {
    SetWindowPos(
      handle,
      HWND_TOP,
      newRect.left,
      newRect.top,
      newRect.width,
      newRect.height,
      SWP_NOZORDER | SWP_NOACTIVATE,
    );
  }

  Rect get clientRect {
    final pRect = calloc<RECT>();
    try {
      GetClientRect(handle, pRect);
      return Rect.fromPRect(pRect);
    } finally {
      free(pRect);
    }
  }

  set pos(Point pos) {
    final thisRect = rect;
    rect = Rect.fromXYWH(pos.x, pos.y, thisRect.width, thisRect.height);
  }

  Size get size => rect.size;

  set size(Size newSize) {
    final thisRect = rect;
    rect = Rect.fromXYWH(
      thisRect.left,
      thisRect.top,
      newSize.width,
      newSize.height,
    );
  }

  void center() {
    final thisRect = rect;
    rect = centredOfScreenRect(
      thisRect.width,
      thisRect.height,
    );
  }

  set style(WindowStyle style) {
    SetWindowLongPtr(handle, GWL_STYLE , style.flags);

    final closeButtonStyle =  style.enableClose
        ? MF_ENABLED
        : ( MF_DISABLED | MF_GRAYED);

    EnableMenuItem(
      GetSystemMenu(handle, FALSE),
      SC_CLOSE,
      MF_BYCOMMAND | closeButtonStyle,
    );
  }

  WindowStyle get style {
    return WindowStyle(GetWindowLongPtr(handle, GWL_STYLE));
  }

  set parent(Hwnd newParent) => SetParent(handle, newParent.handle);

  Hwnd? _childContent;

  Hwnd? get childContent {
    if (_childContent == null) {
      return null;
    }

    if (IsWindow(_childContent!.handle) == 0) {
      _childContent = null;
    }

    return _childContent;
  }

  set childContent(Hwnd? child) {
    if (child == null) {
      return;
    }

    final thisSize = size;
    child.parent = this;
    child.rect = Rect(0, 0, thisSize.width, thisSize.height);
    _childContent = child;
    _childContent!.show();
  }

  var _moveDownPoint = Point(0, 0);

  void beginDrag() {
    final p = calloc<POINT>();
    try {
      if (GetCursorPos(p) == 0) {
        throw 'GetCursorPos fail.';
      }
      ScreenToClient(handle, p);
    } finally {
      free(p);
    }

    var frameSize = 0;
    var caption = 0;

    final thisStyle = style;
    if (thisStyle.visibleTitle) {
      caption = GetSystemMetrics(SM_CYCAPTION) + 1;
    }

    if (thisStyle.enableResize) {
      frameSize = GetSystemMetrics(SM_CYSIZEFRAME) +
          GetSystemMetrics(SM_CYEDGE) * 2 - 1;
    }

    _moveDownPoint = Point(
      p.ref.x + frameSize,
      p.ref.y + frameSize + caption,
    );
  }

  void drag() {
    final p = calloc<POINT>();
    try {
      if (GetCursorPos(p) != 0) {
        var x =  p.ref.x - _moveDownPoint.x;
        var y = p.ref.y - _moveDownPoint.y;

        pos = Point(x, y);
      }
    } finally {
      free(p);
    }
  }
}

class EnumWindowsData extends Struct {
  @IntPtr()
  external int hwnd;

  @IntPtr()
  external int process_id;
}
