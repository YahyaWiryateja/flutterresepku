import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'search.dart'; 
import 'add.dart'; 
import 'favorite.dart'; 
import 'profile.dart'; 
import 'resep.dart';

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
  String _sortOrder = 'newest';

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
        Uri.parse('https://resepku-production.up.railway.app/recipes?search=$searchKeyword'),
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

          // Sort recipes based on _sortOrder
          if (_sortOrder == 'newest') {
            _recipes.sort((a, b) => b['id'].compareTo(a['id']));
          } else if (_sortOrder == 'oldest') {
            _recipes.sort((a, b) => a['id'].compareTo(b['id']));
          }

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

  void _showSortingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Terbaru', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _sortOrder = 'newest';
                  _fetchAllRecipes(); // Reload recipes
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Terlama', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _sortOrder = 'oldest';
                  _fetchAllRecipes(); // Reload recipes
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
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
                GestureDetector(
                  onTap: _showSortingOptions,
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 28,
                  ),
                )
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
                                      imageUrl: 'https://resepku-production.up.railway.app/uploads/${recipe['imagePath']}',
                                      cookTime: recipe['cookTime'],
                                      ingredients: recipe['ingredients'],
                                      steps: recipe['steps'],
                                      recipeAuthorId: recipe['userId'],
                                      currentUserId: _currentUserId ?? 0,
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

  const RecipeCard({
    super.key,
    required this.title,
    required this.timeAgo,
    required this.imageUrl,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian gambar
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author
                Text(
                  author,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                // Judul dengan ukuran lebih besar
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Spacer untuk memberikan ruang fleksibel
          Expanded(
            flex: 2, // Semakin tinggi angkanya, semakin besar ruang yang diberikan
            child: Container(),
          ),
          // Bagian cook time di bawah
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              timeAgo,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}