import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    Key? key,
    required this.initWindowTitle,
    required this.initResizeToCenter,
    required this.initWidowsStyleName,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    required this.onMouseEvent,
    required this.onTitleChange,
    required this.onSizeInc,
    required this.onSizeDec,
    required this.onCheckCenter,
    required this.onToCenter,
    required this.onWindowStyle,
    required this.onTitleButton,

  }) : super(key: key);

  final String initWindowTitle;

  final bool initResizeToCenter;

  final String initWidowsStyleName;

  final Function() onMinimize;

  final Function() onMaximize;

  final Function() onClose;

  final Function(PointerEvent) onMouseEvent;

  final Function(String) onTitleChange;

  final Function() onSizeInc;

  final Function() onSizeDec;

  final Function(bool) onCheckCenter;

  final Function() onToCenter;

  final Function(String) onWindowStyle;

  final Function(List<String>) onTitleButton;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildCommandButtons(),
        _____,
        buildDragMe(),
        _____,
        buildEditTitle(),
        _____,
        buildResize(),
        _____,
        buildToCenter(),
        _____,
        buildWindowStyle(),
      ],
    );
  }

  var windowStyleName = '';
  var resizeCenter = true;

  @override
  void initState() {
    resizeCenter = widget.initResizeToCenter;
    windowStyleName = widget.initWidowsStyleName;
    super.initState();
  }

  get _____ => SizedBox(height: 20);

  Widget buildCommandButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Icon(Icons.minimize),
          onPressed: widget.onMinimize,
        ),
        SizedBox(width: 5),
        ElevatedButton(
          child: Icon(Icons.web_asset),
          onPressed: widget.onMaximize,
        ),
        SizedBox(width: 5),
        ElevatedButton(
          child: Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget buildDragMe() {
    return Listener(
      onPointerDown: widget.onMouseEvent,
      onPointerUp: widget.onMouseEvent,
      onPointerMove: widget.onMouseEvent,
      child: Container(
        alignment: Alignment.center,
        width: 300,
        height: 100,
        color: Theme.of(context).primaryColor,
        child: Text(
          'Drag me',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildEditTitle() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 5),
      width: 200,
      child: TextFormField(
        initialValue: widget.initWindowTitle,
        onChanged: widget.onTitleChange,
      ),
    );
  }

  Widget buildResize() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          child: Icon(Icons.remove),
          onPressed: widget.onSizeDec,
        ),
        SizedBox(
          width: 50,
          height: 50,
          child: Checkbox(
            value: resizeCenter,
            onChanged: (val) {
              widget.onCheckCenter(val ?? false);
              setState(() {
                resizeCenter = val ?? false;
              });
            },
          ),
        ),
        FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: widget.onSizeInc,
        ),
      ],
    );
  }

  Widget buildToCenter() {
    return ElevatedButton(
      child: Text('Center'),
      onPressed: widget.onToCenter,
    );
  }

  buildWindowStyle() {
    return Column(
      children: [
        Text(
          'Window style',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WindowStyleButton(name: 'None'),
            SizedBox(width: 5),
            WindowStyleButton(name: 'Dialog'),
            SizedBox(width: 5),
            Column(
              children: [
                if (windowStyleName == 'MainWindow')
                  Column(
                    children: [
                      buildCommandButtonSwitcher(),
                      SizedBox(height: 5),
                    ],
                  ),
                WindowStyleButton(name: 'MainWindow'),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget WindowStyleButton({required String name}) {
    return Opacity(
      opacity: windowStyleName == name ? 1.0 : 0.7,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: windowStyleName == name
                ? Theme.of(context).primaryColor
                : Colors.blueGrey),
        child: Text(name),
        onPressed: () {
          if (windowStyleName == name) {
            return;
          }
          setState(() {
            windowStyleName = name;
          });
          widget.onWindowStyle(windowStyleName);
        },
      ),
    );
  }

  var _buttons = <String>[];

  var _minimizeButton = true;
  var _maximizeButton = true;
  var _closeButton = true;

  Widget buildCommandButtonSwitcher() {
    return Row(
      children: [
        switchButtonIcon(
          icon: Icons.minimize,
          onOff: _minimizeButton,
          onPressed: () {
            setState(() {
              _minimizeButton = !_minimizeButton;
            });
            sendButtonStyle();
          },
        ),
        switchButtonIcon(
          icon: Icons.web_asset,
          onOff: _maximizeButton,
          onPressed: () {
            setState(() {
              _maximizeButton = !_maximizeButton;
            });
            sendButtonStyle();
          },
        ),
        switchButtonIcon(
          icon: Icons.close,
          onOff: _closeButton,
          onPressed: () {
            setState(() {
              _closeButton = !_closeButton;
            });
            sendButtonStyle();
          },
        ),
      ],
    );
  }

  void sendButtonStyle() {
    final newButtons = [
      _minimizeButton ? 'minimize' : '',
      _maximizeButton ? 'maximize' : '',
      _closeButton ? 'close' : '',
    ];

    if (listEquals(_buttons, newButtons)) {
      return;
    }

    _buttons = newButtons;
    widget.onTitleButton(_buttons);
  }

  Widget switchButtonIcon({
    required IconData icon,
    required bool onOff,
    required Function() onPressed,
  }) {
    return TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          Colors.black.withOpacity(onOff ? 0.25 : 0.05),
        ),
      ),
      child: Icon(icon),
      onPressed: onPressed,
    );
  }
}
