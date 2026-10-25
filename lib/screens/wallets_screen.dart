import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../models/wallet.dart';
import '../widgets/wallet_card.dart';
import '../utils/validators.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  void _showAddEditWalletDialog(BuildContext context, AppState appState, {Wallet? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedType = existing?.type ?? 'Cash';
    final balanceController = TextEditingController(
      text: existing != null ? existing.initialBalance.toStringAsFixed(0) : '0',
    );
    int selectedIcon = existing?.iconCodePoint ?? 0xe481; // payments
    int selectedColor = existing?.colorValue ?? 0xFF1E88E5;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add New Account' : 'Edit Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        hintText: 'e.g. HDFC Bank, Wallet, Card',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Bank', child: Text('Bank Account')),
                        DropdownMenuItem(value: 'UPI/Card', child: Text('UPI / Debit / Credit Card')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (existing == null)
                      TextField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Initial Balance (${appState.currencySymbol})',
                          prefixText: '${appState.currencySymbol} ',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final nameErr = AppValidators.validateTitle(nameController.text, fieldName: 'Account name');
                    if (nameErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr)));
                      return;
                    }

                    final initialBal = double.tryParse(balanceController.text.replaceAll(',', '').trim()) ?? 0.0;

                    if (existing != null) {
                      appState.updateWallet(
                        existing.copyWith(
                          name: nameController.text.trim(),
                          type: selectedType,
                          iconCodePoint: selectedIcon,
                          colorValue: selectedColor,
                        ),
                      );
                    } else {
                      appState.addWallet(
                        name: nameController.text.trim(),
                        type: selectedType,
                        iconCodePoint: selectedIcon,
                        colorValue: selectedColor,
                        initialBalance: initialBal,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteWallet(BuildContext context, AppState appState, Wallet wallet) {
    if (appState.wallets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must have at least one account.')),
      );
      return;
    }

    final txnCount = appState.countTransactionsForWallet(wallet.id);

    if (txnCount > 0) {
      // Must reassign first!
      final remainingWallets = appState.wallets.where((w) => w.id != wallet.id).toList();
      String reassignTarget = remainingWallets.first.id;

      showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Reassign Transactions'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account "${wallet.name}" is used in $txnCount transactions. Please select an account to reassign these transactions to before deleting.',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: reassignTarget,
                      decoration: const InputDecoration(labelText: 'Transfer Transactions To'),
                      items: remainingWallets.map((w) {
                        return DropdownMenuItem(value: w.id, child: Text(w.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => reassignTarget = val);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      appState.deleteWallet(wallet.id, reassignToWalletId: reassignTarget);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account "${wallet.name}" deleted and transactions reassigned.')),
                      );
                    },
                    child: const Text('Reassign & Delete'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      // Directly delete
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Delete "${wallet.name}"?'),
            content: const Text('Are you sure you want to remove this account?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  appState.deleteWallet(wallet.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final wallets = appState.wallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: wallets.length,
        itemBuilder: (context, index) {
          final w = wallets[index];
          final bal = appState.getWalletBalance(w.id);
          final txnCount = appState.countTransactionsForWallet(w.id);

          return WalletCard(
            wallet: w,
            balance: bal,
            currencySymbol: appState.currencySymbol,
            transactionCount: txnCount,
            onEdit: () => _showAddEditWalletDialog(context, appState, existing: w),
            onDelete: () => _confirmDeleteWallet(context, appState, w),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditWalletDialog(context, appState),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Account'),
      ),
    );
  }
}
