import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/models/records.dart';
import 'pawshots_widgets.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowFuture = true,
    this.clearable = true,
  });
  final String label;
  final String? value;
  final bool allowFuture, clearable;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final today = colomboToday();
              final end = allowFuture
                  ? DateTime(2100, 12, 31)
                  : DateTime(today.year, today.month, today.day);
              var initial = value == null
                  ? DateTime(today.year, today.month, today.day)
                  : DateTime.parse(value!);
              if (initial.isAfter(end)) initial = end;
              final date = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1900),
                lastDate: end,
              );
              if (date != null) onChanged(calendarDate(date));
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                value == null ? s.notSet : displayDate(context, value!),
              ),
            ),
          ),
        ),
        if (clearable && value != null)
          IconButton(
            tooltip: s.clearDate,
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }
}
