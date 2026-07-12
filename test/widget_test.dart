import 'package:flutter_test/flutter_test.dart';
import 'package:pet_meds/data/models/treatment_model.dart';
import 'package:pet_meds/domain/entities/dose_unit.dart';
import 'package:pet_meds/domain/entities/schedule_time.dart';
import 'package:pet_meds/domain/entities/treatment.dart';

void main() {
  group('ScheduleTime', () {
    test('formats with zero padding', () {
      expect(const ScheduleTime(8, 5).format(), '08:05');
      expect(const ScheduleTime(20, 30).format(), '20:30');
    });

    test('sorts by time of day', () {
      final times = [
        const ScheduleTime(20, 0),
        const ScheduleTime(8, 30),
        const ScheduleTime(8, 0),
      ]..sort();
      expect(times.first, const ScheduleTime(8, 0));
      expect(times.last, const ScheduleTime(20, 0));
    });
  });

  group('TreatmentModel', () {
    test('encodes and decodes times', () {
      const times = [ScheduleTime(8, 0), ScheduleTime(20, 30)];
      final encoded = TreatmentModel.encodeTimes(times);
      expect(encoded, '08:00,20:30');
      expect(TreatmentModel.decodeTimes(encoded), times);
    });

    test('round-trips through a SQLite row map', () {
      final treatment = TreatmentModel(
        id: 1,
        petId: 2,
        medicationId: 3,
        doseAmount: 5,
        doseUnit: DoseUnit.milligram,
        frequencyType: FrequencyType.interval,
        times: const [ScheduleTime(9, 0)],
        intervalValue: 3,
        intervalUnit: IntervalUnit.days,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 8, 1),
        active: true,
        notes: 'with food',
      );
      // medicationName is a joined display column, not persisted.
      final restored = TreatmentModel.fromMap(treatment.toMap());
      expect(restored, treatment);
    });

    test('round-trips weekdays and cyclic fields', () {
      final treatment = TreatmentModel(
        petId: 1,
        medicationId: 1,
        doseAmount: 1,
        doseUnit: DoseUnit.pill,
        frequencyType: FrequencyType.weekdays,
        times: const [ScheduleTime(9, 0)],
        weekdays: const [1, 3, 5],
        cycleDaysOn: 10,
        cycleDaysOff: 4,
        startDate: DateTime(2026, 7, 1),
      );
      expect(TreatmentModel.fromMap(treatment.toMap()), treatment);
    });

    test('isScheduledOn respects interval days', () {
      final treatment = TreatmentModel(
        petId: 1,
        medicationId: 1,
        doseAmount: 1,
        doseUnit: DoseUnit.pill,
        frequencyType: FrequencyType.interval,
        times: const [ScheduleTime(9, 0)],
        intervalValue: 3,
        intervalUnit: IntervalUnit.days,
        startDate: DateTime(2026, 7, 1),
      );
      expect(treatment.isScheduledOn(DateTime(2026, 7, 1)), isTrue);
      expect(treatment.isScheduledOn(DateTime(2026, 7, 2)), isFalse);
      expect(treatment.isScheduledOn(DateTime(2026, 7, 4)), isTrue);
      expect(treatment.isScheduledOn(DateTime(2026, 6, 30)), isFalse);
    });

    test('isScheduledOn: weekdays, cyclic, monthly, on demand', () {
      TreatmentModel make(FrequencyType type,
              {IntervalUnit unit = IntervalUnit.days, int value = 1}) =>
          TreatmentModel(
            petId: 1,
            medicationId: 1,
            doseAmount: 1,
            doseUnit: DoseUnit.pill,
            frequencyType: type,
            times: const [],
            intervalValue: value,
            intervalUnit: unit,
            weekdays: const [1, 5], // Mon, Fri
            cycleDaysOn: 2,
            cycleDaysOff: 3,
            startDate: DateTime(2026, 7, 1), // a Wednesday
          );

      final wk = make(FrequencyType.weekdays);
      expect(wk.isScheduledOn(DateTime(2026, 7, 3)), isTrue); // Fri
      expect(wk.isScheduledOn(DateTime(2026, 7, 6)), isTrue); // Mon
      expect(wk.isScheduledOn(DateTime(2026, 7, 4)), isFalse); // Sat

      final cy = make(FrequencyType.cyclic);
      expect(cy.isScheduledOn(DateTime(2026, 7, 1)), isTrue); // day 0 (on)
      expect(cy.isScheduledOn(DateTime(2026, 7, 2)), isTrue); // day 1 (on)
      expect(cy.isScheduledOn(DateTime(2026, 7, 3)), isFalse); // day 2 (off)
      expect(cy.isScheduledOn(DateTime(2026, 7, 6)), isTrue); // day 5 (on)

      final mo = make(FrequencyType.interval,
          unit: IntervalUnit.months, value: 1);
      expect(mo.isScheduledOn(DateTime(2026, 7, 1)), isTrue);
      expect(mo.isScheduledOn(DateTime(2026, 8, 1)), isTrue);
      expect(mo.isScheduledOn(DateTime(2026, 8, 2)), isFalse);

      final od = make(FrequencyType.onDemand);
      expect(od.isScheduledOn(DateTime(2026, 12, 25)), isTrue);
      expect(od.isScheduledOn(DateTime(2026, 6, 30)), isFalse); // before start
    });
  });
}
