import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'resepmanage.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;

  // Selected category state
  String _selectedCategory = "Resepmu";

  @override
  void initState() {
    super.initState();
    _fetchRecipesByCategory(_selectedCategory);
  }

  Future<void> _fetchRecipesByCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint('Token: $token');

    try {
      String endpoint;
      if (category == 'Resepmu') {
        endpoint = 'http://10.0.2.2:3000/user/own-recipes';
      } else if (category == 'Tersimpan') {
        endpoint = 'http://10.0.2.2:3000/user/favorite-recipes';
      } else if (category == 'Diterbitkan') {
        endpoint = 'http://10.0.2.2:3000/user/published-recipes';
      } else {
        return;
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _recipes = data.map((item) => {
                'id': item['id'],
                'title': item['title'],
                'imagePath': item['image_path'],
                'cookTime': item['cook_time'], // Tambahkan cook time
                'author': item['author'], // Tambah
                'source': category,
              }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load $category recipes');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load $category recipes: $e')),
      );
    }
  }

  Widget _buildButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.black,
        side: BorderSide(
          color: isSelected ? Colors.orange : Colors.white,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.black,
    ));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const Text(
                'Koleksi Resep',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildButton(
                    text: "Resepmu",
                    isSelected: _selectedCategory == "Resepmu",
                    onPressed: () {
                      setState(() {
                        _selectedCategory = "Resepmu";
                        _isLoading = true;
                      });
                      _fetchRecipesByCategory("Resepmu");
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildButton(
                    text: "Tersimpan",
                    isSelected: _selectedCategory == "Tersimpan",
                    onPressed: () {
                      setState(() {
                        _selectedCategory = "Tersimpan";
                        _isLoading = true;
                      });
                      _fetchRecipesByCategory("Tersimpan");
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildButton(
                    text: "Diterbitkan",
                    isSelected: _selectedCategory == "Diterbitkan",
                    onPressed: () {
                      setState(() {
                        _selectedCategory = "Diterbitkan";
                        _isLoading = true;
                      });
                      _fetchRecipesByCategory("Diterbitkan");
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recipes.isEmpty
                        ? const Center(
                            child: Text(
                              'No recipes found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: _recipes.length,
                            itemBuilder: (context, index) {
                              final recipe = _recipes[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResepManagePage(
                                        id: recipe['id'] ?? 4, // Pass the recipe ID
                                        source: _selectedCategory,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: Colors.grey[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.network(
                                          'http://10.0.2.2:3000/uploads/${recipe['imagePath']}',
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recipe['title'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'By: ${recipe['author']}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Cook Time: ${recipe['cookTime']}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
      appBar: null,
    );
  }
}
