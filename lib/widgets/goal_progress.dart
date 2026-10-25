import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../utils/formatters.dart';

class GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final String currencySymbol;
  final VoidCallback onAddMoney;
  final VoidCallback onWithdrawMoney;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.currencySymbol,
    required this.onAddMoney,
    required this.onWithdrawMoney,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Color(goal.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: goal.isCompleted
              ? color.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
          width: goal.isCompleted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon, Title, Target Date, Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            goal.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (goal.isCompleted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'REACHED! 🎉',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (goal.targetDate != null)
                      Text(
                        'Target: ${AppFormatters.formatDate(goal.targetDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Goal', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ${AppFormatters.formatCurrency(goal.savedAmount, currencySymbol: currencySymbol)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '${(goal.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ${AppFormatters.formatCurrency(goal.targetAmount, currencySymbol: currencySymbol)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!goal.isCompleted)
                Text(
                  '${AppFormatters.formatCurrency(goal.remainingAmount, currencySymbol: currencySymbol)} to go',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons: Add & Withdraw
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onAddMoney,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Money'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWithdrawMoney,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
