import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokemonapi/screens/PokemonDetailScreen.dart';
import '../classes/Pokemon.dart';
import '../classes/PokemonDetail.dart';
import 'CombatePokemon.dart';

class PokemonHome extends StatefulWidget {
  const PokemonHome({super.key});

  @override
  State<PokemonHome> createState() => _PokemonHomeState();
}

class _PokemonHomeState extends State<PokemonHome> {

  int pokemonsToShow = 20;
  List<int> selectedCardIndexes = [];
  final items = ["Lowest Number (First)", "Highest Number (First)", "A-Z", "Z-A"];
  String dropdownValue = 'Lowest Number (First)';
  bool successData = false;
  late List<Pokemon> pokemons;
  bool _dataLoaded = false;

  Map<String, Color> typeColors = {
    'normal': Colors.grey,
    'flying' : Colors.lightBlue,
    'fire': Colors.red,
    'water': Colors.blue,
    'grass' : Colors.green,
    'poison' : Colors.deepPurple,
    'bug' : Colors.green[800]!,
    'electric' : Colors.yellow[400]!,
    'fairy' : Colors.pink[100]!,
    'ground' : Colors.yellow[600]!,
    'fightning' : Colors.orange,
    'psychic' : Colors.pink[600]!,
    'rock' : Colors.yellow[800]!,
    'steel' : Colors.grey[700]!,
    'ice' : Colors.lightBlueAccent,
    'ghost' : Colors.deepPurple
  };

  Future<List<String>> fetchPokemonURL() async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=20'));
    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final results = parsed['results'] as List;
      return results.map((pokemon) => pokemon['url'].toString()).toList();
    } else {
      throw Exception('Failed to load Pokemon URLs');
    }
  }

  Future<List<Pokemon>> fetchPokemons() async {
    try {
      final List<String> urls = await fetchPokemonURL();
      final List<Pokemon> fetchedPokemons = [];

      for (String url in urls) {
        final Pokemon pokemon = await fetchPokemonInfo(url);
        fetchedPokemons.add(pokemon);
      }

      return fetchedPokemons;
    } catch (e) {
      throw Exception('Failed to fetch pokemons: $e');
    }
  }

  Future<Pokemon> fetchPokemonInfo(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<String> pokemonTypes = [];
        for (var typeEntry in parsed['types']) {
          pokemonTypes.add(typeEntry['type']['name']);
        }

        final speciesUrl = parsed['species']['url'];
        final speciesResponse = await http.get(Uri.parse(speciesUrl));
        if (speciesResponse.statusCode == 200) {
          final speciesParsed = jsonDecode(speciesResponse.body);
          final genderRate = speciesParsed['gender_rate'];

          print("Pokemon -> ${parsed['name']}, id -> ${parsed['id']}");

          return Pokemon(
            name: parsed['name'],
            id: parsed['id'],
            image: parsed['sprites']['front_default'],
            types: pokemonTypes,
          );
        } else {
          throw Exception('Failed to load species data');
        }
      } else {
        throw Exception('Failed to load Pokemon data');
      }
    } catch (e) {
      throw Exception('Failed to fetch pokemon info: $e');
    }
  }

  void shufflePokemons() {
    final random = Random();
    pokemons.shuffle(random);
    setState(() {});
  }

  void sortPokemons(String value) {
    setState(() {
      dropdownValue = value;
      switch (dropdownValue) {
        case 'Lowest Number (First)':
          pokemons.sort((a, b) => a.id.compareTo(b.id));
          break;
        case 'Highest Number (First)':
          pokemons.sort((a, b) => b.id.compareTo(a.id));
          break;
        case 'A-Z':
          pokemons.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Z-A':
          pokemons.sort((a, b) => b.name.compareTo(a.name));
          break;
      }
    });
  }

  void navigateToPokemonDetail(BuildContext context, int index) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(
            currentPokemonName: pokemons[index].name,
            prevPokemonName: pokemons[index].id > 1 ? pokemons[index-1].name : pokemons.last.name,
            nextPokemonName: pokemons[index].id < 20 ? pokemons[index+1].name : pokemons.first.name,
        )
      ),
    );
  }

  void onDoubleTap(int index) {
    setState(() {
      if (selectedCardIndexes.length < 2) {
        if (selectedCardIndexes.contains(index)) {
          selectedCardIndexes.remove(index);
          print("Pokemon Eliminado 1- ${pokemons[index].name}");
        } else {
          selectedCardIndexes.add(index);
          print("Pokemon Añadido 1- ${pokemons[index].name}");
        }
      } else {
        print("Pokemon Añadido 2- ${pokemons[index].name}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CombatePokemon(
              firstPokemon: pokemons[selectedCardIndexes[0]],
              secondPokemon: pokemons[selectedCardIndexes[1]],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: const Center(
          child: Text(
            "PokéAPI",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: mediaQuery.height * 0.088,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (successData == true) {
                        shufflePokemons();
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.recycling, color: Colors.white),
                      Text(
                        "Surprise Me!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                  ),
                ),
                Text(
                  "Sort By",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                DropdownButton(
                  value: dropdownValue,
                  icon: Icon(Icons.keyboard_arrow_down),
                  items: items.map((String item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.catching_pokemon),
                          SizedBox(width: 10),
                          Text(
                            item,
                            style: TextStyle(
                                fontSize: 11
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      if (successData == true) {
                        dropdownValue = newValue!;
                        sortPokemons(dropdownValue);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          Container(
            height: mediaQuery.height * 0.7,
            child: FutureBuilder<List<Pokemon>>(
                future: _dataLoaded ? null : fetchPokemons(),
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
                            "Fetching Pokemons",
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
                    if (!_dataLoaded) {
                      pokemons = snapshot.data!;
                      successData = true;
                      _dataLoaded = true;
                    }
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 10.0,
                      ),
                      itemCount: pokemonsToShow,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => navigateToPokemonDetail(context, index),
                          onDoubleTap: () {
                            onDoubleTap(index);
                          },
                          child: Card(
                            color: selectedCardIndexes.contains(index) ? Colors.green : Colors.white,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  height: mediaQuery.height * 0.13,
                                  width: 90,
                                  child: Image.network(
                                    pokemons[index].image,
                                  ),
                                ),
                                Text(
                                  "Num Pokédex: #00${pokemons[index].id.toString()}",
                                  style: TextStyle(fontSize: 13.0, color: Colors.grey),
                                ),
                                Text(
                                  pokemons[index].name.toString().toUpperCase(),
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 14.0, color: Colors.black),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Type: ",
                                      style: TextStyle(fontSize: 12.0, color: Colors.black),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: pokemons[index].types.map((type) {
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
                                              style: TextStyle(fontSize: 7.0, color: Colors.white),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                }
            ),
          ),
          Container(
              height: mediaQuery.height * 0.088,
              padding: EdgeInsets.only(bottom: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (successData == true) {
                          pokemonsToShow += 20;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Load More Pokemos',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
          ),
        ],
      )
    );
  }
}