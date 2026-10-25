import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final Category category;
  final Wallet wallet;
  final Wallet? toWallet;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.wallet,
    this.toWallet,
    required this.currencySymbol,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  void _showQuickActions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(category.colorValue).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                          color: Color(category.colorValue),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          transaction.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (onEdit != null)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit Transaction'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onEdit!();
                    },
                  ),
                if (onDuplicate != null)
                  ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('Duplicate Transaction'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDuplicate!();
                    },
                  ),
                if (onDelete != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                    title: const Text('Delete', style: TextStyle(color: AppColors.expense)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDelete!();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color amountColor;
    final String sign;

    switch (transaction.type) {
      case TransactionType.expense:
        amountColor = isDark ? AppColors.expenseDark : AppColors.expense;
        sign = '-';
        break;
      case TransactionType.income:
        amountColor = isDark ? AppColors.incomeDark : AppColors.income;
        sign = '+';
        break;
      case TransactionType.transfer:
        amountColor = isDark ? AppColors.transferDark : AppColors.transfer;
        sign = '⇄ ';
        break;
    }

    final subtitleParts = <String>[];
    if (transaction.type == TransactionType.transfer) {
      subtitleParts.add('${wallet.name} → ${toWallet?.name ?? 'Account'}');
    } else {
      subtitleParts.add(category.name);
      subtitleParts.add(wallet.name);
    }
    subtitleParts.add(AppFormatters.formatTime(transaction.date));

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        onDelete?.call();
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? (onEdit != null ? () => onEdit!() : null),
          onLongPress: () => _showQuickActions(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Category Icon Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(category.colorValue).withValues(alpha: isDark ? 0.22 : 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Color(category.colorValue),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleParts.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Amount
                Text(
                  '$sign${AppFormatters.formatCurrency(transaction.amount, currencySymbol: currencySymbol)}',
                  style: AppTextStyles.transactionAmount(
                    color: amountColor,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
