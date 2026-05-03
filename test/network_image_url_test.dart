import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_flutter/utility/network_image_url.dart';

void main() {
  test('keeps empty image placeholders empty', () {
    expect(normalizeNetworkImageUrl(null), isEmpty);
    expect(normalizeNetworkImageUrl(' no_url '), isEmpty);
  });

  test('builds absolute URLs for relative image paths', () {
    expect(
      normalizeNetworkImageUrl('/uploads/image one.jpg'),
      'https://api.levanquang.com/uploads/image%20one.jpg',
    );
  });

  test('normalizes Cloudinary images for native clients', () {
    expect(
      normalizeNetworkImageUrl(
        'http://res.cloudinary.com/demo/image/upload/v1/products/a%20b.jpg',
      ),
      'https://res.cloudinary.com/demo/image/upload/f_jpg,q_auto/v1/products/a%20b.jpg',
    );
  });

  test('does not double encode existing escapes in current API image URLs', () {
    expect(
      normalizeNetworkImageUrl(
        'https://res.cloudinary.com/dgyhybufg/image/upload/v1777788699/ecommerce/products/1777788698388-download-%2811%29.jpg',
      ),
      'https://res.cloudinary.com/dgyhybufg/image/upload/f_jpg,q_auto/v1777788699/ecommerce/products/1777788698388-download-%2811%29.jpg',
    );
  });

  test('does not duplicate Cloudinary transformation', () {
    expect(
      normalizeNetworkImageUrl(
        'https://res.cloudinary.com/demo/image/upload/f_jpg,q_auto/v1/products/a.jpg',
      ),
      'https://res.cloudinary.com/demo/image/upload/f_jpg,q_auto/v1/products/a.jpg',
    );
  });
}
