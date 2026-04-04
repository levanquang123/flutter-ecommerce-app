import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../models/api_response.dart';
import '../../../models/cart.dart';
import '../../../models/coupon.dart';
import '../../../models/product.dart';
import '../../../services/http_services.dart';
import '../../../utility/extensions.dart';
import '../../../utility/snack_bar_helper.dart';
import '../../login_screen/provider/user_provider.dart';

class CartProvider extends ChangeNotifier {
  final HttpService service = HttpService();
  final UserProvider _userProvider;

  Cart? _cart;
  bool isLoading = false;

  final GlobalKey<FormState> buyNowFormKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController couponController = TextEditingController();
  bool isExpanded = false;

  Coupon? couponApplied;
  double couponCodeDiscount = 0;
  String selectedPaymentOption = 'cod';
  bool isSubmittingOrder = false;

  CartProvider(this._userProvider);

  List<CartItem> get myCartItems => _cart?.items ?? [];

  bool _isValidObjectId(String? value) {
    if (value == null) return false;
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);
  }

  ProductVariant? _findVariantById(Product product, String? variantId) {
    if (!_isValidObjectId(variantId)) return null;
    for (final variant in (product.variants ?? const <ProductVariant>[])) {
      if (variant.sId == variantId) return variant;
    }
    return null;
  }

  bool _isAddressComplete(dynamic address) {
    if (address == null) return false;
    final phone = (address.phone ?? '').toString().trim();
    final street = (address.street ?? '').toString().trim();
    final city = (address.city ?? '').toString().trim();
    final state = (address.state ?? '').toString().trim();
    final postalCode = (address.postalCode ?? '').toString().trim();
    final country = (address.country ?? '').toString().trim();
    return phone.isNotEmpty &&
        street.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        postalCode.isNotEmpty &&
        country.isNotEmpty;
  }

  Future<void> getCartItems() async {
    await loadCart();
  }

  Future<void> loadCart() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await service.getItems(endpointUrl: 'cart');
      if (response.isOk && response.body != null) {
        _cart = _extractCartFromResponse(response.body);
      } else {
        _cart = const Cart(items: []);
      }
    } catch (_) {
      _cart = const Cart(items: []);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Cart _extractCartFromResponse(dynamic body) {
    if (body is! Map<String, dynamic>) return const Cart(items: []);
    dynamic payload = body;
    if (payload['data'] is Map<String, dynamic>) {
      payload = payload['data'];
    }
    if (payload is Map<String, dynamic> && payload['cart'] is Map<String, dynamic>) {
      payload = payload['cart'];
    }
    if (payload is Map<String, dynamic>) {
      return Cart.fromJson(payload);
    }
    return const Cart(items: []);
  }

  Future<bool> addItemFromProduct({
    required Product product,
    required String variantId,
    int quantity = 1,
  }) async {
    if (!_isValidObjectId(product.sId)) {
      SnackBarHelper.showErrorSnackBar('Invalid product id');
      return false;
    }

    if (quantity < 1) {
      SnackBarHelper.showErrorSnackBar('Quantity must be at least 1');
      return false;
    }

    final hasVariants = (product.variants ?? const <ProductVariant>[]).isNotEmpty;
    ProductVariant? selectedVariant;

    if (hasVariants) {
      selectedVariant = _findVariantById(product, variantId);
      if (selectedVariant?.sId == null) {
        SnackBarHelper.showErrorSnackBar('Please select a valid variant');
        return false;
      }
      if (!(selectedVariant!.isActive)) {
        SnackBarHelper.showErrorSnackBar('Selected variant is inactive');
        return false;
      }
      if ((selectedVariant.quantity ?? 0) < quantity) {
        SnackBarHelper.showErrorSnackBar(
          (selectedVariant.quantity ?? 0) == 0
              ? 'Selected variant is out of stock'
              : 'Only ${selectedVariant.quantity} items available for selected variant',
        );
        return false;
      }
    } else if ((product.quantity ?? 0) < quantity) {
      SnackBarHelper.showErrorSnackBar(
        (product.quantity ?? 0) == 0
            ? 'Out of stock'
            : 'Only ${product.quantity} items available',
      );
      return false;
    }

    try {
      final response = await service.addItem(
        endpointUrl: 'cart/items',
        itemData: {
          'productId': product.sId,
          'quantity': quantity,
          if (_isValidObjectId(variantId)) 'variantId': variantId,
        },
      );

      if (!response.isOk) {
        final message = response.body is Map<String, dynamic>
            ? response.body['message']?.toString()
            : response.statusText;
        SnackBarHelper.showErrorSnackBar(message ?? 'Failed to add cart item');
        return false;
      }

      _cart = _extractCartFromResponse(response.body);
      notifyListeners();
      SnackBarHelper.showSuccessSnackBar('Item added to cart');
      return true;
    } catch (e) {
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      return false;
    }
  }

  Future<void> updateCart(
      CartItem cartItem,
      int quantityChange,
      BuildContext context,
      ) async {
    final product = context.dataProvider.allProducts.firstWhere(
          (p) => p.sId == cartItem.productId,
      orElse: () => const Product(),
    );

    if (product.sId == null) {
      SnackBarHelper.showErrorSnackBar('Product not found');
      return;
    }

    final selectedVariant =
        _findVariantById(product, cartItem.variantId.isEmpty ? null : cartItem.variantId);
    final hasVariants = (product.variants ?? const <ProductVariant>[]).isNotEmpty;
    final stock = selectedVariant?.quantity ?? product.quantity ?? 0;
    final newQuantity = cartItem.quantity + quantityChange;

    if (newQuantity < 1) {
      SnackBarHelper.showErrorSnackBar('The minimum quantity is 1.');
      return;
    }

    if (hasVariants && selectedVariant?.sId == null) {
      SnackBarHelper.showErrorSnackBar('This variant is no longer available');
      return;
    }

    if (selectedVariant != null && !selectedVariant.isActive) {
      SnackBarHelper.showErrorSnackBar('This variant is currently inactive');
      return;
    }

    if (quantityChange > 0 && newQuantity > stock) {
      SnackBarHelper.showErrorSnackBar(
        stock == 0 ? 'Out of stock' : 'Only $stock items available',
      );
      return;
    }

    try {
      final response = await service.putItem(
        endpointUrl: 'cart/items',
        itemData: {
          'productId': cartItem.productId,
          if (_isValidObjectId(cartItem.variantId)) 'variantId': cartItem.variantId,
          'quantity': newQuantity,
        },
      );

      if (!response.isOk) {
        final message = response.body is Map<String, dynamic>
            ? response.body['message']?.toString()
            : response.statusText;
        SnackBarHelper.showErrorSnackBar(message ?? 'Failed to update cart item');
        return;
      }

      _cart = _extractCartFromResponse(response.body);
      notifyListeners();
    } catch (e) {
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
    }
  }

  Future<bool> removeCartItemById({
    required String productId,
    required String variantId,
  }) async {
    if (!_isValidObjectId(productId)) {
      SnackBarHelper.showErrorSnackBar('Invalid product id');
      return false;
    }

    try {
      final response = await service.deleteWithBody(
        endpointUrl: 'cart/items',
        body: {
          'productId': productId,
          if (_isValidObjectId(variantId)) 'variantId': variantId,
        },
      );

      if (!response.isOk) {
        final message = response.body is Map<String, dynamic>
            ? response.body['message']?.toString()
            : response.statusText;
        SnackBarHelper.showErrorSnackBar(message ?? 'Failed to remove cart item');
        return false;
      }

      _cart = _extractCartFromResponse(response.body);
      notifyListeners();
      SnackBarHelper.showSuccessSnackBar('Item removed from cart');
      return true;
    } catch (e) {
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      return false;
    }
  }

  Future<void> clearCartItems() async {
    try {
      final response = await service.deleteItem(
        endpointUrl: 'cart',
        itemId: 'clear',
      );

      if (!response.isOk) {
        final message = response.body is Map<String, dynamic>
            ? response.body['message']?.toString()
            : response.statusText;
        SnackBarHelper.showErrorSnackBar(message ?? 'Failed to clear cart');
        return;
      }

      _cart = const Cart(items: []);
      notifyListeners();
    } catch (e) {
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
    }
  }

  double getCartSubTotal() {
    return myCartItems.fold(
      0,
      (total, item) => total + (item.priceAtAdd * item.quantity),
    );
  }

  double getGrandTotal() {
    return getCartSubTotal() - couponCodeDiscount;
  }

  Future<void> checkCoupon() async {
    try {
      if (couponController.text.isEmpty) {
        SnackBarHelper.showErrorSnackBar('Enter a coupon code');
        return;
      }

      if (couponApplied != null && couponApplied?.couponCode == couponController.text) {
        SnackBarHelper.showErrorSnackBar('This coupon is already applied');
        return;
      }

      final productIds = myCartItems.map((cartItem) => cartItem.productId).toList();

      final couponData = {
        'couponCode': couponController.text.trim(),
        'purchaseAmount': getCartSubTotal(),
        'productIds': productIds,
      };

      final response = await service.addItem(
        endpointUrl: 'couponCodes/check-coupon',
        itemData: couponData,
      );

      if (response.isOk) {
        final apiResponse = ApiResponse<Coupon>.fromJson(
          response.body,
          (json) => Coupon.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success == true && apiResponse.data != null) {
          couponApplied = apiResponse.data;
          couponCodeDiscount = getCouponDiscountAmount(apiResponse.data!);
          notifyListeners();
          SnackBarHelper.showSuccessSnackBar(apiResponse.message);
          return;
        }
        SnackBarHelper.showErrorSnackBar(apiResponse.message);
        return;
      }

      final message = response.body is Map<String, dynamic>
          ? response.body['message']?.toString()
          : response.statusText;
      SnackBarHelper.showErrorSnackBar(message ?? 'Error checking coupon');
    } catch (e) {
      log('Error checking coupon: $e');
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
    }
  }

  double getCouponDiscountAmount(Coupon coupon) {
    final discountType = coupon.discountType ?? 'fixed';
    if (discountType == 'fixed') {
      return coupon.discountAmount ?? 0;
    }
    final discountPercentage = coupon.discountAmount ?? 0;
    return getCartSubTotal() * (discountPercentage / 100);
  }

  Future<void> submitOrder(BuildContext context) async {
    if (isSubmittingOrder) return;
    isSubmittingOrder = true;
    notifyListeners();

    try {
    final hasProfile = await _userProvider.fetchCurrentUserProfile(showSnack: false);
    if (!hasProfile) {
      SnackBarHelper.showErrorSnackBar('Unable to load profile. Please try again.');
      return;
    }

    final profileAddress = _userProvider.currentUser?.address;
    if (!_isAddressComplete(profileAddress)) {
      SnackBarHelper.showErrorSnackBar(
        'Please update your address in Profile > My Addresses before checkout.',
      );
      return;
    }

    fillAddressFromCurrentUser();

    if (selectedPaymentOption == 'cod') {
      await addOrder(context);
    } else {
      await stripePayment(
        operation: () async {
          await addOrder(context);
        },
      );
    }
    } finally {
      isSubmittingOrder = false;
      notifyListeners();
    }
  }

  Future<bool> addOrder(BuildContext context) async {
    try {
      final currentUserId = _userProvider.getLoginUsr()?.sId;
      if (!_isValidObjectId(currentUserId)) {
        SnackBarHelper.showErrorSnackBar('Session expired, please login again');
        return false;
      }

      final orderItems = cartItemToOrderItem(myCartItems);
      if (orderItems.isEmpty) {
        SnackBarHelper.showErrorSnackBar('Cart has invalid items, please refresh cart');
        return false;
      }

      final order = {
        'userID': currentUserId,
        'orderStatus': 'pending',
        'items': orderItems,
        'totalPrice': getCartSubTotal(),
        'shippingAddress': {
          'phone': _userProvider.currentUser?.address?.phone ?? '',
          'street': _userProvider.currentUser?.address?.street ?? '',
          'city': _userProvider.currentUser?.address?.city ?? '',
          'state': _userProvider.currentUser?.address?.state ?? '',
          'postalCode': _userProvider.currentUser?.address?.postalCode ?? '',
          'country': _userProvider.currentUser?.address?.country ?? '',
        },
        'paymentMethod': selectedPaymentOption,
        'orderTotal': {
          'subtotal': getCartSubTotal(),
          'discount': couponCodeDiscount,
          'total': getGrandTotal(),
        },
      };
      if (_isValidObjectId(couponApplied?.sId)) {
        order['couponCode'] = couponApplied!.sId!;
      }

      log('Order payload ids: userID=$currentUserId, '
          'items=${orderItems.map((e) => e['productID']).toList()}, '
          'couponCode=${order['couponCode']}');

      final response = await service.addItem(endpointUrl: 'orders', itemData: order);

      if (!response.isOk) {
        final message = response.body is Map<String, dynamic>
            ? response.body['message']?.toString()
            : response.statusText;
        SnackBarHelper.showErrorSnackBar(message ?? 'Failed to add Order');
        return false;
      }

      final apiResponse = ApiResponse.fromJson(response.body, (json) => json);
      if (apiResponse.success == true) {
        SnackBarHelper.showSuccessSnackBar(apiResponse.message);
        if (!context.mounted) return true;
        clearCouponDiscount();
        await clearCartItems();
        if (context.mounted) {
          Navigator.pop(context);
        }
        return true;
      } else {
        SnackBarHelper.showErrorSnackBar('Failed to add Order: ${apiResponse.message}');
        return false;
      }
    } catch (e) {
      log('Add order error: $e');
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> cartItemToOrderItem(
    List<CartItem> cartItems,
  ) {
    return cartItems.where((cartItem) => _isValidObjectId(cartItem.productId)).map((cartItem) {
      return {
        'productID': cartItem.productId,
        'quantity': cartItem.quantity,
        'price': cartItem.priceAtAdd,
        'variant': cartItem.variant,
        if (_isValidObjectId(cartItem.variantId)) 'variantId': cartItem.variantId,
      };
    }).toList();
  }

  void fillAddressFromCurrentUser() {
    final address = _userProvider.currentUser?.address;
    phoneController.text = address?.phone ?? '';
    streetController.text = address?.street ?? '';
    cityController.text = address?.city ?? '';
    stateController.text = address?.state ?? '';
    postalCodeController.text = address?.postalCode ?? '';
    countryController.text = address?.country ?? '';
    notifyListeners();
  }

  void clearCouponDiscount() {
    couponApplied = null;
    couponCodeDiscount = 0;
    couponController.clear();
    notifyListeners();
  }

  Future<bool> stripePayment({required Future<void> Function() operation}) async {
    try {
      final user = _userProvider.currentUser;

      final paymentData = {
        'email': user?.email,
        'name': user?.address?.fullName ?? user?.email,
        'address': {
          'line1': streetController.text,
          'city': cityController.text,
          'state': stateController.text,
          'postal_code': postalCodeController.text,
          'country': countryController.text.isEmpty ? 'US' : countryController.text,
        },
        'amount': (getGrandTotal() * 100).round(),
        'currency': 'usd',
        'description': 'Payment for order by ${user?.email}',
      };

      final response =
          await service.addItem(endpointUrl: 'payment/stripe', itemData: paymentData);

      if (!response.isOk) {
        SnackBarHelper.showErrorSnackBar('Payment initialization failed');
        return false;
      }

      final data = response.body['data'];
      final paymentIntent = data['paymentIntent'];
      final ephemeralKey = data['ephemeralKey'];
      final customer = data['customer'];
      final publishableKey = data['publishableKey'];

      Stripe.publishableKey = publishableKey;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'MOBIZATE',
          paymentIntentClientSecret: paymentIntent,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customer,
          style: ThemeMode.light,
          billingDetails: BillingDetails(
            email: user?.email,
            name: user?.address?.fullName ?? user?.email,
            address: Address(
              country: countryController.text.isEmpty ? 'US' : countryController.text,
              city: cityController.text,
              line1: streetController.text,
              line2: stateController.text,
              postalCode: postalCodeController.text,
              state: stateController.text,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      SnackBarHelper.showSuccessSnackBar('Payment Success');
      await operation();
      return true;
    } catch (e) {
      log('Stripe Error: $e');
      SnackBarHelper.showErrorSnackBar('Payment cancelled or error occurred');
      return false;
    }
  }

  void resetLocalState() {
    _cart = const Cart(items: []);
    clearCouponDiscount();
    phoneController.clear();
    streetController.clear();
    cityController.clear();
    stateController.clear();
    postalCodeController.clear();
    countryController.clear();
    notifyListeners();
  }

  void updateUI() {
    notifyListeners();
  }
}
