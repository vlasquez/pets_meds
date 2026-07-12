/// Common dog breeds. Stored in SQLite by enum name.
enum DogBreed {
  beagle,
  borderCollie,
  boxer,
  bulldog,
  chihuahua,
  cockerSpaniel,
  dachshund,
  dobermann,
  frenchBulldog,
  germanShepherd,
  goldenRetriever,
  greatDane,
  husky,
  labrador,
  poodle,
  pug,
  rottweiler,
  schnauzer,
  shihTzu,
  yorkshireTerrier,
  mixed,
  other,
}

/// Common cat breeds. Stored in SQLite by enum name.
enum CatBreed {
  abyssinian,
  angora,
  bengal,
  britishShorthair,
  burmese,
  domesticShorthair,
  himalayan,
  maineCoon,
  persian,
  ragdoll,
  russianBlue,
  scottishFold,
  siamese,
  sphynx,
  mixed,
  other,
}

/// Parses a stored breed name back to its enum, per species.
DogBreed? dogBreedFromName(String? name) {
  if (name == null) return null;
  try {
    return DogBreed.values.byName(name);
  } on ArgumentError {
    return null;
  }
}

CatBreed? catBreedFromName(String? name) {
  if (name == null) return null;
  try {
    return CatBreed.values.byName(name);
  } on ArgumentError {
    return null;
  }
}
