import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/category_chip.dart';
import '../utils/formatters.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  late TransactionType _type;
  String _amountStr = '';
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late String _categoryId;
  late String _walletId;
  String? _toWalletId;
  late DateTime _date;
  TimeOfDay? _time;
  bool _showKeypad = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _type = t.type;
      _amountStr = t.amount.toStringAsFixed(t.amount.truncateToDouble() == t.amount ? 0 : 2);
      _titleController = TextEditingController(text: t.title);
      _noteController = TextEditingController(text: t.note ?? '');
      _categoryId = t.categoryId;
      _walletId = t.walletId;
      _toWalletId = t.toWalletId;
      _date = t.date;
      _time = TimeOfDay.fromDateTime(t.date);
      _showKeypad = false;
    } else {
      _type = TransactionType.expense;
      _titleController = TextEditingController();
      _noteController = TextEditingController();
      _categoryId = '';
      _walletId = '';
      _date = DateTime.now();
      _time = TimeOfDay.now();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = AppStateScope.of(context);
    if (_categoryId.isEmpty && appState.categories.isNotEmpty) {
      _categoryId = appState.categories.first.id;
    }
    if (_walletId.isEmpty && appState.wallets.isNotEmpty) {
      _walletId = appState.wallets.first.id;
      if (appState.wallets.length > 1) {
        _toWalletId = appState.wallets[1].id;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _getTypeColor(bool isDark) {
    switch (_type) {
      case TransactionType.expense:
        return isDark ? AppColors.expenseDark : AppColors.expense;
      case TransactionType.income:
        return isDark ? AppColors.incomeDark : AppColors.income;
      case TransactionType.transfer:
        return isDark ? AppColors.transferDark : AppColors.transfer;
    }
  }

  void _onKeypadPress(String key) {
    if (_amountStr.length >= 10) return;
    if (key == '.') {
      if (_amountStr.contains('.')) return;
      if (_amountStr.isEmpty) {
        setState(() => _amountStr = '0.');
        return;
      }
    }
    // Prevent more than 2 decimals
    if (_amountStr.contains('.')) {
      final parts = _amountStr.split('.');
      if (parts.length > 1 && parts[1].length >= 2) return;
    }

    setState(() {
      _amountStr += key;
      _errorMessage = null;
    });
  }

  void _onKeypadBackspace() {
    if (_amountStr.isNotEmpty) {
      setState(() {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _save() {
    final amount = double.tryParse(_amountStr);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount greater than 0');
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? (_type == TransactionType.transfer
            ? 'Transfer'
            : AppStateScope.of(context)
                .categories
                .firstWhere((c) => c.id == _categoryId, orElse: () => AppStateScope.of(context).categories.first)
                .name)
        : _titleController.text.trim();

    if (_type == TransactionType.transfer && _walletId == _toWalletId) {
      setState(() => _errorMessage = 'Source and destination accounts must be different');
      return;
    }

    final appState = AppStateScope.of(context);
    final finalDate = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time?.hour ?? 0,
      _time?.minute ?? 0,
    );

    HapticFeedback.lightImpact();

    if (widget.transaction != null) {
      appState.updateTransaction(
        widget.transaction!.copyWith(
          type: _type,
          amount: amount,
          title: title,
          categoryId: _categoryId,
          walletId: _walletId,
          toWalletId: _type == TransactionType.transfer ? _toWalletId : null,
          date: finalDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        ),
      );
    } else {
      appState.addTransaction(
        type: _type,
        amount: amount,
        title: title,
        categoryId: _categoryId,
        walletId: _walletId,
        toWalletId: _type == TransactionType.transfer ? _toWalletId : null,
        date: finalDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _getTypeColor(isDark);

    // Filter categories by type
    final availableCategories = appState.categories.where((c) {
      if (_type == TransactionType.income) return c.isIncome;
      return !c.isIncome;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New Transaction' : 'Edit Transaction'),
        actions: [
          IconButton(
            icon: Icon(_showKeypad ? Icons.keyboard_hide_rounded : Icons.dialpad_rounded),
            tooltip: _showKeypad ? 'Hide Keypad' : 'Show Keypad',
            onPressed: () => setState(() => _showKeypad = !_showKeypad),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Segmented Type Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab('Expense', TransactionType.expense, isDark),
                          _buildTypeTab('Income', TransactionType.income, isDark),
                          _buildTypeTab('Transfer', TransactionType.transfer, isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Big Centered Amount Display
                    GestureDetector(
                      onTap: () => setState(() => _showKeypad = true),
                      child: Column(
                        children: [
                          Text(
                            'Amount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  appState.currencySymbol,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: typeColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _amountStr.isEmpty ? '0.00' : _amountStr,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: _amountStr.isEmpty
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                                        : typeColor,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title Input
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title / Description',
                        hintText: 'e.g. Grocery shopping, Salary',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category Selection Grid (hidden for transfers)
                    if (_type != TransactionType.transfer) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Category',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: availableCategories.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = availableCategories[index];
                            return CategoryChip(
                              category: cat,
                              isSelected: _categoryId == cat.id,
                              onTap: () => setState(() => _categoryId = cat.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Account / Wallet Selection Row
                    Row(
                      children: [
                        // From Wallet
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: appState.wallets.any((w) => w.id == _walletId) ? _walletId : null,
                            decoration: InputDecoration(
                              labelText: _type == TransactionType.transfer ? 'From Account' : 'Account',
                              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                            ),
                            items: appState.wallets.map((w) {
                              return DropdownMenuItem(value: w.id, child: Text(w.name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _walletId = val);
                            },
                          ),
                        ),

                        // To Wallet (for Transfers only)
                        if (_type == TransactionType.transfer) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: appState.wallets.any((w) => w.id == _toWalletId) ? _toWalletId : null,
                              decoration: const InputDecoration(
                                labelText: 'To Account',
                                prefixIcon: Icon(Icons.account_balance_outlined),
                              ),
                              items: appState.wallets.map((w) {
                                return DropdownMenuItem(value: w.id, child: Text(w.name));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _toWalletId = val);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Date & Time Chips
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_rounded, size: 18),
                            label: Text(AppFormatters.formatDate(_date)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time_rounded, size: 18),
                            label: Text(_time != null ? _time!.format(context) : 'Set Time'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Note field
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Optional Note',
                        hintText: 'Add extra details, invoice numbers...',
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Numeric Keypad (if active)
            if (_showKeypad)
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    NumericKeypad(
                      onKeyPress: _onKeypadPress,
                      onBackspace: _onKeypadBackspace,
                      showDecimal: true,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: typeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        widget.transaction == null ? 'Save Transaction' : 'Update Transaction',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.transaction == null ? 'Save Transaction' : 'Update Transaction',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, TransactionType type, bool isDark) {
    final isSelected = _type == type;
    final color = type == TransactionType.expense
        ? (isDark ? AppColors.expenseDark : AppColors.expense)
        : type == TransactionType.income
            ? (isDark ? AppColors.incomeDark : AppColors.income)
            : (isDark ? AppColors.transferDark : AppColors.transfer);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _type = type;
            _errorMessage = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
