import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'package:win/window.dart';

class WindowsProcess {
  int get handle => _processInfoRef.hProcess;

  int get id => _processInfoRef.dwProcessId;

  final PROCESS_INFORMATION _processInfoRef;

  WindowsProcess._(this._processInfoRef);

  static Future<WindowsProcess> run({
    String? cmd,
    String? appName,
    bool show = true,
  }) async {
    final pNotepad = cmd == null ? nullptr : cmd.toNativeUtf16();
    final pAppName = appName == null ? nullptr : appName.toNativeUtf16();

    final pStartup = calloc<STARTUPINFO>()
      ..ref.cb = sizeOf<STARTUPINFO>()
      ..ref.dwFlags = show ? 0 : STARTF_USESHOWWINDOW
      ..ref.wShowWindow = show ? SW_SHOW : SW_HIDE;
    final pProcessInfo = calloc<PROCESS_INFORMATION>();

    try {
      final isCreate = CreateProcess(
        nullptr,
        pNotepad,
        nullptr,
        nullptr,
        FALSE,
        show ? 0 : CREATE_NO_WINDOW,
        nullptr,
        nullptr,
        pStartup,
        pProcessInfo,
      );

      if (isCreate == 0) {
        throw 'CreateProcess fail.';
      }

      return WindowsProcess._(pProcessInfo.ref);
    } finally {
      free(pNotepad);
      free(pAppName);
      free(pStartup);
      free(pProcessInfo);
    }
  }

  /// get top window of the current process
  Hwnd? get topWindow {
    final data = calloc<EnumWindowsData>()
      ..ref.hwnd = 0
      ..ref.process_id = id;

    final callback = Pointer.fromFunction<EnumWindowsProc>(
      _enumWindowsCallback,
      0,
    );

    try {
      while (data.ref.hwnd == 0) {
        EnumWindows(callback, data.address);
      }
    } finally {
      free(data);
    }

    return Hwnd.fomHandle(data.ref.hwnd);
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
}

class EnumWindowsData extends Struct {
  @IntPtr()
  external int hwnd;

  @IntPtr()
  external int process_id;
}
