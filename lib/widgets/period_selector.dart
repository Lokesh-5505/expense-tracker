import 'package:flutter/material.dart';

enum StatsPeriod {
  week,
  month,
  year,
  custom,
}

class PeriodSelector extends StatelessWidget {
  final StatsPeriod selectedPeriod;
  final ValueChanged<StatsPeriod> onPeriodChanged;
  final VoidCallback? onCustomRangeTap;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.onCustomRangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildItem(context, 'Week', StatsPeriod.week),
          _buildItem(context, 'Month', StatsPeriod.month),
          _buildItem(context, 'Year', StatsPeriod.year),
          _buildItem(context, 'Custom', StatsPeriod.custom, onTap: () {
            onPeriodChanged(StatsPeriod.custom);
            onCustomRangeTap?.call();
          }),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String label, StatsPeriod period, {VoidCallback? onTap}) {
    final isSelected = selectedPeriod == period;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () => onPeriodChanged(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.cardTheme.color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
