import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_man/view.dart';

import 'package:win/window.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Settings(),
      ),
    );
  }
}

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var _checkCenter = true;

  @override
  Widget build(BuildContext context) {
    if (hwnd.ready.isCompleted) {
      return buildView();
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  Widget buildView() {
    return SettingsView(
      initWindowTitle: hwnd.text,
      initResizeToCenter: _checkCenter,
      initWidowsStyleName: 'MainWindow',
      onMinimize: () {
        hwnd.minimize();
      },
      onMaximize: () {
        if (hwnd.isMaximized) {
          hwnd.restore();
        } else {
          hwnd.maximize();
        }
      },
      onClose: () {
        exit(0);
      },
      onMouseEvent: (e) {
        if (e is PointerDownEvent) {
          hwnd.beginDrag();
        } else if (e is PointerMoveEvent) {
          hwnd.drag();
        }
      },
      onTitleChange: (text) {
        hwnd.text = text;
      },
      onSizeInc: () async {
        final currSize = hwnd.size;
        await hwnd.sizeAsync(
          Size(currSize.width + 10, currSize.height + 10),
          center: _checkCenter,
        );
      },
      onSizeDec: () {
        final currSize = hwnd.size;
        hwnd.sizeAsync(
          Size(currSize.width - 10, currSize.height - 10),
          center: _checkCenter,
        );
      },
      onCheckCenter: (val) {
        _checkCenter = val;
      },
      onToCenter: () {
        hwnd.center();
      },
      onWindowStyle: (String styleName) async {
        late final WindowStyle newStyle;
        switch(styleName) {
          case 'None':
            newStyle = noneWindowStyle;
            break;
          case 'Dialog':
            newStyle = dialogWindowStyle;
            break;
          case 'MainWindow':
            newStyle = mainWindowStyle;
            break;
          default:
            return;
        }

        hwnd.forceSizeUpdate(() {
          hwnd.style = newStyle;
        });
      },
      onTitleButton: (List<String> buttons) {
        hwnd.style = mainWindowStyle
          ..enableMaximize = buttons.contains('maximize')
          ..enableMinimize = buttons.contains('minimize')
          ..enableClose = buttons.contains('close');
      },
    );
  }

  static late final WindowStyle noneWindowStyle;
  static late final WindowStyle dialogWindowStyle;
  static late final WindowStyle mainWindowStyle;

  static final hwnd = AsyncHwnd.fromMainWindow();

  @override
  void initState() {
    hwnd.ready.future.then((_) {
      noneWindowStyle = hwnd.style
        ..enableResize = false
        ..visibleTitle = false;

      dialogWindowStyle = hwnd.style
        ..enableResize = false
        ..enableMinimize = false
        ..enableMaximize = false;

      mainWindowStyle = hwnd.style;
      setState(() {});
    });
    super.initState();
  }
}
