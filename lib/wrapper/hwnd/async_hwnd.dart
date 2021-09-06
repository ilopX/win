import 'dart:async';
import 'dart:isolate';
import 'package:win/window.dart';
import 'package:win32/win32.dart';

class AsyncHwnd extends Hwnd {
  static AsyncHwnd fromMainWindow() {
    return AsyncHwnd(Hwnd.fromProcessID(GetCurrentProcessId())!.handle);
  }

  @override
  final int handle;

  AsyncHwnd(this.handle) {
    Isolate.spawn(_thread, _port.sendPort);
    _port.listen(_thisReceive);
  }

  void _thisReceive(message) {
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
      case 'ready':
        _ready.complete();
        break;
    }
  }

  static void _thread(SendPort port) {
    final receive = ReceivePort();
    port.send(receive.sendPort);
    late Hwnd wnd;

    receive.listen((message) {
      switch (message.runtimeType) {
        case Size:
          wnd.size = message;
          port.send('sizeReady');
          return;

        case _SizeAndCenter:
          wnd.rect = wnd.rect.centerTo(message.newSize);
          port.send('sizeReady');
          return;

        case _ForceUpdateSize:
          final oldSize = message.oldSize;
          wnd.size = Size(oldSize.width + 1, oldSize.height + 1);
          wnd.size = oldSize;
          port.send('sizeReady');
          return;

        case Rect:
          wnd.rect = message;
          port.send('rectReady');
          return;

        case int:
          wnd = Hwnd.fomHandle(message);
          port.send('ready');
          return;
      }

      if (message == 'close') {
        receive.close();
      }
    });
  }

  final _ready = Completer();

  Completer get ready => _ready;

  Completer? _sizeReady;

  Future<void> sizeAsync(Size size, {bool center = false}) async {
    _sizeReady = Completer();
    final sizeCondition = center ? _SizeAndCenter(size) : size;
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

  Future<void> forceSizeUpdate(void Function()? onUpdateMethod) async {
    await _sizeReady?.future;
    _sizeReady = Completer();
    var currSize = size;
    onUpdateMethod?.call();
    threadPort!.send(_ForceUpdateSize(currSize));
    await _sizeReady!.future;
    _sizeReady = null;
  }

  final _port = ReceivePort();

  void dispose() {
    threadPort!.send('close');
    _port.close();
  }

  SendPort? threadPort;
}

class _SizeAndCenter  {
  final Size newSize;
  _SizeAndCenter(this.newSize);
}

class _ForceUpdateSize {
  final Size oldSize;
  _ForceUpdateSize(this.oldSize);
}
