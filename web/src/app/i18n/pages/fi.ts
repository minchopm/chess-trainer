import type { Pages } from './types';

/** The four commercial pages in Finnish. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Tuki',
      title: 'Kysy ihmiseltä',
      lede: 'Täällä ei ole tikettijärjestelmää, ei chattibottia eikä ohjekeskusta neljänsadan artikkelin kera. Täällä on sähköpostiosoite ja lista vioista, ja molemmat päätyvät sille, joka kirjoitti tämän sovelluksen.',
    },
    meta: {
      title: 'Tuki',
      description:
        'Miten tavoitat ihmisen Brass Pawnista, mitä liität mukaan kun tehtävä on väärin, ja kysymykset jotka toistuvat useimmin.',
    },
    email: {
      slug: 'Sähköposti',
      body: 'Kaikesta: virhe, virheellinen tehtävä, kysymys ostoksesta tai erimielisyys arviosta. Kirjoita englanniksi tai bulgariaksi.',
    },
    tracker: {
      slug: 'Vikalista',
      name: 'GitHub-issuet',
      body: 'Kaikkeen minkä pidät mieluummin julkisena — ja kaikkeen minkä muiden pitää löytää myöhemmin, mikä koskee useimpia virheilmoituksia.',
    },
    report: {
      slug: 'Kun tehtävä on väärin',
      title: 'Lähetä neljä asiaa, niin tarkistus vie minuutin.',
      checklist: [
        'Tehtävänäytöllä näkyvä FEN — pidä pohjassa kopioidaksesi sen.',
        'Siirto jonka teit, ja siirto jota sovellus sanoi oikeaksi.',
        'Missä tilassa olit.',
        'Sovellusversio, tietonäytöltä.',
      ],
      caveat:
        'Tehtävät ovat silloin tällöin ristiriidassa syvemmän haun kanssa, ja nuo ristiriidat kasautuvat pitkiin, hiljaisiin, korkealle arvioituihin asemiin, joiden pointti on syvemmällä kuin tarkistus ylsi. Se on tarkistuksen raja eikä virhe tehtävässä — mutta on hyödyllistä tietää mitkä ne ovat, ja ainoa tapa tietää on että sanot.',
    },
    faq: { slug: 'Kysymykset', title: 'Kysytään riittävän usein kirjoitettavaksi ylös.' },
    more: {
      ratings: 'Mitä arvo mittaa',
      tactics: 'Aiheet',
      privacy: 'Tietosuojaseloste',
      terms: 'Käyttöehdot',
      licences: 'Lisenssit',
    },
  },

  pricing: {
    head: {
      slug: 'Mitä se maksaa',
      title: 'Pelaaminen on ilmaista. Harjoittelu myydään.',
      lede: 'Shakki moottoria vastaan ja shakki ihmistä vastaan, rajattomasti, ilman mainoksia missään sovelluksessa — se on ilmaista ja pysyy sellaisena. Myytävänä on kirjasto, harjoitukset, tehtävät ja kilpajuoksu kelloa vastaan.',
    },
    meta: {
      title: 'Hinnat',
      description:
        'Pelaaminen on ilmaista ja rajatonta — moottori, elävä vastustaja ja kaikki 900 peliä. Pro poistaa viiden päivärajan: 3,99 dollaria kuussa tai 49,99 kertamaksuna.',
    },
    free: {
      name: 'Ilmainen',
      note: 'Ei tiliä. Ei mitään mihin rekisteröityä.',
      items: [
        'Rajaton peli moottoria vastaan, 1400:sta täyteen voimaan',
        'Rajattomat verkkopelit Game Centerin kautta',
        'Kommentti siirto siirrolta jokaisessa pelaamassasi pelissä',
        'Viisi taktiikkatehtävää päivässä',
        'Viisi Rush-kierrosta päivässä',
        'Viisi kutakin: asemalliset, loppupelit, Arvaa Elo',
        'Arvot, putket ja jaksotettu kertaus, kokonaan',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Kuukausittain',
      per: 'kuukaudessa',
      note: 'Peruuta milloin tahansa Apple-tilisi asetuksista.',
      items: [
        'Kaikki päivärajat pois',
        'Kaikki {tactics} taktiikkatehtävää',
        'Kaikki {positional} asemallista harjoitusta',
        'Kaikki {endgames} loppupeliharjoitusta',
        'Kaikki {games} peliä arvioitavaksi',
        'Rush ilman rajaa',
        'Kaikki ilmaisversiosta, muuttumattomana',
      ],
    },
    lifetime: {
      name: 'Kertaluontoinen avaus',
      once: 'kerran ja lopullisesti',
      note: 'Kuluttamaton osto. Se ei uusiudu.',
      items: [
        'Täsmälleen sama kuin Pro kuukausittain',
        'Ei uusintoja, ei päättymispäivää, ei muistutusviestejä',
        'Palautuu muille laitteillesi',
        'Sille joka päättää mieluummin kerran',
      ],
    },
    table: {
      slug: 'Koko annos',
      title: 'Mitä ilmaisversio todella antaa.',
      activity: 'Toiminto',
      freeCol: 'Ilmainen',
      proCol: 'Pro',
      unlimited: 'Rajaton',
      fiveADay: '5 päivässä',
      none: 'Ei lainkaan',
      rows: [
        'Peli moottoria vastaan',
        'Verkkopelit Game Centerin kautta',
        'Katselu — 900 pelin kirjasto',
        'Taktiikkatehtävät',
        'Rush-kierrokset',
        'Asemalliset harjoitukset',
        'Loppupeliharjoitukset',
        'Arvaa Elo',
        'Mainokset',
      ],
      reset:
        'Päiväannokset nollautuvat kello yhdeksän aamulla paikallista aikaa — ei keskiyöllä, jottei iltasessio katkeaisi kahtia päivämäärän vaihtuessa.',
    },
    why: {
      slug: 'Miksi se on tämän muotoinen',
      title: 'Kolme päätöstä ja kunkin syy.',
      reasons: [
        {
          title: 'Laskettu, ei lukittu',
          body: [
            'Kukaan ei maksa valmentajasta jota ei ole käyttänyt, eikä tila joka kieltäytyy avautumasta kerro mitään siitä mitä sen takana on. Siispä jokainen tila avautuu, joka päivä, ja pääset riittävän pitkälle tunteaksesi rytmin ja nähdäksesi arvon liikkuvan.',
            'Ostonäyttö ei ilmesty koskaan käynnistyksessä. Kun päivän annos on käytetty, näyttö sanoo sen, ja vasta tietoinen napautus avaa ostolomakkeen.',
          ],
        },
        {
          title: 'Kaksi hintaa, ei kolmea',
          body: [
            'Väliin ei tule vuosisuunnitelmaa, koska kolmas hinta on kolmas päätös juuri sillä hetkellä kun joku haluaa ratkaista tehtävän. Kuukausittain jos epäröit. Kerralla jos et.',
          ],
        },
        {
          title: 'Pelaamista ei myydä koskaan',
          body: [
            'Shakki moottoria ja ihmistä vastaan ei maksa mitään ylläpitää ja on syy siihen että sovellus on olemassa. Niiden myyminen tekisi tästä shakkisovelluksen tullipuomilla valmentajan sijaan.',
            'Eikä mainoksia ole — osin makuasia, osin lisenssi. Sovellus linkittää kaksi copyleft-moottoria, Stockfishin GPLv3:n alla ja Recklessin AGPLv3:n alla, ja suljettu mainos-SDK samassa binäärissä tekisi kokonaisuudesta jakelukelvottoman. {link}',
          ],
        },
      ],
      licenceLink: 'Lisenssisivu käy sen läpi kunnolla.',
    },
    answers: {
      slug: 'Osto, peruutus, hyvitys',
      title: 'Kiusalliset kysymykset, vastattuna täällä sähköpostin sijaan.',
      items: [
        {
          q: 'Miten peruutan?',
          a: 'Asetukset → nimesi → Tilaukset → Brass Pawn. Emme voi peruuttaa puolestasi, koska tilaus on sinun ja Applen välinen eikä ole koskaan ollut meillä. Peruutus pysäyttää tulevat uusinnat eikä lyhennä jo maksettua jaksoa.',
        },
        {
          q: 'Miten saan rahani takaisin?',
          a: 'Applen kautta, osoitteessa {link}. Emme voi hyvittää App Store -ostoksia. Jos jokin on rikki, kirjoita meille — korjaamme mieluummin.',
        },
        {
          q: 'Ostin avauksen ja minulla on uusi puhelin.',
          a: 'Kirjaudu samalle Apple-tilille ja napauta ”Palauta ostokset” ostonäytöllä. Sovellus kysyy StoreKitiltä mitä omistat; mitään ei ole meidän palvelimellamme, koska meillä ei ole palvelinta.',
        },
        {
          q: 'Muuttaako Pro arvoani tai avaako ”parempia” tehtäviä?',
          a: 'Ei. Arvojärjestelmä on identtinen, ja jokainen kirjaston tehtävä on saavutettavissa ilmaistilillä — viisi päivässä. Pro poistaa laskurin, ei verhoa.',
        },
        {
          q: 'Pieneneekö ilmainen annos myöhemmin?',
          a: 'Se voi muuttua molempiin suuntiin kirjaston kasvaessa. Rajaton peli moottoria ja ihmistä vastaan ei muutu maksulliseksi ominaisuudeksi; se on kirjattu {link} eikä vain luvattu täällä.',
        },
      ],
      termsLink: 'ehtoihin',
      more: 'Lisää kysymyksiä ja miten tavoitat ihmisen →',
    },
  },

  training: {
    head: {
      slug: 'Ohjelma',
      title: 'Kahdeksan tapaa kuulla totuus',
      lede: 'Kolme niistä on ilmaisia ja rajattomia ikuisesti — pelaaminen, pelaaminen jotakuta vastaan ja yhdeksänsataa peliä Katselussa. Loput viisi ovat viisi päivässä ilmaistilillä ja rajattomia Prolla. Kukin arvioi sinut sanoilla asemasta eikä numerolla jota pitää vasta tulkita.',
    },
    meta: {
      title: 'Harjoittelu',
      description:
        'Kahdeksan tilaa: taktiikka, asemallinen arviointi, loppupelit, Rush, Arvaa Elo, Katselu, peli kommentin kera ja verkkopeli. Miten kukin toimii, miten tehtävät louhitaan ja tarkistetaan, ja mitä valmentaja ei tee.',
    },
    modes: [
      {
        title: 'Taktiikka',
        lede: 'Asemia joissa on täsmälleen yksi voittava siirto, ja tuomio sillä hetkellä kun sen teet.',
        body: [
          'Jokaisella tehtävällä on yksi vastaus eikä haaroja. Tee se laudalla, niin valmentaja sanoo heti löysitkö sen; jos ohitat, asema palaa huomenna, sitten neljän päivän päästä, sitten kymmenen — niin kauan kuin se yhä nappaa sinut.',
          'Jokainen tehtävä kantaa aiheen jonka ympäri se pyörii — haarukka, sidonta, varras, perusrivimatti, poisohjaus, hiljainen siirto — jotta valmentaja voi muutaman sadan jälkeen kertoa sinulle ei sitä että olet 1620, vaan että olet 1620 ja kävelet yhä uudestaan poisohjauksiin.',
        ],
        free: 'Viisi päivässä ilmaistilillä.',
        stat: 'tehtävää, arvioituna 760:stä 2800:aan',
      },
      {
        title: 'Asemallinen arviointi',
        lede: 'Pakotettua voittoa ei ole. Sano kumpi seisoo paremmin, ja etsi sitten siirto joka kertoo miksi.',
        body: [
          'Tämä on tila joka on rakennettu sitä varten mikä erottaa vahvat pelaajat hyvistä laskijoista. Ensin arvioit: selvästi parempi, hieman parempi, tasan. Sitten valitset siirron. Molemmat vastaukset arvioidaan.',
          'Palaute nimeää konkreettisia piirteitä tunnelmien sijaan — avoin linja ja seisooko sillä torni, ratsun ruutu jota mikään sotilas ei voi kiistää, sotilasrakenne, kuninkaan turvallisuus, ero nappuloiden aktiivisuudessa. Asema ei ole ”mukava valkealle”; se on parempi neljästä syystä jotka voit luetella.',
        ],
        free: 'Viisi päivässä ilmaistilillä.',
        stat: 'hiljaista asemaa, moottorin esivalitsemina',
      },
      {
        title: 'Loppupelit',
        lede: 'Kanonisia asemia, pelattuna loppuun moottoria vastaan joka puolustaa kunnolla.',
        body: [
          'Idean tunteminen ei ole sama asia kuin sen kotiin tuominen, joten täällä sinun on todella saavutettava tulos. Stockfish ottaa toisen puolen ja pystyttää parhaan puolustuksen mitä on olemassa.',
          'Jokaisen siirron jälkeen valmentaja tarkistaa uudestaan onko tulos yhä saavutettavissa — ja jos ei, se nimeää tarkan siirron jossa se lakkasi olemasta. Se on lause joka opettaa jotain: ei ”teit tasapelin”, vaan ”teit tasapelin tässä”.',
        ],
        free: 'Viisi päivässä ilmaistilillä.',
        stat: 'harjoitusta, jokainen tulos moottorin tarkistama',
      },
      {
        title: 'Rush',
        lede: 'Kierros aikaa vastaan. Ratkaise niin monta kuin ehdit ennen kuin kello vie loput.',
        body: [
          'Samat tehtävät, kellon alla, vaikeudella joka nousee niin kauan kuin löydät ne. Se harjoittaa eri lihasta kuin tehtävä jota saa tuijottaa: sitä joka on nähtävä nyt.',
          'Kierrokset pisteytetään ja tallennetaan, joten luku nousee kuukausien mittaan yhden illan sijaan.',
        ],
        free: 'Viisi kierrosta päivässä ilmaistilillä.',
      },
      {
        title: 'Arvaa Elo',
        lede: 'Oikea arvopeli, toistettuna siirto siirrolta. Kuinka vahvoja nämä kaksi olivat?',
        body: [
          'Pelin tason lukeminen on sama taito kuin omien siirtojen arviointi: molemmat tiivistyvät siihen että huomaa mitä virheitä tehdään ja mitä ei. Peli siis kulkee, sinä katsot, ja jossain vaiheessa sitoudut lukuun.',
          'Pelit ovat oikeita, Lichessin arkistoista, molemmat pelaajat 150 pisteen sisällä toisistaan — arvaus ”pelaajista” tarkoittaa jotain vain kun on yksi taso arvattavana.',
        ],
        free: 'Viisi päivässä ilmaistilillä.',
        stat: 'arvopeliä, 800:sta 2599:ään',
      },
      {
        title: 'Katselu',
        lede: 'Yhdeksänsataa katsomisen arvoista peliä — ja sillä hetkellä kun olisit pelannut toisin, otat ohjat.',
        body: [
          'Jokainen kirjaston peli on ratkaiseva, kahden nimekkään pelaajan välinen, ja joko ohi kahdessakymmenessäviidessä siirrossa tai riittävän kuuluisa saadakseen oman nimen. Kukaan ei opi mitään yhdeksänkymmenen siirron tasapelistä ihmisten välillä joista ei ole koskaan kuullut, ja kirjasto joka sisältää sellaisia on kirjasto jota kukaan ei avaa toista kertaa.',
          'Etsi pelaaja, turnaus tai vuosi. Käy sitten peli läpi omaan tahtiisi. Kyse ei ole huippuhetkistä: kyse on siitä että jonkin siirron kohdalla ajattelet <em>minä olisin lyönyt siinä</em> — ja sillä hetkellä voit. Ota asema haltuun ja jatka moottoria vastaan täsmälleen siitä ruudusta jossa olit eri mieltä. Sen selvittäminen mitä ideasi todella oli arvoinen, on koko harjoitus.',
        ],
        free: 'Ilmaista, rajatonta, aina.',
        stat: 'peliä, kaikki ratkaisevia',
      },
      {
        title: 'Peli valmentajan kera',
        lede: 'Kokonainen peli valitsemallasi vahvuudella, ja jokainen siirtosi arvioidaan matkan varrella.',
        body: [
          'Aseta moottori jonnekin 1400:n ja täyden voiman väliin ja pelaa peli loppuun. Jokainen siirtosi arvioidaan pelin vielä käydessä, ja valmentaja selittää mitä parempi siirto olisi saavuttanut — sanoin asemasta, ei numerona.',
          'Lopuksi saat tarkkuuden, karkeiden virheiden määrän ja sen yhden hetken joka maksoi eniten.',
        ],
        free: 'Ilmaista, rajatonta, aina.',
      },
      {
        title: 'Verkossa',
        lede: 'Kaksi ihmistä, yksi kello, eikä moottoria lähimaillakaan.',
        body: [
          'Game Center löytää jonkun joka valitsi saman tahdin — 3, 5, 10, 15 tai 30 minuuttia. Se on ainoa tila ilman moottoria sisällään: ei vihjettä, ei siirtojen arvoja, ei valmennusta, sillä apu jonka vain toinen puoli saa, ei ole peli.',
          'Palvelinta ei ole. Kaksi laitetta puhuvat keskenään ja molemmat valvovat sääntöjä, joten siirto pelataan vain jos se on laillinen siinä asemassa joka vastaanottavalla laitteella jo on. Valehteleva vastapuoli tuottaa hylätyn paketin, ei laitonta lautaa.',
        ],
        free: 'Ilmaista, rajatonta, aina.',
      },
    ],
    watchLink: 'Mikä pääsi kirjastoon ja mikä ei →',
    pipeline: {
      slug: 'Miten tehtävä syntyy',
      title: 'Louhittu, ei kopioitu.',
      lede: 'Asemien kirjoittaminen muistista uhkaa tuottaa tehtävän jonka ”ratkaisu” on väärä tai ei yksikäsitteinen, ja se harjoittaa täsmälleen väärää refleksiä. Siksi mitään niistä ei ole kirjoitettu muistista. Ne löydetään ja niitä sitten hyökätään vastaan kunnes ne selviävät tai lentävät pois.',
      steps: [
        {
          title: 'Peli inhimillisellä vahvuudella',
          body: 'Stockfish pelaa itseään vastaan tarkoituksella inhimillisellä vahvuudella — 1320:stä 2500 Eloon — avaten satunnaisella valinnalla parhaiden matalien ehdokkaidensa joukosta, jotta pelit vaihtelevat sen sijaan että toistaisivat yhtä muunnelmaa ikuisesti.',
        },
        {
          title: 'Seulonta ominaisuuden, ei mokan perusteella',
          body: 'Jokainen asema haetaan syvyydellä 12 kahdella ehdokasmuunnelmalla. Signaali ei ole ”joku mokasi” vaan se mitä tehtävä todella vaatii: yksi siirto joka on paljon parempi kuin mikään vaihtoehto.',
        },
        {
          title: 'Uusi syvä haku, marginaalilla',
          body: 'Selviytyneet haetaan uudestaan syvyydellä 20 MultiPV:llä. Ehdokas jää vain jos paras siirto voittaa toiseksi parhaan vähintään 140 sadasosasotilaalla ja lisäksi todella saavuttaa jotain.',
        },
        {
          title: 'Jatkaminen kunnes se haarautuu',
          body: 'Ratkaisua jatketaan siirto siirrolta niin kauan kuin jokainen ratkaisijan siirto pysyy yksikäsitteisesti parhaana. Sillä hetkellä kun hyviä vastauksia on kaksi, tehtävä päättyy siihen — sillä ei siis koskaan ole haaraa jossa sinut voitaisiin laskea väärässä olevaksi.',
        },
        {
          title: 'Tarkistus tuoreella moottorilla',
          body: 'Koko kokoelma tarkastetaan uudelleen suuremmalla syvyydellä erillisellä skriptillä uudella moottorilla. Mukana tulevassa louhitussa kokoelmassa se hylkäsi 6 tehtävää 172:sta, joiden ratkaisut lakkasivat olemasta yksikäsitteisiä kaksi puolisiirtoa syvemmällä. Ne heitettiin pois eikä toimitettu.',
        },
      ],
    },
    honest: {
      title: 'Ja sama epäluulo sovellettuna loppupeleihin',
      body: [
        'Jokaisen loppupeliharjoituksen ilmoitettu tulos tarkistetaan syvällä haulla eikä oteta sanana. Väärin merkitty harjoitus kaatuu tarkistuksessa sen sijaan että opettaisi sinulle hiljaa jotain epätotta.',
        'Tarkistaja nappaa myös jotain mitä tavalliset shakkikirjastot eivät kerro: onko se puoli joka ei ole siirtovuorossa, shakissa. Sellainen asema on laiton — mikään peli ei voi saavuttaa sitä — mutta kirjasto hyväksyy sen auliisti, ja moottori vastaa bestmove (none), mikä kuulostaa moottorin viasta eikä huonosta asemasta. Kolme käsin kirjoitettua harjoitusta oli rikki juuri tällä tavalla. Tarkistus nappaa sen nyt.',
      ],
    },
    limits: {
      slug: 'Rehelliset rajat',
      title: 'Mitä tämä ei tee.',
      items: [
        {
          title: 'Kokoelma sekoittaa kaksi arvoasteikkoa.',
          body: '{lichess} Lichess-tehtävää kantavat arvoja jotka on kalibroitu miljooniin ihmisyrityksiin. {mined} paikallisesti louhittua tehtävää kantavat arvioita ratkaisusyvyydestä ja aiheesta. Molemmat järjestävät järkevästi, mutta louhittu 1600 ja Lichess-1600 eivät ole mitattu samalla tavalla.',
        },
        {
          title: 'Tehtäväarvot eivät ole lauta-arvoja.',
          body: 'Ne ovat useita satoja pisteitä korkeammalla, ja niin pysyy. Ne mittaavat edistystä itseäsi vastaan, eivät vahvuutta ihmiskentän edessä kellon ääressä — {link}, sillä kuilu on rakenteellinen eikä merkki siitä että viimeistelet huonosti.',
        },
        {
          title: 'Avaustreeniä ei ole.',
          body: 'Tarkoituksella. Avausten opiskelu on ulkoa opettelua itse valitsemaasi repertuaaria vasten, ja se on eri työkalu eri muodossa. Asemallinen tila kattaa avauksesta siirtymisen, ja juuri se osa todella yleistyy.',
        },
        {
          title: 'Tämä ei tee sinusta suurmestaria.',
          body: 'Mikään ei tee sitä yksin. Arvonimet syntyvät tuhansista tunneista sekä arvoturnauspeleistä ihmisiä vastaan. Se mitä täältä saat on siitä harjoittelupuolisko, jäsennettynä, rehellisen mitan kera siitä missä todella olet.',
        },
      ],
      ratingsLink: 'kannattaa ymmärtää kunnolla',
    },
    more: {
      motifs: 'Kaksikymmentä aihetta, määriteltyinä ja laskettuina →',
      engine: 'Miten moottoria käytetään →',
    },
  },

  tactics: {
    head: {
      slug: 'Sanasto',
      title: 'Kaksikymmentä aihetta',
      lede: 'Jokainen taktiikka shakissa on yksi pienestä joukosta muotoja, ja heti kun osaat nimetä ne, näet ne siirtoa aiemmin. Nämä ovat aiheet joilla Brass Pawn merkitsee tehtävänsä — kunkin perässä se, kuinka moni mukana tulevan kirjaston asema todella pyörii sen ympärillä.',
      meta: 'Laskettu mukana tulevasta 14 351 tehtävän kokoelmasta · Viimeksi tarkistettu 19. elokuuta 2026',
    },
    meta: {
      title: 'Kaksikymmentä aihetta',
      description:
        'Jokainen taktinen aihe jolla Brass Pawn merkitsee tehtävänsä, määriteltynä ja laskettuna mukana tulevaa kirjastoa vasten, jotta tiedät mitä todella voit harjoitella.',
    },
    indexLabel: 'Aiheet',
    puzzles: 'tehtävää',
    motifs: [
      {
        name: 'Haarukka',
        short:
          'Yksi nappula hyökkää kahta asiaa vastaan yhtä aikaa, ja vain toinen on pelastettavissa.',
        body: 'Ratsu on kuuluisa haarukoija koska se hyökkää ruutuihin joita mikään muu nappula ei kata samalla tavalla, mutta kaikki haarukoivat: sotilas joka osuu kahteen kevyeen nappulaan, kuningatar joka osuu torniin ja irralliseen lähettiin, kuningas loppupelissä joka astuu kahden sotilaan väliin. Koe ei ole ”hyökkäänkö kahta asiaa vastaan” vaan ”pääsevätkö molemmat pakoon”.',
      },
      {
        name: 'Sidonta',
        short: 'Nappula ei voi siirtyä koska sen takana on jotain arvokkaampaa.',
        body: 'Ehdoton kun takana on kuningas — siirtyminen on laitonta, ei vain huonoa. Suhteellinen kun takana on kuningatar tai torni, jolloin siirtyminen on laillista ja yksinkertaisesti maksaa materiaalia. Jatko voittaa: sidottu nappula on nappula joka ei voi suojata, joten kasaa siihen lisää hyökkääjiä tai lyö siihen sotilaalla.',
      },
      {
        name: 'Varras',
        short: 'Sidonta nurinpäin: arvokas nappula on edessä ja sen on siirryttävä.',
        body: 'Anna kuninkaalle shakki linjaa pitkin tornilla, lähetillä tai kuningattarella, ja se mikä oli takana on sinun heti kun kuningas astuu sivuun. Vartaat ovat harvinaisempia kuin sidonnat koska ne vaativat kaksi nappulaa jo samalla linjalla arvokkaampi edessä — siksi ne ilmestyvät yleensä sen jälkeen kun shakki on pakottanut kuninkaan sinne.',
      },
      {
        name: 'Paljastushyökkäys',
        short: 'Yhden nappulan siirtäminen paljastaa takana olleen hyökkäyksen.',
        body: 'Selvästi vahvin taktiikka shakissa, koska pois siirtyvä nappula on vapaa tekemään jotain omaansa samalla kun paljastunut hyökkäys tekee työn. Kaksi uhkaa syntyy yhdellä siirrolla, eikä kumpaankaan vastata lyömällä siirtynyt nappula.',
      },
      {
        name: 'Paljastusshakki',
        short: 'Paljastunut hyökkäys on shakki, joten vastustajalla ei ole aikaa muuhun.',
        body: 'Paljastushyökkäys jossa takimmainen nappula antaa shakin. Teki pois siirtyvä nappula mitä hyvänsä — lyö kuningattaren, asettuu mattiruutuun, asettuu lyötäväksi — vastauksen on ensin hoidettava shakki, joten se tapahtuu ilmaiseksi.',
      },
      {
        name: 'Kaksoisshakki',
        short:
          'Kaksi nappulaa antaa shakin yhtä aikaa, joten kuninkaan on siirryttävä. Ei suojata, ei lyödä.',
        body: 'Ainoa taktiikka jota vastaan on täsmälleen yhdenlainen laillinen vastaus. Toisen shakkaajan lyöminen jättää toisen; toisen linjan tukkiminen jättää toisen auki. Siksi kaksoisshakki tuottaa matteja jotka näyttävät mahdottomilta — puolustajalla voi olla viisi tapaa pysäyttää kumpikin shakki erikseen eikä yhtään joka pysäyttää molemmat.',
      },
      {
        name: 'Poisohjaus',
        short: 'Pakota puolustaja pois työstä jota se tekee.',
        body: 'Nappula pitää mattiruutua, perusriviä tai toista nappulaa. Hyökkää jotain vastaan jota se arvostaa korkeammalle, tai lyö yksinkertaisesti jotain johon sen on lyötävä takaisin, niin sen antama suoja lähtee mukana. Uhraus näyttää usein järjettömältä kunnes huomaat mitä takaisin lyövä nappula ei enää suojaa.',
      },
      {
        name: 'Houkuttelu',
        short: 'Houkuttele nappula — yleensä kuningas — ruutuun jossa siihen voidaan osua.',
        body: 'Uhraus jonka vastustaja on pakotettu ottamaan, tehtynä ei materiaalin voittamiseksi vaan nappulan asettamiseksi kohtalokkaasti: kuningas raahattuna haarukkaruutuun, kuningatar vedettynä linjalle tornin kanssa. Materiaali palaa siirtoa myöhemmin korkoineen.',
      },
      {
        name: 'Raivaus',
        short: 'Siirrä oma nappulasi pois oman hyökkäyksesi tieltä.',
        body: 'Linja tai ruutu on oikea ja siinä seisoo oma mies. Raivaus siirtää hänet pois tempolla — yleensä shakilla tai lyönnillä, jottei vastustaja ehdi ryhmittyä uudelleen tien avautuessa.',
      },
      {
        name: 'Katkaisu',
        short: 'Katkaise linja puolustajan ja sen välillä mitä se puolustaa.',
        body: 'Aseta nappula — usein uhrattu — täsmälleen tornin ja sen vartioiman ruudun väliin. Puolustaja on yhä laudalla, puolustaa teoriassa yhä, eikä enää voi. Harvinainen, ja yksi vaikeimmin nähtävistä kuvioista, koska katkaiseva nappula näyttää yleensä mokalta.',
      },
      {
        name: 'Röntgenhyökkäys',
        short:
          'Nappula vaikuttaa toisen nappulan läpi, sitä linjaa pitkin jonka se myöhemmin miehittää.',
        body: 'Torni joka puolustaa omaa nappulaansa vihollisnappulan läpi tai hyökkää sen läpi. Vielä ei tapahdu mitään; merkitsevää on se mitä tapahtuu kun välissä oleva nappula siirtyy tai lyödään. Röntgenin näkeminen on yleensä se mikä saa ”materiaalia menettävän” lyönnin olemaan menettämättä materiaalia.',
      },
      {
        name: 'Välisiirto',
        short: 'Siirto välissä: tee jotain pakottavampaa ennen kuin lyöt takaisin.',
        body: 'Saksan sanasta ”Zwischenzug”, ja yleisin yksittäinen syy siihen että laskettu muunnelma osoittautuu vääräksi. Odotat takaisinlyöntiä; sen sijaan tulee shakki tai suurempi uhka, ja siihen mennessä kun takaisinlyönti tapahtuu, asema on muuttunut. Etsi sellaista aina kun sarja näyttää pakotetulta.',
      },
      {
        name: 'Siirtopakko',
        short: 'Itse velvollisuus siirtää on ongelma.',
        body: 'Jokainen laillinen siirto huonontaa asemaa, eikä ohitus ole sallittu. Ennen kaikkea loppupeli-idea — se ratkaisee sotilasloppupelit — ja syy siihen miksi ”oppositio” merkitsee: se joka ensin joutuu astumaan sivuun, luovuttaa ruudun. Lähes ainoa tilanne shakissa jossa oikeus siirtää on taakka.',
      },
      {
        name: 'Perusrivimatti',
        short: 'Omien sotilaidensa sulkema kuningas saa matin ensimmäisellä rivillä.',
        body: 'Yleisin matti niiden pelaajien kesken jotka ovat linnoittaneet ja jättäneet sotilaat rauhaan. Se ilmestyy harvoin mattina laudalla — se ilmestyy uhkana joka voittaa materiaalia, koska jokaisen puolustussiirron on jatkettava rivin kattamista. Koko poisohjaustaktiikoiden perhe on olemassa poistaakseen tuon suojan.',
      },
      {
        name: 'Tukahdutusmatti',
        short: 'Ratsu mattaa kuninkaan jonka omat nappulat ovat sulkeneet sisään.',
        body: 'Philidorin perinnön loppu: kuningatarturhaus g8:ssa, torni lyö takaisin, ratsu f7:ssä antaa matin kuninkaan ollessa omiensa ympäröimä. Harvinainen oikeissa peleissä ja silti tuntemisen arvoinen, sillä juuri tämä kuvio saa sinut katsomaan nurkkaan ja laskemaan pakoruutuja.',
      },
      {
        name: 'Riippuva nappula',
        short: 'Jokin on yksinkertaisesti suojaamaton ja otettavissa.',
        body: 'Ei loisteliasta, ja se ratkaisee enemmän pelejä kuin kaikki muu tällä listalla yhteensä. Useimmat tappiot alle 1800:n ovat toinen pelaaja ottamassa ilmaisen nappulan jonka toinen kadotti näkyvistään. Tapa joka parantaa sen on tarkistaa mikä seisoo irrallaan — molemmilla väreillä — ennen jokaista siirtoa.',
      },
      {
        name: 'Ansaan jäänyt nappula',
        short: 'Nappulalla ei ole turvallista ruutua ja se voidaan ajaa rauhassa nurin.',
        body: 'Yleensä lähetti joka otti sotilaan jonka olisi pitänyt jättää, tai ratsu joka lähti saaliille. Taktiikka ei ole yksi isku vaan kuristus: ota ruudut yksi kerrallaan, niin nappula kaatuu ilman että uhrausta tarvitaan.',
      },
      {
        name: 'Hiljainen siirto',
        short: 'Voittava siirto ei ole shakki, lyönti eikä uhka.',
        body: 'Syy siihen miksi vahvat pelaajat löytävät yhdistelmiä jotka muilta jäävät. Pakotetun sarjan jälkeen vastaus on vaatimaton siirto joka vie viimeisen pakoruudun, ja se on näkymätön sille joka laskee vain shakkeja ja lyöntejä. Kun asema näyttää voitetulta eikä mikään pakottava toimi, etsi hiljainen.',
      },
      {
        name: 'Uhraus',
        short: 'Anna materiaalia jostain joka on materiaalia arvokkaampaa.',
        body: 'Aika, linjat, ruudut tai vihollisen kuninkaan asema. Todellinen uhraus ei ole veto; se on laskelma jolla on konkreettinen loppu. Toimivan uhrauksen erottaa toimimattomasta lähes aina se, ehtivätkö puolustavat nappulat takaisin.',
      },
      {
        name: 'Pitkälle edennyt sotilas',
        short: 'Korotusta lähellä oleva sotilas muuttaa jokaisen muun nappulan arvon.',
        body: 'Sotilas seitsemännellä ei ole sotilas; se on kuningatar jota jonkin on vartioitava, eikä tuo jokin ole enää vapaa. Useimmat loppupelitaktiikat koskevat todellisuudessa jännitettä sotilaan pysäyttämisen ja minkä tahansa muun tekemisen välillä.',
      },
    ],
    after: {
      slug: 'Miksi luvut ovat täällä',
      title: 'Sanasto kertoo mikä haarukka on. Luku kertoo voitko harjoitella sitä.',
      body: [
        'Kuvion nimen tunteminen ja sen löytäminen kellon alla ovat eri taitoja, ja vain jälkimmäinen voittaa pelejä. Jokainen yllä oleva luku on todellinen määrä mukana tulevan kirjaston asemia jotka on merkitty sillä aiheella — ei arvio eikä ylöspäin pyöristetty. Kuusikymmentä röntgentehtävää on kuusikymmentä; jos juuri se on se mikä sinulta jää yhä huomaamatta, on hyvä tietää etteivät ne lopu yhtenä iltana.',
        'Valmentaja seuraa mitkä aiheet menevät sinulta väärin, jotta se voi muutaman sadan tehtävän jälkeen kertoa sinulle ei sitä että olet 1620, vaan että olet 1620 ja kävelet yhä uudestaan poisohjauksiin.',
      ],
      more: 'Miten tehtävät louhitaan ja tarkistetaan →',
    },
  },
};
