import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../classes/Pokemon.dart';
import '../classes/PokemonCombate.dart';

class CombatePokemon extends StatefulWidget {
  final Pokemon firstPokemon;
  final Pokemon secondPokemon;

  CombatePokemon({required this.firstPokemon, required this.secondPokemon});

  @override
  State<CombatePokemon> createState() => _CombatePokemonState();
}

class _CombatePokemonState extends State<CombatePokemon> {
  Random random = new Random();
  late int levelFirstPokemon, levelSecondPokemon;
  late PokemonCombate firstPokemon;
  late PokemonCombate secondPokemon;
  late String backSecondPokemon;
  bool showAttacks = false;
  late int psFirstPokemon, psSecondPokemon;

  @override
  void initState() {
    super.initState();
    levelSecondPokemon = random.nextInt(100) + 1;
    levelFirstPokemon = random.nextInt(7) + levelSecondPokemon;
    _fetchPokemonData();
  }

  Future<void> _fetchPokemonData() async {
    PokemonCombate first = await fetchPokemonCombate(widget.firstPokemon.id);
    PokemonCombate second = await fetchPokemonCombate(widget.secondPokemon.id);
    setState(() {
      firstPokemon = first;
      psFirstPokemon = firstPokemon.base_experience;
      secondPokemon = second;
      psSecondPokemon = secondPokemon.base_experience;
    });
  }

  Future<PokemonCombate> fetchPokemonCombate(int id) async {
    String url = "https://pokeapi.co/api/v2/pokemon/$id";
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
      final genderRate = speciesData['gender_rate'];

      int baseExperience = parsed['base_experience'];

      List<dynamic> movesData = parsed['moves'];
      List<String> moves = movesData.map((move) => move['move']['name'] as String).toList();
      String backImage = parsed['sprites']['back_default'];

      List<String> weaknesses = await getWeaknesses(pokemonTipos); // Obtener las debilidades

      return PokemonCombate(
        name: parsed['name'],
        id: parsed['id'],
        image: parsed['sprites']['front_default'],
        base_experience: baseExperience,
        backImage: backImage,
        gifBack: parsed['sprites']['other']['showdown']['back_default'],
        types: pokemonTipos,
        moves: moves,
        gender: genderRate,
        gifFront: parsed['sprites']['other']['showdown']['front_default'],
        weakness: weaknesses, // Agregar las debilidades al objeto PokemonCombate
      );
    } else {
      throw Exception('Failed to fetch Pokemon data: ${response.statusCode}');
    }
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


  Icon getPokemonSex(int genderRate, int level) {

    switch (genderRate) {
      case -1:
        return Icon(Icons.circle, color: Colors.black, size: 18,);
      case 0:
        return Icon(Icons.female, color: Colors.black, size: 18,);
      case 8:
        return Icon(Icons.male, color: Colors.black, size: 18,);
      default:
        if (level % 2 == 0) {
          return Icon(Icons.male, color: Colors.black, size: 18,);
        } else {
          return Icon(Icons.female, color: Colors.black, size: 18,);
        }
    }
  }

  void attackPokemon(String nameOfensive, String nameDefensive, String attack) {
    print("$nameOfensive ataca a $nameDefensive con $attack");
  }

  Widget buildAttackButtonsForSecondPokemon() {
    List<String> moves = secondPokemon.moves;
    int numMoves = moves.length;

    if (numMoves >= 4) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  print("Attack with ${moves[0]}");
                },
                child: Text(
                  moves[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 8,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print("Attack with ${moves[1]}");
                },
                child: Text(
                  moves[1],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  print("Attack with ${moves[2]}");
                },
                child: Text(
                  moves[2],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 8,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print("Attack with ${moves[3]}");
                },
                child: Text(
                  moves[3],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (numMoves == 3) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Lógica para atacar con el primer movimiento
                  print("Attack with ${moves[0]}");
                },
                child: Text(
                  moves[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  print("Attack with ${moves[1]}");
                },
                child: Text(
                  moves[1],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 8,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print("Attack with ${moves[2]}");
                },
                child: Text(
                  moves[2],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (numMoves == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              print("Attack with ${moves[0]}");
            },
            child: Text(
              moves[0],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
                fontSize: 8,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print("Attack with ${moves[1]}");
            },
            child: Text(
              moves[1],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
                fontSize: 8,
              ),
            ),
          ),
        ],
      );
    } else if (numMoves == 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              print("Attack with ${moves[0]}");
            },
            child: Text(
              moves[0],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
                fontSize: 8,
              ),
            ),
          ),
        ],
      );
    } else {
      return Text(
        "No moves available",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text(
          "Combate Pókemon",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/_bd95f220-9883-4bbf-87e7-46e52d3c0461.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        height: mediaQuery.height,
        width: mediaQuery.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              height: mediaQuery.height * 0.4,
              width: mediaQuery.width * 0.97,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Container(
                        width: mediaQuery.width * 0.5,
                        height: mediaQuery.height * 0.1,
                        child: Card(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    firstPokemon.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  getPokemonSex(firstPokemon.gender, levelFirstPokemon),
                                  Text(
                                    "Nv: ${levelFirstPokemon}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "PS",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900]
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.38,
                                    height: MediaQuery.of(context).size.height * 0.015,
                                    color: Colors.green[800],
                                    child: Center(
                                      child: Text(
                                        "${psFirstPokemon}/${firstPokemon.base_experience} PS",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  Container(
                    width: mediaQuery.width * 0.4,
                    child: Image.network(
                      firstPokemon.gifFront,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: mediaQuery.height * 0.4,
              width: mediaQuery.width * 0.97,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: mediaQuery.width * 0.4,
                    child: Image.network(
                      secondPokemon.gifBack,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        width: mediaQuery.width * 0.5,
                        height: mediaQuery.height * 0.15,
                        child: Card(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    secondPokemon.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  getPokemonSex(secondPokemon.gender, levelSecondPokemon),
                                  Text(
                                    "Nv: ${levelSecondPokemon}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "PS",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900]
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.38,
                                    height: MediaQuery.of(context).size.height * 0.015,
                                    color: Colors.green[800],
                                    child: Center(
                                      child: Text(
                                        "${psSecondPokemon}/${secondPokemon.base_experience} PS",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (showAttacks) {
                                      showAttacks = false;
                                    } else {
                                      showAttacks = true;
                                    }
                                  });
                                },
                                child:  Text(
                                  "¡ATACAR!",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.red
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: showAttacks,
                        child: Container(
                          height: mediaQuery.height * 0.15,
                          width: mediaQuery.width * 0.5,
                          child: buildAttackButtonsForSecondPokemon()
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
