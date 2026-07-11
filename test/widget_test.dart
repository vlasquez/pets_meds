import 'package:flutter_test/flutter_test.dart';
import 'package:pet_meds/data/models/medication_model.dart';
import 'package:pet_meds/domain/entities/dose_unit.dart';
import 'package:pet_meds/domain/entities/medication.dart';
import 'package:pet_meds/domain/entities/schedule_time.dart';

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

  group('MedicationModel', () {
    test('encodes and decodes times', () {
      const times = [ScheduleTime(8, 0), ScheduleTime(20, 30)];
      final encoded = MedicationModel.encodeTimes(times);
      expect(encoded, '08:00,20:30');
      expect(MedicationModel.decodeTimes(encoded), times);
    });

    test('round-trips through a SQLite row map', () {
      final med = MedicationModel(
        id: 1,
        petId: 2,
        name: 'Amoxicillin',
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
      final restored = MedicationModel.fromMap(med.toMap());
      expect(restored, med);
    });
  });
}
