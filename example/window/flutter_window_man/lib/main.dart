import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_man/view.dart';
import 'package:win/tools/hwnd.dart';
import 'package:win/tools/primitives.dart';

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
        hwnd.hide();
        Future.delayed(Duration(seconds: 1), hwnd.show);
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
        late final WindowStyle style;
        switch(styleName) {
          case 'None':
            style = noneWindowStyle;
            break;
          case 'Dialog':
            style = dialogWindowStyle;
            break;
          case 'MainWindow':
            style = mainWindowStyle;
            break;
        }

        // updateSize
        var currSize = hwnd.size;
        hwnd.style = style;
        await hwnd.sizeAsync(Size(currSize.width - 1, currSize.height - 1));
        await hwnd.sizeAsync(Size(currSize.width, currSize.height));
      },
      onTitleButton: (List<String> buttons) {
        hwnd.style = mainWindowStyle
          ..enableMaximize = buttons.contains('maximize')
          ..enableMinimize = buttons.contains('minimize')
          ..enableClose = buttons.contains('close');
      },
    );
  }
}
