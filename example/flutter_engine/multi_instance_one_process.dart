import 'package:win/flutter_engine.dart';
import 'package:win/tools/screen.dart';
import 'package:win/window.dart';

void main(List<String> args) {
  final bundlePath = FlutterFinder.searchBundleFolder('../../empty_flutter_app');
  final flutterDllPath = FlutterFinder.searchDllFile();

  final bundle = Bundle.fromSourceDir(bundlePath);
  final flutterApi = FlutterApi.load(flutterDllPath);

  final gridLen = fromArgs(args);

  for (var rect in generateScreenGrid(gridLen)) {
    FlutterWindow(bundle, flutterApi)
      ..text = 'Flutter dart runner'
      ..rect = rect
      ..show();
  }
  NativeApp.run();
}

int fromArgs(List<String> args) {
  try {
    return int.parse(args[0]);
  } catch (e) {
    return 2;
  }
}

Iterable<Rect> generateScreenGrid(int gridLen) sync* {
  final screen = Screen.rect;
  final cellWidth = screen.width ~/ gridLen;
  final cellHeight = screen.height ~/ gridLen;

  for (var x = 0; x < gridLen; x++) {
    for (var y = 0; y < gridLen; y++) {
      yield Rect.fromXYWH(
        screen.left + x * cellWidth,
        screen.top + y * cellHeight,
        cellWidth,
        cellHeight,
      );
    }
  }
}
