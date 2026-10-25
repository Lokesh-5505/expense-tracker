import 'package:flutter/material.dart';
import 'budgets_screen.dart';
import 'goals_screen.dart';
import 'wallets_screen.dart';
import 'recurring_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final features = [
      _FeatureCardData(
        title: 'Budgets & Limits',
        subtitle: 'Monthly targets & alerts',
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFF2979FF),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen())),
      ),
      _FeatureCardData(
        title: 'Savings Goals',
        subtitle: 'Target dreams & progress',
        icon: Icons.savings_rounded,
        color: const Color(0xFF00C853),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
      ),
      _FeatureCardData(
        title: 'Accounts & Wallets',
        subtitle: 'Cash, Banks & Cards',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFFF9100),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletsScreen())),
      ),
      _FeatureCardData(
        title: 'Recurring Rules',
        subtitle: 'Subscriptions & auto-pay',
        icon: Icons.repeat_rounded,
        color: const Color(0xFF7C4DFF),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen())),
      ),
      _FeatureCardData(
        title: 'Settings & Security',
        subtitle: 'Currency, PIN & Backup',
        icon: Icons.settings_rounded,
        color: const Color(0xFF00B0FF),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Features'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final f = features[index];
              return InkWell(
                onTap: f.onTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: f.color.withValues(alpha: isDark ? 0.22 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(f.icon, color: f.color, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _FeatureCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
