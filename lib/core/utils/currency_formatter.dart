// Helper functions for formatting amounts and currencies across Rahhal.

/// Formats an amount with standard Rahhal currency symbols (e.g. YER -> ر.ي, SAR -> ر.س).
String formatCurrencyAmount(num amount, [String currency = 'YER']) {
  final formattedAmount = amount % 1 == 0
      ? amount.toInt().toString()
      : amount.toStringAsFixed(1);
  final upper = currency.toUpperCase().trim();
  if (upper == 'YER' ||
      upper == 'YER_RIYAL' ||
      upper == 'ريال يمني' ||
      upper == 'ر.ي' ||
      upper == 'ريال') {
    return '$formattedAmount ر.ي';
  } else if (upper == 'SAR' ||
      upper == 'SAR_RIYAL' ||
      upper == 'ريال سعودي' ||
      upper == 'ر.س') {
    return '$formattedAmount ر.س';
  } else if (upper == 'USD' || upper == 'دولار' || upper == '\$') {
    return '$formattedAmount \$';
  } else if (upper.isNotEmpty) {
    return '$formattedAmount $currency';
  }
  return '$formattedAmount ر.ي';
}
