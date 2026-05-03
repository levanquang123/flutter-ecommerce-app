import 'constants.dart';

const _cloudinaryUploadMarker = '/image/upload/';

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

  url = _normalizeCloudinaryImageUrl(url);

  return _encodeUrlPreservingEscapes(url);
}

String _normalizeCloudinaryImageUrl(String url) {
  if (!url.contains('res.cloudinary.com') ||
      !url.contains(_cloudinaryUploadMarker)) {
    return url;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  final markerIndex = url.indexOf(_cloudinaryUploadMarker);
  final transformStart = markerIndex + _cloudinaryUploadMarker.length;
  final afterUpload = url.substring(transformStart);
  if (afterUpload.startsWith('f_jpg,')) return url;

  return url.replaceFirst(
    _cloudinaryUploadMarker,
    '${_cloudinaryUploadMarker}f_jpg,q_auto/',
  );
}

String _encodeUrlPreservingEscapes(String url) {
  final escapes = <String>[];
  final protectedUrl = url.replaceAllMapped(
    RegExp(r'%[0-9A-Fa-f]{2}'),
    (match) {
      escapes.add(match.group(0)!);
      return '__percent_escape_${escapes.length - 1}__';
    },
  );

  var encodedUrl = Uri.encodeFull(protectedUrl);
  for (var index = 0; index < escapes.length; index++) {
    encodedUrl = encodedUrl.replaceAll(
      '__percent_escape_${index}__',
      escapes[index],
    );
  }

  return encodedUrl;
}
