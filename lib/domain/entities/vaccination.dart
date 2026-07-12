import 'package:equatable/equatable.dart';

/// Unit for the revaccination reminder interval.
enum ReminderUnit { weeks, months, years }

/// Domain entity: a vaccination applied to a pet, with an optional
/// reminder for the next dose (e.g. every 6 months, every 1 year).
class Vaccination extends Equatable {
  final int? id;
  final int petId;

  /// Vaccine type/name (e.g. "Rabia", "Triple felina").
  final String vaccineType;

  /// Date the vaccine was applied.
  final DateTime appliedAt;

  /// Reminder interval, null when no reminder is wanted.
  final int? reminderValue;
  final ReminderUnit? reminderUnit;

  final String? notes;

  const Vaccination({
    this.id,
    required this.petId,
    required this.vaccineType,
    required this.appliedAt,
    this.reminderValue,
    this.reminderUnit,
    this.notes,
  });

  bool get hasReminder => reminderValue != null && reminderUnit != null;

  /// When the next dose is due, or null when no reminder is set.
  DateTime? get nextDueDate {
    if (!hasReminder) return null;
    switch (reminderUnit!) {
      case ReminderUnit.weeks:
        return appliedAt.add(Duration(days: 7 * reminderValue!));
      case ReminderUnit.months:
        return _addMonths(appliedAt, reminderValue!);
      case ReminderUnit.years:
        return _addMonths(appliedAt, 12 * reminderValue!);
    }
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  Vaccination copyWith({
    int? id,
    int? petId,
    String? vaccineType,
    DateTime? appliedAt,
    int? reminderValue,
    ReminderUnit? reminderUnit,
    String? notes,
  }) =>
      Vaccination(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        vaccineType: vaccineType ?? this.vaccineType,
        appliedAt: appliedAt ?? this.appliedAt,
        reminderValue: reminderValue ?? this.reminderValue,
        reminderUnit: reminderUnit ?? this.reminderUnit,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props =>
      [id, petId, vaccineType, appliedAt, reminderValue, reminderUnit, notes];
}
