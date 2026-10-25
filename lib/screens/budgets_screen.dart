import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../models/category.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/empty_state.dart';
import '../utils/validators.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _showSetOverallBudgetDialog(BuildContext context, AppState appState) {
    final currentBudget = appState.currentOverallBudget;
    final controller = TextEditingController(
      text: currentBudget != null ? currentBudget.amount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(currentBudget == null ? 'Set Monthly Budget' : 'Edit Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Monthly Limit (${appState.currencySymbol})',
              hintText: 'e.g. 50000',
              prefixText: '${appState.currencySymbol} ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final error = AppValidators.validateAmount(controller.text);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                final amount = double.parse(controller.text.replaceAll(',', '').trim());
                appState.setOverallBudget(
                  amount: amount,
                  month: appState.selectedDashboardMonth.month,
                  year: appState.selectedDashboardMonth.year,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSetCategoryBudgetDialog(BuildContext context, AppState appState) {
    String selectedCatId = appState.categories.first.id;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Category Budget'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCatId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: appState.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCatId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Budget Limit (${appState.currencySymbol})',
                      hintText: 'e.g. 10000',
                      prefixText: '${appState.currencySymbol} ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final error = AppValidators.validateAmount(controller.text);
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    final amount = double.parse(controller.text.replaceAll(',', '').trim());
                    appState.setCategoryBudget(
                      categoryId: selectedCatId,
                      amount: amount,
                      month: appState.selectedDashboardMonth.month,
                      year: appState.selectedDashboardMonth.year,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Set Budget'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = Theme.of(context);

    final overall = appState.currentOverallBudget;
    final categoryBudgets = appState.budgets
        .where((b) =>
            !b.isOverall &&
            b.month == appState.selectedDashboardMonth.month &&
            b.year == appState.selectedDashboardMonth.year)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Limits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded),
            tooltip: 'Add Category Budget',
            onPressed: () => _showSetCategoryBudgetDialog(context, appState),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Overall Monthly Budget Header & Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Monthly Budget',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                icon: Icon(overall == null ? Icons.add_rounded : Icons.edit_rounded, size: 16),
                label: Text(overall == null ? 'Set Limit' : 'Edit'),
                onPressed: () => _showSetOverallBudgetDialog(context, appState),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (overall == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.speed_rounded, size: 40, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    'No overall budget set for this month',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set a spending limit to track daily pacing and receive overspend alerts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _showSetOverallBudgetDialog(context, appState),
                    child: const Text('Set Monthly Budget'),
                  ),
                ],
              ),
            )
          else
            BudgetProgressBar(
              label: 'All Expenses',
              spent: appState.selectedMonthExpense,
              limit: overall.amount,
              currencySymbol: appState.currencySymbol,
              onTap: () => _showSetOverallBudgetDialog(context, appState),
            ),

          const SizedBox(height: 28),

          // Category Budgets Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Budgets',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Add Category Budget',
                onPressed: () => _showSetCategoryBudgetDialog(context, appState),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (categoryBudgets.isEmpty)
            const EmptyStateWidget(
              icon: Icons.category_outlined,
              title: 'No category budgets yet',
              message: 'Set individual spending targets for Groceries, Dining, Shopping, etc.',
            )
          else
            ...categoryBudgets.map((b) {
              final cat = appState.categories.firstWhere(
                (c) => c.id == b.categoryId,
                orElse: () => Category(
                  id: b.categoryId ?? '',
                  name: 'Other',
                  iconCodePoint: Icons.more_horiz.codePoint,
                  colorValue: 0xFF9E9E9E,
                ),
              );

              // Calculate category spend for current month
              final catSpend = appState.transactions
                  .where((t) =>
                      t.categoryId == b.categoryId &&
                      t.date.year == b.year &&
                      t.date.month == b.month)
                  .fold(0.0, (sum, t) => sum + t.amount);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key(b.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    appState.deleteBudget(b.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted ${cat.name} budget')),
                    );
                  },
                  child: BudgetProgressBar(
                    label: cat.name,
                    spent: catSpend,
                    limit: b.amount,
                    currencySymbol: appState.currencySymbol,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
