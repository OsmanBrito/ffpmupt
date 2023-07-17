import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MottoScreen extends StatelessWidget {
  const MottoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lema para o ano de 2023'),
      ),
      body: Container(
        margin: const EdgeInsets.all(14.0),
        padding: const EdgeInsets.all(14.0),
        child: Expanded(
          child: SizedBox(
            child: Column(children: const [
              Text(
                '11° Ano da Cheon Il Guk ',
                style: TextStyle(
                    fontSize: kIsWeb ? 42 : 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 14,
              ),
              Text(
                'Vamos  tornar-nos  os  verdadeiros  senhores da  Cheon Il Guk\nque  praticam  o  Verdadeiro  Amor\nà semelhança  do  nosso  Criador,  o  Pai  Celestial',
                style: TextStyle(fontSize: kIsWeb ? 36 : 18),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
