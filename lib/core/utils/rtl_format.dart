import 'package:intl/intl.dart';

class RtlFormat {
  static String formatPrice(double price) {
    final format = NumberFormat.currency(
      locale: 'ar',
      symbol: 'ر.س',
      decimalDigits: 2,
    );
    return format.format(price);
  }

  static String formatNumber(num number) {
    final format = NumberFormat('#,###', 'ar');
    return format.format(number);
  }

  static String formatDate(DateTime date) {
    final format = DateFormat.yMMMMd('ar');
    return format.format(date);
  }

  static String formatTime(DateTime date) {
    final format = DateFormat.jm('ar');
    return format.format(date);
  }
}
