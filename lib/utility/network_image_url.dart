import 'constants.dart';

String normalizeNetworkImageUrl(String? rawUrl) {
  var url = (rawUrl ?? '')
      .trim()
      .replaceAll('\\', '/')
      .replaceAll('"', '')
      .replaceAll("'", '');

  if (url.isEmpty || url == 'no_url' || url == 'null' || url == 'undefined') {
    return '';
  }

  final normalizedBase = MAIN_URL.replaceAll(RegExp(r'/$'), '');
  final localhostPattern = RegExp(r'^(https?:\/\/)?localhost:3000\/?');
  if (localhostPattern.hasMatch(url)) {
    url = url.replaceFirst(localhostPattern, '$normalizedBase/');
  }

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = url.startsWith('/') ? '$normalizedBase$url' : '$normalizedBase/$url';
  }

  if (url.contains('res.cloudinary.com') && url.startsWith('http://')) {
    url = url.replaceFirst('http://', 'https://');
  }

  return Uri.encodeFull(url);
}
