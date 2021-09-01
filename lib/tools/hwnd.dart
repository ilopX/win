import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'primitives.dart';

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

  void destroy() => DestroyWindow(handle);

  void hide() => ShowWindowAsync(handle, SW_HIDE);

  void show() => ShowWindowAsync(handle, SW_SHOW);

  void minimize() => ShowWindowAsync(handle, SW_SHOWMINIMIZED);

  void focused() => SetFocus(handle);

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
      NULL,
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

  Size get size => clientRect.size;

  set size(Size newSize) {
    final thisRect = rect;
    rect = Rect.fromXYWH(
      thisRect.left,
      thisRect.top,
      newSize.width,
      newSize.height,
    );
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
    _childContent?.show();
  }
}
