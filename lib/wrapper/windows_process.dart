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
    return Hwnd.fromProcessID(id, wait: true);
  }
}
