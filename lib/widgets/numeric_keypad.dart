import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final bool showDecimal;

  const NumericKeypad({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    this.onClear,
    this.showDecimal = true,
  });

  Widget _buildKey(BuildContext context, String label, {Widget? customWidget, VoidCallback? customAction}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (customAction != null) {
                customAction();
              } else {
                onKeyPress(label);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 58,
              child: Center(
                child: customWidget ??
                    Text(
                      label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildKey(context, '1'),
            _buildKey(context, '2'),
            _buildKey(context, '3'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '4'),
            _buildKey(context, '5'),
            _buildKey(context, '6'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '7'),
            _buildKey(context, '8'),
            _buildKey(context, '9'),
          ],
        ),
        Row(
          children: [
            if (showDecimal)
              _buildKey(context, '.')
            else if (onClear != null)
              _buildKey(
                context,
                'C',
                customWidget: const Text(
                  'C',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                customAction: onClear,
              )
            else
              const Spacer(),
            _buildKey(context, '0'),
            _buildKey(
              context,
              'DEL',
              customWidget: const Icon(Icons.backspace_outlined, size: 22),
              customAction: onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}
