import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:win/tools/primitives.dart';

class Screen {
  static Rect get rect {
    final pRect = calloc<RECT>();
    try {
      if (SystemParametersInfo(SPI_GETWORKAREA, 0, pRect, 0) == 0) {
        throw 'SystemParametersInfo error.';
      }
      return Rect.fromPRect(pRect);
    } finally {
      free(pRect);
    }
  }
}
