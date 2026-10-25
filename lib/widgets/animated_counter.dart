import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final String currencySymbol;
  final TextStyle? style;
  final bool isCompact;
  final bool showDecimals;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.currencySymbol = '₹',
    this.style,
    this.isCompact = false,
    this.showDecimals = true,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final formatted = isCompact
            ? AppFormatters.formatCompactNumber(val, currencySymbol: currencySymbol)
            : AppFormatters.formatCurrency(val,
                currencySymbol: currencySymbol, showDecimals: showDecimals);
        return Text(
          formatted,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
