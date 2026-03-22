import 'package:flutter/cupertino.dart';
import 'package:flutter_cart/flutter_cart.dart';
import 'package:get/get.dart';
import '../../../core/data/data_provider.dart';
import '../../../models/product.dart';
import '../../../utility/snack_bar_helper.dart';
import '../../../utility/utility_extension.dart';

class ProductDetailProvider extends ChangeNotifier {
  final DataProvider _dataProvider;
  String? selectedVariant;
  var flutterCart = FlutterCart();

  ProductDetailProvider(this._dataProvider);

  void addToCart(Product product) {
    if (product.proVariantId!.isNotEmpty && selectedVariant == null) {
      SnackBarHelper.showErrorSnackBar('Please select a variant');
      return;
    }

    final isItemInCart = flutterCart.cartItemsList.any((item) =>
      item.productId == product.sId && 
      (item.variants.isEmpty || item.variants[0].color == selectedVariant)
    );

    if (isItemInCart) {
      SnackBarHelper.showErrorSnackBar('This product is already in the shopping cart.');
      return;
    }

    double? price = product.offerPrice != product.price
        ? product.offerPrice
        : product.price;

    flutterCart.addToCart(
      cartModel: CartModel(
        productId: '${product.sId}',
        productName: '${product.name}',
        productImages: ['${product.images.safeElementAt(0)?.url}'],
        variants: [ProductVariant(price: price ?? 0, color: selectedVariant)],
        productDetails: '${product.description}',
      ),
    );

    selectedVariant = null;
    SnackBarHelper.showSuccessSnackBar('Item Added');
    notifyListeners();
  }

  void updateUI() {
    notifyListeners();
  }
}
