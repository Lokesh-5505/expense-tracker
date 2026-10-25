import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../utils/formatters.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(appState: appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = Theme.of(context);
    final filtered = appState.filteredTransactions;

    // Group filtered transactions by relative date
    final Map<String, List<Transaction>> grouped = {};
    for (final t in filtered) {
      final dateKey = AppFormatters.formatRelativeDate(t.date);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: appState.hasActiveFilters,
              child: const Icon(Icons.filter_list_rounded),
            ),
            tooltip: 'Filter & Sort',
            onPressed: () => _openFilterSheet(appState),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title, note, or amount...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          appState.setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                appState.setSearchQuery(val);
                setState(() {});
              },
            ),
          ),

          // Active Filter Chips (if any)
          if (appState.hasActiveFilters)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  InputChip(
                    avatar: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Clear All'),
                    onPressed: () {
                      _searchController.clear();
                      appState.clearFilters();
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  if (appState.filterType != null)
                    Chip(
                      label: Text('Type: ${appState.filterType!.name}'),
                      onDeleted: () => appState.setFilterType(null),
                    ),
                  if (appState.filterWalletId != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        'Wallet: ${appState.wallets.firstWhere((w) => w.id == appState.filterWalletId).name}',
                      ),
                      onDeleted: () => appState.setFilterWallet(null),
                    ),
                  ],
                  if (appState.filterStartDate != null && appState.filterEndDate != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${appState.filterStartDate!.day}/${appState.filterStartDate!.month} - ${appState.filterEndDate!.day}/${appState.filterEndDate!.month}',
                      ),
                      onDeleted: () => appState.setDateRangeFilter(null, null),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 4),

          // Transactions List or Empty State
          Expanded(
            child: filtered.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: 'No transactions found',
                  message: appState.hasActiveFilters
                      ? 'Try resetting your search or adjusting your filters.'
                      : 'You haven\'t added any transactions yet.',
                  actionLabel: appState.hasActiveFilters ? 'Reset Filters' : 'Add Transaction',
                  onAction: () {
                    if (appState.hasActiveFilters) {
                      _searchController.clear();
                      appState.clearFilters();
                      setState(() {});
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
                      );
                    }
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final dateKey = grouped.keys.elementAt(index);
                    final txnsInGroup = grouped[dateKey]!;

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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Text(
                              dateKey,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
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
                ),
          ),
        ],
      ),
    );
  }
}
