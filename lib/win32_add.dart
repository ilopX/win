import 'dart:ffi';

/// Notifies applications that a power-management event has occurred.

const WM_POWERBROADCAST = 0x0218;

///Sent when the effective dots per inch (dpi) for a window has changed
/// WINVER >= 0x0601
const WM_DPICHANGED = 0x02E0;

/// For Per Monitor v2 top-level windows, this message is sent to all HWNDs in
/// the child HWDN tree of the window that is undergoing a DPI change. This
/// message occurs before the top-level window receives WM_DPICHANGED, and
/// traverses the child tree from the bottom up.
/// WINVER >= 0x0605
const WM_DPICHANGED_BEFOREPARENT = 0x02E2;
const WM_DPICHANGED_AFTERPARENT = 0x02E3;

/// This message tells the operating system that the window will be sized to
/// dimensions other than the default.
const WM_GETDPISCALEDSIZE = 0x02E4;

const INFINITE = 4294967295;


const GW_OWNER = 4;

final _gdi32 = DynamicLibrary.open('gdi32.dll');

final FillPath =
    _gdi32.lookupFunction<Int32 Function(Int32), int Function(int)>('FillPath');
