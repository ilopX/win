import 'package:meta/meta.dart';
import '../tools/hwnd.dart';
import 'package:win/window/native_window.dart';

import 'bundle.dart';
import 'flutter_api.dart';
import 'flutter_engine.dart';


class FlutterWindow extends NativeWindow {
  FlutterEngine? engine;
  late Function() _createEngineLazy;

  FlutterWindow(Bundle bundle, FlutterApi flutterApi) : super() {
    _createEngineLazy = () {
      engine = FlutterEngine(size, bundle, flutterApi);
      childContent = Hwnd.fomHandle(engine!.view.nativeWindow);
    };
  }

  @override
  @protected
  void onShow() {
    if (engine == null) {
      _createEngineLazy();
    }
    super.onShow();
  }

  @override
  @protected
  void onDestroy() {
    engine?.controller.destroy();
    super.onDestroy();
  }

  @override
  @protected
  void onFontChange() {
    engine?.reloadSystemFonts();
    super.onFontChange();
  }

  @override
  @protected
  int wndProc(int hWnd, int uMsg, int wParam, int lParam) {
    final flutterResult =
        engine?.controller.wndProc(hWnd, uMsg, wParam, lParam);

    if (flutterResult != null && flutterResult != 0) {
      return flutterResult;
    }

    return super.wndProc(hWnd, uMsg, wParam, lParam);
  }
}
