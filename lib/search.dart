import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';  // Import the RecipeCard from home.dart
import 'resep.dart'; // Import RecipeDetailPage

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _recipes = [];
  bool _isSearching = false;

  // Data bahan populer dengan gambar dari aset
  final List<Map<String, String>> bahanPopuler = [
    {
      'imageUrl': 'assets/images/tomat.jpg',
      'title': 'Tomat',
    },
    {
      'imageUrl': 'assets/images/labu.jpeg',
      'title': 'Labu siam',
    },
    {
      'imageUrl': 'assets/images/bawang.jpg',
      'title': 'Bawang bombay',
    },
    {
      'imageUrl': 'assets/images/kentang.jpeg',
      'title': 'Kentang',
    },
    {
      'imageUrl': 'assets/images/terong.jpg',
      'title': 'Terong',
    },
    {
      'imageUrl': 'assets/images/buncis.jpg',
      'title': 'Buncis',
    },
    {
      'imageUrl': 'assets/images/kencur.jpeg',
      'title': 'Kencur',
    },
    {
      'imageUrl': 'assets/images/daging.jpeg',
      'title': 'Ayam',
    },
  ];

  Future<void> _searchRecipes(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://resepku-production.up.railway.app/recipes?search=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _recipes = data.map((item) {
            List<String> ingredientsList = List<String>.from(jsonDecode(item['ingredients']));
            List<String> stepsList = List<String>.from(jsonDecode(item['steps']));

            return {
              'id': item['id'],
              'title': item['title'],
              'imagePath': item['image_path'],
              'author': item['username'],
              'cookTime': 'Cook Time : ${item['cook_time']}',
              'ingredients': ingredientsList,
              'steps': stepsList,
              'userId': item['user_id'],
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recipes: $e')),
      );
    }
  }

  void _searchByIngredient(String ingredient) {
    _searchController.text = ingredient;
    _searchRecipes(ingredient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50), 
            Row(
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  color: Colors.orange,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _searchRecipes(value);
                      } else {
                        setState(() {
                          _recipes.clear();
                          _isSearching = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari resep atau bahan...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.search, color: Colors.white60),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // const Icon(
                //   Icons.tune,
                //   color: Colors.white,
                //   size: 28,
                // ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Conditional title based on search state
            Text(
              _isSearching ? 'Resep Dan Bahan Terkait' : 'Bahan Populer',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (!_isSearching) 
              const Text(
                'Diperbarui 04.22',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: _isSearching
                  ? (_recipes.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada resep ditemukan',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    builder: (context) => RecipeDetailPage(
                                      title: recipe['title'],
                                      author: recipe['author'],
                                      imageUrl: 'https://resepku-production.up.railway.app/uploads/${recipe['imagePath']}',
                                      cookTime: recipe['cookTime'],
                                      ingredients: recipe['ingredients'],
                                      steps: recipe['steps'],
                                      recipeAuthorId: recipe['userId'],
                                      currentUserId: 0, // You might want to pass actual user ID
                                      recipeId: recipe['id'],
                                    ),
                                  ),
                                );
                              },
                              child: RecipeCard(
                                title: recipe['title'],
                                timeAgo: recipe['cookTime'],
                                imageUrl: 'https://resepku-production.up.railway.app/uploads/${recipe['imagePath']}',
                                author: recipe['author'],
                              ),
                            );
                          },
                        ))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 10, 
                        mainAxisSpacing: 10, 
                        childAspectRatio: 1.5, 
                      ),
                      itemCount: bahanPopuler.length, 
                      itemBuilder: (context, index) {
                        final bahan = bahanPopuler[index];
                        return GestureDetector(
                          onTap: () => _searchByIngredient(bahan['title']!),
                          child: BahanCard(
                            imageUrl: bahan['imageUrl']!,
                            title: bahan['title']!,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black, 
    );
  }
}

class BahanCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const BahanCard({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 150, 
        height: 150, 
        child: Stack(
          children: [
            Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Center( 
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, 
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}