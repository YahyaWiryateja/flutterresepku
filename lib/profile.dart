import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'welcome.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  Map<String, dynamic> _userProfile = {};
  File? _selectedImage;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idCookpadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _userProfile = json.decode(response.body);
          _usernameController.text = _userProfile['username'] ?? '';
          _emailController.text = _userProfile['email'] ?? '';
          _idCookpadController.text = _userProfile['id_cookpad'] ?? '';
        });
      } else {
        _showErrorSnackBar('Failed to load profile');
      }
    } catch (error) {
      _showErrorSnackBar('Error fetching profile');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'id_cookpad': _idCookpadController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEditing = false;
          _userProfile['username'] = _usernameController.text;
          _userProfile['email'] = _emailController.text;
          _userProfile['id_cookpad'] = _idCookpadController.text;
        });
        _showSuccessSnackBar('Profile updated successfully');
      } else {
        _showErrorSnackBar('Failed to update profile');
      }
    } catch (error) {
      _showErrorSnackBar('Error updating profile');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:3000/upload-profile-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'profilePicture',
        _selectedImage!.path,
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        setState(() {
          _userProfile['profile_picture'] = jsonResponse['filePath'];
        });
        _showSuccessSnackBar('Profile picture uploaded successfully');
      } else {
        _showErrorSnackBar('Failed to upload profile picture');
      }
    } catch (error) {
      _showErrorSnackBar('Error uploading profile picture');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  void _showProfileOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true; // Set to true to enable editing mode
                  });
                  Navigator.pop(context); // Close the dialog
                },
                child: const Text('Edit Profile'),
              ),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // Untuk menghindari overflow
      body: SafeArea(
        child: SingleChildScrollView( // Tambahkan ScrollView di sekitar konten
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_userProfile['profile_picture'] != null
                                  ? NetworkImage(
                                      'http://10.0.2.2:3000/${_userProfile['profile_picture']}',
                                    )
                                  : const AssetImage(
                                          'assets/images/Profile.png')
                                      as ImageProvider),
                          child: _isEditing
                              ? Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 18,
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt,
                                          size: 18, color: Colors.black),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProfileField('Nama', _usernameController, _isEditing),
                    _buildProfileField('ID Cookpad', _idCookpadController, _isEditing),
                    _buildProfileField('Email', _emailController, _isEditing),
                    const SizedBox(height: 20),
                    _isEditing
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _updateProfile,
                            child: const Text('Simpan'),
                          )
                        : Container(), // No "Edit Profile" button here
                  ],
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _showProfileOptions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildProfileField(
    String label,
    TextEditingController controller,
    bool isEditing,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          isEditing
              ? TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
          const Divider(color: Colors.grey),
        ],
      ),
    );
  }
}
