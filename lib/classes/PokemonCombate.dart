class PokemonCombate {
  String name;
  int id;
  String image;
  String backImage;
  int base_experience;
  int gender;
  String gifFront;
  String gifBack;
  List<String> moves;
  List<String> types;
  List<String> weakness;

  PokemonCombate({
    required this.name,
    required this.id,
    required this.image,
    required this.backImage,
    required this.gender,
    required this.gifFront,
    required this.gifBack,
    required this.base_experience,
    required this.moves,
    required this.types,
    required this.weakness,
  });
}