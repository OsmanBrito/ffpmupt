import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MottoScreen extends StatelessWidget {
  const MottoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lema para o ano de 2026'),
      ),
      body: Container(
        margin: const EdgeInsets.all(14.0),
        padding: const EdgeInsets.all(14.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '14° Ano da Cheon Il Guk ',
                style: TextStyle(
                    fontSize: kIsWeb ? 42 : 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 14,
              ),
              Text(
                'No 14° ano do Cheon Il Guk, quando atendemos substancialmente o Criador, os Pais Celestiais, Nós, as famílias abençoadas de todo o mundo, vamos tornar-nos verdadeiros filhos e filhas da Cheon Il Guk que cumprem a nossa responsabilidade em unidade com os Verdadeiros Pais.',
                style: TextStyle(fontSize: kIsWeb ? 36 : 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
