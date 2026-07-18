import 'package:flutter/material.dart';

/// One intake: shows its hour (or index) and whether it was taken.
class IntakeChip extends StatelessWidget {
  final String label;
  final bool taken;
  final VoidCallback onTap;

  const IntakeChip({
    super.key,
    required this.label,
    required this.taken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: taken,
      showCheckmark: true,
      avatar: taken ? null : const Icon(Icons.schedule, size: 18),
      label: Text(label),
      selectedColor: theme.colorScheme.primaryContainer,
      onSelected: (_) => onTap(),
    );
  }
}
