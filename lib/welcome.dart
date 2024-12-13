import 'package:flutter/material.dart';
import 'login.dart'; // Import file login.dart
import 'register.dart'; // Import file register.dart

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wallpaper.jpeg'), // Ganti dengan path wallpaper
            fit: BoxFit.cover, // Menyesuaikan gambar dengan ukuran layar
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/MYRESEP_logo.png', height: 150),
                const SizedBox(height: 40), // Spasi di antara logo dan tombol
                SizedBox(
                  width: double.infinity, // Memastikan tombol menyesuaikan lebar
                  height: 50, // Mengatur tinggi tombol
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Login screen
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity, // Memastikan tombol menyesuaikan lebar
                  height: 50, // Mengatur tinggi tombol
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to Register screen
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white, // Menambahkan warna latar belakang putih
                      side: const BorderSide(color: Colors.grey), // Garis tepi abu-abu
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.black, // Warna teks hitam
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
