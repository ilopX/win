import 'dart:async';

import 'package:win32/win32.dart';
import 'package:win/window.dart';
import 'package:win/wrapper/windows_process.dart';

Future main() async {
  final notepadProcess = await WindowsProcess.run(cmd: r'notepad', show: false);
  final notepadWindow = notepadProcess.topWindow;

  notepadWindow!.style = WindowStyle()
    ..isChild = true
    ..isPopup = true;

  NativeWindow()
    ..childContent = notepadWindow
    ..text = 'Dart native window example'
    ..size = Size(640, 480)
    ..center()
    ..show();

  NativeApp.run();
}
