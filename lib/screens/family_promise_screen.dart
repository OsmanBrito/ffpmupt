import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FamilyPromiseScreen extends StatefulWidget {
  const FamilyPromiseScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPromiseScreen> createState() => _FamilyPromiseScreenState();
}

class _FamilyPromiseScreenState extends State<FamilyPromiseScreen> {
  int _currentIndex = 0;

  late FamilyPromiseLanguage _currentLanguage =
      FamilyPromiseLanguage.portuguese;

  void _nextItem() {
    setState(() {
      if (_currentIndex < 7) {
        _currentIndex =
            (_currentIndex + 1) % familyPromise[_currentLanguage]!.length;
      }
    });
  }

  void _previousItem() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex =
            (_currentIndex - 1 + familyPromise[_currentLanguage]!.length) %
                familyPromise[_currentLanguage]!.length;
      }
    });
  }

  void _changeLanguage(FamilyPromiseLanguage newLanguage) {
    setState(() {
      _currentLanguage = newLanguage;
    });
  }

  Color _getColorByCurrentLanguage() {
    switch (_currentLanguage) {
      case FamilyPromiseLanguage.portuguese:
        return Colors.green;
      case FamilyPromiseLanguage.korean:
        return Colors.lightBlueAccent;
      case FamilyPromiseLanguage.english:
        return Colors.redAccent;
    }
  }

  String _getTitleByCurrentLanguage() {
    switch (_currentLanguage) {
      case FamilyPromiseLanguage.portuguese:
        return 'Promessa da familia';
      case FamilyPromiseLanguage.korean:
        return '가정맹세 (ka-jeong-maeng-se)';
      case FamilyPromiseLanguage.english:
        return 'Family Pledge';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _getColorByCurrentLanguage(),
        title: Text(
          _getTitleByCurrentLanguage(),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _changeLanguage(FamilyPromiseLanguage.portuguese),
                    icon: const Icon(Icons.directions_boat_rounded),
                    label: const Text('Português'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 20),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _changeLanguage(FamilyPromiseLanguage.korean),
                    icon: const Icon(Icons.translate),
                    label: const Text('Coreano'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent),
                  ),
                  const SizedBox(width: 20),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _changeLanguage(FamilyPromiseLanguage.english),
                    icon: const Icon(Icons.account_balance),
                    label: const Text('English'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                  ),
                ],
              ),
              Card(
                margin: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        _currentLanguage == FamilyPromiseLanguage.portuguese
                            ? 'Português'
                            : _currentLanguage == FamilyPromiseLanguage.english
                                ? 'English'
                                : 'Coreano',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: kIsWeb ? 42 : 26,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 32.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _previousItem,
                          child: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _nextItem,
                          child: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 32.0,
                    ),
                    Text(
                      familyPromise[_currentLanguage]![_currentIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: kIsWeb ? 36 : 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final Map<FamilyPromiseLanguage, List<String>> familyPromise = {
  FamilyPromiseLanguage.portuguese: [
    '1.  A nossa Família, senhora da Cheon Il Guk, promete procurar a nossa terra natal original e construir o Reino de Deus na Terra e no Céu, o ideal original da criação, centrando-se no verdadeiro amor.',
    '2.  A nossa Família, senhora da Cheon Il Guk, promete representar e tornar-se central para o Céu e para a Terra ao servir o Pai Celestial e os Verdadeiros Pais; prometemos aperfeiçoar o caminho de obediência na família, de filhos e filhas de piedade filial na nossa família, patriotas na nossa nação, santos no mundo e filhos e filhas divinos no Céu e na Terra, centrando-se no verdadeiro amor.',
    '3.  A nossa Família, senhora da Cheon Il Guk, promete aperfeiçoar as Quatro Grandes Esferas do Coração, as Três Grandes Realezas e o Reino da Família Real, centrando-se no verdadeiro amor.',
    '4.  A nossa Família, senhora da Cheon Il Guk, promete construir a família universal que abraça o Céu e a Terra, que é o ideal da criação do Pai Celestial e aperfeiçoar o mundo de liberdade, paz, unidade e felicidade, centrando-se no verdadeiro amor.',
    '5.  A nossa Família, senhora da Cheon Il Guk, promete labutar diariamente para o avanço da unificação do mundo espiritual e o do mundo físico, como parceiros sujeito e objecto, centrando-se no verdadeiro amor.',
    '6.  A nossa Família, senhora da Cheon Il Guk, promete tornar-se uma família que transmite a fortuna celestial ao encarnar o Pai Celestial e os Verdadeiros Pais e aperfeiçoar uma família que transmite a bênção do Céu à nossa comunidade, centrando-se no verdadeiro amor.',
    '7.  A nossa Família, senhora da Cheon Il Guk, promete, ao viver pela causa do bem dos outros, aperfeiçoar o mundo com base na cultura de coração, que tem a raiz na linhagem original, centrando-se no verdadeiro amor.',
    '8.  A nossa Família, senhora da Cheon Il Guk, promete, tendo entrado na Era da Cheon Il Guk, atingir o ideal de Deus e dos seres humanos unidos em amor através da fé absoluta, amor absoluto e obediência absoluta e aperfeiçoar a esfera de libertação e plena liberdade no Reino de Deus na Terra e no Céu, centrando-se no verdadeiro amor.',
  ],
  FamilyPromiseLanguage.korean: [
    '1 (il) Cheon-il-guk ju-in u-ri ka-jeong-eun, cham-sa-rang-eul chung-shim-há-go,\nbon-hyang-dang-eul cha-ja,\nbon-yeon-é chang-jo-i-sang-in, ji-sang-cheon-guk-gwa cheon-sang-cheon-guk-eul,\nchang-geon-hal go-seul maeng-se-ha-na-i-da.',
    '2 (hi) Cheon-il-guk   ju-in   u-ri   ka-jeong-eun,   cham-sa-rang-eul   chung-shim-há-go,\nha-neul-bu-mo-nim-gwa   cham-bu-mo-nim-eul   mo-chi-ô,\ncheon-ju-é   dae-pyo-jeok   ka-jeong-i  dwe-myeo,  choong-chim-jeok ka-jeong-i   dwe-yo,  ka-jeong-e-seo-neun   hyo-ja,\ngug-ka-e-seo-neun   chung-shin,   se-gye-e-seo-neun   seong-in,   cheon-ju-e-seo-neun\nseong-ja-é   ga-jeong-é   do-ri-rul,   wan-seong-hal   go-seul   maeng-se-há-na-i-da.',
    '3 (sam) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,   cham-sa-rang-eul   chung-shim-ha-go,\nsa-dé-chim-jeong-gweon-gwa, \nsam-dae-wang-gweon-gwa   hwang-jok-kweon-eul,   wan-seong-hal   go-seul \nmaeng-se-há-na-i-da.',
    '4 (sa) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,   cham-sa-rang-eul   chung-shim-ha-go,\nha-neul-bu-mo-nim-é chang-jo-i-sang-in,\ncheon-ju-dae-ga-jok-eul  hyeong-seong-ha-yeo,  ja-yu-wa  pyeong-hwa-wa  tong-il-gwa,\nhaeng-bok-é  se-gye-reul,   wan-seong-hal  go-seul   maeng-se-há-na-i-da.',
    '5 (oh) Cheon-il-guk   ju-in   u-ri   ka-jeong-eun,   cham-sa-rang-eul   chung-shim-ha-go,\nmé-il   ju-che-jeok cheon-sang-se-gye-wa,\ndae-sang-jeok ji-sang-se-gye-é tong-i-rul hwang-hae, jeon-jin-joek pal-jeon-eul,\nchok-jin-hwa-hal go-sul maeng-se-há-na-i-da.',
    '6 (yuk) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,   cham-sa-rang-eul   chung-shim-ha-go,\nha-neul-bu-mo-nim-gwa   cham-bu-mo-nim-é,  dae-shin    ka-jeong-eu-ro-seo,\ncheon-un-eul  um-jik-i-neun  ka-geong- i  dé-ô,  ha-neul-e  chuk-bok-eul,   ju-byeon-é\n yeon-gyeol-chi-ki-neun  ka-jeong-eul,  wan-seong-hal  go-seul  maeng-se-ha-na-i-da.',
    '7 (chil) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,   cham-sa-rang-eul   chung-shim-ha-go,\nbon-yeon-é   hyeol-tong-gwa   yeon-gyeol-doen,\nwi-ha-neun   saeng-hwa-reul   tong-ha-yeo,   shim-jeong-mun-hwa   se-gye-reul,\nwan-seong-hal  go-seul   maeng-se-ha-na-i-da.',
    '8 (pal) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,   cham-sa-rang-eul   chung-shim-ha-go,\ncheon-il-guk-shi-de-reul   ma-ji-ha-yeo,\ncheol-dae-shin-ang,   cheol-dae-sa-rang,   cheol-dae-bok-chong-eu-ro,\nshin-in-é   il-che-i-sang-eul   i-ru-ô,\nji-sang-cheon-guk-gwa   cheon-sang-cheon-guk-é,   hae-bang-gweon-gwa \nseok-bang-gweon-eul,   wan-seong-hal  go-seul   maeng-se-ha-na-i-da.',
  ],
  FamilyPromiseLanguage.english: [
    '1. Our family, the owner of Cheon II Guk, pledges to seek our original homeland and build the Kingdom of God on earth and in heaven, the original ideal of creation, by centring on true love.',
    '2. Our family, the owner of Cheon II Guk, pledges to represent and become central to heaven and earth by attending the Heavenly Parent and True Parents; we pledge to perfect the dutiful family way of filial sons and daughters in our family, patriots in our nation, saints in the world, and divine sons and daughters in heaven and on earth, by centring on true love.',
    '3. Our family, the owner of Cheon II Guk, pledges to perfect the Four Great Realms of Heart, the Three Great Kingships and the Realm of the Royal Family, by centring on true love.',
    '4. Our family, the owner of Cheon II Guk, pledges to build the universal family encompassing heaven and earth, which is the Heavenly Parent\'s ideal of creation, and perfect the world of freedom, peace, unity and happiness, by centring on true love.',
    '5. Our family, the owner of Cheon I Guk, pledges to strive every day to advance the unification of the spirit world and the physical world as subject and object partners, by centring on true love.',
    '6. Our family, the owner of Cheon Il Guk, pledges to become a family that moves heavenly fortune by embodying the Heavenly Parent and True Parents, and to perfect a family that conveys Heaven\'s blessing to our community, by centring on true love.',
    '7. Our family, the owner of Cheon II Guk, pledges, through living for the sake of others, to perfect the world based on the culture of heart, which is rooted in the original lineage, by centring on true love.',
    '8. Our family, the owner of Cheon II Guk, pledges, having entered the Era of Cheon I Guk, to achieve the ideal of God and human beings united in love through absolute faith, absolute love and absolute obedience, and to perfect the realm of liberation and complete freedom in the Kingdom of God on earth and in heaven, by centring on true love.',
  ]
};

enum FamilyPromiseLanguage { portuguese, korean, english }
