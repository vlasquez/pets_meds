import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';

/// Circle avatar showing the pet's photo, or a species icon as fallback.
class PetAvatar extends StatelessWidget {
  final Pet pet;
  final double radius;

  const PetAvatar({super.key, required this.pet, this.radius = 20});

  IconData get _speciesIcon {
    switch (pet.species) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets_outlined;
      default:
        return Icons.cruelty_free;
    }
  }

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
      child: Icon(_speciesIcon, size: radius),
    );
  }
}
