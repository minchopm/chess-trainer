import type { Pages } from './types';

/** The four commercial pages in Dutch. Informal, as the app addresses its player. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Ondersteuning',
      title: 'Vraag het een mens',
      lede: 'Er is geen ticketsysteem, geen chatbot en geen helpcentrum met 400 artikelen erin. Er is een e-mailadres en een lijst met problemen, en beide komen uit bij degene die de app geschreven heeft.',
    },
    meta: {
      title: 'Ondersteuning',
      description:
        'Hoe je een mens bereikt over Brass Pawn, wat je meestuurt als een oefening fout is, en de vragen die het vaakst gesteld worden.',
    },
    email: {
      slug: 'E-mail',
      body: 'Voor alles: een fout, een verkeerde oefening, een vraag over een aankoop, of onenigheid met een beoordeling. Schrijf in het Engels of het Bulgaars.',
    },
    tracker: {
      slug: 'Probleemlijst',
      name: 'GitHub-issues',
      body: 'Voor alles wat je liever openbaar hebt — en voor alles wat anderen later moeten kunnen vinden, wat voor de meeste foutmeldingen geldt.',
    },
    report: {
      slug: 'Als een oefening fout is',
      title: 'Stuur vier dingen en het is in een minuut na te kijken.',
      checklist: [
        'De FEN die op het oefenscherm staat — houd ingedrukt om hem te kopiëren.',
        'De zet die je deed, en de zet die de app goed noemde.',
        'In welke modus je zat.',
        'De appversie, uit het infoscherm.',
      ],
      caveat:
        'Oefeningen spreken af en toe een diepere zoektocht tegen, en die tegenspraak hoopt zich op bij lange, rustige, hoog gewaardeerde stellingen waarvan de pointe dieper ligt dan de controle gezocht heeft. Dat is een grens van de controle en geen fout in de oefening — maar het is de moeite waard te weten welke het zijn, en de enige manier om dat te weten is dat jij het zegt.',
    },
    faq: { slug: 'Vragen', title: 'Vaak genoeg gesteld om op te schrijven.' },
    more: {
      ratings: 'Wat een rating meet',
      tactics: 'De motieven',
      privacy: 'Privacyverklaring',
      terms: 'Gebruiksvoorwaarden',
      licences: 'Licenties',
    },
  },

  pricing: {
    head: {
      slug: 'Wat het kost',
      title: 'Spelen is gratis. De training wordt verkocht.',
      lede: 'Schaken tegen de engine en schaken tegen een mens, onbeperkt, zonder reclame ergens in de app — dat is gratis en dat blijft het. Wat verkocht wordt is de bibliotheek, de oefeningen, de opgaven en de race tegen de klok.',
    },
    meta: {
      title: 'Prijzen',
      description:
        'Spelen is gratis en onbeperkt — de engine, een echte tegenstander en alle 900 partijen. Pro haalt de limiet van vijf per dag weg: 3,99 dollar per maand of 49,99 eenmalig.',
    },
    free: {
      name: 'Gratis',
      note: 'Geen account. Niets om je voor aan te melden.',
      items: [
        'Onbeperkt spelen tegen de engine, 1400 tot volle sterkte',
        'Onbeperkt online partijen via Game Center',
        'Zet voor zet commentaar in elke partij die je speelt',
        'Vijf tactiekoefeningen per dag',
        'Vijf Rush-runs per dag',
        'Vijf van elk: positioneel, eindspel, Raad de Elo',
        'Ratings, reeksen en gespreide herhaling, volledig',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Maandelijks',
      per: 'per maand',
      note: 'Wanneer je wilt op te zeggen in de instellingen van je Apple-account.',
      items: [
        'Elke daglimiet weg',
        'Alle {tactics} tactiekoefeningen',
        'Alle {positional} positionele oefeningen',
        'Alle {endgames} eindspeloefeningen',
        'Alle {games} partijen om te beoordelen',
        'Rush zonder limiet',
        'Alles uit Gratis, ongewijzigd',
      ],
    },
    lifetime: {
      name: 'Eenmalige ontgrendeling',
      once: 'eenmalig',
      note: 'Een niet-verbruikbare aankoop. Hij verlengt niet.',
      items: [
        'Precies hetzelfde als Pro maandelijks',
        'Geen verlenging, geen vervaldatum, geen herinneringsmails',
        'Wordt hersteld op je andere apparaten',
        'Voor wie liever één keer beslist',
      ],
    },
    table: {
      slug: 'De hele portie',
      title: 'Wat de gratis versie werkelijk geeft.',
      activity: 'Activiteit',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Onbeperkt',
      fiveADay: '5 per dag',
      none: 'Geen',
      rows: [
        'Spelen tegen de engine',
        'Online partijen via Game Center',
        'Kijken — de bibliotheek van 900 partijen',
        'Tactiekoefeningen',
        'Rush-runs',
        'Positionele oefeningen',
        'Eindspeloefeningen',
        'Raad de Elo',
        'Reclame',
      ],
      reset:
        'De dagporties gaan om negen uur ’s ochtends lokale tijd op nul — niet om middernacht, zodat een avondsessie niet doormidden wordt gesneden door een datumwissel.',
    },
    why: {
      slug: 'Waarom het zo gevormd is',
      title: 'Drie beslissingen, en de reden voor elk.',
      reasons: [
        {
          title: 'Geteld, niet op slot',
          body: [
            'Niemand betaalt voor een trainer die hij niet gebruikt heeft, en een modus die weigert open te gaan leert niets over wat erachter zit. Dus elke modus gaat open, elke dag, en je komt ver genoeg om het ritme te voelen en de rating te zien bewegen.',
            'De betaalmuur verschijnt nooit bij het opstarten. Als de portie van de dag op is, zegt het scherm dat, en pas een bewuste tik opent het koopblad.',
          ],
        },
        {
          title: 'Twee prijzen, geen drie',
          body: [
            'Er zit geen jaarplan tussen, want een derde prijs is een derde beslissing op precies het moment dat iemand een oefening wil oplossen. Maandelijks als je twijfelt. Eenmalig als je dat niet doet.',
          ],
        },
        {
          title: 'Spelen wordt nooit verkocht',
          body: [
            'Schaken tegen de engine en tegen een mens kosten niets om te draaien en zijn de reden dat de app bestaat. Ze verkopen zou hier een schaakapp met een tolhek van maken in plaats van een trainer.',
            'En er is geen reclame — deels smaak, deels licentie. De app koppelt twee copyleft-engines, Stockfish onder de GPLv3 en Reckless onder de AGPLv3, en een propriëtaire advertentie-SDK in hetzelfde binaire bestand zou het geheel onverspreidbaar maken. {link}',
          ],
        },
      ],
      licenceLink: 'De licentiepagina legt het netjes uit.',
    },
    answers: {
      slug: 'Kopen, opzeggen, terugbetaling',
      title: 'De ongemakkelijke vragen, hier beantwoord in plaats van per e-mail.',
      items: [
        {
          q: 'Hoe zeg ik op?',
          a: 'Instellingen → je naam → Abonnementen → Brass Pawn. Wij kunnen het niet voor je opzeggen, want het abonnement is tussen jou en Apple en is nooit bij ons geweest. Opzeggen stopt toekomstige verlengingen en verkort de al betaalde periode niet.',
        },
        {
          q: 'Hoe krijg ik mijn geld terug?',
          a: 'Via Apple, op {link}. Wij kunnen geen aankopen uit de App Store terugbetalen. Als er iets stuk is, schrijf ons — wij repareren het liever.',
        },
        {
          q: 'Ik heb de ontgrendeling gekocht en een nieuwe telefoon.',
          a: 'Log in met hetzelfde Apple-account en tik op „Aankopen herstellen” op het koopscherm. De app vraagt StoreKit wat je bezit; er staat niets op een server van ons, want er is geen server van ons.',
        },
        {
          q: 'Verandert Pro mijn rating of ontgrendelt het „betere” oefeningen?',
          a: 'Nee. Het ratingsysteem is identiek en elke oefening in de bibliotheek is bereikbaar met een gratis account — vijf per dag. Pro haalt de teller weg, geen gordijn.',
        },
        {
          q: 'Wordt de gratis portie later kleiner?',
          a: 'Hij kan beide kanten op veranderen naarmate de bibliotheek groeit. Onbeperkt spelen tegen de engine en tegen een mens wordt geen betaalde functie; dat staat in de {link} en is niet alleen hier beloofd.',
        },
      ],
      termsLink: 'voorwaarden',
      more: 'Meer vragen, en hoe je een mens bereikt →',
    },
  },

  training: {
    head: {
      slug: 'Het programma',
      title: 'Acht manieren om de waarheid te horen',
      lede: 'Drie ervan zijn voor altijd gratis en onbeperkt — spelen, tegen iemand spelen, en de negenhonderd partijen in Kijken. De andere vijf zijn vijf per dag met een gratis account en onbeperkt met Pro. Elk beoordeelt je met woorden over de stelling in plaats van met een getal dat je moet duiden.',
    },
    meta: {
      title: 'Training',
      description:
        'Acht modi: tactiek, positioneel oordeel, eindspelen, Rush, Raad de Elo, Kijken, spelen met commentaar en online. Hoe elk werkt, hoe de oefeningen gewonnen en gecontroleerd worden, en wat de trainer niet doet.',
    },
    modes: [
      {
        title: 'Tactiek',
        lede: 'Stellingen met precies één winnende zet, en een oordeel op het moment dat je hem speelt.',
        body: [
          'Elke oefening heeft één antwoord en geen vertakkingen. Speel hem op het bord en de trainer zegt meteen of je hem gevonden hebt; mis je hem, dan komt de stelling morgen terug, daarna over vier dagen, daarna over tien — zolang hij je blijft betrappen.',
          'Elke oefening draagt het motief waar hij om draait — vork, penning, spies, achterstemat, afleiding, de stille zet — zodat de trainer je na een paar honderd niet kan vertellen dat je 1620 bent, maar dat je 1620 bent en steeds langs afleidingen loopt.',
        ],
        free: 'Vijf per dag met een gratis account.',
        stat: 'oefeningen, gewaardeerd van 760 tot 2800',
      },
      {
        title: 'Positioneel oordeel',
        lede: 'Er is geen geforceerde winst. Zeg wie beter staat, en vind dan de zet die zegt waarom.',
        body: [
          'Dit is de modus gemaakt voor wat sterke spelers scheidt van goede rekenaars. Eerst beoordeel je: duidelijk beter, iets beter, in evenwicht. Daarna kies je een zet. Beide antwoorden worden beoordeeld.',
          'De terugkoppeling noemt concrete kenmerken in plaats van stemmingen — de open lijn en of er een toren op staat, het paardveld dat geen pion kan betwisten, de pionnenstructuur, de koningsveiligheid, het verschil in stukactiviteit. Een stelling is niet „prettig voor wit”; ze is beter door vier dingen die je kunt opsommen.',
        ],
        free: 'Vijf per dag met een gratis account.',
        stat: 'rustige stellingen, voorgeselecteerd door de engine',
      },
      {
        title: 'Eindspelen',
        lede: 'Canonieke stellingen, uitgespeeld tegen een engine die fatsoenlijk verdedigt.',
        body: [
          'Het idee kennen is niet hetzelfde als het binnenhalen, dus hier moet je het resultaat echt bereiken. Stockfish neemt de andere kant en zet de beste verdediging op die er is.',
          'Na elke zet controleert de trainer opnieuw of het resultaat nog haalbaar is — en zo niet, dan noemt hij de precieze zet waarop het dat niet meer was. Dat is de zin die iets leert: niet „je hebt remise gemaakt”, maar „je hebt hier remise gemaakt”.',
        ],
        free: 'Vijf per dag met een gratis account.',
        stat: 'oefeningen, elk resultaat door de engine gecontroleerd',
      },
      {
        title: 'Rush',
        lede: 'Een run op tijd. Los er zoveel op als je kunt voordat de klok de rest neemt.',
        body: [
          'Dezelfde oefeningen, tegen de klok, met een moeilijkheid die stijgt zolang je ze blijft vinden. Dat traint een andere spier dan een oefening waar je naar mag staren: die het nú moet zien.',
          'Runs worden gescoord en bewaard, zodat het getal over maanden stijgt in plaats van over één avond.',
        ],
        free: 'Vijf runs per dag met een gratis account.',
      },
      {
        title: 'Raad de Elo',
        lede: 'Een echte gewaardeerde partij, zet voor zet afgespeeld. Hoe sterk waren deze twee?',
        body: [
          'Het niveau van een partij lezen is dezelfde vaardigheid als je eigen zetten beoordelen: beide komen neer op opmerken welke fouten gemaakt worden en welke niet. Dus de partij loopt, jij kijkt, en op een gegeven moment leg je je vast op een getal.',
          'De partijen zijn echt, uit de archieven van Lichess, met beide spelers binnen 150 punten van elkaar — een gok over „de spelers” betekent alleen iets als er één niveau te raden valt.',
        ],
        free: 'Vijf per dag met een gratis account.',
        stat: 'gewaardeerde partijen, van 800 tot 2599',
      },
      {
        title: 'Kijken',
        lede: 'Negenhonderd partijen die het kijken waard zijn — en op het moment dat jij anders had gespeeld, neem je hem over.',
        body: [
          'Elke partij in de bibliotheek is beslissend, tussen twee spelers met een naam, en ofwel binnen vijfentwintig zetten afgelopen ofwel beroemd genoeg om een eigen naam te hebben. Niemand leert iets van een remise van negentig zetten tussen mensen van wie hij nooit gehoord heeft, en een bibliotheek die die bevat is een bibliotheek die niemand twee keer opent.',
          'Zoek een speler op, of een toernooi, of een jaar. Speel de partij dan in je eigen tempo door. Het gaat niet om de hoogtepunten: het gaat erom dat je bij een zet zult denken <em>ik had daar geslagen</em> — en op dat moment kan dat. Neem de stelling over en speel tegen de engine verder vanaf precies het veld waar je het oneens was. Uitvinden wat je idee werkelijk waard was is de hele oefening.',
        ],
        free: 'Gratis, onbeperkt, altijd.',
        stat: 'partijen, allemaal beslissend',
      },
      {
        title: 'Spelen met coach',
        lede: 'Een hele partij op de sterkte die je kiest, met elke zet van jou beoordeeld terwijl je speelt.',
        body: [
          'Zet de engine ergens tussen 1400 en volle sterkte en speel hem uit. Elke zet van jou wordt beoordeeld terwijl de partij nog loopt, en de coach legt uit wat de betere zet had bereikt — in woorden over de stelling, niet als getal.',
          'Aan het eind krijg je nauwkeurigheid, het aantal blunders, en het ene moment dat je het meest gekost heeft.',
        ],
        free: 'Gratis, onbeperkt, altijd.',
      },
      {
        title: 'Online',
        lede: 'Twee mensen, één klok, en geen engine in de buurt.',
        body: [
          'Game Center vindt iemand die hetzelfde tempo koos — 3, 5, 10, 15 of 30 minuten. Het is de ene modus zonder engine erin: geen hint, geen zetwaarden, geen coaching, want hulp die maar één kant krijgt is geen partij.',
          'Er is geen server. De twee apparaten praten met elkaar en passen allebei de regels toe, dus een zet wordt alleen gespeeld als hij geldig is in de stelling die het ontvangende apparaat al heeft. Een tegenpartij die liegt levert een weggegooid pakket op, geen ongeldig bord.',
        ],
        free: 'Gratis, onbeperkt, altijd.',
      },
    ],
    watchLink: 'Wat in de bibliotheek kwam en wat niet →',
    pipeline: {
      slug: 'Hoe een oefening gemaakt wordt',
      title: 'Gewonnen, niet overgeschreven.',
      lede: 'Stellingen uit het hoofd opschrijven riskeert een oefening waarvan de „oplossing” fout of niet uniek is, en dat traint precies het verkeerde instinct. Dus geen van hen is uit het hoofd opgeschreven. Ze worden gevonden en daarna aangevallen tot ze het overleven of worden weggegooid.',
      steps: [
        {
          title: 'Spelen, op menselijke sterkte',
          body: 'Stockfish speelt tegen zichzelf op bewust menselijke sterkte — 1320 tot 2500 Elo — en opent met een willekeurige keuze uit zijn beste ondiepe kandidaten, zodat de partijen variëren in plaats van één lijn eeuwig te herhalen.',
        },
        {
          title: 'Zeven op de eigenschap, niet op de blunder',
          body: 'Elke stelling wordt op diepte 12 doorzocht met twee kandidaatlijnen. Het signaal is niet „iemand heeft geblunderd” maar wat een oefening werkelijk nodig heeft: één zet die veel beter is dan elk alternatief.',
        },
        {
          title: 'Opnieuw diep zoeken, met marge',
          body: 'De overlevenden worden opnieuw doorzocht op diepte 20 met MultiPV. Een kandidaat blijft alleen als de beste zet de tweede met minstens 140 honderdste pion verslaat en ook werkelijk iets bereikt.',
        },
        {
          title: 'Verlengen tot het vertakt',
          body: 'De oplossing wordt zet voor zet verlengd zolang elke zet van de oplosser uniek de beste blijft. Op het moment dat er twee goede antwoorden zijn, eindigt de oefening daar — hij heeft dus nooit een vertakking waarvoor je fout gerekend kan worden.',
        },
        {
          title: 'Controleren met een verse engine',
          body: 'De hele verzameling wordt op grotere diepte nagekeken door een apart script met een nieuwe engine. Op de meegeleverde gewonnen verzameling verwierp dat 6 van de 172 oefeningen waarvan de oplossingen twee halve zetten dieper niet meer uniek waren. Die zijn weggegooid in plaats van uitgeleverd.',
        },
      ],
    },
    honest: {
      title: 'En hetzelfde wantrouwen toegepast op de eindspelen',
      body: [
        'Het opgegeven resultaat van elke eindspeloefening wordt tegen een diepe zoektocht gecontroleerd in plaats van op gezag aangenomen. Een verkeerd gelabelde oefening zakt voor de controle in plaats van je stilletjes iets onwaars te leren.',
        'De controleur vangt ook iets op wat de gebruikelijke schaakbibliotheken je niet vertellen: of de partij die niet aan zet is schaak staat. Zo’n stelling is ongeldig — geen partij kan hem bereiken — maar een bibliotheek accepteert hem gewillig, en de engine antwoordt met bestmove (none), wat klinkt als een storing van de engine in plaats van een slechte stelling. Drie met de hand geschreven oefeningen waren precies zo fout. De controle vangt het nu op.',
      ],
    },
    limits: {
      slug: 'Eerlijke grenzen',
      title: 'Wat dit niet doet.',
      items: [
        {
          title: 'De verzameling mengt twee ratingschalen.',
          body: 'De {lichess} Lichess-oefeningen dragen ratings die geijkt zijn aan miljoenen menselijke pogingen. De {mined} lokaal gewonnen oefeningen dragen schattingen uit oplossingsdiepte en motief. Beide ordenen zinnig, maar een gewonnen 1600 en een Lichess-1600 zijn niet op dezelfde manier gemeten.',
        },
        {
          title: 'Oefeningratings zijn geen bordratings.',
          body: 'Ze liggen enkele honderden punten hoger, en dat blijft zo. Ze meten vooruitgang tegen jezelf, niet sterkte tegen een veld mensen aan de klok — {link}, want het gat is structureel en geen teken dat je slecht afmaakt.',
        },
        {
          title: 'Er is geen openingstraining.',
          body: 'Met opzet. Openingsstudie is uit het hoofd leren tegen een repertoire dat jij kiest, en dat is een ander gereedschap met een andere vorm. De positionele modus dekt de overgang uit de opening, en dat is het deel dat zich werkelijk laat veralgemenen.',
        },
        {
          title: 'Dit maakt je geen grootmeester.',
          body: 'Niets doet dat op zichzelf. Titels komen uit duizenden uren plus gewaardeerde toernooipartijen tegen mensen. Wat dit je geeft is de trainingshelft daarvan, gestructureerd, met een eerlijke maat van waar je werkelijk staat.',
        },
      ],
      ratingsLink: 'wat het waard is goed te begrijpen',
    },
    more: {
      motifs: 'De twintig motieven, gedefinieerd en geteld →',
      engine: 'Hoe de engine gebruikt wordt →',
    },
  },

  tactics: {
    head: {
      slug: 'Woordenlijst',
      title: 'De twintig motieven',
      lede: 'Elke tactiek in het schaken is een van een klein aantal vormen, en zodra je ze kunt benoemen zie je ze een zet eerder. Dit zijn de motieven waarmee Brass Pawn zijn oefeningen labelt — elk gevolgd door hoeveel stellingen in de meegeleverde bibliotheek er werkelijk om draaien.',
      meta: 'Geteld uit de meegeleverde verzameling van 14.351 oefeningen · Laatst nagekeken 19 augustus 2026',
    },
    meta: {
      title: 'De twintig motieven',
      description:
        'Elk tactisch motief waarmee Brass Pawn zijn oefeningen labelt, gedefinieerd en geteld tegen de meegeleverde bibliotheek, zodat je weet welke je werkelijk kunt oefenen.',
    },
    indexLabel: 'De motieven',
    puzzles: 'oefeningen',
    motifs: [
      {
        name: 'Vork',
        short: 'Eén stuk valt twee dingen tegelijk aan, en maar één ervan is te redden.',
        body: 'Het paard is de beroemde vorker omdat het velden aanvalt die geen ander stuk op dezelfde manier dekt, maar elk stuk vorkt: een pion die twee lichte stukken raakt, een dame die een toren en een losse loper raakt, een koning in het eindspel die tussen twee pionnen stapt. De toets is niet „val ik twee dingen aan” maar „kunnen ze er allebei uit”.',
      },
      {
        name: 'Penning',
        short: 'Een stuk kan niet weg omdat er iets waardevollers achter staat.',
        body: 'Absoluut als de koning erachter staat — wegzetten is ongeldig, niet slechts slecht. Relatief als er een dame of toren achter staat, waar wegzetten geldig is en simpelweg materiaal kost. Het vervolg wint: een gepend stuk is een stuk dat niet kan dekken, dus stapel er meer aanvallers op, of raak het met een pion.',
      },
      {
        name: 'Spies',
        short: 'Een penning andersom: het waardevolle stuk staat vóór en moet weg.',
        body: 'Geef de koning schaak op een lijn met toren, loper of dame, en wat erachter stond is van jou zodra de koning opzij stapt. Spiesen zijn zeldzamer dan penningen omdat ze de twee stukken al op één lijn nodig hebben met het waardevolle vooraan — daarom verschijnen ze meestal nadat een schaak de koning op die lijn heeft gedwongen.',
      },
      {
        name: 'Aftrekaanval',
        short: 'Eén stuk wegzetten ontmaskert de aanval van het stuk erachter.',
        body: 'Met afstand de sterkste tactiek in het schaken, omdat het stuk dat weggaat vrij is iets van zichzelf te doen terwijl de ontmaskerde aanval het werk doet. Twee dreigingen ontstaan in één zet, en geen van beide is te beantwoorden door het wegtrekkende stuk te slaan.',
      },
      {
        name: 'Aftrekschaak',
        short:
          'De ontmaskerde aanval is een schaak, dus de tegenstander heeft nergens anders tijd voor.',
        body: 'Een aftrekaanval waarbij het stuk erachter schaak geeft. Wat het wegtrekkende stuk ook doet — een dame slaan, naar een matveld lopen, zichzelf laten slaan — het antwoord moet eerst het schaak afhandelen, dus het gebeurt gratis.',
      },
      {
        name: 'Dubbelschaak',
        short:
          'Twee stukken geven tegelijk schaak, dus de koning moet weg. Niet dekken, niet slaan.',
        body: 'De enige tactiek waartegen precies één soort geldig antwoord bestaat. Eén schaakgever slaan laat de andere staan; één lijn blokkeren laat de andere open. Daarom levert dubbelschaak matten op die onmogelijk lijken — de verdediger kan vijf manieren hebben om elk schaak apart te stoppen en geen enkele die ze allebei stopt.',
      },
      {
        name: 'Afleiding',
        short: 'Dwing een verdediger weg van het werk dat hij doet.',
        body: 'Een stuk houdt een matveld, een achterste rij of een ander stuk. Val iets aan dat het hoger acht, of sla gewoon iets dat het moet terugslaan, en de dekking die het gaf verdwijnt ermee. Het offer lijkt vaak absurd tot je merkt wat het terugslaande stuk niet meer dekt.',
      },
      {
        name: 'Lokzet',
        short: 'Lok een stuk — meestal de koning — naar een veld waar het geraakt kan worden.',
        body: 'Ook aas genoemd. Een offer dat de tegenstander verplicht is aan te nemen, gespeeld niet om materiaal te winnen maar om een stuk ergens fataal neer te zetten: een koning die naar een vorkveld gesleept wordt, een dame die op een lijn met een toren getrokken wordt. Het materiaal komt een zet later met rente terug.',
      },
      {
        name: 'Ruiming',
        short: 'Haal je eigen stuk uit de weg van je eigen aanval.',
        body: 'De lijn of het veld is het juiste en er staat een eigen man op. De ruiming zet hem weg met tempo — meestal met schaak of een slag, zodat de tegenstander geen tijd heeft zich te hergroeperen terwijl de weg opengaat.',
      },
      {
        name: 'Onderbreking',
        short: 'Snijd de lijn door tussen een verdediger en wat hij verdedigt.',
        body: 'Zet een stuk — vaak een geofferd — precies tussen een toren en het veld dat hij bewaakt. De verdediger staat nog op het bord, verdedigt in theorie nog, en kan het niet meer. Zeldzaam, en een van de moeilijkst te zien patronen, omdat het onderbrekende stuk er meestal uitziet als een blunder.',
      },
      {
        name: 'Röntgenaanval',
        short: 'Een stuk werkt door een ander stuk heen, langs de lijn die het later zal bezetten.',
        body: 'Een toren die zijn eigen stuk dekt door een vijandelijk stuk heen, of erdoorheen aanvalt. Er gebeurt nog niets; wat telt is wat er gebeurt zodra het stuk ertussen weggaat of geslagen wordt. Een röntgenaanval herkennen is meestal wat een slag die „materiaal verliest” toch geen materiaal laat verliezen.',
      },
      {
        name: 'Tussenzet',
        short: 'De zet ertussen: doe vóór het terugslaan iets dwingenders.',
        body: 'Uit het Duits, „Zwischenzug”, en de meest voorkomende enkele reden dat een berekende variant fout blijkt. Je verwacht een terugslag; in plaats daarvan komt een schaak, of een grotere dreiging, en tegen de tijd dat het terugslaan gebeurt is de stelling veranderd. Zoek er een telkens als een reeks gedwongen lijkt.',
      },
      {
        name: 'Zetdwang',
        short: 'Moeten zetten is zelf het probleem.',
        body: 'Elke geldige zet maakt de stelling slechter, en passen mag niet. Vooral een eindspelidee — koning-en-pion-eindspelen worden erdoor beslist — en de reden dat „de oppositie” telt: wie als eerste opzij moet, verliest het veld. Bijna de enige situatie in het schaken waarin het recht om te zetten een last is.',
      },
      {
        name: 'Achterstemat',
        short: 'Een koning ingesloten door zijn eigen pionnen, mat op de eerste rij.',
        body: 'Het meest voorkomende mat tussen spelers die gerokeerd hebben en de pionnen met rust lieten. Het verschijnt zelden als mat op het bord — het verschijnt als dreiging die materiaal wint, omdat elke verdedigende zet de rij moet blijven dekken. De hele familie van afleidingstactieken bestaat om die dekking weg te halen.',
      },
      {
        name: 'Verstikkingsmat',
        short: 'Een paard zet een koning mat die zijn eigen stukken hebben ingesloten.',
        body: 'Het slot van Philidors nalatenschap: dameoffer op g8, de toren slaat terug, het paard op f7 geeft mat met de koning omringd door zijn eigen mannen. Zeldzaam in echte partijen en toch het weten waard, want het patroon is wat je een hoek laat bekijken en vluchtvelden laat tellen.',
      },
      {
        name: 'Hangend stuk',
        short: 'Iets is simpelweg ongedekt en kan genomen worden.',
        body: 'Niet glamoureus, en het beslist meer partijen dan al het andere op deze lijst bij elkaar. De meeste nederlagen onder 1800 zijn de ene speler die een gratis stuk pakt dat de andere uit het oog verloor. De gewoonte die het verhelpt is nagaan wat los staat — bij beide kleuren — vóór elke zet.',
      },
      {
        name: 'Ingesloten stuk',
        short: 'Een stuk heeft geen veilig veld en kan op je gemak worden opgejaagd.',
        body: 'Meestal een loper die een pion nam die hij had moeten laten staan, of een paard dat op strooptocht ging. De tactiek is geen enkele klap maar een wurggreep: neem de velden een voor een weg en het stuk valt zonder dat er een offer nodig is.',
      },
      {
        name: 'Stille zet',
        short: 'De winnende zet is geen schaak, geen slag en geen dreiging.',
        body: 'De reden dat sterke spelers combinaties vinden die anderen missen. Na een gedwongen reeks is het antwoord een bescheiden zet die het laatste vluchtveld wegneemt, en hij is onzichtbaar voor wie alleen schaken en slagen rekent. Als een stelling gewonnen lijkt en niets dwingends werkt, zoek dan de stille.',
      },
      {
        name: 'Offer',
        short: 'Geef materiaal voor iets dat meer waard is dan materiaal.',
        body: 'Tijd, lijnen, velden, of de positie van de vijandelijke koning. Een echt offer is geen gok; het is een berekening met een concreet einde. Wat een werkend offer scheidt van een niet-werkend is bijna altijd of de verdedigende stukken op tijd terug kunnen komen.',
      },
      {
        name: 'Ver opgerukte pion',
        short: 'Een pion dicht bij promotie verandert wat elk ander stuk waard is.',
        body: 'Een pion op de zevende is geen pion; hij is een dame die door iets bewaakt moet worden, en dat iets is niet langer vrij. De meeste eindspeltactieken gaan in werkelijkheid over de spanning tussen een pion tegenhouden en iets anders doen.',
      },
    ],
    after: {
      slug: 'Waarom de getallen hier staan',
      title: 'Een woordenlijst zegt wat een vork is. Een getal zegt of je hem kunt oefenen.',
      body: [
        'De naam van een patroon kennen en het onder de klok kunnen vinden zijn verschillende vaardigheden, en alleen de tweede wint partijen. Elk getal hierboven is het werkelijke aantal stellingen in de meegeleverde bibliotheek dat met dat motief gelabeld is — geen schatting, en niet naar boven afgerond. Zestig röntgenoefeningen zijn er zestig; als dat het ding is dat je blijft missen, is het goed te weten dat ze op één avond niet opraken.',
        'De trainer houdt bij welke motieven je fout doet, zodat hij je na een paar honderd oefeningen niet kan vertellen dat je 1620 bent, maar dat je 1620 bent en steeds langs afleidingen loopt.',
      ],
      more: 'Hoe de oefeningen gewonnen en gecontroleerd worden →',
    },
  },
};
