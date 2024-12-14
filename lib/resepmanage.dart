import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'editresep.dart';  

class ResepManagePage extends StatefulWidget {
  final int id;
  final String source;

  const ResepManagePage({super.key, required this.id, required this.source});

  @override
  State<ResepManagePage> createState() => _ResepManagePageState();
}

class _ResepManagePageState extends State<ResepManagePage> with WidgetsBindingObserver {
  Map<String, dynamic>? _recipeDetails;
  bool _isLoading = true;
  final bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchRecipeDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchRecipeDetails();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if this page is being returned to
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _fetchRecipeDetails();
    }
  }

  Future<void> _fetchRecipeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token found')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String source = '';
    if (widget.source == 'Resepmu') {
      source = 'own';
    } else if (widget.source == 'Tersimpan') {
      source = 'favorite';
    } else if (widget.source == 'Diterbitkan') {
      source = 'published';
    } else {
      return;
    }

    String endpoint = 'https://resepku-production.up.railway.app/user/recipe-detail/$source/${widget.id}';

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _recipeDetails = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch recipe details: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch recipe details: $e')),
      );
    }
  }

  void _shareRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('currentUserId');  // Mengambil userId yang sudah disimpan

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token or user ID found')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://resepku-production.up.railway.app/user/share-recipe/${widget.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,  // Kirimkan userId ke server
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe shared successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share recipe: ${response.body}')),
      );
    }
  }


  void _deleteRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('currentUserId');  // Mengambil userId yang sudah disimpan

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token or user ID found')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('https://resepku-production.up.railway.app/user/delete-recipe/${widget.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,  // Kirimkan userId ke server
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted successfully')),
      );
      // Kembali ke halaman sebelumnya setelah berhasil menghapus
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recipe: ${response.body}')),
      );
    }
  }

  void _unshareRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('currentUserId');

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token or user ID found')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('https://resepku-production.up.railway.app/user/unshare-recipe/${widget.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe unshared successfully')),
      );
      Navigator.pop(context);  // Kembali ke halaman sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unshare recipe: ${response.body}')),
      );
    }
  }

  void _unfavRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('currentUserId'); // Mengambil userId yang sudah disimpan

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token or user ID found')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('https://resepku-production.up.railway.app/user/unfav-recipe/${widget.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId, // Kirimkan userId ke server
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe unfav successfully')),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfav recipe: ${response.body}')),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Bagikan'),
              onTap: () {
                // Menampilkan dialog konfirmasi untuk bagikan resep
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Konfirmasi', 
                      style: TextStyle(color: Colors.white),
                    ),
                      content: const Text('Apakah Anda ingin membagikan resep ini?',
                      style: TextStyle(color: Colors.white70),
                    ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Menutup dialog
                          },
                          child: const Text('Tidak', 
                          style: TextStyle(color: Colors.white),
                        ),
                        ),
                        TextButton(
                          onPressed: () {
                            _shareRecipe(); // Menjalankan fungsi untuk membagikan resep
                            Navigator.pop(context); // Menutup dialog
                            Navigator.pop(context); // Menutup bottom sheet
                          },
                          child: const Text('Ya', 
                          style: TextStyle(color: Colors.orange),
                        ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Hapus Resep'),
              onTap: () {
                // Menampilkan dialog konfirmasi untuk hapus resep
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Konfirmasi', 
                      style: TextStyle(color: Colors.white),
                    ),
                      content: const Text('Apakah Anda yakin ingin menghapus resep ini?',
                      style: TextStyle(color: Colors.white70),
                    ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Menutup dialog
                          },
                          child: const Text('Tidak', 
                          style: TextStyle(color: Colors.white),
                        ),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteRecipe(); // Menjalankan fungsi untuk menghapus resep
                            Navigator.pop(context); // Menutup dialog
                            Navigator.pop(context); // Menutup bottom sheet
                          },
                          child: const Text('Ya', 
                          style: TextStyle(color: Colors.orange),
                        ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context); // Menutup bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditResepPage(recipeId: widget.id),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }


  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.stop_circle),
              title: const Text('Berhenti Bagikan'),
              onTap: () {
                // Menampilkan dialog konfirmasi
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Konfirmasi',style: TextStyle(color: Colors.white),
                    ),
                      content: const Text('Apakah Anda ingin berhenti membagikan resep?',
                      style: TextStyle(color: Colors.white70),
                    ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // Menutup dialog dan tidak melakukan apa-apa
                            Navigator.pop(context);
                          },
                          child: const Text('Tidak', 
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Menutup dialog dan memanggil _unshareRecipe
                            _unshareRecipe();
                            Navigator.pop(context); // Menutup dialog
                            Navigator.pop(context); // Menutup bottom sheet
                          },
                          child: const Text('Ya', 
                          style: TextStyle(color: Colors.orange),
                        ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }


  List<Widget> _buildIngredientsList() {
    if (_recipeDetails == null || _recipeDetails!['ingredients'] == null) {
      return [];
    }

    List<dynamic> ingredients = _recipeDetails!['ingredients'] is String
        ? jsonDecode(_recipeDetails!['ingredients'])
        : _recipeDetails!['ingredients'];

    return ingredients.map((ingredient) {
      return _buildIngredientItem(ingredient.toString());
    }).toList();
  }

  List<Widget> _buildStepsList() {
    if (_recipeDetails == null || _recipeDetails!['steps'] == null) {
      return [];
    }

    List<dynamic> steps = _recipeDetails!['steps'] is String
        ? jsonDecode(_recipeDetails!['steps'])
        : _recipeDetails!['steps'];

    return steps.asMap().entries.map((entry) {
      int index = entry.key;
      String step = entry.value.toString();
      return _buildStepItem(index + 1, step);
    }).toList();
  }

  Widget _buildIngredientItem(String ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.grey, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.orange,
            child: Text('$stepNumber',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipeDetails == null
              ? const Center(
                  child: Text('Recipe not found',
                      style: TextStyle(color: Colors.white)))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      expandedHeight: 300,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          _recipeDetails!['title'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://resepku-production.up.railway.app/uploads/${_recipeDetails!['image_path']}',
                              fit: BoxFit.cover,
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
                            ),
                          ],
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      actions: [
                        if (widget.source == 'Resepmu')
                          IconButton(
                            icon: const Icon(Icons.more_horiz, color: Colors.white),
                            onPressed: _showMoreOptions,
                          ),
                        if (widget.source == 'Tersimpan')
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              bool? confirmUnfavorite = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text('Hapus dari Favorit',style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text('Anda yakin ingin menghapus resep ini dari favorit?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Tidak', 
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Ya', 
                                        style: TextStyle(color: Colors.orange),),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmUnfavorite == true) {
                                _unfavRecipe();
                              }
                            },
                          ),
                        if (widget.source == 'Diterbitkan')
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white),
                            onPressed: _showShareOptions,
                          ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recipeDetails!['author'] ?? 'Unknown Author',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.grey, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${_recipeDetails!['cook_time']}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Bahan-bahan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ..._buildIngredientsList(),
                            const SizedBox(height: 16),
                            const Text(
                              'Langkah',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ..._buildStepsList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
