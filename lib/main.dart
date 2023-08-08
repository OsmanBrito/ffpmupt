import 'package:ffpmupt/screens/family_promise_screen.dart';
import 'package:ffpmupt/screens/list_of_songs_screen.dart';
import 'package:ffpmupt/screens/motto_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Canções',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 64) / 3;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 400),
        child: Center(
          child: GridView.count(
            crossAxisCount: screenWidth < 360 ? 2 : 3, 
            crossAxisSpacing: 16,
            padding: const EdgeInsets.all(16),
            childAspectRatio: cardWidth / 100,
            children: [
              CardButton(
                icon: Icons.text_snippet,
                label: 'Lema para o ano de 2023',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MottoScreen(),
                  ),
                ),
              ),
              CardButton(
                icon: Icons.library_music,
                label: 'Canções / Songs',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ListOfSongsScreen(),
                  ),
                ),
              ),
              CardButton(
                icon: Icons.church_rounded,
                label: 'Promessa da família / Family Pledge',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FamilyPromiseScreen(),
                  ),
                ),
              ),
              // Add more CardButtons here if needed
            ],
          ),
        ),
      ),
    );
  }
}

class CardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const CardButton({
    Key? key, // Fix the parameter name
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

 @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}