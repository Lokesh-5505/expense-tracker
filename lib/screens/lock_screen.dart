import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../widgets/numeric_keypad.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    final appState = AppStateScope.of(context);
    if (_enteredPin == appState.pin) {
      HapticFeedback.lightImpact();
      appState.unlockApp();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN. Please try again.'),
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {
        _enteredPin = '';
      });
    }
  }

  void _showForgotPinDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'For security, your PIN is stored exclusively on your device. If you cannot remember your PIN, you can reset all app data to access the application again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.clearAllData();
              appState.unlockApp();
            },
            child: const Text('Reset All Data'),
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
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Lock Icon & Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded, size: 44, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter PIN',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your 4-digit security PIN to unlock',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // PIN Dots with Shake Animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = sin(_shakeAnimation.value * pi * 4) * 12;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          border: Border.all(
                            color: isFilled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            const Spacer(),

            // Custom Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NumericKeypad(
                onKeyPress: _onKeyPress,
                onBackspace: _onBackspace,
                showDecimal: false,
              ),
            ),

            const SizedBox(height: 12),

            // Forgot PIN option
            TextButton(
              onPressed: () => _showForgotPinDialog(context, appState),
              child: Text(
                'Forgot PIN?',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
