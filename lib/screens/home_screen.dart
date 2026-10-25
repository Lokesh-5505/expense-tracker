import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/insight_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import '../utils/formatters.dart';
import '../models/transaction.dart';
import 'budgets_screen.dart';
import 'add_edit_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = Theme.of(context);
    final budget = appState.currentOverallBudget;

    // Group recent transactions by date
    final recent = appState.recentTransactions;
    final Map<String, List<Transaction>> groupedByDate = {};
    for (final t in recent) {
      final key = AppFormatters.formatRelativeDate(t.date);
      groupedByDate.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar with Greeting & Month Selector
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Greeting & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Overview',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // Month Selector with Prev/Next
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Previous Month',
                            onPressed: () => appState.prevDashboardMonth(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              AppFormatters.formatMonthYear(appState.selectedDashboardMonth),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Next Month',
                            onPressed: () => appState.nextDashboardMonth(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gradient Balance Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: BalanceCard(
                  totalBalance: appState.totalBalance,
                  monthIncome: appState.selectedMonthIncome,
                  monthExpense: appState.selectedMonthExpense,
                  expenseChangeVsLastMonth: appState.expenseChangeVsLastMonth,
                  currencySymbol: appState.currencySymbol,
                ),
              ),
            ),

            // Quick Stats Row (Today, This Week, Daily Average)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverToBoxAdapter(
                child: QuickStatsRow(
                  todaySpend: appState.todaySpend,
                  weekSpend: appState.thisWeekSpend,
                  dailyAverage: appState.dailyAverageSpendThisMonth,
                  currencySymbol: appState.currencySymbol,
                ),
              ),
            ),

            // Budget Summary Mini Card
            if (budget != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                sliver: SliverToBoxAdapter(
                  child: BudgetProgressBar(
                    label: 'Monthly Budget',
                    spent: appState.selectedMonthExpense,
                    limit: budget.amount,
                    currencySymbol: appState.currencySymbol,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                      );
                    },
                  ),
                ),
              ),

            // Smart Insights Header & Horizontal Scroll
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Smart Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 125,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: appState.smartInsights.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return InsightCard(insight: appState.smartInsights[index]);
                  },
                ),
              ),
            ),

            // Recent Transactions Section Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (recent.isNotEmpty)
                      Text(
                        'Last ${recent.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Recent Transactions List Grouped by Date
            if (recent.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: Icons.receipt_long_rounded,
                  title: 'No transactions yet',
                  message: 'Tap the + button below to log your first income or expense.',
                  actionLabel: 'Add Transaction',
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dateGroup = groupedByDate.keys.elementAt(index);
                      final txnsInGroup = groupedByDate[dateGroup]!;

                      // Compute day total
                      final daySpend = txnsInGroup
                          .where((t) => t.type == TransactionType.expense)
                          .fold(0.0, (sum, t) => sum + t.amount);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Group Header with Daily Total
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateGroup,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (daySpend > 0)
                                    Text(
                                      'Spent: ${AppFormatters.formatCurrency(daySpend, currencySymbol: appState.currencySymbol, showDecimals: false)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Transactions in this Date Group
                            ...txnsInGroup.map((t) {
                              final cat = appState.categories.firstWhere(
                                (c) => c.id == t.categoryId,
                                orElse: () => appState.categories.last,
                              );
                              final wallet = appState.wallets.firstWhere(
                                (w) => w.id == t.walletId,
                                orElse: () => appState.wallets.first,
                              );
                              final toWallet = t.toWalletId != null
                                  ? appState.wallets.firstWhere(
                                      (w) => w.id == t.toWalletId,
                                      orElse: () => appState.wallets.first,
                                    )
                                  : null;

                              return TransactionTile(
                                transaction: t,
                                category: cat,
                                wallet: wallet,
                                toWallet: toWallet,
                                currencySymbol: appState.currencySymbol,
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditTransactionScreen(transaction: t),
                                    ),
                                  );
                                },
                                onDuplicate: () => appState.duplicateTransaction(t),
                                onDelete: () {
                                  appState.deleteTransaction(t.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "${t.title}"'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () => appState.undoDeleteTransaction(),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    childCount: groupedByDate.keys.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80), // Padding for FloatingActionButton
            ),
          ],
        ),
      ),
    );
  }
}
