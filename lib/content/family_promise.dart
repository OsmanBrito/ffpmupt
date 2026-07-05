import 'package:ffpmupt/models/family_promise.dart';

enum FamilyPromiseLanguage { portuguese, korean, english }

String familyPromiseTitle(FamilyPromiseLanguage language) {
  switch (language) {
    case FamilyPromiseLanguage.portuguese:
      return 'Promessa da Família';
    case FamilyPromiseLanguage.korean:
      return '가정맹세 (ka-jeong-maeng-se)';
    case FamilyPromiseLanguage.english:
      return 'Family Pledge';
  }
}

const koreanFamilyPromiseTtsLocale = 'ko-KR';

const koreanFamilyPromiseSpeech = [
  '1. 천일국 주인 우리 가정은 참사랑을 중심하고 본향땅을 찾아 본연의 창조이상인 지상천국과 천상천국을 창건할 것을 맹세하나이다.',
  '2. 천일국 주인 우리 가정은 참사랑을 중심하고 하늘부모님과 참부모님을 모시어 천주의 대표적 가정이 되며 중심적 가정이 되어 가정에서는 효자, 국가에서는 충신, 세계에서는 성인, 천주에서는 성자의 가정의 도리를 완성할 것을 맹세하나이다.',
  '3. 천일국 주인 우리 가정은 참사랑을 중심하고 사대 심정권과 삼대 왕권과 황족권을 완성할 것을 맹세하나이다.',
  '4. 천일국 주인 우리 가정은 참사랑을 중심하고 하늘부모님의 창조이상인 천주대가족을 형성하여 자유와 평화와 통일과 행복의 세계를 완성할 것을 맹세하나이다.',
  '5. 천일국 주인 우리 가정은 참사랑을 중심하고 매일 주체적 천상세계와 대상적 지상세계의 통일을 향해 전진적 발전을 촉진화할 것을 맹세하나이다.',
  '6. 천일국 주인 우리 가정은 참사랑을 중심하고 하늘부모님과 참부모님의 대신 가정으로서 천운을 움직이는 가정이 되어 하늘의 축복을 주변에 연결시키는 가정을 완성할 것을 맹세하나이다.',
  '7. 천일국 주인 우리 가정은 참사랑을 중심하고 본연의 혈통과 연결된 위하는 생활을 통하여 심정문화세계를 완성할 것을 맹세하나이다.',
  '8. 천일국 주인 우리 가정은 참사랑을 중심하고 천일국시대를 맞이하여 절대신앙 절대사랑 절대복종으로 신인애 일체이상을 이루어 지상천국과 천상천국의 해방권과 석방권을 완성할 것을 맹세하나이다.',
];

const englishFamilyPromise = [
  '1. Our family, the owner of Cheon II Guk, pledges to seek our original homeland and build the Kingdom of God on earth and in heaven, the original ideal of creation, by centring on true love.',
  '2. Our family, the owner of Cheon II Guk, pledges to represent and become central to heaven and earth by attending the Heavenly Parent and True Parents; we pledge to perfect the dutiful family way of filial sons and daughters in our family, patriots in our nation, saints in the world, and divine sons and daughters in heaven and on earth, by centring on true love.',
  '3. Our family, the owner of Cheon II Guk, pledges to perfect the Four Great Realms of Heart, the Three Great Kingships and the Realm of the Royal Family, by centring on true love.',
  '4. Our family, the owner of Cheon II Guk, pledges to build the universal family encompassing heaven and earth, which is the Heavenly Parent\'s ideal of creation, and perfect the world of freedom, peace, unity and happiness, by centring on true love.',
  '5. Our family, the owner of Cheon I Guk, pledges to strive every day to advance the unification of the spirit world and the physical world as subject and object partners, by centring on true love.',
  '6. Our family, the owner of Cheon Il Guk, pledges to become a family that moves heavenly fortune by embodying the Heavenly Parent and True Parents, and to perfect a family that conveys Heaven\'s blessing to our community, by centring on true love.',
  '7. Our family, the owner of Cheon II Guk, pledges, through living for the sake of others, to perfect the world based on the culture of heart, which is rooted in the original lineage, by centring on true love.',
  '8. Our family, the owner of Cheon II Guk, pledges, having entered the Era of Cheon I Guk, to achieve the ideal of God and human beings united in love through absolute faith, absolute love and absolute obedience, and to perfect the realm of liberation and complete freedom in the Kingdom of God on earth and in heaven, by centring on true love.',
];

const Map<FamilyPromiseLanguage, List<String>> familyPromise = {
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
    '1 (il) Cheon-il-guk ju-in u-ri ka-jeong-eun,\ncham-sa-rang-eul chung-shim-há-go,\nbon-hyang-dang-eul cha-ja,\nbon-yeon-é chang-jo-i-sang-in,\nji-sang-cheon-guk-gwa cheon-sang-cheon-guk-eul,\nchang-geon-hal go-seul maeng-se-ha-na-i-da.\n',
    '2 (hi) Cheon-il-guk   ju-in   u-ri   ka-jeong-eun,\ncham-sa-rang-eul   chung-shim-há-go,\nha-neul-bu-mo-nim-gwa   cham-bu-mo-nim-eul   mo-chi-ô,\ncheon-ju-é   dae-pyo-jeok   ka-jeong-i  dwe-myeo,\nchoong-chim-jeok ka-jeong-i   dwe-yo,\nka-jeong-e-seo-neun   hyo-ja,\ngug-ka-e-seo-neun   chung-shin,\nse-gye-e-seo-neun   seong-in,\ncheon-ju-e-seo-neun   seong-ja-é   ga-jeong-é   do-ri-rul,\nwan-seong-hal   go-seul   maeng-se-há-na-i-da.',
    '3 (sam) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,\ncham-sa-rang-eul   chung-shim-ha-go,\nsa-dé-chim-jeong-gweon-gwa,\nsam-dae-wang-gweon-gwa   hwang-jok-kweon-eul,\nwan-seong-hal   go-seul   maeng-se-há-na-i-da.\n',
    '4 (sa) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,\ncham-sa-rang-eul   chung-shim-ha-go,\nha-neul-bu-mo-nim-é chang-jo-i-sang-in,\ncheon-ju-dae-ga-jok-eul  hyeong-seong-ha-yeo,\nja-yu-wa  pyeong-hwa-wa  tong-il-gwa,\nhaeng-bok-é  se-gye-reul,\nwan-seong-hal  go-seul   maeng-se-há-na-i-da.\n',
    '5 (oh) Cheon-il-guk   ju-in   u-ri   ka-jeong-eun,\ncham-sa-rang-eul   chung-shim-ha-go,\nmé-il ju-che-jeok cheon-sang-se-gye-wa,\ndae-sang-jeok ji-sang-se-gye-é tong-i-rul hwang-hae,\njeon-jin-joek pal-jeon-eul,\nchok-jin-hwa-hal go-sul maeng-se-há-na-i-da.\n',
    '6 (yuk) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,\ncham-sa-rang-eul   chung-shim-ha-go,\nha-neul-bu-mo-nim-gwa   cham-bu-mo-nim-é,\ndae-shin    ka-jeong-eu-ro-seo,\ncheon-un-eul  um-jik-i-neun  ka-geong- i  dé-ô,\nha-neul-e  chuk-bok-eul,\nju-byeon-é   yeon-gyeol-chi-ki-neun  ka-jeong-eul,\nwan-seong-hal  go-seul  maeng-se-ha-na-i-da.\n',
    '7 (chil) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,\ncham-sa-rang-eul   chung-shim-ha-go,\nbon-yeon-é   hyeol-tong-gwa   yeon-gyeol-doen,\nwi-ha-neun   saeng-hwa-reul   tong-ha-yeo,\nshim-jeong-mun-hwa   se-gye-reul,\nwan-seong-hal  go-seul   maeng-se-ha-na-i-da.\n',
    '8 (pal) Cheon-il-guk  ju-in   u-ri  ka-jeong-eun,\ncham-sa-rang-eul   chung-shim-ha-go,\ncheon-il-guk-shi-de-reul   ma-ji-ha-yeo,\ncheol-dae-shin-ang,   cheol-dae-sa-rang,\ncheol-dae-bok-chong-eu-ro,\nshin-in-é   il-che-i-sang-eul   i-ru-ô,\nji-sang-cheon-guk-gwa   cheon-sang-cheon-guk-é,\nhae-bang-gweon-gwa   seok-bang-gweon-eul,\nwan-seong-hal  go-seul   maeng-se-ha-na-i-da.\n',
  ],
  FamilyPromiseLanguage.english: englishFamilyPromise,
};

List<FamilyPromiseDocument> bundledFamilyPromisesForCountry({
  required String countryCode,
  required String defaultLanguage,
}) {
  final promises = <FamilyPromiseDocument>[
    FamilyPromiseDocument(
      languageCode: 'ko',
      title: familyPromiseTitle(FamilyPromiseLanguage.korean),
      verses: familyPromise[FamilyPromiseLanguage.korean]!,
      enabled: true,
      sortOrder: defaultLanguage == 'ko' ? 0 : 1,
    ),
    FamilyPromiseDocument(
      languageCode: 'en',
      title: familyPromiseTitle(FamilyPromiseLanguage.english),
      verses: familyPromise[FamilyPromiseLanguage.english]!,
      enabled: true,
      sortOrder: defaultLanguage == 'en' ? 0 : 2,
    ),
  ];
  if (countryCode.toLowerCase() == 'pt' || defaultLanguage == 'pt') {
    promises.add(
      FamilyPromiseDocument(
        languageCode: 'pt',
        title: familyPromiseTitle(FamilyPromiseLanguage.portuguese),
        verses: familyPromise[FamilyPromiseLanguage.portuguese]!,
        enabled: true,
        sortOrder: 0,
      ),
    );
  }
  promises.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
  return promises;
}
