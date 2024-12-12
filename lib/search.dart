import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

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
                    decoration: InputDecoration(
                      hintText: 'Cari bahan...',
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
              'Bahan populer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Diperbarui 04.22',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 10, 
                  mainAxisSpacing: 10, 
                  childAspectRatio: 1.5, 
                ),
                itemCount: bahanPopuler.length, 
                itemBuilder: (context, index) {
                  final bahan = bahanPopuler[index];
                  return BahanCard(
                    imageUrl: bahan['imageUrl']!,
                    title: bahan['title']!,
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
    'title': 'Daging sapi',
  },
];
