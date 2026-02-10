import 'package:web/web.dart' as web;

Future<bool> openExternalUrl(String url) async {
  final opened = web.window.open(url, '_blank');
  return opened != null;
}
