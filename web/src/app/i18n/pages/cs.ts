import type { Pages } from './types';

/** The four commercial pages in Czech. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Podpora',
      title: 'Zeptejte se člověka',
      lede: 'Není tu žádný ticketovací systém, žádný chatbot a žádné centrum nápovědy se čtyřmi sty články. Je tu e-mailová adresa a seznam závad, a obojí končí u toho, kdo tuhle aplikaci napsal.',
    },
    meta: {
      title: 'Podpora',
      description:
        'Jak se dostat k člověku ohledně Brass Pawn, co přiložit, když je úloha špatná, a otázky, které se objevují nejčastěji.',
    },
    email: {
      slug: 'E-mail',
      body: 'Na cokoli: chyba, špatná úloha, dotaz k nákupu nebo nesouhlas s hodnocením. Pište anglicky nebo bulharsky.',
    },
    tracker: {
      slug: 'Seznam závad',
      name: 'Issues na GitHubu',
      body: 'Na všechno, co raději necháte na veřejnosti — a na všechno, co budou muset později najít ostatní, což platí pro většinu hlášení chyb.',
    },
    report: {
      slug: 'Když je úloha špatná',
      title: 'Pošlete čtyři věci a ověření zabere minutu.',
      checklist: [
        'FEN zobrazený na obrazovce úlohy — podržte prstem a zkopírujte ho.',
        'Tah, který jste zahráli, a tah, který aplikace označila za správný.',
        'V jakém režimu to bylo.',
        'Verze aplikace, z obrazovky s informacemi.',
      ],
      caveat:
        'Úlohy občas odporují hlubšímu výpočtu a tyhle rozpory se hromadí u dlouhých, tichých, vysoko hodnocených pozic, jejichž pointa leží hlouběji, než kam ověření dosáhlo. To je hranice ověření, ne chyba v úloze — ale stojí za to vědět, které to jsou, a jediný způsob, jak to zjistit, je vaše hlášení.',
    },
    faq: { slug: 'Otázky', title: 'Ptají se dost často na to, aby se to napsalo.' },
    more: {
      ratings: 'Co měří hodnocení',
      tactics: 'Motivy',
      privacy: 'Zásady soukromí',
      terms: 'Podmínky užívání',
      licences: 'Licence',
    },
  },

  pricing: {
    head: {
      slug: 'Co to stojí',
      title: 'Hraní je zdarma. Prodává se trénink.',
      lede: 'Hra proti enginu a hra proti člověku, bez omezení, bez reklam kdekoli v aplikaci — to je zdarma a zdarma zůstane. Prodává se knihovna, cvičení, úlohy a závod s hodinami.',
    },
    meta: {
      title: 'Ceník',
      description:
        'Hraní je zdarma a neomezené — engine, živý soupeř a všech 900 partií. Pro ruší limit pět denně: 3,99 dolaru měsíčně nebo 49,99 jednorázově.',
    },
    free: {
      name: 'Zdarma',
      note: 'Bez účtu. Není se k čemu registrovat.',
      items: [
        'Neomezená hra proti enginu, od 1400 po plnou sílu',
        'Neomezené partie online přes Game Center',
        'Komentář ke každému tahu v každé odehrané partii',
        'Pět taktických úloh denně',
        'Pět běhů Rush denně',
        'Po pěti z každého: poziční, koncovky, Hádej Elo',
        'Hodnocení, série a rozložené opakování, v plném rozsahu',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Měsíčně',
      per: 'měsíčně',
      note: 'Zrušit lze kdykoli v nastavení účtu Apple.',
      items: [
        'Všechny denní limity pryč',
        'Všech {tactics} taktických úloh',
        'Všech {positional} pozičních cvičení',
        'Všech {endgames} koncovkových cvičení',
        'Všech {games} partií k ohodnocení',
        'Rush bez omezení',
        'Vše z verze zdarma, beze změny',
      ],
    },
    lifetime: {
      name: 'Jednorázové odemknutí',
      once: 'jednou provždy',
      note: 'Nespotřebovatelný nákup. Neobnovuje se.',
      items: [
        'Přesně totéž co Pro měsíčně',
        'Žádné obnovy, žádná expirace, žádné připomínkové e-maily',
        'Obnoví se na vašich dalších zařízeních',
        'Pro ty, kdo se raději rozhodnou jednou',
      ],
    },
    table: {
      slug: 'Celá porce',
      title: 'Co verze zdarma skutečně dává.',
      activity: 'Činnost',
      freeCol: 'Zdarma',
      proCol: 'Pro',
      unlimited: 'Bez omezení',
      fiveADay: '5 denně',
      none: 'Žádné',
      rows: [
        'Hra proti enginu',
        'Partie online přes Game Center',
        'Sledování — knihovna 900 partií',
        'Taktické úlohy',
        'Běhy Rush',
        'Poziční cvičení',
        'Koncovková cvičení',
        'Hádej Elo',
        'Reklamy',
      ],
      reset:
        'Denní porce se nulují v devět ráno místního času — ne o půlnoci, aby večerní sezení nepřeťala změna data v půli.',
    },
    why: {
      slug: 'Proč má tenhle tvar',
      title: 'Tři rozhodnutí a důvod každého z nich.',
      reasons: [
        {
          title: 'Počítá se, nezamyká',
          body: [
            'Nikdo neplatí za trenéra, kterého nepoužil, a režim, který se odmítne otevřít, neřekne nic o tom, co je za ním. Takže každý režim se otevře, každý den, a vy se dostanete dost daleko na to, abyste ucítili rytmus a viděli, jak se hodnocení hýbe.',
            'Nákupní obrazovka se nikdy neobjeví při spuštění. Když denní porce dojde, obrazovka to řekne, a nákupní list otevře až vědomé klepnutí.',
          ],
        },
        {
          title: 'Dvě ceny, ne tři',
          body: [
            'Roční plán mezi nimi není, protože třetí cena je třetí rozhodnutí přesně ve chvíli, kdy někdo chce vyřešit úlohu. Měsíčně, pokud váháte. Jednorázově, pokud ne.',
          ],
        },
        {
          title: 'Hraní se nikdy neprodává',
          body: [
            'Hra proti enginu a proti člověku nic nestojí na provozu a je důvodem, proč tahle aplikace existuje. Prodávat je by z ní udělalo šachovou aplikaci s mýtnou branou místo trenéra.',
            'A reklamy nejsou — částečně vkus, částečně licence. Aplikace váže dva copyleftové enginy, Stockfish pod GPLv3 a Reckless pod AGPLv3, a proprietární reklamní SDK ve stejném binárním souboru by celek učinilo nešiřitelným. {link}',
          ],
        },
      ],
      licenceLink: 'Stránka s licencemi to rozebírá popořadě.',
    },
    answers: {
      slug: 'Nákup, zrušení, vrácení peněz',
      title: 'Nepříjemné otázky, zodpovězené tady místo e-mailem.',
      items: [
        {
          q: 'Jak zrušit předplatné?',
          a: 'Nastavení → vaše jméno → Předplatné → Brass Pawn. Zrušit to za vás nemůžeme, protože předplatné je mezi vámi a Apple a nikdy u nás nebylo. Zrušení zastaví budoucí obnovy a nezkrátí už zaplacené období.',
        },
        {
          q: 'Jak dostanu peníze zpět?',
          a: 'Přes Apple, na {link}. Nákupy z App Store vracet nemůžeme. Pokud je něco rozbité, napište nám — raději to spravíme.',
        },
        {
          q: 'Koupil jsem odemknutí a mám nový telefon.',
          a: 'Přihlaste se ke stejnému účtu Apple a klepněte na „Obnovit nákupy“ na nákupní obrazovce. Aplikace se zeptá StoreKitu, co vlastníte; nic neleží na našem serveru, protože žádný náš server neexistuje.',
        },
        {
          q: 'Změní Pro moje hodnocení nebo odemkne „lepší“ úlohy?',
          a: 'Ne. Hodnoticí systém je totožný a každá úloha v knihovně je dosažitelná s účtem zdarma — pět denně. Pro odstraňuje počítadlo, ne oponu.',
        },
        {
          q: 'Zmenší se porce zdarma později?',
          a: 'Může se změnit oběma směry, jak knihovna roste. Neomezená hra proti enginu a proti člověku se placenou funkcí nestane; to je zapsáno v {link}, ne jen slíbeno tady.',
        },
      ],
      termsLink: 'podmínkách',
      more: 'Další otázky a jak se dostat k člověku →',
    },
  },

  training: {
    head: {
      slug: 'Program',
      title: 'Osm způsobů, jak slyšet pravdu',
      lede: 'Tři z nich jsou zdarma a neomezené navždy — hraní, hraní s někým a devět set partií ve Sledování. Zbylých pět je pět denně s účtem zdarma a bez omezení s Pro. Každý vás hodnotí slovy o pozici místo číslem, které se musí teprve rozluštit.',
    },
    meta: {
      title: 'Trénink',
      description:
        'Osm režimů: taktika, poziční úsudek, koncovky, Rush, Hádej Elo, Sledování, hra s komentářem a online. Jak každý funguje, jak se úlohy těží a ověřují a co trenér nedělá.',
    },
    modes: [
      {
        title: 'Taktika',
        lede: 'Pozice s právě jedním vyhrávajícím tahem a rozsudek ve chvíli, kdy ho zahrajete.',
        body: [
          'Každá úloha má jednu odpověď a žádné odbočky. Zahrajte ji na šachovnici a trenér hned řekne, jestli jste ji našli; když minete, pozice se vrátí zítra, pak za čtyři dny, pak za deset — dokud vás dál chytá.',
          'Každá úloha nese motiv, kolem kterého se točí — vidlička, vazba, špíz, mat na základní řadě, odlákání, tichý tah — aby vám trenér po pár stovkách řekl ne že máte 1620, ale že máte 1620 a pořád naletíte na odlákání.',
        ],
        free: 'Pět denně s účtem zdarma.',
        stat: 'úloh, hodnocených od 760 do 2800',
      },
      {
        title: 'Poziční úsudek',
        lede: 'Není tu vynucená výhra. Řekněte, kdo stojí lépe, a pak najděte tah, který říká proč.',
        body: [
          'Tohle je režim postavený pro to, co odlišuje silné hráče od dobrých počtářů. Nejdřív hodnotíte: zřetelně lépe, o něco lépe, rovnováha. Pak vybíráte tah. Hodnotí se obě odpovědi.',
          'Zpětná vazba pojmenovává konkrétní znaky místo nálad — otevřený sloupec a jestli na něm stojí věž, pole pro jezdce, které žádný pěšec nezpochybní, pěšcová struktura, bezpečnost krále, rozdíl v aktivitě figur. Pozice není „příjemná pro bílého“; je lepší ze čtyř důvodů, které jde vyjmenovat.',
        ],
        free: 'Pět denně s účtem zdarma.',
        stat: 'tichých pozic, předvybraných enginem',
      },
      {
        title: 'Koncovky',
        lede: 'Kanonické pozice, dohrané proti enginu, který se brání slušně.',
        body: [
          'Znát myšlenku není totéž jako ji dovézt, takže tady musíte výsledku skutečně dosáhnout. Stockfish si vezme druhou stranu a postaví nejlepší obranu, jaká existuje.',
          'Po každém tahu trenér znovu ověří, jestli je výsledek pořád dosažitelný — a pokud ne, pojmenuje přesný tah, po kterém přestal být. To je věta, která něco naučí: ne „remizovali jste“, ale „remizovali jste tady“.',
        ],
        free: 'Pět denně s účtem zdarma.',
        stat: 'cvičení, každý výsledek ověřený enginem',
      },
      {
        title: 'Rush',
        lede: 'Běh na čas. Vyřešte jich tolik, kolik stihnete, než hodiny vezmou zbytek.',
        body: [
          'Tytéž úlohy, pod hodinami, s obtížností stoupající tak dlouho, dokud je nacházíte. To trénuje jiný sval než úloha, na kterou se smí zírat: ten, který to musí vidět teď.',
          'Běhy se bodují a ukládají, takže číslo roste přes měsíce, ne přes jeden večer.',
        ],
        free: 'Pět běhů denně s účtem zdarma.',
      },
      {
        title: 'Hádej Elo',
        lede: 'Skutečná hodnocená partie, přehrávaná tah po tahu. Jak silní ti dva byli?',
        body: [
          'Číst úroveň partie je tatáž dovednost jako hodnotit vlastní tahy: obojí se scvrkne na všímání si, jaké chyby se dělají a jaké ne. Takže partie běží, vy se díváte a v určité chvíli se upnete na číslo.',
          'Partie jsou skutečné, z archivů Lichess, s oběma hráči do 150 bodů od sebe — hádat „úroveň hráčů“ dává smysl jen tehdy, když je jedna úroveň k uhádnutí.',
        ],
        free: 'Pět denně s účtem zdarma.',
        stat: 'hodnocených partií, od 800 do 2599',
      },
      {
        title: 'Sledování',
        lede: 'Devět set partií, které stojí za vidění — a ve chvíli, kdy byste zahráli jinak, partii přebíráte.',
        body: [
          'Každá partie v knihovně je rozhodná, mezi dvěma hráči se jménem, a buď skončená do dvaceti pěti tahů, nebo dost slavná na to, aby měla vlastní název. Nikdo se nic nenaučí z devadesátitahové remízy mezi lidmi, o kterých nikdy neslyšel, a knihovna, která tohle obsahuje, je knihovna, kterou nikdo neotevře podruhé.',
          'Vyhledejte hráče, turnaj nebo rok. Pak partii projděte vlastním tempem. Nejde o vrcholné momenty: jde o to, že u některého tahu si pomyslíte <em>já bych tam bral</em> — a v ten okamžik můžete. Přeberte pozici a hrajte dál proti enginu přesně z toho pole, kde jste nesouhlasili. Zjistit, co váš nápad opravdu stál, je celé to cvičení.',
        ],
        free: 'Zdarma, bez omezení, vždy.',
        stat: 'partií, všechny rozhodné',
      },
      {
        title: 'Hra s trenérem',
        lede: 'Celá partie na síle, kterou zvolíte, s každým vaším tahem hodnoceným za pochodu.',
        body: [
          'Nastavte engine někam mezi 1400 a plnou sílu a dohrajte partii. Každý váš tah se hodnotí, dokud partie ještě běží, a trenér vysvětlí, čeho by lepší tah dosáhl — slovy o pozici, ne číslem.',
          'Na konci dostanete přesnost, počet hrubek a ten jeden okamžik, který stál nejvíc.',
        ],
        free: 'Zdarma, bez omezení, vždy.',
      },
      {
        title: 'Online',
        lede: 'Dva lidé, jedny hodiny a žádný engine nablízku.',
        body: [
          'Game Center najde někoho, kdo zvolil stejné tempo — 3, 5, 10, 15 nebo 30 minut. Je to jediný režim bez enginu uvnitř: bez nápovědy, bez hodnocení tahů, bez koučování, protože pomoc, kterou dostává jen jedna strana, není partie.',
          'Server neexistuje. Dvě zařízení spolu mluví a obě vynucují pravidla, takže tah se odehraje jen tehdy, je-li legální v pozici, kterou přijímající zařízení už má. Lhoucí protějšek dá zahozený paket, ne nelegální šachovnici.',
        ],
        free: 'Zdarma, bez omezení, vždy.',
      },
    ],
    watchLink: 'Co se do knihovny dostalo a co ne →',
    pipeline: {
      slug: 'Jak vzniká úloha',
      title: 'Vytěženo, ne opsáno.',
      lede: 'Zapisovat pozice po paměti riskuje úlohu, jejíž „řešení“ je špatné nebo není jediné, a to trénuje přesně opačný reflex. Takže žádná z nich není zapsaná po paměti. Nacházejí se a pak se na ně útočí, dokud nepřežijí nebo neletí pryč.',
      steps: [
        {
          title: 'Hra na lidské síle',
          body: 'Stockfish hraje sám proti sobě na záměrně lidské síle — 1320 až 2500 Elo — a otevírá náhodným výběrem ze svých nejlepších mělkých kandidátů, aby se partie lišily místo věčného opakování jedné varianty.',
        },
        {
          title: 'Prosévání podle vlastnosti, ne podle hrubky',
          body: 'Každá pozice se počítá do hloubky 12 se dvěma kandidátskými variantami. Signálem není „někdo udělal hrubku“, ale to, co úloha opravdu potřebuje: jeden tah mnohem lepší než jakákoli alternativa.',
        },
        {
          title: 'Nový hluboký výpočet, s rezervou',
          body: 'Přeživší se počítají znovu do hloubky 20 s MultiPV. Kandidát zůstane, jen když nejlepší tah předčí druhý alespoň o 140 setin pěšce a skutečně něčeho dosáhne.',
        },
        {
          title: 'Prodlužování až k odbočce',
          body: 'Řešení se prodlužuje tah po tahu tak dlouho, dokud každý tah řešitele zůstává jednoznačně nejlepší. Ve chvíli, kdy jsou dvě dobré odpovědi, úloha tam končí — takže nikdy nemá odbočku, za kterou by vás šlo počítat za chybu.',
        },
        {
          title: 'Ověření čerstvým enginem',
          body: 'Celá sada se přezkoumá do větší hloubky samostatným skriptem s novým enginem. Na dodávané vytěžené sadě to zamítlo 6 ze 172 úloh, jejichž řešení přestávala být jediná o dva půltahy hlouběji. Ty se vyhodily místo dodání.',
        },
      ],
    },
    honest: {
      title: 'A tatáž nedůvěra použitá na koncovky',
      body: [
        'Deklarovaný výsledek každého koncovkového cvičení se ověřuje hlubokým výpočtem, ne přijímá na slovo. Špatně označené cvičení u ověření propadne místo toho, aby vás tiše naučilo nepravdu.',
        'Ověřovatel zachytí i něco, co vám běžné šachové knihovny neřeknou: jestli je strana, která není na tahu, v šachu. Taková pozice je nelegální — žádná partie ji nemůže dosáhnout — ale knihovna ji ochotně přijme a engine odpoví bestmove (none), což zní jako selhání enginu, ne jako špatná pozice. Tři ručně psaná cvičení byla rozbitá přesně takhle. Ověření to teď zachytí.',
      ],
    },
    limits: {
      slug: 'Poctivé hranice',
      title: 'Co tohle nedělá.',
      items: [
        {
          title: 'Sada míchá dvě hodnoticí škály.',
          body: 'Úlohy z {lichess} Lichess nesou hodnocení kalibrovaná na milionech lidských pokusů. {mined} lokálně vytěžených úloh nese odhady z hloubky řešení a motivu. Obě škály řadí smysluplně, ale vytěžená 1600 a lichessová 1600 nejsou měřené stejně.',
        },
        {
          title: 'Hodnocení úloh nejsou hodnocení od šachovnice.',
          body: 'Leží o několik set bodů výš a tak to zůstane. Měří postup vůči vám samotným, ne sílu proti poli lidí u hodin — {link}, protože ten rozdíl je strukturální, ne známka toho, že špatně dohráváte.',
        },
        {
          title: 'Trénink zahájení tu není.',
          body: 'Záměrně. Studium zahájení je memorování vůči repertoáru, který si zvolíte, a to je jiný nástroj jiného tvaru. Poziční režim pokrývá přechod ze zahájení, a to je ta část, která se opravdu zobecňuje.',
        },
        {
          title: 'Velmistra z vás tohle neudělá.',
          body: 'Nic to samo o sobě neudělá. Tituly vznikají z tisíců hodin plus hodnocených turnajových partií proti lidem. Tady dostáváte tréninkovou polovinu toho, uspořádanou, s poctivou mírou toho, kde skutečně stojíte.',
        },
      ],
      ratingsLink: 'stojí za to tomu porozumět správně',
    },
    more: {
      motifs: 'Dvacet motivů, definovaných a spočítaných →',
      engine: 'Jak se používá engine →',
    },
  },

  tactics: {
    head: {
      slug: 'Slovníček',
      title: 'Dvacet motivů',
      lede: 'Každá taktika v šachu je jedním z malého počtu tvarů, a jakmile je umíte pojmenovat, vidíte je o tah dřív. Tohle jsou motivy, kterými Brass Pawn značí své úlohy — u každého následuje, kolik pozic v dodávané knihovně se kolem něj skutečně točí.',
      meta: 'Spočítáno z dodávané sady 14 351 úloh · Naposledy ověřeno 19. srpna 2026',
    },
    meta: {
      title: 'Dvacet motivů',
      description:
        'Každý taktický motiv, kterým Brass Pawn značí své úlohy, definovaný a spočítaný proti dodávané knihovně, abyste věděli, které si opravdu můžete procvičit.',
    },
    indexLabel: 'Motivy',
    puzzles: 'úloh',
    motifs: [
      {
        name: 'Vidlička',
        short: 'Jedna figura útočí na dvě věci najednou a zachránit jde jen jedna.',
        body: 'Jezdec je slavný vidličkář, protože útočí na pole, která žádná jiná figura nekryje stejným způsobem, ale vidličku dělá všechno: pěšec beroucí dvě lehké figury, dáma beroucí věž a volného střelce, král v koncovce vstupující mezi dva pěšce. Zkouškou není „útočím na dvě věci“, ale „mohou uniknout obě“.',
      },
      {
        name: 'Vazba',
        short: 'Figura se nemůže hnout, protože za ní stojí něco cennějšího.',
        body: 'Absolutní, když je za ní král — odchod je nelegální, ne jen špatný. Relativní, když je za ní dáma nebo věž, kde je odchod legální a prostě stojí materiál. Vyhrává pokračování: vázaná figura je figura, která nemůže krýt, takže na ni přidejte útočníky nebo do ní udeřte pěšcem.',
      },
      {
        name: 'Špíz',
        short: 'Vazba naopak: cenná figura stojí vpředu a musí se hnout.',
        body: 'Dejte králi šach po linii věží, střelcem nebo dámou, a to, co stálo za ním, je vaše, jakmile král uhne. Špízy jsou vzácnější než vazby, protože potřebují dvě figury už na jedné linii s cennější vpředu — proto se obvykle objevují až poté, co šach krále na tu linii vyhnal.',
      },
      {
        name: 'Odkrytý útok',
        short: 'Odchod jedné figury odkryje útok té, která stála za ní.',
        body: 'Zdaleka nejsilnější taktika v šachu, protože odcházející figura má volnost dělat něco svého, zatímco odkrytý útok dělá práci. Dvě hrozby vznikají jedním tahem a ani jedna se nedá odrazit sebráním odcházející figury.',
      },
      {
        name: 'Odkrytý šach',
        short: 'Odkrytý útok je šachem, takže soupeř nemá čas na nic jiného.',
        body: 'Odkrytý útok, kde zadní figura dává šach. Ať odcházející figura dělá cokoli — bere dámu, staví se na matové pole, nabízí se k sebrání — odpověď musí nejdřív vyřešit šach, takže se to děje zadarmo.',
      },
      {
        name: 'Dvojšach',
        short: 'Dvě figury šachují naráz, takže král se musí hnout. Ne zaclonit, ne brát.',
        body: 'Jediná taktika, proti níž existuje právě jeden druh legální odpovědi. Sebrání jednoho šachujícího nechá druhého; zaclonění jedné linie nechá otevřenou druhou. Proto dvojšach dává maty, které vypadají nemožně — obránce může mít pět způsobů, jak zastavit každý šach zvlášť, a žádný, který zastaví oba.',
      },
      {
        name: 'Odlákání',
        short: 'Přinuťte obránce odejít od práce, kterou dělá.',
        body: 'Figura drží matové pole, základní řadu nebo jinou figuru. Zaútočte na něco, co cení výš, nebo prostě vezměte něco, na co musí brát zpět, a krytí, které dávala, odejde s ní. Oběť často vypadá absurdně, dokud si nevšimnete, co beroucí figura přestala krýt.',
      },
      {
        name: 'Přilákání',
        short: 'Nalákejte figuru — obvykle krále — na pole, kde ji lze zasáhnout.',
        body: 'Oběť, kterou je soupeř povinen přijmout, zahraná ne pro materiál, ale proto, aby figuru postavila osudově: král vtažený na pole vidličky, dáma vytažená na linii s věží. Materiál se vrátí o tah později i s úroky.',
      },
      {
        name: 'Uvolnění',
        short: 'Odstraňte vlastní figuru z cesty vlastnímu útoku.',
        body: 'Linie nebo pole jsou ty správné, jen na nich stojí váš vlastní muž. Uvolnění ho odsune s tempem — obvykle šachem nebo braním, aby soupeř neměl čas se přeskupit, zatímco se cesta otevírá.',
      },
      {
        name: 'Přerušení',
        short: 'Přetněte linii mezi obráncem a tím, co brání.',
        body: 'Postavte figuru — často obětovanou — přesně mezi věž a pole, které hlídá. Obránce je pořád na šachovnici, teoreticky pořád brání a už nemůže. Vzácné a jeden z nejhůř viditelných vzorců, protože přerušující figura obvykle vypadá jako hrubka.',
      },
      {
        name: 'Rentgen',
        short: 'Figura působí skrz jinou figuru, po linii, kterou obsadí později.',
        body: 'Věž bránící svou figuru skrz soupeřovu figuru nebo skrz ni útočící. Zatím se nic neděje; důležité je, co se stane, až figura uprostřed odejde nebo bude sebrána. Rozpoznat rentgen je obvykle to, co způsobí, že braní „ztrácející materiál“ materiál neztratí.',
      },
      {
        name: 'Mezitah',
        short: 'Tah mezitím: než vezmete zpět, udělejte něco vynucujícího.',
        body: 'Z německého „Zwischenzug“ a nejčastější jednotlivý důvod, proč se spočítaná varianta ukáže jako špatná. Čekáte braní zpět; místo něj přijde šach nebo větší hrozba, a než k braní dojde, pozice se změnila. Hledejte ho pokaždé, když sekvence vypadá vynuceně.',
      },
      {
        name: 'Zugzwang',
        short: 'Problémem je sama povinnost táhnout.',
        body: 'Každý legální tah pozici zhoršuje a vynechat se nesmí. Především koncovková myšlenka — rozhoduje pěšcové koncovky — a důvod, proč záleží na „opozici“: kdo musí uhnout první, odevzdá pole. Téměř jediná situace v šachu, kde je právo táhnout přítěží.',
      },
      {
        name: 'Mat na základní řadě',
        short: 'Král uzavřený vlastními pěšci dostane mat na první řadě.',
        body: 'Nejčastější mat mezi hráči, kteří rošádovali a nechali pěšce na pokoji. Jako mat na šachovnici se objevuje zřídka — objevuje se jako hrozba, která vyhrává materiál, protože každý obranný tah musí řadu dál krýt. Celá rodina odlákávacích taktik existuje proto, aby tohle krytí odstranila.',
      },
      {
        name: 'Dusivý mat',
        short: 'Jezdec matuje krále, kterého uzavřely jeho vlastní figury.',
        body: 'Závěr Philidorova odkazu: oběť dámy na g8, věž bere zpět, jezdec na f7 dává mat a král je obklopen vlastními muži. Ve skutečných partiích vzácný, a přesto stojí za znalost, protože právě tenhle vzorec vás přiměje podívat se do rohu a spočítat úniková pole.',
      },
      {
        name: 'Visící figura',
        short: 'Něco prostě není kryté a dá se to vzít.',
        body: 'Bez lesku, a rozhoduje víc partií než všechno ostatní na tomhle seznamu dohromady. Většina proher pod 1800 je jeden hráč beroucí figuru zdarma, kterou druhý přehlédl. Návyk, který to léčí, je kontrolovat, co stojí volně — u obou barev — před každým tahem.',
      },
      {
        name: 'Uvězněná figura',
        short: 'Figura nemá bezpečné pole a dá se v klidu uštvat.',
        body: 'Obvykle střelec, který vzal pěšce, jehož měl nechat, nebo jezdec, který se vydal na kořist. Taktikou není jediná rána, ale dušení: berte pole jedno po druhém a figura padne, aniž by byla potřeba oběť.',
      },
      {
        name: 'Tichý tah',
        short: 'Vyhrávající tah není šach, braní ani hrozba.',
        body: 'Důvod, proč silní hráči nacházejí kombinace, které jiní přehlédnou. Po vynucené sekvenci je odpovědí skromný tah, který bere poslední únikové pole, a je neviditelný pro toho, kdo počítá jen šachy a braní. Když pozice vypadá vyhraně a nic vynucujícího nefunguje, hledejte ten tichý.',
      },
      {
        name: 'Oběť',
        short: 'Dejte materiál za něco, co má větší cenu než materiál.',
        body: 'Čas, linie, pole nebo postavení soupeřova krále. Skutečná oběť není sázka; je to výpočet s konkrétním koncem. To, co odlišuje fungující oběť od nefungující, je téměř vždy otázka, jestli se bránící figury stihnou vrátit.',
      },
      {
        name: 'Postoupený pěšec',
        short: 'Pěšec blízko proměny mění cenu každé jiné figury.',
        body: 'Pěšec na sedmé není pěšec; je to dáma, kterou něco musí hlídat, a to něco přestává být volné. Většina koncovkových taktik je ve skutečnosti o napětí mezi zastavením pěšce a děláním čehokoli jiného.',
      },
    ],
    after: {
      slug: 'Proč jsou tu ta čísla',
      title: 'Slovníček řekne, co je vidlička. Číslo řekne, jestli se dá procvičit.',
      body: [
        'Znát název vzorce a umět ho najít pod hodinami jsou různé dovednosti a partie vyhrává jen ta druhá. Každé číslo výše je skutečný počet pozic v dodávané knihovně označených tím motivem — ne odhad a ne zaokrouhlení nahoru. Šedesát rentgenových úloh je šedesát; pokud je zrovna tohle to, co pořád míjíte, je dobré vědět, že za jeden večer nedojdou.',
        'Trenér sleduje, které motivy pletete, aby vám po pár stovkách úloh mohl říct ne že máte 1620, ale že máte 1620 a pořád naletíte na odlákání.',
      ],
      more: 'Jak se úlohy těží a ověřují →',
    },
  },
};
