import 'package:flutter/material.dart';

import '../../utils/strings.dart';
import '../blocs/weight/weight_bloc.dart';

/// Dialog to log a weight measurement. Dispatches [WeightLogged]
/// on the [WeightBloc] provided by [bloc].
Future<void> showLogWeightDialog(BuildContext context,
    {required WeightBloc bloc}) {
  final s = S.of(context);
  final controller = TextEditingController();
  var date = DateTime.now();

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(s.logWeight),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s.weightKgLabel),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(s.date),
              subtitle: Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              final value =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(s.invalidNumber)));
                return;
              }
              bloc.add(WeightLogged(weightKg: value, measuredAt: date));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(s.weightLoggedSnack(value.toString()))));
            },
            child: Text(s.save),
          ),
        ],
      ),
    ),
  );
}
