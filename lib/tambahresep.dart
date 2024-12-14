import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
  final List<TextEditingController> _stepControllers = [TextEditingController()];
  File? _selectedRecipeImage;

  Future<void> _saveRecipe() async {
    // Validasi field wajib
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul resep harus diisi')),
      );
      return;
    }

    if (_cookTimeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lama Memasak resep harus diisi')),
      );
      return;
    }

    if (_servingsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Porsi Memasak resep harus diisi')),
      );
      return;
    }

    // Validasi bahan
    if (_ingredientControllers.isEmpty || 
        _ingredientControllers.every((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal satu bahan harus diisi')),
      );
      return;
    }

    // Validasi langkah
    if (_stepControllers.isEmpty || 
        _stepControllers.every((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal satu langkah harus diisi')),
      );
      return;
    }

    if (_selectedRecipeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto resep harus ditambahkan')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menyimpan resep.')),
      );
      return;
    }

    final ingredients = _ingredientControllers
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();
    final steps = _stepControllers
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();

    Map<String, dynamic> recipeData = {
      'title': _titleController.text.trim(),
      'servings': _servingsController.text.trim(),
      'cookTime': _cookTimeController.text.trim(),
      'ingredients': ingredients,
      'steps': steps,
    };

    if (_selectedRecipeImage != null) {
      final imagePath = await _uploadRecipeImage(_selectedRecipeImage!);
      if (imagePath == null) return;
      recipeData['imagePath'] = imagePath;
    }

    try {
      final response = await http.post(
        Uri.parse('https://resepku-production.up.railway.app/addRecipe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(recipeData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resep berhasil disimpan!')),
        );
        Navigator.pop(context);
      } else {
        final message = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan resep: $message')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan. Silakan coba lagi.')),
      );
    }
  }

  Future<String?> _uploadRecipeImage(File image) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('https://resepku-production.up.railway.app/upload-recipe-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('recipeImage', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      return jsonResponse['filePath'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengupload gambar.')),
      );
      return null;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedRecipeImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            // Check if any field has been filled
            bool hasFilledFields = _titleController.text.isNotEmpty ||
                _servingsController.text.isNotEmpty ||
                _cookTimeController.text.isNotEmpty ||
                _ingredientControllers.any((controller) => controller.text.isNotEmpty) ||
                _stepControllers.any((controller) => controller.text.isNotEmpty) ||
                _selectedRecipeImage != null;

            if (hasFilledFields) {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text(
                      'Keluar dari Halaman', 
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Anda yakin ingin keluar dari halaman ini? Perubahan tidak tersimpan',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text(
                          'Batal', 
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Dismiss dialog
                        },
                      ),
                      TextButton(
                        child: const Text(
                          'Keluar', 
                          style: TextStyle(color: Colors.orange),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Dismiss dialog
                          Navigator.of(context).pop(); // Go back to previous screen
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              // If no fields are filled, simply go back
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('Buat Resep', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _saveRecipe,
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 16),
              _buildSectionTitle('Judul'),
              _buildTextField(_titleController, '[Wajib] Judul: Sup Ayam Favorit', true),
              const SizedBox(height: 16),
              _buildSectionTitle('Porsi'),
              _buildTextField(_servingsController, '2 orang', false),
              const SizedBox(height: 16),
              _buildSectionTitle('Lama Memasak'),
              _buildTextField(_cookTimeController, '1 Jam 30 menit', false),
              const SizedBox(height: 16),
              _buildSectionTitle('Bahan-bahan'),
              ..._buildIngredientFields(),
              _buildAddButton('Bahan', _addIngredient),
              const SizedBox(height: 16),
              _buildSectionTitle('Langkah'),
              ..._buildStepFields(),
              _buildAddButton('Langkah', _addStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          image: _selectedRecipeImage != null
              ? DecorationImage(
                  image: FileImage(_selectedRecipeImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedRecipeImage == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text('[Wajib] Foto Resep', style: TextStyle(color: Colors.white)),
                  Text('Tambahkan foto akhir masakan', style: TextStyle(color: Colors.grey)),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isRequired, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          fillColor: Colors.grey[900],
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  List<Widget> _buildIngredientFields() {
    return _ingredientControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      var controller = entry.value;
      return Row(
        children: [
          Expanded(child: _buildTextField(controller, 'Bahan ${idx + 1}', false)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeIngredient(idx),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildStepFields() {
    return _stepControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      var controller = entry.value;
      return Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: Text('${idx + 1}', style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildTextField(controller, 'Langkah ${idx + 1}', false)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeStep(idx),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, color: Colors.orange),
      label: Text(label, style: const TextStyle(color: Colors.orange)),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers.removeAt(index);
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers.removeAt(index);
    });
  }
}


