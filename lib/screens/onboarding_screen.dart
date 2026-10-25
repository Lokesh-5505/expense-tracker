import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Setup state
  String _selectedCurrencySymbol = '₹';
  String _selectedCurrencyCode = 'INR';
  final TextEditingController _budgetController = TextEditingController();

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF2979FF),
      title: 'Effortless Money Tracking',
      description:
          'Take full control of your income, expenses, and inter-account transfers with a lightning-fast offline experience.',
    ),
    _OnboardingPageData(
      icon: Icons.analytics_rounded,
      color: Color(0xFF7C4DFF),
      title: 'Actionable Smart Insights',
      description:
          'Visualize where your money goes with interactive category breakdowns, daily trends, and spending curve analysis.',
    ),
    _OnboardingPageData(
      icon: Icons.savings_rounded,
      color: Color(0xFF00C853),
      title: 'Budgets & Dream Goals',
      description:
          'Stay ahead with automated budget warnings, daily allowances, and track progress toward your dream savings targets.',
    ),
  ];

  void _finishOnboarding() {
    final appState = AppStateScope.of(context);
    appState.setCurrency(_selectedCurrencySymbol, _selectedCurrencyCode);

    final budgetStr = _budgetController.text.trim();
    if (budgetStr.isNotEmpty) {
      final err = AppValidators.validateAmount(budgetStr);
      if (err == null) {
        final amt = double.parse(budgetStr.replaceAll(',', ''));
        final now = DateTime.now();
        appState.setOverallBudget(amount: amt, month: now.month, year: now.year);
      }
    }

    appState.completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance space
                  // Dots Indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(4, (index) {
                      final isCurrent = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrent ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          3,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Main PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  ..._pages.map((p) => _buildSlide(p, isDark, theme)),
                  _buildSetupSlide(isDark, theme),
                ],
              ),
            ),

            // Bottom Navigation Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _currentPage < 3
                  ? FilledButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    )
                  : FilledButton(
                      onPressed: _finishOnboarding,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingPageData data, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 72, color: data.color),
          ),
          const SizedBox(height: 36),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupSlide(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.tune_rounded, size: 40, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Quick Personalization',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Select your currency and an optional monthly target to tailor the app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),

          // Currency selector
          Text('Your Primary Currency', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrencySymbol,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.currency_exchange_rounded)),
            items: AppConstants.currencies.map((c) {
              return DropdownMenuItem(
                value: c['symbol'],
                child: Text('${c['name']}'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final match = AppConstants.currencies.firstWhere((c) => c['symbol'] == val);
                setState(() {
                  _selectedCurrencySymbol = val;
                  _selectedCurrencyCode = match['code']!;
                });
              }
            },
          ),

          const SizedBox(height: 20),

          // Monthly budget input
          Text('Optional Monthly Budget', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monthly Limit',
              hintText: 'e.g. 50000 (can be changed anytime)',
              prefixText: '$_selectedCurrencySymbol ',
              prefixIcon: const Icon(Icons.speed_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
