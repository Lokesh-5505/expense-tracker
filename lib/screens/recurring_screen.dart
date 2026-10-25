import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../models/transaction.dart';
import '../models/recurring_rule.dart';
import '../widgets/empty_state.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  void _showAddEditRuleDialog(BuildContext context, AppState appState, {RecurringRule? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    TransactionType selectedType = existing?.type ?? TransactionType.expense;
    RecurringFrequency selectedFreq = existing?.frequency ?? RecurringFrequency.monthly;
    String selectedCatId = existing?.categoryId ?? appState.categories.first.id;
    String selectedWalletId = existing?.walletId ?? appState.wallets.first.id;
    DateTime startDate = existing?.startDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'New Recurring Rule' : 'Edit Recurring Rule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Netflix Subscription, House Rent',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (${appState.currencySymbol})',
                        prefixText: '${appState.currencySymbol} ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RecurringFrequency>(
                      initialValue: selectedFreq,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: RecurringFrequency.values.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedFreq = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TransactionType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: TransactionType.expense, child: Text('Expense')),
                        DropdownMenuItem(value: TransactionType.income, child: Text('Income')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedWalletId,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: appState.wallets.map((w) {
                        return DropdownMenuItem(value: w.id, child: Text(w.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedWalletId = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final titleErr = AppValidators.validateTitle(titleController.text);
                    final amtErr = AppValidators.validateAmount(amountController.text);
                    if (titleErr != null || amtErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(titleErr ?? amtErr!)),
                      );
                      return;
                    }

                    final amount = double.parse(amountController.text.replaceAll(',', '').trim());

                    if (existing != null) {
                      appState.updateRecurringRule(
                        existing.copyWith(
                          title: titleController.text.trim(),
                          amount: amount,
                          type: selectedType,
                          frequency: selectedFreq,
                          categoryId: selectedCatId,
                          walletId: selectedWalletId,
                        ),
                      );
                    } else {
                      appState.addRecurringRule(
                        title: titleController.text.trim(),
                        amount: amount,
                        type: selectedType,
                        frequency: selectedFreq,
                        categoryId: selectedCatId,
                        walletId: selectedWalletId,
                        startDate: startDate,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Rule'),
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
    final isDark = theme.brightness == Brightness.dark;
    final rules = appState.recurringRules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
      ),
      body: rules.isEmpty
          ? EmptyStateWidget(
              icon: Icons.repeat_rounded,
              title: 'No recurring rules active',
              message: 'Automate repetitive subscriptions, rent, salary, and utility bills.',
              actionLabel: 'Add Recurring Rule',
              onAction: () => _showAddEditRuleDialog(context, appState),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                final cat = appState.categories.firstWhere(
                  (c) => c.id == rule.categoryId,
                  orElse: () => appState.categories.first,
                );
                final wallet = appState.wallets.firstWhere(
                  (w) => w.id == rule.walletId,
                  orElse: () => appState.wallets.first,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(cat.colorValue).withValues(alpha: isDark ? 0.22 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                          color: Color(cat.colorValue),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${rule.frequency.name.toUpperCase()} • ${wallet.name}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(rule.amount, currencySymbol: appState.currencySymbol),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  rule.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                  size: 20,
                                  color: rule.isPaused ? Colors.green : Colors.amber,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                tooltip: rule.isPaused ? 'Resume' : 'Pause',
                                onPressed: () => appState.toggleRecurringRulePause(rule.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                tooltip: 'Delete',
                                onPressed: () => appState.deleteRecurringRule(rule.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditRuleDialog(context, appState),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Rule'),
      ),
    );
  }
}
