import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditResepPage extends StatefulWidget {
  final int recipeId;

  const EditResepPage({super.key, required this.recipeId});

  @override
  _EditResepPageState createState() => _EditResepPageState();
}

class _EditResepPageState extends State<EditResepPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _servings = '';
  String _cookTime = '';
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _stepControllers = [];
  bool _isLoading = true;
  File? _imageFile;
  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _fetchRecipeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token found')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('https://resepku-production.up.railway.app/user/recipe-detail/own/${widget.recipeId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final recipeDetails = jsonDecode(response.body);
      setState(() {
        _title = recipeDetails['title'];
        _servings = recipeDetails['servings']?.toString() ?? '';
        _cookTime = recipeDetails['cook_time']?.toString() ?? '';
        _existingImagePath = recipeDetails['image_path'];

        final ingredients = jsonDecode(recipeDetails['ingredients']) as List;
        _ingredientControllers.addAll(
          ingredients.map((ingredient) => TextEditingController(text: ingredient)),
        );

        final steps = jsonDecode(recipeDetails['steps']) as List;
        _stepControllers.addAll(
          steps.map((step) => TextEditingController(text: step)),
        );
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch recipe details: ${response.body}')),
      );
    }
  }

  Future<void> _updateRecipe() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_ingredientControllers.isEmpty || _ingredientControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All ingredients must be filled in')),
      );
      return;
    }

    if (_stepControllers.isEmpty || _stepControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All steps must be filled in')),
      );
      return;
    }

    if (_imageFile == null && _existingImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a recipe image')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authentication token found')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('https://resepku-production.up.railway.app/editRecipe/${widget.recipeId}'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = _title;
    request.fields['servings'] = _servings;
    request.fields['cookTime'] = _cookTime;
    request.fields['ingredients'] = jsonEncode(
      _ingredientControllers.map((c) => c.text).toList(),
    );
    request.fields['steps'] = jsonEncode(
      _stepControllers.map((c) => c.text).toList(),
    );

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _imageFile!.path,
      ));
    } else if (_existingImagePath != null) {
      request.fields['existingImagePath'] = _existingImagePath!;
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update recipe: $responseBody')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Keluar dari Halaman',style: TextStyle(color: Colors.white),),
        content: const Text(
          'Apakah Anda ingin keluar dari halaman ini? Perubahan tidak tersimpan',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    ) ?? false;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Edit Resep',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPhotoSection(),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Judul Resep'),
                        const SizedBox(height: 8),
                        _buildTextFieldNoLabel(_title, (value) => _title = value),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Porsi'),
                        const SizedBox(height: 8),
                        _buildTextFieldNoLabel(_servings, (value) => _servings = value),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Waktu Memasak'),
                        const SizedBox(height: 8),
                        _buildTextFieldNoLabel(_cookTime, (value) => _cookTime = value),
                        const SizedBox(height: 24),
                        _buildDynamicFields(
                            'Bahan-bahan', _ingredientControllers, 'Tambah Bahan'),
                        const SizedBox(height: 24),
                        _buildDynamicSteps(
                            'Langkah Memasak', _stepControllers, 'Tambah Langkah'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _updateRecipe();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          image: _imageFile != null
              ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
              : _existingImagePath != null
                  ? DecorationImage(
                      image: NetworkImage('https://resepku-production.up.railway.app/uploads/$_existingImagePath'),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: _imageFile == null && _existingImagePath == null
            ? const Center(
                child: Icon(
                  Icons.camera_enhance_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextFieldNoLabel(String initialValue, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field ini tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDynamicFields(String label, List<TextEditingController> controllers, String buttonLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '$label ${index + 1}',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field ini tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      controllers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: () {
            setState(() {
              controllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add, color: Colors.orange),
          label: Text(buttonLabel, style: const TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }

  Widget _buildDynamicSteps(String label, List<TextEditingController> controllers, String buttonLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '$label ${index + 1}',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field ini tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      controllers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: () {
            setState(() {
              controllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add, color: Colors.orange),
          label: Text(buttonLabel, style: const TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}
