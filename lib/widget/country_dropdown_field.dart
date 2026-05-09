import 'package:flutter/material.dart';

class CountryDropdownField extends StatelessWidget {
  static const List<String> defaultCountries = [
    'Vietnam',
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Singapore',
    'Thailand',
    'Japan',
    'South Korea',
    'China',
    'Germany',
    'France',
  ];

  final TextEditingController controller;
  final String labelText;
  final double? height;

  const CountryDropdownField({
    super.key,
    required this.controller,
    this.labelText = 'Country',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = controller.text.trim();
    final countries = <String>[
      ...defaultCountries,
      if (currentValue.isNotEmpty && !defaultCountries.contains(currentValue))
        currentValue,
    ];

    return SizedBox(
      height: height,
      child: DropdownButtonFormField<String>(
        initialValue: currentValue.isEmpty ? null : currentValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: countries
            .map(
              (country) => DropdownMenuItem<String>(
                value: country,
                child: Text(
                  country,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          controller.text = value ?? '';
        },
        validator: (value) {
          final selected = value?.trim() ?? controller.text.trim();
          return selected.isEmpty ? 'Please select a country' : null;
        },
      ),
    );
  }
}
