import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class QuickStatsRow extends StatelessWidget {
  final double todaySpend;
  final double weekSpend;
  final double dailyAverage;
  final String currencySymbol;

  const QuickStatsRow({
    super.key,
    required this.todaySpend,
    required this.weekSpend,
    required this.dailyAverage,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Today',
            amount: todaySpend,
            currencySymbol: currencySymbol,
            icon: Icons.today_rounded,
            color: const Color(0xFF2979FF),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'This Week',
            amount: weekSpend,
            currencySymbol: currencySymbol,
            icon: Icons.calendar_view_week_rounded,
            color: const Color(0xFF7C4DFF),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Daily Avg',
            amount: dailyAverage,
            currencySymbol: currencySymbol,
            icon: Icons.speed_rounded,
            color: const Color(0xFF00B0FF),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double amount;
  final String currencySymbol;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.currencySymbol,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.formatCompactNumber(amount, currencySymbol: currencySymbol),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
