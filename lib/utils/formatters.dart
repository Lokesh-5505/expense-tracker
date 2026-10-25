import 'package:intl/intl.dart';

class AppFormatters {
  /// Format currency with full precision and proper grouping (Indian formatting for INR/₹).
  static String formatCurrency(
    double amount, {
    String currencySymbol = '₹',
    bool showDecimals = true,
  }) {
    // Avoid floating point -0.0
    final safeAmount = (amount.abs() < 0.001) ? 0.0 : amount;

    if (currencySymbol == '₹' || currencySymbol == 'INR') {
      return _formatIndianCurrency(safeAmount, currencySymbol, showDecimals);
    }

    final pattern = showDecimals ? '#,##0.00' : '#,##0';
    final formatter = NumberFormat(pattern, 'en_US');
    return '$currencySymbol${formatter.format(safeAmount)}';
  }

  /// Indian currency format: 1,25,000.00
  static String _formatIndianCurrency(
    double amount,
    String symbol,
    bool showDecimals,
  ) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final fixedStr = absAmount.toStringAsFixed(2);
    final parts = fixedStr.split('.');
    String integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    if (integerPart.length > 3) {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);

      final buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      integerPart = '${buffer.toString()},$lastThree';
    }

    final formattedDecimals = showDecimals ? '.$decimalPart' : '';
    final sign = isNegative ? '-' : '';
    return '$sign$symbol$integerPart$formattedDecimals';
  }

  /// Format compact numbers (e.g. 1.2L, 3.5Cr for INR or 1.5M, 20K for others)
  static String formatCompactNumber(
    double amount, {
    String currencySymbol = '₹',
  }) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final sign = isNegative ? '-' : '';

    if (currencySymbol == '₹' || currencySymbol == 'INR') {
      if (absAmount >= 10000000) {
        // Crores
        final cr = absAmount / 10000000;
        final str = cr.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        return '$sign$currencySymbol${str}Cr';
      } else if (absAmount >= 100000) {
        // Lakhs
        final lk = absAmount / 100000;
        final str = lk.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        return '$sign$currencySymbol${str}L';
      } else if (absAmount >= 1000) {
        // Thousands
        final k = absAmount / 1000;
        final str = k.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        return '$sign$currencySymbol${str}K';
      } else {
        return '$sign$currencySymbol${absAmount.toStringAsFixed(0)}';
      }
    } else {
      if (absAmount >= 1000000000) {
        final b = absAmount / 1000000000;
        final str = b.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        return '$sign$currencySymbol${str}B';
      } else if (absAmount >= 1000000) {
        final m = absAmount / 1000000;
        final str = m.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        return '$sign$currencySymbol${str}M';
      } else if (absAmount >= 1000) {
        final k = absAmount / 1000;
        final str = k.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        return '$sign$currencySymbol${str}K';
      } else {
        return '$sign$currencySymbol${absAmount.toStringAsFixed(0)}';
      }
    }
  }

  /// Format Date: "25 Oct 2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format Month and Year: "October 2026"
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Format Short Month: "Oct"
  static String formatShortMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  /// Format Relative or Date: "Today", "Yesterday", or "25 Oct"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;
    if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff == -1) {
      return 'Tomorrow';
    } else if (date.year == now.year) {
      return DateFormat('dd MMM').format(date);
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  /// Format Time: "10:30 AM"
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Format Percentage: "+15.2%" or "-5.0%"
  static String formatPercentage(double percent) {
    final sign = percent > 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }
}
