import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Shows a localized confirm dialog; resolves to true when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  final s = S.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
      ],
    ),
  );
  return confirmed ?? false;
}
