import 'package:flutter/material.dart';

class MottoScreen extends StatelessWidget {
  const MottoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const title = '11° Ano da Cheon Il Guk ';
    const titleContent =
        'Vamos tornar-nos os verdadeiros senhores da Cheon Il Guk que praticam o Verdadeiro Amor à semelhança do nosso Criador, o Pai Celestial';

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Lema para o ano de 2023'),
      // ),
      body: Scaffold(
        backgroundColor: const Color.fromARGB(255, 177, 231, 244),
        body: Stack(
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 3.8,
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.height / 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            titleContent,
                            style: TextStyle(fontSize: 36),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: Divider(color: Colors.red),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Volta'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 20,
                  ),
                  Container(
                    alignment: Alignment.center,
                    height: MediaQuery.of(context).size.height / 5,
                    width: MediaQuery.of(context).size.height / 1,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2.0,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: const Text(
                      title,
                      style:
                          TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


  //   body: Container(
//         margin: const EdgeInsets.all(14.0),
//         padding: const EdgeInsets.all(14.0),
//         child: Expanded(
//           child: SizedBox(
//             child: Column(children: const [
//               Text(
//                 '11° Ano da Cheon Il Guk ',
//                 style: TextStyle(
//                     fontSize: kIsWeb ? 42 : 24, fontWeight: FontWeight.bold),
//               ),
//               Expanded(
//                 child: SizedBox(
//                   height: 14,
//                 ),
//               ),
//               Text(
//                 'Vamos  tornar-nos  os  verdadeiros  senhores da  Cheon Il Guk\nque  praticam  o  Verdadeiro  Amor\nà semelhança  do  nosso  Criador,  o  Pai  Celestial',
//                 style: TextStyle(fontSize: kIsWeb ? 36 : 18),
//                 textAlign: TextAlign.center,
//               ),
//             ]),
//           ),
//         ),
//       ),
//     );
//   }
// }
