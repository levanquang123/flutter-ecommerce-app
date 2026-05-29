import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final double? height;
  final TextEditingController controller;
  final TextInputType? inputType;
  final int? lineNumber;
  final void Function(String?) onSave;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.onSave,
    this.inputType = TextInputType.text,
    this.lineNumber = 1,
    this.validator, 
    required this.controller, 
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Optimization: We now rely more on the global Theme defined in AppTheme
    // This makes the widget cleaner and more consistent across the app.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: lineNumber,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: labelText,
          alignLabelWithHint: true,
          // Inherits decoration from Theme.inputDecorationTheme
        ),
        keyboardType: inputType,
        onSaved: (value) {
          onSave(value?.isEmpty ?? true ? null : value);
        },
        validator: validator,
        inputFormatters: [
          LengthLimitingTextInputFormatter(700),
          if (inputType == TextInputType.number) FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
        ],
      ),
    );
  }
}
