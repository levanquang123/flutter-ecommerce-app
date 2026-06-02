import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../models/cart.dart';
import '../../../models/coupon.dart';
import '../../../models/product.dart';
import '../../../services/http_services.dart';
import '../../../utility/extensions.dart';
import '../../../utility/snack_bar_helper.dart';
import '../../login_screen/provider/user_provider.dart';
import '../data/cart_repository.dart';
import '../data/checkout_repository.dart';

class CartProvider extends ChangeNotifier {
  final UserProvider _userProvider;
  final CartRepository _cartRepository;
  final CheckoutRepository _checkoutRepository;

  Cart? _cart;
  bool isLoading = false;
  String? loadErrorMessage;

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

  CartProvider(
    this._userProvider, {
    CartRepository? cartRepository,
    CheckoutRepository? checkoutRepository,
  })  : _cartRepository = cartRepository ?? CartRepository(HttpService()),
        _checkoutRepository =
            checkoutRepository ?? CheckoutRepository(HttpService());

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
    loadErrorMessage = null;
    notifyListeners();
    try {
      _cart = await _cartRepository.loadCart();
    } catch (e) {
      loadErrorMessage = HttpService.humanizeError(
        e,
        fallback: 'Unable to load your cart right now.',
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

    final hasVariants =
        (product.variants ?? const <ProductVariant>[]).isNotEmpty;
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
      _cart = await _cartRepository.addItem(
        product: product,
        variantId: variantId,
        quantity: quantity,
      );
      notifyListeners();
      SnackBarHelper.showSuccessSnackBar('Item added to cart');
      return true;
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to add this item to your cart right now.',
        ),
      );
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

    final selectedVariant = _findVariantById(
        product, cartItem.variantId.isEmpty ? null : cartItem.variantId);
    final hasVariants =
        (product.variants ?? const <ProductVariant>[]).isNotEmpty;
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
      _cart = await _cartRepository.updateItem(
        productId: cartItem.productId,
        variantId: cartItem.variantId,
        quantity: newQuantity,
      );
      notifyListeners();
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to update cart quantity right now.',
        ),
      );
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
      _cart = await _cartRepository.removeItem(
        productId: productId,
        variantId: variantId,
      );
      notifyListeners();
      SnackBarHelper.showSuccessSnackBar('Item removed from cart');
      return true;
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to remove this item from your cart right now.',
        ),
      );
      return false;
    }
  }

  Future<void> clearCartItems() async {
    try {
      await _cartRepository.clearCart();

      _cart = const Cart(items: []);
      notifyListeners();
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to clear your cart right now.',
        ),
      );
    }
  }

  double getCartSubTotal() {
    return myCartItems.fold(
      0,
      (total, item) => total + (item.priceAtAdd * item.quantity),
    );
  }

  double getGrandTotal() {
    final total = getCartSubTotal() - couponCodeDiscount;
    return total < 0 ? 0 : total;
  }

  Future<void> checkCoupon() async {
    try {
      if (couponController.text.isEmpty) {
        SnackBarHelper.showErrorSnackBar('Enter a coupon code');
        return;
      }

      if (couponApplied != null &&
          couponApplied?.couponCode == couponController.text) {
        SnackBarHelper.showErrorSnackBar('This coupon is already applied');
        return;
      }

      final productIds =
          myCartItems.map((cartItem) => cartItem.productId).toList();
      final items = cartItemToOrderItem(myCartItems);

      final couponData = {
        'couponCode': couponController.text.trim(),
        'purchaseAmount': getCartSubTotal(),
        'productIds': productIds,
        'items': items,
      };

      final result = await _checkoutRepository.checkCoupon(couponData);
      final apiResponse = result.apiResponse;

      if (apiResponse.success == true && apiResponse.data != null) {
        couponApplied = apiResponse.data;
        couponCodeDiscount =
            result.serverDiscount ?? getCouponDiscountAmount(apiResponse.data!);
        notifyListeners();
        SnackBarHelper.showSuccessSnackBar(apiResponse.message);
        return;
      }
      SnackBarHelper.showErrorSnackBar(apiResponse.message);
      return;
    } catch (e) {
      log('Error checking coupon: $e');
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to validate this coupon code right now.',
        ),
      );
    }
  }

  double getCouponDiscountAmount(Coupon coupon) {
    final subtotal = getCartSubTotal();
    final discountType = coupon.discountType ?? 'fixed';
    double discount = 0;
    if (discountType == 'fixed') {
      discount = coupon.discountAmount ?? 0;
    } else {
      final discountPercentage = coupon.discountAmount ?? 0;
      discount = subtotal * (discountPercentage / 100);
    }
    return discount.clamp(0, subtotal).toDouble();
  }

  Future<void> submitOrder(BuildContext context) async {
    if (isSubmittingOrder) return;
    isSubmittingOrder = true;
    notifyListeners();

    try {
      final hasProfile =
          await _userProvider.fetchCurrentUserProfile(showSnack: false);
      if (!hasProfile) {
        SnackBarHelper.showErrorSnackBar(
          'Unable to load your profile. Please sign in again.',
        );
        return;
      }

      final profileAddress = _userProvider.currentUser?.address;
      if (!_isAddressComplete(profileAddress)) {
        SnackBarHelper.showErrorSnackBar(
          'Please update your shipping address in Profile > My Addresses before checkout.',
        );
        return;
      }

      fillAddressFromCurrentUser();
      if (!context.mounted) return;

      if (selectedPaymentOption == 'cod') {
        await addOrder(context);
      } else {
        await stripePayment(context);
      }
    } finally {
      isSubmittingOrder = false;
      notifyListeners();
    }
  }

  Future<bool> addOrder(BuildContext context) async {
    try {
      if (!_isValidObjectId(_userProvider.getLoginUsr()?.sId)) {
        SnackBarHelper.showErrorSnackBar(
            'Your session expired. Please log in again.');
        return false;
      }

      final orderItems = cartItemToOrderItem(myCartItems);
      if (orderItems.isEmpty) {
        SnackBarHelper.showErrorSnackBar(
            'Cart has invalid items, please refresh cart');
        return false;
      }

      final order = {
        'items': orderItems,
        'shippingAddress': {
          'phone': _userProvider.currentUser?.address?.phone ?? '',
          'street': _userProvider.currentUser?.address?.street ?? '',
          'city': _userProvider.currentUser?.address?.city ?? '',
          'state': _userProvider.currentUser?.address?.state ?? '',
          'postalCode': _userProvider.currentUser?.address?.postalCode ?? '',
          'country': _userProvider.currentUser?.address?.country ?? '',
        },
        'paymentMethod': selectedPaymentOption,
      };
      if (_isValidObjectId(couponApplied?.sId)) {
        order['couponCode'] = couponApplied!.sId!;
      }

      log('Order payload ids: items=${orderItems.map((e) => e['productID']).toList()}, '
          'couponCode=${order['couponCode']}');

      final apiResponse = await _checkoutRepository.createOrder(order);
      if (apiResponse.success == true) {
        SnackBarHelper.showSuccessSnackBar(apiResponse.message);
        if (!context.mounted) return true;
        final dataProvider = context.dataProvider;
        clearCouponDiscount();
        await clearCartItems();
        await dataProvider.getAllProducts();
        if (context.mounted) {
          Navigator.pop(context);
        }
        return true;
      } else {
        SnackBarHelper.showErrorSnackBar(
          HttpService.parseApiMessage(
            null,
            fallback: apiResponse.message.isNotEmpty
                ? apiResponse.message
                : 'Unable to place your order. Please try again.',
          ),
        );
        return false;
      }
    } catch (e) {
      log('Add order error: $e');
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to place your order right now. Please try again.',
        ),
      );
      return false;
    }
  }

  List<Map<String, dynamic>> cartItemToOrderItem(
    List<CartItem> cartItems,
  ) {
    return cartItems
        .where((cartItem) => _isValidObjectId(cartItem.productId))
        .map((cartItem) {
      return {
        'productID': cartItem.productId,
        'quantity': cartItem.quantity,
        'price': cartItem.priceAtAdd,
        'variant': cartItem.variant,
        if (_isValidObjectId(cartItem.variantId))
          'variantId': cartItem.variantId,
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

  Map<String, dynamic>? _buildCheckoutPayload() {
    final orderItems = cartItemToOrderItem(myCartItems);
    if (orderItems.isEmpty) {
      SnackBarHelper.showErrorSnackBar(
          'Cart has invalid items, please refresh cart');
      return null;
    }

    final payload = {
      'items': orderItems,
      'shippingAddress': {
        'phone': _userProvider.currentUser?.address?.phone ?? '',
        'street': _userProvider.currentUser?.address?.street ?? '',
        'city': _userProvider.currentUser?.address?.city ?? '',
        'state': _userProvider.currentUser?.address?.state ?? '',
        'postalCode': _userProvider.currentUser?.address?.postalCode ?? '',
        'country': _userProvider.currentUser?.address?.country ?? '',
      },
    };

    if (_isValidObjectId(couponApplied?.sId)) {
      payload['couponCode'] = couponApplied!.sId!;
    }

    return payload;
  }

  Future<bool> stripePayment(BuildContext context) async {
    try {
      final user = _userProvider.currentUser;
      final paymentData = _buildCheckoutPayload();
      if (paymentData == null) return false;

      final body =
          await _checkoutRepository.initializeStripePayment(paymentData);
      final data = body['data'];
      final paymentIntent = data['paymentIntent'];
      final ephemeralKey = data['ephemeralKey'];
      final customer = data['customer'];
      final publishableKey = data['publishableKey'];

      Stripe.publishableKey = publishableKey;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'QMarket',
          paymentIntentClientSecret: paymentIntent,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customer,
          style: ThemeMode.light,
          billingDetails: BillingDetails(
            email: user?.email,
            name: user?.address?.fullName ?? user?.email,
            address: Address(
              country: countryController.text.isEmpty
                  ? 'US'
                  : countryController.text,
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
      if (!context.mounted) return true;
      final dataProvider = context.dataProvider;
      clearCouponDiscount();
      await clearCartItems();
      await dataProvider.getAllProducts();
      if (context.mounted) {
        Navigator.pop(context);
      }
      return true;
    } catch (e) {
      log('Stripe Error: $e');
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Payment was cancelled or could not be completed.',
        ),
      );
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
