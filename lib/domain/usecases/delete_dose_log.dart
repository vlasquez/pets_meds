import '../repositories/dose_log_repository.dart';

/// Removes a dose log (e.g. when the user unchecks a treatment
/// they marked as given by mistake).
class DeleteDoseLog {
  final DoseLogRepository _repository;
  const DeleteDoseLog(this._repository);

  Future<void> call(int id) => _repository.deleteDoseLog(id);
}
