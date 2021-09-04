import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:win/win32_add.dart';
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
    SetWindowLongPtr(handle, GWL_STYLE , style.style);
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
}

class EnumWindowsData extends Struct {
  @IntPtr()
  external int hwnd;

  @IntPtr()
  external int process_id;
}

class AsyncHwnd extends Hwnd {
  static AsyncHwnd fromMainWindow() {
    return AsyncHwnd(Hwnd.fromProcessID(GetCurrentProcessId())!.handle);
  }

  @override
  final int handle;

  AsyncHwnd(this.handle) {
    Isolate.spawn(_thread, _port.sendPort);
    _port.listen((message) {
      if (message is SendPort) {
        threadPort = message;
        threadPort!.send(handle);
      }

      switch(message) {
        case 'sizeReady':
          _sizeReady!.complete();
          break;
        case 'rectReady':
          _sizeReady!.complete();
          break;
        case 'styleReady':
          _styleReady!.complete();
          break;
        case 'ready':
          _ready.complete();
          break;
      }
    });
  }

  final _ready = Completer();

  Completer get ready => _ready;

  Completer? _sizeReady;

  Future<void> sizeAsync(Size size, {bool center = false}) async {
    _sizeReady = Completer();
    final sizeCondition = center ? _SizeCenter(size.width, size.height) : size;
    threadPort!.send(sizeCondition);
    await _sizeReady!.future;
    _sizeReady = null;
  }

  Completer? _rectReady;

  Future<void> rectAsync(Rect rect) async {
    _rectReady = Completer();
    threadPort!.send(rect);
    await _rectReady!.future;
    _rectReady = null;
  }

  Completer? _styleReady;

  Future<void> styleAsync(WindowStyle style) async {
    _styleReady = Completer();
    threadPort!.send(_Style(style.style));
    await _styleReady!.future;
    _styleReady = null;
  }

  final _port = ReceivePort();

  void dispose() {
    threadPort!.send('close');
    _port.close();
  }

  SendPort? threadPort;

  static void _thread(SendPort port) {
    final receive = ReceivePort();
    port.send(receive.sendPort);
    late Hwnd wnd;

    receive.listen((message) {
      if (message is Size) {
        final newSize = message;
        if (message is _SizeCenter) {
          final oldRect = wnd.rect;
          wnd.rect = Rect.fromXYWH(
            oldRect.left + (oldRect.width - newSize.width) ~/ 2,
            oldRect.top + (oldRect.height - newSize.height) ~/ 2,
            newSize.width,
            newSize.height,
          );
        } else {
          wnd.size = message;
        }
        port.send('sizeReady');
      } else if (message is Rect) {
        wnd.rect = message;
        port.send('rectReady');
      } else if (message is _Style) {
        wnd.style = WindowStyle(message.style);
        port.send('styleReady');
      } else if (message is int) {
        wnd = Hwnd.fomHandle(message);
        port.send('ready');
      } else if (message == 'close') {
        receive.close();
      }
    });
  }
}

class _SizeCenter extends Size {
  _SizeCenter(int width, int height) : super(width, height);
}

class _Style {
  final int style;

  _Style(this.style);
}

class WindowStyle {
  WindowStyle([this._style = 0]);

  static WindowStyle get none {
    return WindowStyle(0);
  }

  static WindowStyle get dialog {
    return mainWindow
      ..enableMaximize = false
      ..enableMinimize;
  }

  static WindowStyle get mainWindow {
    return WindowStyle(WS_OVERLAPPEDWINDOW);
  }

  int _style;

  int get style => _style;

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
}
