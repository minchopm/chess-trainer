import type { Pages } from './types';

/** The four commercial pages in Hungarian. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Támogatás',
      title: 'Kérdezz egy embert',
      lede: 'Nincs jegyrendszer, nincs chatbot, és nincs négyszáz cikkes súgóközpont. Van egy e-mail-cím és egy hibalista, és mindkettő ahhoz fut be, aki az alkalmazást írta.',
    },
    meta: {
      title: 'Támogatás',
      description:
        'Hogyan érsz el egy embert a Brass Pawn ügyében, mit küldj, ha egy feladvány hibás, és a leggyakrabban felmerülő kérdések.',
    },
    email: {
      slug: 'E-mail',
      body: 'Bármiről: hiba, hibás feladvány, vásárlással kapcsolatos kérdés, vagy egyet nem értés egy értékeléssel. Írj angolul vagy bolgárul.',
    },
    tracker: {
      slug: 'Hibalista',
      name: 'GitHub-hibajegyek',
      body: 'Mindenre, amit inkább nyilvánosan intéznél — és mindenre, amit másoknak később meg kell találniuk, ami a hibajelentések többségére igaz.',
    },
    report: {
      slug: 'Ha egy feladvány hibás',
      title: 'Küldj négy dolgot, és az ellenőrzés egy percbe telik.',
      checklist: [
        'A feladványképernyőn látható FEN — tartsd nyomva a másoláshoz.',
        'A lépés, amit tettél, és a lépés, amit az alkalmazás helyesnek mondott.',
        'Melyik módban voltál.',
        'Az alkalmazás verziója, az információs képernyőről.',
      ],
      caveat:
        'A feladványok időnként ellentmondanak egy mélyebb keresésnek, és ezek az ellentmondások hosszú, csendes, magasra értékelt állásokban gyűlnek össze, amelyek lényege mélyebben van, mint ameddig az ellenőrzés elért. Ez az ellenőrzés határa, nem a feladvány hibája — de érdemes tudni, melyek ezek, és az egyetlen módja ennek az, ha szólsz.',
    },
    faq: { slug: 'Kérdések', title: 'Elég gyakran kérdezik ahhoz, hogy leírjuk.' },
    more: {
      ratings: 'Mit mér egy értékszám',
      tactics: 'A motívumok',
      privacy: 'Adatvédelmi tájékoztató',
      terms: 'Felhasználási feltételek',
      licences: 'Licencek',
    },
  },

  pricing: {
    head: {
      slug: 'Mibe kerül',
      title: 'A játék ingyenes. A képzés az, amit eladunk.',
      lede: 'Sakk a motor ellen és sakk ember ellen, korlátlanul, reklám nélkül bárhol az alkalmazásban — ez ingyenes, és az is marad. Amit eladunk, az a könyvtár, a gyakorlatok, a feladványok és az órával való versenyfutás.',
    },
    meta: {
      title: 'Árak',
      description:
        'A játék ingyenes és korlátlan — a motor, egy élő ellenfél és mind a 900 játszma. A Pro leveszi a napi ötös korlátot: 3,99 dollár havonta vagy 49,99 egyszer.',
    },
    free: {
      name: 'Ingyenes',
      note: 'Nincs fiók. Nincs mire feliratkozni.',
      items: [
        'Korlátlan játék a motor ellen, 1400-tól teljes erőig',
        'Korlátlan online játszmák a Game Centeren keresztül',
        'Lépésről lépésre szóló megjegyzés minden lejátszott játszmában',
        'Napi öt taktikai feladvány',
        'Napi öt Rush-futam',
        'Ötöt mindegyikből: pozicionális, végjáték, Találd ki az Élőt',
        'Értékszámok, sorozatok és elosztott ismétlés, teljes egészében',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Havonta',
      per: 'havonta',
      note: 'Bármikor lemondható az Apple-fiókod beállításaiban.',
      items: [
        'Minden napi korlát eltűnik',
        'Mind a(z) {tactics} taktikai feladvány',
        'Mind a(z) {positional} pozicionális gyakorlat',
        'Mind a(z) {endgames} végjátékgyakorlat',
        'Mind a(z) {games} értékelendő játszma',
        'Rush korlát nélkül',
        'Minden az ingyenes verzióból, változatlanul',
      ],
    },
    lifetime: {
      name: 'Egyszeri feloldás',
      once: 'egyszer és mindenkorra',
      note: 'Nem elfogyó vásárlás. Nem újul meg.',
      items: [
        'Pontosan ugyanaz, mint a havi Pro',
        'Nincs megújítás, nincs lejárat, nincsenek emlékeztető levelek',
        'Visszaáll a többi eszközödön',
        'Annak, aki inkább egyszer dönt',
      ],
    },
    table: {
      slug: 'A teljes adag',
      title: 'Mit ad valójában az ingyenes verzió.',
      activity: 'Tevékenység',
      freeCol: 'Ingyenes',
      proCol: 'Pro',
      unlimited: 'Korlátlan',
      fiveADay: 'Napi 5',
      none: 'Nincs',
      rows: [
        'Játék a motor ellen',
        'Online játszmák a Game Centeren keresztül',
        'Nézés — a 900 játszmás könyvtár',
        'Taktikai feladványok',
        'Rush-futamok',
        'Pozicionális gyakorlatok',
        'Végjátékgyakorlatok',
        'Találd ki az Élőt',
        'Reklámok',
      ],
      reset:
        'A napi adagok helyi idő szerint reggel kilenckor nullázódnak — nem éjfélkor, hogy egy esti ülést ne vágjon ketté a dátumváltás.',
    },
    why: {
      slug: 'Miért ilyen az alakja',
      title: 'Három döntés, és mindegyiknek az oka.',
      reasons: [
        {
          title: 'Számolva, nem elzárva',
          body: [
            'Senki nem fizet olyan edzőért, akit nem használt, és egy mód, amely megtagadja a megnyílást, semmit nem mond arról, mi van mögötte. Így minden mód megnyílik, minden nap, és elég messzire jutsz ahhoz, hogy megérezd a ritmust és lásd az értékszámot mozogni.',
            'A vásárlási képernyő soha nem jelenik meg indításkor. Amikor a napi adag elfogyott, a képernyő ezt mondja, és csak egy tudatos koppintás nyitja meg a vásárlási lapot.',
          ],
        },
        {
          title: 'Két ár, nem három',
          body: [
            'Nincs köztük éves csomag, mert egy harmadik ár egy harmadik döntés pontosan abban a pillanatban, amikor valaki meg akar oldani egy feladványt. Havonta, ha ingadozol. Egyszer, ha nem.',
          ],
        },
        {
          title: 'A játékot soha nem áruljuk',
          body: [
            'A motor és az ember elleni sakk semmibe nem kerül üzemeltetni, és ez az oka annak, hogy az alkalmazás létezik. Eladni őket azt jelentené, hogy sorompós sakkalkalmazássá válik edző helyett.',
            'És nincsenek reklámok — részben ízlés, részben licenc. Az alkalmazás két copyleft motort linkel, a Stockfisht GPLv3 alatt és a Recklesst AGPLv3 alatt, és egy zárt hirdetési SDK ugyanabban a bináris fájlban terjeszthetetlenné tenné az egészet. {link}',
          ],
        },
      ],
      licenceLink: 'A licencoldal ezt rendesen végigveszi.',
    },
    answers: {
      slug: 'Vásárlás, lemondás, visszatérítés',
      title: 'A kényelmetlen kérdések, itt megválaszolva e-mail helyett.',
      items: [
        {
          q: 'Hogyan mondom le?',
          a: 'Beállítások → a neved → Előfizetések → Brass Pawn. Nem tudjuk helyetted lemondani, mert az előfizetés közted és az Apple között van, és soha nem volt nálunk. A lemondás megállítja a jövőbeli megújításokat, és nem rövidíti le a már kifizetett időszakot.',
        },
        {
          q: 'Hogyan kapom vissza a pénzem?',
          a: 'Az Apple-n keresztül, itt: {link}. Az App Store-vásárlásokat nem tudjuk visszatéríteni. Ha valami elromlott, írj nekünk — inkább megjavítjuk.',
        },
        {
          q: 'Megvettem a feloldást, és új telefonom van.',
          a: 'Jelentkezz be ugyanazzal az Apple-fiókkal, és koppints a „Vásárlások visszaállítása” gombra a vásárlási képernyőn. Az alkalmazás megkérdezi a StoreKitet, mit birtokolsz; semmi nem fekszik a mi szerverünkön, mert nekünk nincs szerverünk.',
        },
        {
          q: 'Megváltoztatja a Pro az értékszámomat, vagy „jobb” feladványokat old fel?',
          a: 'Nem. Az értékelőrendszer azonos, és a könyvtár minden feladványa elérhető ingyenes fiókkal — napi öt. A Pro a számlálót veszi le, nem függönyt.',
        },
        {
          q: 'Csökken később az ingyenes adag?',
          a: 'Mindkét irányba változhat, ahogy a könyvtár nő. A motor és az ember elleni korlátlan játék nem lesz fizetős funkció; ez a {link} van rögzítve, nem csak itt megígérve.',
        },
      ],
      termsLink: 'feltételekben',
      more: 'További kérdések, és hogyan érsz el egy embert →',
    },
  },

  training: {
    head: {
      slug: 'A program',
      title: 'Nyolc mód meghallani az igazságot',
      lede: 'Ezek közül három örökre ingyenes és korlátlan — a játék, a játék valaki ellen, és a kilencszáz játszma a Nézésben. A másik öt ingyenes fiókkal napi öt, Próval korlátlan. Mindegyik szavakkal értékel az állásról, nem egy számmal, amit előbb meg kell fejteni.',
    },
    meta: {
      title: 'Képzés',
      description:
        'Nyolc mód: taktika, pozicionális ítélet, végjátékok, Rush, Találd ki az Élőt, Nézés, játék megjegyzésekkel és online. Hogyan működik mindegyik, hogyan bányásszuk és ellenőrizzük a feladványokat, és mit nem csinál az edző.',
    },
    modes: [
      {
        title: 'Taktika',
        lede: 'Állások pontosan egy nyerő lépéssel, és ítélet abban a pillanatban, ahogy meglépted.',
        body: [
          'Minden feladványnak egy megoldása van, elágazás nélkül. Lépd meg a táblán, és az edző azonnal megmondja, megtaláltad-e; ha elvéted, az állás holnap visszatér, aztán négy nap múlva, aztán tíz múlva — ameddig még mindig elkap.',
          'Minden feladvány magával hozza a motívumot, ami körül forog — villa, kötés, nyárs, alapsormatt, elterelés, a csendes lépés —, hogy pár száz után az edző ne azt mondhassa neked, hogy 1620 vagy, hanem azt, hogy 1620 vagy, és újra meg újra belesétálsz az elterelésekbe.',
        ],
        free: 'Napi öt ingyenes fiókkal.',
        stat: 'feladvány, 760-tól 2800-ig értékelve',
      },
      {
        title: 'Pozicionális ítélet',
        lede: 'Nincs kikényszerített nyerés. Mondd meg, ki áll jobban, aztán találd meg a lépést, ami megmondja, miért.',
        body: [
          'Ez az a mód, amely azért épült, ami az erős játékosokat elválasztja a jó számolóktól. Először értékelsz: egyértelműen jobb, kicsit jobb, egyensúly. Aztán lépést választasz. Mindkét választ értékeljük.',
          'A visszajelzés konkrét jegyeket nevez meg hangulatok helyett — a nyitott vonalat és hogy áll-e rajta bástya, a huszármezőt, amit egyetlen gyalog sem vitathat, a gyalogszerkezetet, a királybiztonságot, a figuraaktivitás különbségét. Egy állás nem „kellemes világosnak”; négy okból jobb, amiket fel tudsz sorolni.',
        ],
        free: 'Napi öt ingyenes fiókkal.',
        stat: 'csendes állás, a motor által előválogatva',
      },
      {
        title: 'Végjátékok',
        lede: 'Kanonikus állások, végigjátszva egy motor ellen, amely tisztességesen véd.',
        body: [
          'Ismerni az ötletet nem ugyanaz, mint hazahozni, ezért itt tényleg el kell érned az eredményt. A Stockfish veszi a másik oldalt, és a létező legjobb védelmet állítja fel.',
          'Minden lépés után az edző újra ellenőrzi, hogy az eredmény még elérhető-e — és ha nem, megnevezi a pontos lépést, ahol megszűnt annak lenni. Ez az a mondat, ami tanít valamit: nem „döntetlenre vitted”, hanem „itt vitted döntetlenre”.',
        ],
        free: 'Napi öt ingyenes fiókkal.',
        stat: 'gyakorlat, minden eredmény motorral ellenőrizve',
      },
      {
        title: 'Rush',
        lede: 'Futam időre. Oldj meg annyit, amennyit bírsz, mielőtt az óra elveszi a többit.',
        body: [
          'Ugyanazok a feladványok, óra alatt, olyan nehézséggel, amely addig nő, ameddig megtalálod őket. Ez más izmot edz, mint egy feladvány, amit bámulhatsz: azt, amelyiknek most kell látnia.',
          'A futamok pontot kapnak és mentődnek, így a szám hónapok alatt nő, nem egyetlen este alatt.',
        ],
        free: 'Napi öt futam ingyenes fiókkal.',
      },
      {
        title: 'Találd ki az Élőt',
        lede: 'Egy valódi értékelt játszma, lépésről lépésre lejátszva. Milyen erősek voltak ők ketten?',
        body: [
          'Egy játszma szintjét olvasni ugyanaz a készség, mint a saját lépéseidet értékelni: mindkettő arra fut ki, hogy észreveszed, milyen hibák történnek és milyenek nem. Így a játszma pereg, te nézed, és valamikor elköteleződsz egy szám mellett.',
          'A játszmák valódiak, a Lichess archívumaiból, mindkét játékos 150 ponton belül egymástól — a „játékosokra” tett tipp csak akkor jelent valamit, ha egy szintet kell kitalálni.',
        ],
        free: 'Napi öt ingyenes fiókkal.',
        stat: 'értékelt játszma, 800-tól 2599-ig',
      },
      {
        title: 'Nézés',
        lede: 'Kilencszáz megnézésre érdemes játszma — és abban a pillanatban, ahol te másképp léptél volna, átveszed.',
        body: [
          'A könyvtár minden játszmája döntő, két nevesített játékos között, és vagy huszonöt lépésen belül véget ér, vagy elég híres ahhoz, hogy saját neve legyen. Senki nem tanul semmit egy kilencvenlépéses döntetlenből olyan emberek között, akikről soha nem hallott, és az a könyvtár, amelyik ilyet tartalmaz, olyan könyvtár, amit senki nem nyit ki kétszer.',
          'Keress rá egy játékosra, egy versenyre vagy egy évre. Aztán menj végig a játszmán a saját tempódban. Nem a csúcspontokról szól: arról szól, hogy valamelyik lépésnél azt fogod gondolni, <em>ott én ütöttem volna</em> — és abban a pillanatban megteheted. Vedd át az állást, és játssz tovább a motor ellen pontosan arról a mezőről, ahol nem értettél egyet. Kideríteni, mit ért valójában az ötleted, ez maga az egész gyakorlat.',
        ],
        free: 'Ingyenes, korlátlan, mindig.',
        stat: 'játszma, mind döntő',
      },
      {
        title: 'Játék edzővel',
        lede: 'Egy egész játszma az általad választott erővel, minden lépésedet menet közben értékelve.',
        body: [
          'Állítsd a motort valahová 1400 és a teljes erő közé, és játszd végig. Minden lépésedet értékeljük, miközben a játszma még tart, és az edző elmagyarázza, mit ért volna el a jobb lépés — szavakkal az állásról, nem számként.',
          'A végén megkapod a pontosságot, a durva hibák számát, és azt az egy pillanatot, ami a legtöbbe került.',
        ],
        free: 'Ingyenes, korlátlan, mindig.',
      },
      {
        title: 'Online',
        lede: 'Két ember, egy óra, és sehol egy motor.',
        body: [
          'A Game Center talál valakit, aki ugyanazt a tempót választotta — 3, 5, 10, 15 vagy 30 perc. Ez az egyetlen mód motor nélkül: nincs tipp, nincsenek lépésértékek, nincs edzés, mert a segítség, amit csak az egyik oldal kap, nem játszma.',
          'Nincs szerver. A két készülék egymással beszél, és mindkettő betartatja a szabályokat, így egy lépés csak akkor kerül lejátszásra, ha szabályos abban az állásban, amellyel a fogadó készülék már rendelkezik. A hazudó ellenfél eldobott csomagot eredményez, nem szabálytalan táblát.',
        ],
        free: 'Ingyenes, korlátlan, mindig.',
      },
    ],
    watchLink: 'Mi került be a könyvtárba, és mi nem →',
    pipeline: {
      slug: 'Hogyan készül egy feladvány',
      title: 'Kibányászva, nem lemásolva.',
      lede: 'Az állások emlékezetből való leírása azt kockáztatja, hogy a feladvány „megoldása” rossz vagy nem egyértelmű, és ez pontosan a rossz reflexet edzi. Ezért egyiket sem írtuk le emlékezetből. Megtaláljuk őket, aztán támadjuk, amíg túlélik vagy kirepülnek.',
      steps: [
        {
          title: 'Játék emberi erővel',
          body: 'A Stockfish önmaga ellen játszik szándékosan emberi erőn — 1320-tól 2500 Élőig —, és véletlenszerű választással nyit a legjobb sekély jelöltjei közül, hogy a játszmák változatosak legyenek, ahelyett hogy örökké egyetlen változatot ismételnének.',
        },
        {
          title: 'Szűrés a tulajdonságra, nem a baklövésre',
          body: 'Minden állást 12-es mélységben keresünk át két jelöltváltozattal. A jel nem az, hogy „valaki hibázott”, hanem az, amire egy feladványnak valóban szüksége van: egy lépés, amely sokkal jobb minden alternatívánál.',
        },
        {
          title: 'Újabb mély keresés, tartalékkal',
          body: 'A túlélőket újra átkeressük 20-as mélységben MultiPV-vel. Egy jelölt csak akkor marad, ha a legjobb lépés legalább 140 századgyaloggal veri a másodikat, és ténylegesen el is ér valamit.',
        },
        {
          title: 'Hosszabbítás az elágazásig',
          body: 'A megoldást lépésről lépésre hosszabbítjuk, ameddig a megoldó minden lépése egyértelműen a legjobb marad. Abban a pillanatban, amikor két jó válasz van, a feladvány ott véget ér — így soha nincs benne elágazás, amiért tévesnek számíthatnának.',
        },
        {
          title: 'Ellenőrzés friss motorral',
          body: 'Az egész gyűjteményt nagyobb mélységben átvizsgálja egy külön szkript új motorral. A mellékelt kibányászott gyűjteményen ez 172 feladványból 6-ot elvetett, amelyeknek a megoldásai két félépéssel mélyebben megszűntek egyértelműek lenni. Ezeket kidobtuk, nem pedig kiszállítottuk.',
        },
      ],
    },
    honest: {
      title: 'És ugyanez a bizalmatlanság a végjátékokra alkalmazva',
      body: [
        'Minden végjátékgyakorlat megadott eredményét mély kereséssel ellenőrizzük, nem szavára vesszük. Egy rosszul címkézett gyakorlat megbukik az ellenőrzésen, ahelyett hogy csendben valami valótlanra tanítana.',
        'Az ellenőrző azt is elkapja, amit a szokásos sakk-könyvtárak nem mondanak el: hogy sakkban áll-e az a fél, amelyik nincs lépésen. Az ilyen állás szabálytalan — egyetlen játszma sem érheti el —, de a könyvtár készségesen elfogadja, a motor pedig bestmove (none)-nal válaszol, ami motorhibának hangzik, nem rossz állásnak. Három kézzel írt gyakorlat pontosan így volt hibás. Az ellenőrzés ezt most elkapja.',
      ],
    },
    limits: {
      slug: 'Őszinte határok',
      title: 'Mit nem csinál ez.',
      items: [
        {
          title: 'A gyűjtemény két értékelőskálát kever.',
          body: 'A {lichess} Lichess-feladvány olyan értékszámokat hordoz, amelyeket emberi próbálkozások millióihoz kalibráltak. A {mined} helyben kibányászott feladvány becsléseket hordoz a megoldásmélységből és a motívumból. Mindkettő értelmesen rendez, de egy kibányászott 1600 és egy Lichess-1600 nem ugyanúgy van mérve.',
        },
        {
          title: 'A feladványértékszám nem táblaértékszám.',
          body: 'Több száz ponttal magasabban van, és ez így is marad. Az önmagadhoz mért haladást méri, nem az erőt egy emberi mezőnnyel szemben az óra mellett — {link}, mert a szakadék szerkezeti, nem annak jele, hogy rosszul fejezel be.',
        },
        {
          title: 'Nincs megnyitásképzés.',
          body: 'Szándékosan. A megnyitástanulás memorizálás egy általad választott repertoárhoz, és az másik eszköz, más alakkal. A pozicionális mód lefedi a megnyitásból való átmenetet, és éppen ez az a rész, ami valóban általánosítható.',
        },
        {
          title: 'Ez nem csinál belőled nagymestert.',
          body: 'Semmi nem csinálja ezt önmagában. A címek több ezer órából és emberek elleni értékelt versenyjátszmákból jönnek. Amit itt kapsz, az ennek a képzési fele, rendszerezve, őszinte mércével arról, hogy hol állsz valójában.',
        },
      ],
      ratingsLink: 'érdemes rendesen megérteni',
    },
    more: {
      motifs: 'A húsz motívum, meghatározva és megszámolva →',
      engine: 'Hogyan használjuk a motort →',
    },
  },

  tactics: {
    head: {
      slug: 'Szójegyzék',
      title: 'A húsz motívum',
      lede: 'A sakkban minden taktika néhány alak egyike, és amint meg tudod nevezni őket, egy lépéssel korábban látod meg őket. Ezek azok a motívumok, amelyekkel a Brass Pawn a feladványait címkézi — mindegyik után az, hány állás forog valójában körülötte a mellékelt könyvtárban.',
      meta: 'A mellékelt, 14 351 feladványos gyűjteményből számolva · Utoljára ellenőrizve 2026. augusztus 19.',
    },
    meta: {
      title: 'A húsz motívum',
      description:
        'Minden taktikai motívum, amellyel a Brass Pawn a feladványait címkézi, meghatározva és megszámolva a mellékelt könyvtárban, hogy tudd, melyiket gyakorolhatod valóban.',
    },
    indexLabel: 'A motívumok',
    puzzles: 'feladvány',
    motifs: [
      {
        name: 'Villa',
        short: 'Egy figura két dolgot támad egyszerre, és csak az egyik menthető.',
        body: 'A huszár a híres villázó, mert olyan mezőket támad, amelyeket más figura nem fed ugyanúgy, de villázik minden: egy gyalog, amely két könnyűtisztet ér el, egy vezér, amely bástyát és lógó futót ér el, egy király a végjátékban, amely két gyalog közé lép. A próba nem az, hogy „két dolgot támadok-e”, hanem az, hogy „mindkettő el tud-e menekülni”.',
      },
      {
        name: 'Kötés',
        short: 'Egy figura nem tud elmozdulni, mert valami értékesebb áll mögötte.',
        body: 'Abszolút, ha a király áll mögötte — az elmozdulás szabálytalan, nem csupán rossz. Relatív, ha vezér vagy bástya áll mögötte, ahol az elmozdulás szabályos, és egyszerűen anyagba kerül. A folytatás nyer: a megkötött figura olyan figura, amely nem tud fedezni, ezért halmozz rá több támadót, vagy üss rá gyaloggal.',
      },
      {
        name: 'Nyárs',
        short: 'A kötés fordítva: az értékes figura elöl áll, és el kell mozdulnia.',
        body: 'Adj sakkot a királynak egy vonal mentén bástyával, futóval vagy vezérrel, és ami mögötte állt, a tiéd, amint a király félrelép. A nyárs ritkább a kötésnél, mert két figurát kíván már egy vonalon, az értékesebbel elöl — ezért többnyire azután jelenik meg, hogy egy sakk odakényszerítette a királyt.',
      },
      {
        name: 'Felfedett támadás',
        short: 'Egy figura elmozdítása felfedi a mögötte álló támadását.',
        body: 'Messze a legerősebb taktika a sakkban, mert az elmozduló figura szabadon tehet valami sajátot, miközben a felfedett támadás elvégzi a munkát. Két fenyegetés keletkezik egyetlen lépéssel, és egyiket sem lehet az elmozduló figura leütésével megválaszolni.',
      },
      {
        name: 'Felfedett sakk',
        short: 'A felfedett támadás sakk, így az ellenfélnek nincs ideje másra.',
        body: 'Felfedett támadás, ahol a hátsó figura sakkot ad. Bármit tesz az elmozduló figura — vezért üt, mattmezőre áll, leüthetővé teszi magát —, a válasznak először a sakkal kell foglalkoznia, tehát ez ingyen történik.',
      },
      {
        name: 'Kettős sakk',
        short:
          'Két figura ad sakkot egyszerre, tehát a királynak lépnie kell. Nem fedni, nem ütni.',
        body: 'Az egyetlen taktika, amellyel szemben pontosan egyfajta szabályos válasz létezik. Az egyik sakkadó leütése ott hagyja a másikat; az egyik vonal elzárása nyitva hagyja a másikat. Ezért ad a kettős sakk olyan mattokat, amelyek lehetetlennek látszanak — a védőnek lehet öt módja külön-külön megállítani mindegyik sakkot, és egy sem, amely mindkettőt megállítja.',
      },
      {
        name: 'Elterelés',
        short: 'Kényszerítsd el a védőt a munkától, amit végez.',
        body: 'Egy figura mattmezőt, alapsort vagy egy másik figurát tart. Támadj valamit, amit magasabbra értékel, vagy egyszerűen üss le valamit, amire vissza kell ütnie, és a fedezés, amit adott, vele együtt elmegy. Az áldozat gyakran képtelenségnek látszik, amíg észre nem veszed, mit nem fed többé a visszaütő figura.',
      },
      {
        name: 'Odacsalás',
        short: 'Csalj oda egy figurát — rendszerint a királyt — olyan mezőre, ahol elérhető.',
        body: 'Áldozat, amelyet az ellenfél köteles elfogadni, nem anyagnyerésért, hanem hogy egy figurát végzetesen állítson: király villamezőre vonszolva, vezér bástyával közös vonalra húzva. Az anyag egy lépéssel később kamatostul visszatér.',
      },
      {
        name: 'Felszabadítás',
        short: 'Vidd el a saját figurádat a saját támadásod útjából.',
        body: 'A vonal vagy a mező a megfelelő, csak a sajátod áll rajta. A felszabadítás tempóval mozdítja el — rendszerint sakkal vagy ütéssel, hogy az ellenfélnek ne legyen ideje átcsoportosítani, miközben az út megnyílik.',
      },
      {
        name: 'Elzárás',
        short: 'Vágd el a vonalat a védő és a védett dolog között.',
        body: 'Állíts egy figurát — gyakran feláldozottat — pontosan a bástya és az általa őrzött mező közé. A védő még a táblán van, elvileg még véd, és már nem tud. Ritka, és az egyik legnehezebben meglátható minta, mert az elzáró figura rendszerint baklövésnek látszik.',
      },
      {
        name: 'Röntgentámadás',
        short: 'Egy figura egy másik figurán át hat, azon a vonalon, amelyet később elfoglal.',
        body: 'Bástya, amely saját figuráját ellenséges figurán át fedezi, vagy azon át támad. Még semmi nem történik; az számít, mi történik, amikor a közbülső figura elmozdul vagy leütik. Egy röntgen meglátása rendszerint az, ami miatt egy „anyagot vesztő” ütés nem veszít anyagot.',
      },
      {
        name: 'Közbeiktatott lépés',
        short: 'A közbeeső lépés: a visszaütés előtt tégy valami kényszerítőbbet.',
        body: 'A német „Zwischenzug”-ból, és a leggyakoribb egyedi ok, amiért egy kiszámolt változat tévesnek bizonyul. Visszaütést vársz; helyette sakk jön, vagy nagyobb fenyegetés, és mire a visszaütés megtörténik, az állás megváltozott. Keresd minden alkalommal, amikor egy sorozat kényszerítettnek látszik.',
      },
      {
        name: 'Lépéskényszer',
        short: 'Maga a lépéskötelezettség a probléma.',
        body: 'Minden szabályos lépés rontja az állást, és a kihagyás nem megengedett. Elsősorban végjátékötlet — a gyalogvégjátékokat ez dönti el —, és ez az oka annak, hogy az „oppozíció” számít: aki elsőként kényszerül félrelépni, átadja a mezőt. Csaknem az egyetlen helyzet a sakkban, ahol a lépéshez való jog teher.',
      },
      {
        name: 'Alapsormatt',
        short: 'A saját gyalogjaitól bezárt király mattot kap az első soron.',
        body: 'A leggyakoribb matt azok között, akik sáncoltak, és békén hagyták a gyalogokat. Ritkán jelenik meg mattként a táblán — fenyegetésként jelenik meg, amely anyagot nyer, mert minden védekező lépésnek tovább kell fednie a sort. Az elterelő taktikák egész családja azért van, hogy ezt a fedezést eltávolítsa.',
      },
      {
        name: 'Fojtott matt',
        short: 'Huszár mattol egy királyt, akit a saját figurái zártak be.',
        body: 'A Philidor-hagyaték vége: vezéráldozat g8-on, a bástya visszaüt, az f7-es huszár mattot ad, a király pedig a sajátjaival körülvéve. Valódi játszmákban ritka, mégis érdemes ismerni, mert éppen ez a minta készteti arra, hogy a sarokba nézz, és menekülőmezőket számolj.',
      },
      {
        name: 'Lógó figura',
        short: 'Valami egyszerűen fedezetlen, és el lehet venni.',
        body: 'Nem látványos, és több játszmát dönt el, mint ezen a listán minden más együttvéve. A 1800 alatti vereségek többsége az egyik játékos, aki ingyen figurát vesz el, amit a másik szem elől tévesztett. A szokás, ami ezt gyógyítja: minden lépés előtt megnézni, mi áll lazán — mindkét színnél.',
      },
      {
        name: 'Csapdába esett figura',
        short: 'Egy figurának nincs biztonságos mezője, és nyugodtan levadászható.',
        body: 'Rendszerint futó, amely olyan gyalogot ütött le, amit ott kellett volna hagynia, vagy huszár, amely zsákmány után indult. A taktika nem egyetlen csapás, hanem fojtogatás: vedd el a mezőket egyenként, és a figura áldozat nélkül is elesik.',
      },
      {
        name: 'Csendes lépés',
        short: 'A nyerő lépés nem sakk, nem ütés és nem fenyegetés.',
        body: 'Ezért találnak az erős játékosok olyan kombinációkat, amelyeket mások nem vesznek észre. Egy kényszerített sorozat után a válasz egy szerény lépés, amely elveszi az utolsó menekülőmezőt, és láthatatlan annak, aki csak sakkokat és ütéseket számol. Ha egy állás nyertnek látszik, és semmi kényszerítő nem működik, keresd a csendeset.',
      },
      {
        name: 'Áldozat',
        short: 'Adj anyagot valamiért, ami többet ér az anyagnál.',
        body: 'Idő, vonalak, mezők, vagy az ellenséges király helyzete. Az igazi áldozat nem fogadás; számítás konkrét véggel. Ami a működő áldozatot elválasztja a nem működőtől, az szinte mindig az, hogy a védő figurák időben vissza tudnak-e érni.',
      },
      {
        name: 'Előrenyomult gyalog',
        short: 'Az átalakuláshoz közeli gyalog megváltoztatja, mit ér minden más figura.',
        body: 'A hetediken álló gyalog nem gyalog; vezér, amelyet valaminek őriznie kell, és az a valami többé nem szabad. A végjátéktaktikák többsége valójában a gyalog megállítása és bármi más megtétele közti feszültségről szól.',
      },
    ],
    after: {
      slug: 'Miért állnak itt a számok',
      title: 'Egy szójegyzék megmondja, mi a villa. Egy szám megmondja, tudod-e gyakorolni.',
      body: [
        'Ismerni egy minta nevét és megtalálni óra alatt: két különböző készség, és csak a második nyer játszmákat. A fenti minden szám a mellékelt könyvtár azzal a motívummal címkézett állásainak valódi száma — nem becslés, és nem felfelé kerekítve. Hatvan röntgenfeladvány hatvan; ha éppen ez az, amit folyton elnézel, jó tudni, hogy egy este alatt nem fogynak el.',
        'Az edző nyilvántartja, mely motívumokat rontod el, hogy pár száz feladvány után ne azt mondhassa neked, hogy 1620 vagy, hanem azt, hogy 1620 vagy, és újra meg újra belesétálsz az elterelésekbe.',
      ],
      more: 'Hogyan bányásszuk és ellenőrizzük a feladványokat →',
    },
  },
};
