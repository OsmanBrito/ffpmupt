import 'package:ffpmupt/screens/family_promise_screen.dart';
import 'package:ffpmupt/screens/list_of_songs_screen.dart';
import 'package:ffpmupt/screens/motto_screen.dart';
import 'package:flutter/foundation.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('FFPMU PT'),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MottoScreen(),
              ),
            ),
            icon: const Icon(Icons.text_snippet),
            label: const Text('Lema para o ano de 2026'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ListOfSongsScreen(),
              ),
            ),
            icon: const Icon(Icons.library_music),
            label: const Text('Canções / Songs'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FamilyPromiseScreen(),
              ),
            ),
            icon: const Icon(Icons.church_rounded),
            label: const Text('Promessa da Família / Family Pledge'),
          )
        ],
      )),
    );
  }
}
