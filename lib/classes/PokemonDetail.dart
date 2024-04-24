class PokemonDetail {
  final String name;
  final int id;
  final String image;
  final String descriptionX;
  final String descriptionY;
  final List<String> types;
  final int height;
  final int weight;
  final int gender;
  final List<String> abilities;
  final List<String> abilitiesDescription;
  final List<String> weakness;
  final String category;
  final Map<String, int> stats;

  PokemonDetail({
    required this.name,
    required this.id,
    required this.image,
    required this.descriptionX,
    required this.descriptionY,
    required this.types,
    required this.height,
    required this.weight,
    required this.gender,
    required this.abilities,
    required this.abilitiesDescription,
    required this.weakness,
    required this.category,
    required this.stats,
  });
}