import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../utils/formatters.dart';

class InsightItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const InsightItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class InsightsService {
  static List<InsightItem> generateInsights({
    required List<Transaction> transactions,
    required List<Category> categories,
    required Budget? overallBudget,
    required String currencySymbol,
  }) {
    final List<InsightItem> insights = [];
    final now = DateTime.now();

    // 1. Current month expenses and incomes
    final thisMonthTxns = transactions.where((t) =>
        t.date.year == now.year && t.date.month == now.month).toList();

    final thisMonthExpenses = thisMonthTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final thisMonthIncome = thisMonthTxns
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    // 2. Last month expenses
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonthTxns = transactions.where((t) =>
        t.date.year == lastMonthDate.year &&
        t.date.month == lastMonthDate.month).toList();

    final lastMonthExpenses = lastMonthTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Insight: Overall Month Comparison
    if (lastMonthExpenses > 0 && thisMonthExpenses > 0) {
      final overallDiff = ((thisMonthExpenses - lastMonthExpenses) / lastMonthExpenses) * 100;
      final isLower = overallDiff < 0;
      insights.add(InsightItem(
        title: 'Monthly Spending Trend',
        message: isLower
            ? 'Great job! Your spending is ${overallDiff.abs().toStringAsFixed(0)}% lower than last month.'
            : 'Your spending is currently ${overallDiff.abs().toStringAsFixed(0)}% higher than last month.',
        icon: isLower ? Icons.trending_down_rounded : Icons.trending_up_rounded,
        color: isLower ? const Color(0xFF00C853) : const Color(0xFFFF9800),
      ));
    }

    // Insight A: Budget Pacing (if overall budget exists)
    if (overallBudget != null && overallBudget.amount > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final remainingDays = (daysInMonth - now.day) + 1;
      final remainingBudget = overallBudget.amount - thisMonthExpenses;

      if (remainingBudget > 0 && remainingDays > 0) {
        final dailyAllowance = remainingBudget / remainingDays;
        insights.add(InsightItem(
          title: 'Budget Pacing',
          message:
              'You can spend ${AppFormatters.formatCurrency(dailyAllowance, currencySymbol: currencySymbol, showDecimals: false)}/day for the remaining $remainingDays days to stay within your budget.',
          icon: Icons.speed_rounded,
          color: const Color(0xFF2979FF),
        ));
      } else if (remainingBudget <= 0) {
        final over = remainingBudget.abs();
        insights.add(InsightItem(
          title: 'Budget Exceeded',
          message:
              'You have exceeded your monthly budget by ${AppFormatters.formatCurrency(over, currencySymbol: currencySymbol)}.',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFFF5252),
        ));
      }
    }

    // Insight B: Monthly Savings or Deficit
    if (thisMonthIncome > 0) {
      final savings = thisMonthIncome - thisMonthExpenses;
      if (savings > 0) {
        final savingsRate = (savings / thisMonthIncome) * 100;
        insights.add(InsightItem(
          title: 'Monthly Savings',
          message:
              'You have saved ${AppFormatters.formatCurrency(savings, currencySymbol: currencySymbol)} this month (${savingsRate.toStringAsFixed(0)}% of your income).',
          icon: Icons.savings_outlined,
          color: const Color(0xFF00C853),
        ));
      } else if (savings < 0) {
        insights.add(InsightItem(
          title: 'Cashflow Alert',
          message:
              'Your expenses currently exceed your income by ${AppFormatters.formatCurrency(savings.abs(), currencySymbol: currencySymbol)} this month.',
          icon: Icons.trending_down_rounded,
          color: const Color(0xFFFF5252),
        ));
      }
    }

    // Insight C: Category Comparison with Last Month
    if (thisMonthTxns.isNotEmpty) {
      // Find top spending category this month
      final Map<String, double> thisMonthCatSpend = {};
      for (final t in thisMonthTxns.where((e) => e.type == TransactionType.expense)) {
        thisMonthCatSpend[t.categoryId] = (thisMonthCatSpend[t.categoryId] ?? 0.0) + t.amount;
      }

      if (thisMonthCatSpend.isNotEmpty) {
        final sortedCats = thisMonthCatSpend.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topEntry = sortedCats.first;

        final category = categories.firstWhere(
          (c) => c.id == topEntry.key,
          orElse: () => Category(
            id: topEntry.key,
            name: 'Expense',
            iconCodePoint: Icons.category.codePoint,
            colorValue: 0xFF9E9E9E,
          ),
        );

        // Compare with last month's spend in same category
        final lastMonthCatSpend = lastMonthTxns
            .where((t) => t.type == TransactionType.expense && t.categoryId == topEntry.key)
            .fold(0.0, (sum, t) => sum + t.amount);

        if (lastMonthCatSpend > 0) {
          final diff = ((topEntry.value - lastMonthCatSpend) / lastMonthCatSpend) * 100;
          final direction = diff >= 0 ? 'more' : 'less';
          insights.add(InsightItem(
            title: '${category.name} Spend Trend',
            message:
                'You spent ${diff.abs().toStringAsFixed(0)}% $direction on ${category.name} compared to last month (${AppFormatters.formatCurrency(topEntry.value, currencySymbol: currencySymbol)}).',
            icon: Icons.analytics_outlined,
            color: diff >= 0 ? const Color(0xFFFF9800) : const Color(0xFF00C853),
          ));
        } else {
          final percentOfTotal = thisMonthExpenses > 0
              ? (topEntry.value / thisMonthExpenses) * 100
              : 100.0;
          insights.add(InsightItem(
            title: 'Top Expense Category',
            message:
                '${category.name} is your highest spend this month (${percentOfTotal.toStringAsFixed(0)}% of total expenses).',
            icon: Icons.pie_chart_outline_rounded,
            color: const Color(0xFF7C4DFF),
          ));
        }
      }
    }

    // Insight D: Highest Spending Day of the Week
    final allExpenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (allExpenses.length >= 5) {
      final Map<int, double> dayOfWeekTotals = {};
      final Map<int, int> dayOfWeekCounts = {};

      for (final t in allExpenses) {
        final weekday = t.date.weekday; // 1 = Monday, 7 = Sunday
        dayOfWeekTotals[weekday] = (dayOfWeekTotals[weekday] ?? 0.0) + t.amount;
        dayOfWeekCounts[weekday] = (dayOfWeekCounts[weekday] ?? 0) + 1;
      }

      if (dayOfWeekTotals.isNotEmpty) {
        int highestDay = 1;
        double maxAvg = 0.0;

        dayOfWeekTotals.forEach((day, total) {
          final count = dayOfWeekCounts[day] ?? 1;
          final avg = total / count;
          if (avg > maxAvg) {
            maxAvg = avg;
            highestDay = day;
          }
        });

        const dayNames = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        final dayName = dayNames[highestDay - 1];

        insights.add(InsightItem(
          title: 'Peak Spending Day',
          message:
              'Your highest-spending day is usually $dayName, averaging ${AppFormatters.formatCurrency(maxAvg, currencySymbol: currencySymbol, showDecimals: false)}.',
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF00B0FF),
        ));
      }
    }

    // Fallback if no transactions yet
    if (insights.isEmpty) {
      insights.add(const InsightItem(
        title: 'Smart Insights Ready',
        message:
            'Start adding transactions and budgets to see automated spending trends, pacing, and financial insights here.',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFF2979FF),
      ));
    }

    return insights;
  }
}
