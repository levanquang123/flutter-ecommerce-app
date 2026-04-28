import 'package:flutter/material.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/empty_cart.png',
                width: MediaQuery.sizeOf(context).width,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 50),
              const Text(
                "Empty cart",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
              )
            ],
          ),
        ),
      ),
    );
  }
}
