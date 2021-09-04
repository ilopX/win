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

  late AsyncHwnd hwnd;

  @override
  void initState() {
    hwnd = AsyncHwnd.fromMainWindow();
    hwnd.ready.future.then((value) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    hwnd.dispose();
    super.dispose();
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
      onDrag: (e) {
        print('onDrag');
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
      onWindowStyle: (String styleName, List<String> buttons) {
        late WindowStyle style;
        switch(styleName) {
          case 'None':
            style = WindowStyle.none;
            break;
          case 'Dialog':
            style = WindowStyle.dialog;
            break;
          case 'MainWindow':
            style = WindowStyle.mainWindow;
            style.enableMinimize = buttons.contains('minimize');
            style.enableMaximize = buttons.contains('maximize');
            style.enableClose = buttons.contains('close');
            break;
        }
        hwnd.styleAsync(style);

      },
    );
  }
}
