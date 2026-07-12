import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pet.dart';
import '../../domain/entities/treatment.dart';
import '../../l10n/strings.dart';
import '../blocs/treatments/treatments_bloc.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/pet_avatar.dart';
import 'treatment_form_screen.dart';

/// Treatments tab: all treatments across pets. A treatment assigns a
/// catalog medication to a pet — both are chosen on the form.
/// Expects a [TreatmentsBloc] to be provided above it.
class TreatmentsScreen extends StatelessWidget {
  const TreatmentsScreen({super.key});

  void _openForm(BuildContext context,
      {Treatment? treatment, Pet? initialPet}) {
    final s = S.of(context);
    final bloc = context.read<TreatmentsBloc>();
    final pets = bloc.state.pets;
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.addPetFirst)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreatmentFormScreen(
          pets: pets,
          initialPet: initialPet,
          treatment: treatment,
          onSave: (t, pet) => bloc.add(TreatmentSaved(
            treatment: t,
            notificationTitle: s.reminderTitle(pet.name),
            notificationBody: s.reminderBody(
                t.medicationName, s.formatDose(t.doseAmount, t.doseUnit)),
          )),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, TreatmentEntry entry) async {
    final s = S.of(context);
    final bloc = context.read<TreatmentsBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteTreatment,
      content: s.deleteTreatmentConfirm,
    );
    if (confirmed) bloc.add(TreatmentDeleted(entry.treatment));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.treatmentsTab)),
      body: BlocBuilder<TreatmentsBloc, TreatmentsState>(
        builder: (context, state) {
          switch (state.status) {
            case TreatmentsStatus.initial:
            case TreatmentsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case TreatmentsStatus.failure:
              return EmptyState(message: state.error ?? 'Error');
            case TreatmentsStatus.success:
              if (state.entries.isEmpty) {
                return EmptyState(message: s.noTreatments);
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final e in state.entries)
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: PetAvatar(pet: e.pet),
                        title: Text(
                            '${e.treatment.medicationName} · ${s.formatDose(e.treatment.doseAmount, e.treatment.doseUnit)}'),
                        subtitle: Text(
                            '${e.pet.name} · ${s.scheduleLabel(e.treatment)}\n'
                            '${s.remainingDaysLabel(e.treatment.remainingDays(DateTime.now()))}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _openForm(context,
                                    treatment: e.treatment,
                                    initialPet: e.pet);
                              case 'delete':
                                _delete(context, e);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: Text(s.editTreatment))),
                            PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                    leading:
                                        const Icon(Icons.delete_outline),
                                    title: Text(s.deleteTreatment))),
                          ],
                        ),
                        onTap: () => _openForm(context,
                            treatment: e.treatment, initialPet: e.pet),
                      ),
                    ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'treatments_fab', // Unique within the IndexedStack.
        tooltip: s.addTreatment,
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
