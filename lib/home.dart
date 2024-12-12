import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'search.dart'; 
import 'add.dart'; 
import 'favorite.dart'; 
import 'profile.dart'; 
import 'resep.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const SearchPage(),
    const AddPage(),
    const FavoritePage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Resep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white60,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _fetchAllRecipes();
  }

  Future<void> _fetchAllRecipes([String searchKeyword = '']) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kirim pencarian ke backend
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/recipes?search=$searchKeyword'),
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
              'cookTime': '${item['cook_time']} mins',
              'ingredients': ingredientsList,
              'steps': stepsList,
              'userId': item['user_id'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recipes: $e')),
      );
    }
  }



  Future<void> _fetchCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('currentUserId');
    });
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
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      _fetchAllRecipes(value);  // Memanggil fungsi pencarian saat teks berubah
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari resep...',
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
                const Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Semua Resep',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recipes.isEmpty
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
                                      imageUrl: 'http://10.0.2.2:3000/uploads/${recipe['imagePath']}',
                                      cookTime: recipe['cookTime'],
                                      ingredients: recipe['ingredients'],
                                      steps: recipe['steps'],
                                      recipeAuthorId: recipe['userId'], // Assuming you add this to your recipe data
                                      currentUserId: _currentUserId ?? 0,
                                      recipeId: recipe['id'], // You'll need to manage this in your login/state management
                                    ),
                                  ),
                                );
                              },
                              child: RecipeCard(
                                title: recipe['title'],
                                timeAgo: recipe['cookTime'],
                                imageUrl: 'http://10.0.2.2:3000/uploads/${recipe['imagePath']}',
                                author: recipe['author'],
                                likes: 0, // Default atau bisa tambahkan field
                                hearts: 0,
                                claps: 0,
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

class RecipeCard extends StatelessWidget {
  final String title;
  final String timeAgo;
  final String imageUrl;
  final String author;
  final int likes;
  final int hearts;
  final int claps;

  const RecipeCard({
    super.key,
    required this.title,
    required this.timeAgo,
    required this.imageUrl,
    required this.author,
    required this.likes,
    required this.hearts,
    required this.claps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              imageUrl,
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
                  author,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  timeAgo,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}