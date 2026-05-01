import '../../../utility/extensions.dart';
import '../../../utility/currency_formatter.dart';
import '../../../widget/compleate_order_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widget/applay_coupon_btn.dart';
import '../../../widget/custom_dropdown.dart';
import '../../../widget/custom_text_field.dart';
import '../provider/cart_provider.dart';

void showCustomBottomSheet(BuildContext context) {
  context.cartProvider.clearCouponDiscount();
  context.cartProvider.fillAddressFromCurrentUser();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

      return AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: context.cartProvider.buyNowFormKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle Address Fields
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return ListTile(
                          title: const Text('Shipping Address (from Profile)'),
                          trailing: IconButton(
                            icon: Icon(cartProvider.isExpanded
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down),
                            onPressed: () {
                              cartProvider.isExpanded =
                                  !cartProvider.isExpanded;
                              cartProvider.updateUI();
                            },
                          ),
                        );
                      },
                    ),

                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return Visibility(
                          visible: cartProvider.isExpanded,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  spreadRadius: 2,
                                  blurRadius: 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              children: [
                                CustomTextField(
                                  height: 65,
                                  labelText: 'Phone',
                                  onSave: (value) {},
                                  inputType: TextInputType.phone,
                                  controller: cartProvider.phoneController,
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter a phone number'
                                      : null,
                                ),
                                CustomTextField(
                                  height: 65,
                                  labelText: 'Street',
                                  onSave: (val) {},
                                  controller: cartProvider.streetController,
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter a street'
                                      : null,
                                ),
                                CustomTextField(
                                  height: 65,
                                  labelText: 'City',
                                  onSave: (value) {},
                                  controller: cartProvider.cityController,
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter a city'
                                      : null,
                                ),
                                CustomTextField(
                                  height: 65,
                                  labelText: 'State',
                                  onSave: (value) {},
                                  controller: cartProvider.stateController,
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter a state'
                                      : null,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        height: 65,
                                        labelText: 'Postal Code',
                                        onSave: (value) {},
                                        inputType: TextInputType.number,
                                        controller:
                                            cartProvider.postalCodeController,
                                        validator: (value) => value!.isEmpty
                                            ? 'Please enter a code'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomTextField(
                                        height: 65,
                                        labelText: 'Country',
                                        onSave: (value) {},
                                        controller:
                                            cartProvider.countryController,
                                        validator: (value) => value!.isEmpty
                                            ? 'Please enter a country'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Payment Options
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return CustomDropdown<String>(
                            bgColor: Colors.white,
                            hintText: cartProvider.selectedPaymentOption,
                            items: const ['cod', 'prepaid'],
                            onChanged: (val) {
                              cartProvider.selectedPaymentOption =
                                  val ?? 'prepaid';
                              cartProvider.updateUI();
                            },
                            displayItem: (val) => val);
                      },
                    ),
                    // Coupon Code Field
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            height: 60,
                            labelText: 'Enter Coupon code',
                            onSave: (value) {},
                            controller: context.cartProvider.couponController,
                          ),
                        ),
                        ApplyCouponButton(onPressed: () {
                          context.cartProvider.checkCoupon();
                        })
                      ],
                    ),
                    //? Text for Total Amount, Total Offer Applied, and Grand Total
                    Container(
                      width: double.maxFinite,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 5, left: 6),
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TotalLine(
                                label: 'Total Amount',
                                value:
                                    formatUsd(cartProvider.getCartSubTotal()),
                              ),
                              _TotalLine(
                                label: 'Total Offer Applied',
                                value:
                                    formatUsd(cartProvider.couponCodeDiscount),
                              ),
                              _TotalLine(
                                label: 'Grand Total',
                                value: formatUsd(cartProvider.getGrandTotal()),
                                color: Colors.blue,
                                fontSize: 18,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    //? Pay Button
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return CompleteOrderButton(
                            labelText: cartProvider.isSubmittingOrder
                                ? 'Processing...'
                                : 'Complete Order ${formatUsd(cartProvider.getGrandTotal())}',
                            onPressed: cartProvider.isSubmittingOrder
                                ? null
                                : () {
                                    if (!cartProvider.isExpanded) {
                                      cartProvider.isExpanded = true;
                                      cartProvider.updateUI();
                                    } else {
                                      cartProvider.submitOrder(context);
                                    }
                                  });
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double fontSize;

  const _TotalLine({
    required this.label,
    required this.value,
    this.color = Colors.black,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
