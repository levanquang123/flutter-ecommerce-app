import 'package:flutter/cupertino.dart';

import '../../../models/product.dart';
import '../../../utility/extensions.dart';
import '../../../utility/snack_bar_helper.dart';

class ProductDetailProvider extends ChangeNotifier {
  String? selectedVariant;

  ProductDetailProvider();

  Future<void> addToCart(Product product, BuildContext context) async {
    if ((product.proVariantId ?? []).isNotEmpty && selectedVariant == null) {
      SnackBarHelper.showErrorSnackBar('Please select a variant');
      return;
    }

    await context.cartProvider.addItemFromProduct(
      product: product,
      variant: selectedVariant ?? '',
      quantity: 1,
    );
    selectedVariant = null;
    notifyListeners();
  }

  void updateUI() {
    notifyListeners();
  }
}
