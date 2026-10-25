import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../models/goal.dart';
import '../widgets/goal_progress.dart';
import '../widgets/empty_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showAddEditGoalDialog(BuildContext context, AppState appState, {SavingsGoal? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final targetController = TextEditingController(
      text: existing != null ? existing.targetAmount.toStringAsFixed(0) : '',
    );
    int selectedIcon = existing?.iconCodePoint ?? 0xe57a; // savings
    int selectedColor = existing?.colorValue ?? 0xFF00C853;
    DateTime? selectedDate = existing?.targetDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Create Savings Goal' : 'Edit Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        hintText: 'e.g. Vacation, New Laptop, Car',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Amount (${appState.currencySymbol})',
                        hintText: 'e.g. 100000',
                        prefixText: '${appState.currencySymbol} ',
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text(
                        selectedDate != null
                            ? 'Target: ${AppFormatters.formatDate(selectedDate!)}'
                            : 'Set Optional Target Date',
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Pick Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: AppConstants.selectableIcons.take(12).map((codePoint) {
                          final isSel = selectedIcon == codePoint;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedIcon = codePoint),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSel ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                                border: Border.all(
                                  color: isSel ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(IconData(codePoint, fontFamily: 'MaterialIcons'), size: 20),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final nameErr = AppValidators.validateTitle(nameController.text, fieldName: 'Goal name');
                    final amountErr = AppValidators.validateAmount(targetController.text);
                    if (nameErr != null || amountErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(nameErr ?? amountErr!)),
                      );
                      return;
                    }

                    final target = double.parse(targetController.text.replaceAll(',', '').trim());

                    if (existing != null) {
                      appState.updateGoal(
                        existing.copyWith(
                          name: nameController.text.trim(),
                          targetAmount: target,
                          targetDate: selectedDate,
                          iconCodePoint: selectedIcon,
                          colorValue: selectedColor,
                        ),
                      );
                    } else {
                      appState.addGoal(
                        name: nameController.text.trim(),
                        targetAmount: target,
                        targetDate: selectedDate,
                        iconCodePoint: selectedIcon,
                        colorValue: selectedColor,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddOrWithdrawDialog(BuildContext context, AppState appState, SavingsGoal goal, bool isAdd) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isAdd ? 'Contribute to ${goal.name}' : 'Withdraw from ${goal.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Amount (${appState.currencySymbol})',
              prefixText: '${appState.currencySymbol} ',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final error = AppValidators.validateAmount(controller.text);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                final amount = double.parse(controller.text.replaceAll(',', '').trim());

                if (isAdd) {
                  appState.contributeToGoal(goal.id, amount);
                  Navigator.pop(ctx);

                  // Check if goal completed!
                  final newTotal = goal.savedAmount + amount;
                  if (newTotal >= goal.targetAmount && goal.savedAmount < goal.targetAmount) {
                    HapticFeedback.heavyImpact();
                    _showCelebrationDialog(context, goal);
                  }
                } else {
                  appState.withdrawFromGoal(goal.id, amount);
                  Navigator.pop(ctx);
                }
              },
              child: Text(isAdd ? 'Add Money' : 'Withdraw'),
            ),
          ],
        );
      },
    );
  }

  void _showCelebrationDialog(BuildContext context, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0x1F00C853),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF00C853), size: 54),
              ),
              const SizedBox(height: 16),
              const Text(
                'Goal Completed! 🏆',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Congratulations! You have reached your target for "${goal.name}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final goals = appState.goals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
      ),
      body: goals.isEmpty
          ? EmptyStateWidget(
              icon: Icons.savings_outlined,
              title: 'No savings goals yet',
              message: 'Set targets for vacation, gadgets, emergency funds, or dreams.',
              actionLabel: 'Create Goal',
              onAction: () => _showAddEditGoalDialog(context, appState),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return GoalCard(
                  goal: goal,
                  currencySymbol: appState.currencySymbol,
                  onAddMoney: () => _showAddOrWithdrawDialog(context, appState, goal, true),
                  onWithdrawMoney: () => _showAddOrWithdrawDialog(context, appState, goal, false),
                  onEdit: () => _showAddEditGoalDialog(context, appState, existing: goal),
                  onDelete: () => appState.deleteGoal(goal.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditGoalDialog(context, appState),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
    );
  }
}
