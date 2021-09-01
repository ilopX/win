
import '../tools/primitives.dart';

import 'package:win/flutter_engine.dart';

class FlutterEngine {
  final FlutterApi _flutterApi;

  late final EngineRef _engineRef;

  late final FlutterController controller;
  late final FlutterView view;

  FlutterEngine(Size size, Bundle bundle, this._flutterApi) {
    _engineRef = _flutterApi.createEngine(bundle);
    final controllerRef = _flutterApi.createController(size, _engineRef);
    final viewRef = _flutterApi.controllerGetView(controllerRef);

    controller = FlutterController(size, controllerRef, _flutterApi);
    view = FlutterView(viewRef, _flutterApi);
  }

  void reloadSystemFonts() {
    _flutterApi.engineReloadSystemFonts(_engineRef);
  }
}
