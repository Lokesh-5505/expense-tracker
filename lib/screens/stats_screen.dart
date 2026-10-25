import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_state.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_charts.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TransactionType _selectedType = TransactionType.expense;
  StatsPeriod _period = StatsPeriod.month;
  DateTimeRange? _customRange;

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = StatsPeriod.custom;
      });
    }
  }

  List<Transaction> _getFilteredTransactions(AppState appState) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_period) {
      case StatsPeriod.week:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case StatsPeriod.month:
        start = DateTime(appState.selectedDashboardMonth.year, appState.selectedDashboardMonth.month, 1);
        end = DateTime(appState.selectedDashboardMonth.year, appState.selectedDashboardMonth.month + 1, 0, 23, 59, 59);
        break;
      case StatsPeriod.year:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case StatsPeriod.custom:
        start = _customRange?.start ?? now.subtract(const Duration(days: 30));
        end = _customRange?.end ?? now;
        break;
    }

    return appState.transactions.where((t) {
      if (t.type != _selectedType) return false;
      if (t.date.isBefore(start) || t.date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final txns = _getFilteredTransactions(appState);
    final totalAmount = txns.fold(0.0, (sum, t) => sum + t.amount);

    // Group by category
    final Map<String, double> catMap = {};
    for (final t in txns) {
      catMap[t.categoryId] = (catMap[t.categoryId] ?? 0.0) + t.amount;
    }

    final List<CategoryPieData> pieData = [];
    catMap.forEach((catId, amount) {
      final cat = appState.categories.firstWhere(
        (c) => c.id == catId,
        orElse: () => Category(
          id: catId,
          name: 'Other',
          iconCodePoint: Icons.more_horiz.codePoint,
          colorValue: 0xFF9E9E9E,
        ),
      );
      final percent = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;
      pieData.add(CategoryPieData(category: cat, amount: amount, percentage: percent));
    });
    pieData.sort((a, b) => b.amount.compareTo(a.amount));

    // Trend bar data
    final List<double> barValues = [];
    final List<String> barLabels = [];

    if (_period == StatsPeriod.week) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 1; i <= 7; i++) {
        final daySum = txns
            .where((t) => t.date.weekday == i)
            .fold(0.0, (sum, t) => sum + t.amount);
        barValues.add(daySum);
        barLabels.add(days[i - 1]);
      }
    } else {
      // Group by weeks or 5-day intervals
      for (int i = 1; i <= 4; i++) {
        final rangeSum = txns
            .where((t) => (t.date.day >= (i - 1) * 7 + 1) && (t.date.day <= i * 7))
            .fold(0.0, (sum, t) => sum + t.amount);
        barValues.add(rangeSum);
        barLabels.add('W$i');
      }
    }

    // Cumulative line spots
    final sortedTxns = List<Transaction>.from(txns)..sort((a, b) => a.date.compareTo(b.date));
    final List<FlSpot> cumulativeSpots = [];
    double cumulative = 0;
    for (int i = 0; i < sortedTxns.length; i++) {
      cumulative += sortedTxns[i].amount;
      cumulativeSpots.add(FlSpot(i.toDouble(), cumulative));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Stats'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Income / Expense Toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Expenses', style: TextStyle(fontWeight: FontWeight.w700))),
                  selected: _selectedType == TransactionType.expense,
                  selectedColor: (isDark ? AppColors.expenseDark : AppColors.expense).withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = TransactionType.expense);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Income', style: TextStyle(fontWeight: FontWeight.w700))),
                  selected: _selectedType == TransactionType.income,
                  selectedColor: (isDark ? AppColors.incomeDark : AppColors.income).withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = TransactionType.income);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Period Selector
          PeriodSelector(
            selectedPeriod: _period,
            onPeriodChanged: (p) => setState(() => _period = p),
            onCustomRangeTap: _pickCustomRange,
          ),

          const SizedBox(height: 20),

          if (txns.isEmpty)
            const EmptyStateWidget(
              icon: Icons.analytics_outlined,
              title: 'No data for this timeframe',
              message: 'Try switching to another period or adding new transactions.',
            )
          else ...[
            // Donut Chart Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  CategoryDonutChart(
                    data: pieData,
                    currencySymbol: appState.currencySymbol,
                    totalAmount: totalAmount,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Trend Bar Chart Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Trend',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TrendBarChart(
                    values: barValues,
                    labels: barLabels,
                    currencySymbol: appState.currencySymbol,
                    barColor: _selectedType == TransactionType.expense
                        ? (isDark ? AppColors.expenseDark : AppColors.expense)
                        : (isDark ? AppColors.incomeDark : AppColors.income),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cumulative Line Chart Container
            if (cumulativeSpots.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cumulative Spending Curve',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    CumulativeLineChart(
                      spots: cumulativeSpots,
                      currencySymbol: appState.currencySymbol,
                      lineColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Top Ranking Categories List with Progress Bars
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Categories Ranking',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ...pieData.take(5).map((item) {
                    final color = Color(item.category.colorValue);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    IconData(item.category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                    size: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.category.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                              Text(
                                '${AppFormatters.formatCurrency(item.amount, currencySymbol: appState.currencySymbol)} (${item.percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: item.percentage / 100,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
