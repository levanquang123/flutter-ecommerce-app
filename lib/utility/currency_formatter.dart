String formatUsd(num value) {
  final normalized = value.isFinite ? value.toDouble() : 0.0;
  final sign = normalized < 0 ? '-' : '';
  final fixed = normalized.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final dollars = parts[0];
  final cents = parts[1];
  final buffer = StringBuffer();

  for (var i = 0; i < dollars.length; i++) {
    final remaining = dollars.length - i;
    buffer.write(dollars[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return '$sign\$$buffer.$cents';
}
