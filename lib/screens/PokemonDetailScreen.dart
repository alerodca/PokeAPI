import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../classes/PokemonDetail.dart';

class PokemonDetailScreen extends StatefulWidget {
  final String prevPokemonName;
  final String currentPokemonName;
  final String nextPokemonName;

  PokemonDetailScreen({required this.prevPokemonName, required this.currentPokemonName, required this.nextPokemonName});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {

  @override
  initState() {
    fetchPokemonsDetail();
  }

  List<PokemonDetail> pokemons = [];
  late PokemonDetail pokemon;
  late PokemonDetail prevPokemon;
  late PokemonDetail nextPokemon;
  String? description;
  bool showDescription = false;
  bool changePokemon = false;

  Future<List<PokemonDetail>> fetchPokemonsDetail() async {
    List<PokemonDetail> fetchedPokemons = await Future.wait([
      fetchInfoPokemonDetail(widget.prevPokemonName),
      fetchInfoPokemonDetail(widget.currentPokemonName),
      fetchInfoPokemonDetail(widget.nextPokemonName),
    ]);

    return fetchedPokemons;
  }

  Future<PokemonDetail> fetchInfoPokemonDetail(String name) async {
    String url = "https://pokeapi.co/api/v2/pokemon/$name";
    print(url);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      List<String> pokemonTipos = [];
      for (var typeEntry in parsed['types']) {
        pokemonTipos.add(typeEntry['type']['name']);
      }
      final speciesUrl = parsed['species']['url'];
      final speciesResponse = await http.get(Uri.parse(speciesUrl));
      final speciesData = json.decode(speciesResponse.body);
      final descriptions = speciesData['flavor_text_entries'];
      final spanishDescriptionX = descriptions.firstWhere(
            (entry) => entry['language']['name'] == 'en' && entry['version']['name'] == 'x',
        orElse: () => {'flavor_text': 'No disponible'},
      )['flavor_text'];
      final spanishDescriptionY = descriptions.firstWhere(
            (entry) => entry['language']['name'] == 'enº' && entry['version']['name'] == 'y',
        orElse: () => {'flavor_text': 'No disponible'},
      )['flavor_text'];
      final category = speciesData['genera'].firstWhere(
            (genus) => genus['language']['name'] == 'en',
        orElse: () => {'genus': 'No disponible'},
      )['genus'];
      final genderRate = speciesData['gender_rate'];

      String genero;
      if (genderRate == -1) {
        genero = 'Sin género';
      } else if (genderRate == 0) {
        genero = '100% hembra';
      } else if (genderRate == 8) {
        genero = '100% macho';
      } else {
        genero = 'Género variable';
      }

      final abilities = parsed['abilities']
          .map((ability) => ability['ability']['name'] as String)
          .whereType<String>()
          .toList();

      final abilityDescriptions = await getAbilityDescriptions(parsed['abilities']);

      final weaknesses = await getWeaknesses(pokemonTipos);

      final stats = <String, int>{};
      for (var statEntry in parsed['stats']) {
        final statName = statEntry['stat']['name'];
        final baseStat = statEntry['base_stat'];
        stats[statName] = baseStat;
      }

      return PokemonDetail(
        name: parsed['name'],
        id: parsed['id'],
        image: parsed['sprites']['front_default'],
        descriptionX: spanishDescriptionX,
        descriptionY: spanishDescriptionY,
        types: pokemonTipos,
        height: parsed['height'],
        weight: parsed['weight'],
        gender: genderRate,
        abilities: abilities,
        abilitiesDescription: abilityDescriptions,
        weakness: weaknesses,
        category: category,
        stats: stats,
      );

    } else {
      throw Exception('Failed to fetch Pokemon data: ${response.statusCode}');
    }
  }

  Future<List<String>> getAbilityDescriptions(List<dynamic> abilities) async {
    List<String> abilityDescriptions = [];

    for (var abilityData in abilities) {
      final abilityUrl = abilityData['ability']['url'];
      final response = await http.get(Uri.parse(abilityUrl));
      if (response.statusCode == 200) {
        final abilityDetails = jsonDecode(response.body);
        final flavorTextEntries = abilityDetails['flavor_text_entries'];
        final englishDescription = flavorTextEntries.firstWhere(
              (entry) => entry['language']['name'] == 'en',
          orElse: () => {'flavor_text': 'No available'},
        )['flavor_text'];
        abilityDescriptions.add(englishDescription);
      }
    }

    return abilityDescriptions;
  }

  Future<List<String>> getWeaknesses(List<String> types) async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/type'));
    if (response.statusCode == 200) {
      final typesData = jsonDecode(response.body)['results'];
      Map<String, List<String>> weaknessesMap = {};
      for (var typeData in typesData) {
        final typeResponse = await http.get(Uri.parse(typeData['url']));
        if (typeResponse.statusCode == 200) {
          final typeDetails = jsonDecode(typeResponse.body);
          final typeName = typeDetails['name'];
          final damageRelations = typeDetails['damage_relations'];
          final weaknesses = (damageRelations['double_damage_from'] as List<dynamic>)
              .map<String>((weakness) => weakness['name'] as String)
              .toList();
          weaknessesMap[typeName] = weaknesses;
        }
      }
      List<String> weaknesses = [];
      for (var type in types) {
        weaknesses.addAll(weaknessesMap[type] ?? []);
      }

      return weaknesses.toSet().toList();
    } else {
      throw Exception('Failed to load type data');
    }
  }

  void updatePokemonByIndex(int index) async {
    if (index == -1) {
      final newPrevPokemonDetail = await fetchInfoPokemonDetail((prevPokemon.id > 1 ? prevPokemon.id-1 : 20).toString());
      setState(() {
        nextPokemon = pokemon;
        pokemon = prevPokemon;
        prevPokemon = newPrevPokemonDetail;
        description = pokemon.descriptionX;
      });
    } else if (index == 1) {
      final newNextPokemonDetail = await fetchInfoPokemonDetail((nextPokemon.id < 20 ? nextPokemon.id+1 : 1).toString());
      setState(() {
        prevPokemon = pokemon;
        pokemon = nextPokemon;
        nextPokemon = newNextPokemonDetail;
        description = pokemon.descriptionX;
      });
    }
  }

  List<IconData> _obtenerIconos() {
    if (pokemon != null) {
      switch (pokemon.gender) {
        case -1:
          return [Icons.not_interested];
        case 0:
          return [Icons.male];
        case 8:
          return [Icons.female];
        default:
          return [Icons.male, Icons.female];
      }
    } else {
      return [];
    }
  }

  Widget _buildStatColumn(String statName, int statValue) {
    Color getColorForStat(int currentValue) {
      double percentage = currentValue / 255;
      int blue = (255 * percentage).round();
      return Color.fromRGBO(blue, blue, 255, 1);
    }

    List<Widget> statContainers = List.generate(15, (index) {
      Color color = index < (statValue / 255 * 15).round()
          ? Colors.white
          : getColorForStat(statValue);

      return Container(
        width: 35,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black),
        ),
      );
    });

    return Column(
      children: [
        Column(
          children: statContainers,
        ),
        SizedBox(height: 5),
        Text(
          statName.substring(0, 2),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumns(Map<String, int> stats) {

    List<Widget> statColumns = stats.entries.map((entry) {
      return _buildStatColumn(entry.key, entry.value);
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: statColumns,
    );
  }

  Map<String, Color> typeColors = {
    'normal': Colors.grey,
    'flying': Colors.lightBlue,
    'fire': Colors.red,
    'water': Colors.blue,
    'grass': Colors.green,
    'poison': Colors.deepPurple,
    'bug': Colors.green[800]!,
    'electric': Colors.yellow[400]!,
    'fairy': Colors.pink[100]!,
    'ground': Colors.yellow[600]!,
    'fightning': Colors.orange,
    'psychic': Colors.pink[600]!,
    'rock': Colors.yellow[800]!,
    'steel': Colors.grey[700]!,
    'ice': Colors.lightBlueAccent,
    'ghost': Colors.deepPurple
  };

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          "Pokemon Detail",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<PokemonDetail>>(
        future: !changePokemon ? fetchPokemonsDetail() : null,
        builder: (context,snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: mediaQuery.height * 0.2,
                      width: mediaQuery.width * 0.4,
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: mediaQuery.height * 0.05,),
                    Text(
                      "Fetching Pokemons Details",
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                      ),
                    )
                  ],
                )
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                ),
              ),
            );
          } else {
            changePokemon = true;
            pokemons = snapshot.data!;
            prevPokemon = pokemons.first;
            pokemon = pokemons[1];
            nextPokemon = pokemons.last;
            description = pokemon.descriptionX;
            List<IconData> iconos = _obtenerIconos();
            return Container(
              height: mediaQuery.height,
              color: Colors.grey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.05,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => updatePokemonByIndex(-1),
                          child: Container(
                            color: Colors.grey[300],
                            width: MediaQuery.of(context).size.width * 0.499,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                      Icons.arrow_back
                                  ),
                                  Text(
                                    prevPokemon?.name ?? "",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    "#000${prevPokemon?.id ?? ""}",
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          width: MediaQuery.of(context).size.width * 0.001,
                        ),
                        GestureDetector(
                          onTap: () => updatePokemonByIndex(1),
                          child: Container(
                            color: Colors.grey[300],
                            width: MediaQuery.of(context).size.width * 0.499,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    nextPokemon?.name ?? "",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    "#000${nextPokemon?.id ?? ""}",
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Icon(
                                      Icons.arrow_forward
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.07,
                    child: Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            pokemon!.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "#000${pokemon!.id}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.40,
                      child: Card(
                        child: Row(
                          children: [
                            Container(
                              width: mediaQuery.width * 0.4,
                              child: Image.network(
                                pokemon.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Container(
                              width: mediaQuery.width * 0.53,
                              padding: EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(description! ?? ''),
                                  Row(
                                    children: [
                                      Text("Versions: "),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            description = pokemon?.descriptionX;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.catching_pokemon,
                                          color: Colors.redAccent,
                                          size: 25,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            description = pokemon?.descriptionY;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.catching_pokemon,
                                          color: Colors.blue,
                                          size: 25,
                                        ),
                                      )
                                    ],
                                  ),
                                  Container(
                                    height: mediaQuery.height * 0.17,
                                    width: mediaQuery.width * 0.5,
                                    child: Card(
                                      color: !showDescription ? Colors.lightBlue: Colors.grey[800],
                                      child: !showDescription ?
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                "Height:",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                pokemon!.height.toString(),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                "Weight:",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                pokemon!.weight.toString(),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                "Gender:",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: iconos.map((icono) => Icon(icono, color: Colors.white,)).toList(),
                                              )
                                            ],
                                          ),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                "Category: ",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                pokemon.category.split(' ').first,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                "Abilities: ",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                pokemon.abilities.first,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showDescription = true;
                                                  });
                                                },
                                                icon: Icon(
                                                    Icons.question_mark),
                                                color: Colors.white,
                                                iconSize: 20,
                                              )
                                            ],
                                          ),
                                        ],
                                      ) :
                                      Column(
                                        children: [
                                          Align(
                                            child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showDescription = false;
                                                  });
                                                },
                                                icon: Icon(
                                                  Icons.disabled_by_default_outlined,
                                                  color: Colors.white,
                                                )
                                            ),
                                            alignment: Alignment.topRight,
                                          ),
                                          Text(
                                            pokemon.abilitiesDescription.first,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                  ),
                  Container(
                    height: mediaQuery.height * 0.23,
                    width: mediaQuery.width * 0.9,
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Stats",
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                            ),
                          ),
                          _buildStatColumns(pokemon.stats),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: mediaQuery.width * 0.8,
                    height: mediaQuery.height * 0.1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Type: ",
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: pokemon.types.map((type) {
                                Color? color = typeColors[type];
                                return Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color ?? Colors.grey,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(fontSize: 10.0, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Weakness: ",
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: pokemon.weakness.map((type) {
                                Color? color = typeColors[type];
                                return Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color ?? Colors.grey,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(fontSize: 10.0, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        },
      ),
    );
  }
}


