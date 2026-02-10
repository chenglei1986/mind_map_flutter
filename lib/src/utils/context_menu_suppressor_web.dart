import 'dart:js_interop';
import 'package:web/web.dart' as web;

web.EventListener? _handler;

void disableBrowserContextMenu() {
  if (_handler != null) {
    return;
  }
  _handler = ((web.Event event) {
    event.preventDefault();
  }).toJS;
  web.document.addEventListener('contextmenu', _handler);
}

void enableBrowserContextMenu() {
  if (_handler == null) {
    return;
  }
  web.document.removeEventListener('contextmenu', _handler);
  _handler = null;
}
