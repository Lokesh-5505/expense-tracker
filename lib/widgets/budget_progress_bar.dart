import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class BudgetProgressBar extends StatelessWidget {
  final String label;
  final double spent;
  final double limit;
  final String currencySymbol;
  final bool showDailyRemaining;
  final VoidCallback? onTap;

  const BudgetProgressBar({
    super.key,
    required this.label,
    required this.spent,
    required this.limit,
    required this.currencySymbol,
    this.showDailyRemaining = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ratio = limit > 0 ? (spent / limit) : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final isExceeded = spent > limit;
    final isWarning = ratio >= 0.8 && !isExceeded;

    final Color barColor;
    if (isExceeded) {
      barColor = isDark ? AppColors.expenseDark : AppColors.expense;
    } else if (isWarning) {
      barColor = isDark ? AppColors.warningDark : AppColors.warning;
    } else {
      barColor = isDark ? AppColors.incomeDark : AppColors.income;
    }

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (daysInMonth - now.day) + 1;
    final remainingBudget = limit - spent;
    final dailyRemaining = (remainingBudget > 0 && remainingDays > 0)
        ? (remainingBudget / remainingDays)
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExceeded
                ? barColor.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
            width: isExceeded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Label & Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isExceeded) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EXCEEDED',
                          style: TextStyle(
                            color: barColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Animated Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 9,
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return FractionallySizedBox(
                        widthFactor: val,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Footer Row: Spent / Limit and Remaining Per Day
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppFormatters.formatCompactNumber(spent, currencySymbol: currencySymbol)} of ${AppFormatters.formatCompactNumber(limit, currencySymbol: currencySymbol)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showDailyRemaining)
                  Text(
                    isExceeded
                        ? 'Over by ${AppFormatters.formatCurrency(remainingBudget.abs(), currencySymbol: currencySymbol, showDecimals: false)}'
                        : '${AppFormatters.formatCurrency(dailyRemaining, currencySymbol: currencySymbol, showDecimals: false)}/day left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isExceeded ? barColor : theme.colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
