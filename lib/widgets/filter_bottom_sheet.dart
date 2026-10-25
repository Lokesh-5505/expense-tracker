import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/app_state.dart';

class FilterBottomSheet extends StatefulWidget {
  final AppState appState;

  const FilterBottomSheet({super.key, required this.appState});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TransactionType? _tempType;
  late Set<String> _tempCategories;
  late String? _tempWalletId;
  late DateTime? _tempStartDate;
  late DateTime? _tempEndDate;
  late TransactionSortOrder _tempSort;

  @override
  void initState() {
    super.initState();
    _tempType = widget.appState.filterType;
    _tempCategories = Set<String>.from(widget.appState.filterCategoryIds);
    _tempWalletId = widget.appState.filterWalletId;
    _tempStartDate = widget.appState.filterStartDate;
    _tempEndDate = widget.appState.filterEndDate;
    _tempSort = widget.appState.sortOrder;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: (_tempStartDate != null && _tempEndDate != null)
          ? DateTimeRange(start: _tempStartDate!, end: _tempEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _tempStartDate = picked.start;
        _tempEndDate = picked.end;
      });
    }
  }

  void _apply() {
    widget.appState.setFilterType(_tempType);
    widget.appState.clearFilters();
    widget.appState.setFilterType(_tempType);
    for (final id in _tempCategories) {
      widget.appState.toggleCategoryFilter(id);
    }
    widget.appState.setFilterWallet(_tempWalletId);
    widget.appState.setDateRangeFilter(_tempStartDate, _tempEndDate);
    widget.appState.setSortOrder(_tempSort);
    Navigator.pop(context);
  }

  void _reset() {
    widget.appState.clearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Sort',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sort By
              Text('Sort By', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Newest'),
                    selected: _tempSort == TransactionSortOrder.newest,
                    onSelected: (val) => setState(() => _tempSort = TransactionSortOrder.newest),
                  ),
                  ChoiceChip(
                    label: const Text('Oldest'),
                    selected: _tempSort == TransactionSortOrder.oldest,
                    onSelected: (val) => setState(() => _tempSort = TransactionSortOrder.oldest),
                  ),
                  ChoiceChip(
                    label: const Text('Highest Amount'),
                    selected: _tempSort == TransactionSortOrder.highestAmount,
                    onSelected: (val) => setState(() => _tempSort = TransactionSortOrder.highestAmount),
                  ),
                  ChoiceChip(
                    label: const Text('Lowest Amount'),
                    selected: _tempSort == TransactionSortOrder.lowestAmount,
                    onSelected: (val) => setState(() => _tempSort = TransactionSortOrder.lowestAmount),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Transaction Type
              Text('Transaction Type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('All')),
                      selected: _tempType == null,
                      onSelected: (val) => setState(() => _tempType = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: _tempType == TransactionType.expense,
                      onSelected: (val) => setState(() => _tempType = TransactionType.expense),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: _tempType == TransactionType.income,
                      onSelected: (val) => setState(() => _tempType = TransactionType.income),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Transfer')),
                      selected: _tempType == TransactionType.transfer,
                      onSelected: (val) => setState(() => _tempType = TransactionType.transfer),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Wallet Filter
              Text('Account / Wallet', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Wallets'),
                    selected: _tempWalletId == null,
                    onSelected: (val) => setState(() => _tempWalletId = null),
                  ),
                  ...widget.appState.wallets.map((w) {
                    return ChoiceChip(
                      label: Text(w.name),
                      selected: _tempWalletId == w.id,
                      onSelected: (val) => setState(() => _tempWalletId = val ? w.id : null),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 20),

              // Date Range Picker
              Text('Date Range', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: Text(
                  (_tempStartDate != null && _tempEndDate != null)
                      ? '${_tempStartDate!.day}/${_tempStartDate!.month} - ${_tempEndDate!.day}/${_tempEndDate!.month}'
                      : 'Select Date Range',
                ),
              ),

              const SizedBox(height: 20),

              // Categories Multi-Select
              Text('Categories', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.appState.categories.map((c) {
                  final isSelected = _tempCategories.contains(c.id);
                  return FilterChip(
                    label: Text(c.name),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _tempCategories.add(c.id);
                        } else {
                          _tempCategories.remove(c.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Apply Button
              FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
