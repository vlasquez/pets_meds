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
        frequencyType: FrequencyType.intervalDays,
        times: const [ScheduleTime(9, 0)],
        intervalDays: 3,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 8, 1),
        active: true,
        notes: 'with food',
      );
      // medicationName is a joined display column, not persisted.
      final restored = TreatmentModel.fromMap(treatment.toMap());
      expect(restored, treatment);
    });

    test('isScheduledOn respects interval days', () {
      final treatment = TreatmentModel(
        petId: 1,
        medicationId: 1,
        doseAmount: 1,
        doseUnit: DoseUnit.pill,
        frequencyType: FrequencyType.intervalDays,
        times: const [ScheduleTime(9, 0)],
        intervalDays: 3,
        startDate: DateTime(2026, 7, 1),
      );
      expect(treatment.isScheduledOn(DateTime(2026, 7, 1)), isTrue);
      expect(treatment.isScheduledOn(DateTime(2026, 7, 2)), isFalse);
      expect(treatment.isScheduledOn(DateTime(2026, 7, 4)), isTrue);
      expect(treatment.isScheduledOn(DateTime(2026, 6, 30)), isFalse);
    });
  });
}
