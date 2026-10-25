import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CategoryIconPicker extends StatelessWidget {
  final int selectedIconCodePoint;
  final ValueChanged<int> onIconSelected;

  const CategoryIconPicker({
    super.key,
    required this.selectedIconCodePoint,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.selectableIcons.map((codePoint) {
        final isSelected = selectedIconCodePoint == codePoint;
        return GestureDetector(
          onTap: () => onIconSelected(codePoint),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              IconData(codePoint, fontFamily: 'MaterialIcons'),
              size: 20,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
    );
  }
}
