import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';

/// Small ♂/♀ symbol for a pet's gender, or nothing when unset.
class GenderIcon extends StatelessWidget {
  final PetGender? gender;
  final double size;

  const GenderIcon({super.key, required this.gender, this.size = 18});

  @override
  Widget build(BuildContext context) {
    switch (gender) {
      case PetGender.male:
        return Icon(Icons.male, size: size, color: Colors.blue.shade400);
      case PetGender.female:
        return Icon(Icons.female, size: size, color: Colors.pink.shade300);
      case null:
        return const SizedBox.shrink();
    }
  }
}
