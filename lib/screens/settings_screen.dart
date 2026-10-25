import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/category_icon_picker.dart';
import '../widgets/color_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showCurrencyPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Currency',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: AppConstants.currencies.length,
                  itemBuilder: (context, index) {
                    final curr = AppConstants.currencies[index];
                    final isSelected = appState.currencySymbol == curr['symbol'];

                    return ListTile(
                      title: Text(curr['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: isSelected ? const Icon(Icons.check_rounded, color: Colors.blue) : null,
                      onTap: () {
                        appState.setCurrency(curr['symbol']!, curr['code']!);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccentColorPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Accent Seed Color',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: AppConstants.accentColors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final color = item['color'] as Color;
                    final isSelected = appState.accentColorIndex == index;

                    return GestureDetector(
                      onTap: () {
                        appState.setAccentColorIndex(index);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.6),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['name'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPinDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(appState.hasPin ? 'Change or Disable PIN' : 'Set 4-Digit PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter 4-Digit PIN',
                  hintText: '••••',
                ),
              ),
            ],
          ),
          actions: [
            if (appState.hasPin)
              TextButton(
                onPressed: () {
                  appState.disablePin();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN Lock Disabled')),
                  );
                },
                child: const Text('Disable PIN', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final err = AppValidators.validatePin(controller.text);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  return;
                }
                appState.setPin(controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN Successfully Configured')),
                );
              },
              child: const Text('Save PIN'),
            ),
          ],
        );
      },
    );
  }

  void _showManageCategoriesDialog(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scroll) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: ListView(
                    controller: scroll,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Manage Categories',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Add Custom Category',
                            onPressed: () => _showAddCustomCategoryDialog(context, appState),
                          ),
                        ],
                      ),
                      const Divider(),
                      ...appState.categories.map((c) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(c.colorValue).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconData(c.iconCodePoint, fontFamily: 'MaterialIcons'),
                              color: Color(c.colorValue),
                              size: 20,
                            ),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.isCustom ? 'Custom Category' : 'Built-in Category'),
                          trailing: c.id == AppConstants.otherCategoryId
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  onPressed: () {
                                    appState.deleteCategory(c.id);
                                    setSheetState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Category "${c.name}" deleted. Transactions moved to "Other".')),
                                    );
                                  },
                                ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddCustomCategoryDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();
    int selectedIcon = 0xe532; // restaurant
    int selectedColor = 0xFFEF5350; // Red
    bool isIncome = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Custom Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Subscriptions, Coffee'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Income Category?'),
                      value: isIncome,
                      onChanged: (val) => setDialogState(() => isIncome = val),
                    ),
                    const SizedBox(height: 12),
                    const Text('Pick Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    ColorPickerWidget(
                      selectedColorValue: selectedColor,
                      onColorSelected: (val) => setDialogState(() => selectedColor = val),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pick Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    CategoryIconPicker(
                      selectedIconCodePoint: selectedIcon,
                      onIconSelected: (val) => setDialogState(() => selectedIcon = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final err = AppValidators.validateTitle(nameCtrl.text, fieldName: 'Category name');
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }
                    appState.addCategory(
                      name: nameCtrl.text.trim(),
                      iconCodePoint: selectedIcon,
                      colorValue: selectedColor,
                      isIncome: isIncome,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRestoreDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Restore Data from Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste your backup JSON text below or use the paste button.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Paste backup JSON here...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        controller.text = data!.text!;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final parsed = AppValidators.validateBackupJson(controller.text);
                if (parsed == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid backup JSON format. Please verify the copied text.')),
                  );
                  return;
                }

                // Show confirmation before overwrite
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Overwrite All Data?'),
                    content: const Text(
                      'Restoring this backup will replace all current transactions, categories, and accounts. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Confirm Restore'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await appState.restoreFromJson(parsed['data'] as Map<String, dynamic>);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data restored successfully!')),
                    );
                  }
                }
              },
              child: const Text('Restore Data'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDataConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all transactions, budgets, goals, and accounts. You cannot recover this data unless you have a backup.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              // Double confirmation
              final secondConfirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Are you completely sure?'),
                  content: const Text('Tap "Erase Everything" to proceed with complete data wipe.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Erase Everything'),
                    ),
                  ],
                ),
              );

              if (secondConfirm == true) {
                await appState.clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data has been reset to defaults.')),
                  );
                }
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Section: Preferences
          _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.currency_rupee_rounded,
            title: 'Currency',
            subtitle: appState.currencyCode,
            trailing: Text(
              appState.currencySymbol,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            onTap: () => _showCurrencyPicker(context, appState),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Accent Seed Color',
            subtitle: AppConstants.accentColors[appState.accentColorIndex]['name'] as String,
            trailing: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: appState.accentSeedColor,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => _showAccentColorPicker(context, appState),
          ),
          _SettingsTile(
            icon: Icons.brightness_6_rounded,
            title: 'Theme Mode',
            subtitle: appState.themeMode == ThemeMode.dark
                ? 'Dark Theme'
                : appState.themeMode == ThemeMode.light
                    ? 'Light Theme'
                    : 'System Default',
            onTap: () {
              if (appState.themeMode == ThemeMode.system) {
                appState.setThemeMode(ThemeMode.light);
              } else if (appState.themeMode == ThemeMode.light) {
                appState.setThemeMode(ThemeMode.dark);
              } else {
                appState.setThemeMode(ThemeMode.system);
              }
            },
          ),

          const SizedBox(height: 16),

          // Section: Security & Management
          _SectionHeader(title: 'Security & Management'),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: '4-Digit PIN Lock',
            subtitle: appState.hasPin ? 'PIN Enabled' : 'Disabled',
            trailing: Switch(
              value: appState.hasPin,
              onChanged: (val) => _showPinDialog(context, appState),
            ),
            onTap: () => _showPinDialog(context, appState),
          ),
          _SettingsTile(
            icon: Icons.category_rounded,
            title: 'Manage Categories',
            subtitle: '${appState.categories.length} total categories',
            onTap: () => _showManageCategoriesDialog(context, appState),
          ),

          const SizedBox(height: 16),

          // Section: Data & Backup
          _SectionHeader(title: 'Data & Backup'),
          _SettingsTile(
            icon: Icons.file_download_outlined,
            title: 'Export to CSV',
            subtitle: 'Share spreadsheet file with all transactions',
            onTap: () async {
              await ExportService.exportTransactionsToCsv(
                transactions: appState.transactions,
                categories: appState.categories,
                wallets: appState.wallets,
                currencySymbol: appState.currencySymbol,
              );
            },
          ),
          _SettingsTile(
            icon: Icons.cloud_upload_outlined,
            title: 'Export JSON Backup',
            subtitle: 'Complete offline backup file',
            onTap: () async {
              await ExportService.exportJsonBackup(
                transactions: appState.transactions,
                categories: appState.categories,
                wallets: appState.wallets,
                budgets: appState.budgets,
                goals: appState.goals,
                rules: appState.recurringRules,
                settings: {
                  'currencySymbol': appState.currencySymbol,
                  'currencyCode': appState.currencyCode,
                  'accentColorIndex': appState.accentColorIndex,
                  'hasOnboarded': appState.hasOnboarded,
                },
              );
            },
          ),
          _SettingsTile(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Restore Data',
            subtitle: 'Import backup JSON text',
            onTap: () => _showRestoreDialog(context, appState),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Clear All Data',
            subtitle: 'Wipe all transactions and reset',
            titleColor: Colors.red,
            onTap: () => _showClearAllDataConfirmation(context, appState),
          ),

          const SizedBox(height: 16),

          // Section: About
          _SectionHeader(title: 'About'),
          Container(
            padding: const EdgeInsets.all(18),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Version 1.0.0 (Release)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '100% offline, privacy-first personal finance app crafted with Flutter and Material 3 design tokens.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: titleColor ?? theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor ?? theme.colorScheme.onSurface),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
