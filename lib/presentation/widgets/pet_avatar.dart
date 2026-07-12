import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';
import 'species_silhouette.dart';

/// Circle avatar showing the pet's photo, or a cat/dog silhouette as fallback.
class PetAvatar extends StatelessWidget {
  final Pet pet;
  final double radius;

  const PetAvatar({super.key, required this.pet, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final path = pet.photoPath;
    if (path != null && File(path).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(path)),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: SpeciesSilhouette(
        species: pet.species,
        size: radius * 1.4,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
