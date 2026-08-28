import type { Pages } from './types';

/** The four commercial pages in Danish. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Support',
      title: 'Spørg et menneske',
      lede: 'Der er intet sagssystem, ingen chatbot og intet hjælpecenter med fire hundrede artikler. Der er en e-mailadresse og en liste over fejl, og begge ender hos den, der skrev appen.',
    },
    meta: {
      title: 'Support',
      description:
        'Sådan får du fat i et menneske om Brass Pawn, hvad du sender med, når en opgave er forkert, og de spørgsmål der kommer oftest.',
    },
    email: {
      slug: 'E-mail',
      body: 'Om alt: en fejl, en forkert opgave, et spørgsmål om et køb, eller uenighed med en bedømmelse. Skriv på engelsk eller bulgarsk.',
    },
    tracker: {
      slug: 'Fejlliste',
      name: 'GitHub-issues',
      body: 'Til alt, du hellere vil have offentligt — og til alt, andre skal kunne finde senere, hvilket gælder de fleste fejlrapporter.',
    },
    report: {
      slug: 'Når en opgave er forkert',
      title: 'Send fire ting, så tager kontrollen et minut.',
      checklist: [
        'FEN’en vist på opgaveskærmen — hold nede for at kopiere den.',
        'Trækket du spillede, og trækket appen kaldte rigtigt.',
        'Hvilken tilstand du var i.',
        'Appversionen, fra informationsskærmen.',
      ],
      caveat:
        'Opgaver modsiger nu og da en dybere søgning, og de modsigelser samler sig i lange, stille, højt vurderede stillinger, hvis pointe ligger dybere, end kontrollen nåede. Det er en grænse for kontrollen og ikke en fejl i opgaven — men det er værd at vide, hvilke det er, og den eneste måde at vide det på er, at du siger til.',
    },
    faq: { slug: 'Spørgsmål', title: 'Stillet ofte nok til at blive skrevet ned.' },
    more: {
      ratings: 'Hvad en rating måler',
      tactics: 'Motiverne',
      privacy: 'Privatlivspolitik',
      terms: 'Brugsvilkår',
      licences: 'Licenser',
    },
  },

  pricing: {
    head: {
      slug: 'Hvad det koster',
      title: 'At spille er gratis. Træningen sælges.',
      lede: 'Skak mod motoren og skak mod et menneske, uden grænse, uden reklamer nogen steder i appen — det er gratis og forbliver det. Det, der sælges, er biblioteket, øvelserne, opgaverne og kapløbet med uret.',
    },
    meta: {
      title: 'Priser',
      description:
        'At spille er gratis og ubegrænset — motoren, en levende modstander og alle 900 partier. Pro fjerner grænsen på fem om dagen: 3,99 dollar om måneden eller 49,99 én gang.',
    },
    free: {
      name: 'Gratis',
      note: 'Ingen konto. Der er ikke noget at tilmelde sig.',
      items: [
        'Ubegrænset spil mod motoren, 1400 til fuld styrke',
        'Ubegrænsede partier online via Game Center',
        'Kommentar træk for træk i hvert parti, du spiller',
        'Fem taktikopgaver om dagen',
        'Fem Rush-runder om dagen',
        'Fem af hver: positionelle, slutspil, Gæt Elo',
        'Ratings, serier og spredt gentagelse, fuldt ud',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Månedligt',
      per: 'om måneden',
      note: 'Opsig når som helst i indstillingerne for din Apple-konto.',
      items: [
        'Alle daglige grænser væk',
        'Alle {tactics} taktikopgaver',
        'Alle {positional} positionelle øvelser',
        'Alle {endgames} slutspilsøvelser',
        'Alle {games} partier at bedømme',
        'Rush uden grænse',
        'Alt fra Gratis, uændret',
      ],
    },
    lifetime: {
      name: 'Engangsoplåsning',
      once: 'én gang for alle',
      note: 'Et ikke-forbrugeligt køb. Det fornyes ikke.',
      items: [
        'Præcis det samme som Pro månedligt',
        'Ingen fornyelser, ingen udløbsdato, ingen påmindelsesmails',
        'Genoprettes på dine andre enheder',
        'Til den, der hellere beslutter sig én gang',
      ],
    },
    table: {
      slug: 'Hele portionen',
      title: 'Hvad gratisversionen faktisk giver.',
      activity: 'Aktivitet',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Ubegrænset',
      fiveADay: '5 om dagen',
      none: 'Ingen',
      rows: [
        'Spil mod motoren',
        'Partier online via Game Center',
        'Se — biblioteket med 900 partier',
        'Taktikopgaver',
        'Rush-runder',
        'Positionelle øvelser',
        'Slutspilsøvelser',
        'Gæt Elo',
        'Reklamer',
      ],
      reset:
        'Dagsportionerne nulstilles klokken ni om morgenen lokal tid — ikke ved midnat, så en aftensession ikke skæres over af et datoskift.',
    },
    why: {
      slug: 'Hvorfor det er formet sådan',
      title: 'Tre beslutninger, og grunden til hver.',
      reasons: [
        {
          title: 'Talt, ikke låst',
          body: [
            'Ingen betaler for en træner, han ikke har brugt, og en tilstand, der nægter at åbne, siger intet om, hvad der er bag den. Så hver tilstand åbner, hver dag, og du kommer langt nok til at mærke rytmen og se ratingen bevæge sig.',
            'Købsskærmen dukker aldrig op ved start. Når dagens portion er brugt, siger skærmen det, og først et bevidst tryk åbner købsarket.',
          ],
        },
        {
          title: 'To priser, ikke tre',
          body: [
            'Der er ingen årsplan imellem, for en tredje pris er en tredje beslutning netop i det øjeblik, nogen vil løse en opgave. Månedligt, hvis du er i tvivl. Én gang, hvis du ikke er.',
          ],
        },
        {
          title: 'At spille sælges aldrig',
          body: [
            'Skak mod motoren og mod et menneske koster intet at drive og er grunden til, at appen findes. At sælge dem ville gøre den til en skakapp med bomanlæg i stedet for en træner.',
            'Og der er ingen reklamer — dels smag, dels licens. Appen linker to copyleft-motorer, Stockfish under GPLv3 og Reckless under AGPLv3, og et proprietært reklame-SDK i samme binære fil ville gøre helheden umulig at distribuere. {link}',
          ],
        },
      ],
      licenceLink: 'Licenssiden gennemgår det ordentligt.',
    },
    answers: {
      slug: 'Køb, opsigelse, refusion',
      title: 'De ubehagelige spørgsmål, besvaret her i stedet for pr. mail.',
      items: [
        {
          q: 'Hvordan opsiger jeg?',
          a: 'Indstillinger → dit navn → Abonnementer → Brass Pawn. Vi kan ikke opsige for dig, fordi abonnementet er mellem dig og Apple og aldrig har været hos os. Opsigelse stopper fremtidige fornyelser og forkorter ikke den allerede betalte periode.',
        },
        {
          q: 'Hvordan får jeg pengene tilbage?',
          a: 'Via Apple, på {link}. Vi kan ikke refundere køb fra App Store. Er noget i stykker, så skriv til os — vi reparerer hellere.',
        },
        {
          q: 'Jeg købte oplåsningen og har en ny telefon.',
          a: 'Log ind på den samme Apple-konto og tryk på „Gendan køb“ på købsskærmen. Appen spørger StoreKit, hvad du ejer; intet ligger på en server hos os, for vi har ingen server.',
        },
        {
          q: 'Ændrer Pro min rating eller låser „bedre“ opgaver op?',
          a: 'Nej. Ratingsystemet er identisk, og enhver opgave i biblioteket kan nås med en gratis konto — fem om dagen. Pro fjerner tælleren, ikke et forhæng.',
        },
        {
          q: 'Bliver gratisportionen mindre senere?',
          a: 'Den kan ændre sig begge veje, efterhånden som biblioteket vokser. Ubegrænset spil mod motoren og mod et menneske bliver ikke en betalt funktion; det står i {link} og er ikke kun lovet her.',
        },
      ],
      termsLink: 'vilkårene',
      more: 'Flere spørgsmål, og hvordan du får fat i et menneske →',
    },
  },

  training: {
    head: {
      slug: 'Programmet',
      title: 'Otte måder at høre sandheden på',
      lede: 'Tre af dem er gratis og ubegrænsede for altid — at spille, at spille mod nogen, og de ni hundrede partier i Se. De øvrige fem er fem om dagen med en gratis konto og ubegrænsede med Pro. Hver af dem bedømmer dig med ord om stillingen i stedet for med et tal, du først skal tyde.',
    },
    meta: {
      title: 'Træning',
      description:
        'Otte tilstande: taktik, positionel bedømmelse, slutspil, Rush, Gæt Elo, Se, spil med kommentar og online. Hvordan hver enkelt virker, hvordan opgaverne udvindes og kontrolleres, og hvad træneren ikke gør.',
    },
    modes: [
      {
        title: 'Taktik',
        lede: 'Stillinger med præcis ét vindende træk, og en dom i samme øjeblik du spiller det.',
        body: [
          'Hver opgave har ét svar og ingen forgreninger. Spil det på brættet, så siger træneren straks, om du fandt det; rammer du forbi, kommer stillingen igen i morgen, så om fire dage, så om ti — så længe den bliver ved at fange dig.',
          'Hver opgave bærer det motiv, den drejer sig om — gaffel, binding, spid, grundlinjemat, bortledning, det stille træk — så træneren efter et par hundrede kan fortælle dig ikke, at du er 1620, men at du er 1620 og gang på gang går i bortledninger.',
        ],
        free: 'Fem om dagen med en gratis konto.',
        stat: 'opgaver, vurderet fra 760 til 2800',
      },
      {
        title: 'Positionel bedømmelse',
        lede: 'Der er ingen tvunget gevinst. Sig hvem der står bedst, og find så trækket der siger hvorfor.',
        body: [
          'Det er tilstanden bygget til det, der skiller stærke spillere fra gode regnere. Først bedømmer du: klart bedre, lidt bedre, lige. Så vælger du et træk. Begge svar bedømmes.',
          'Tilbagemeldingen navngiver konkrete træk ved stillingen i stedet for stemninger — den åbne linje og om et tårn står på den, springerfeltet ingen bonde kan bestride, bondestrukturen, kongesikkerheden, forskellen i brikaktivitet. En stilling er ikke „behagelig for hvid“; den er bedre af fire grunde, du kan remse op.',
        ],
        free: 'Fem om dagen med en gratis konto.',
        stat: 'stille stillinger, forudvalgt af motoren',
      },
      {
        title: 'Slutspil',
        lede: 'Kanoniske stillinger, spillet til ende mod en motor der forsvarer sig anstændigt.',
        body: [
          'At kende idéen er ikke det samme som at hente den hjem, så her skal du faktisk nå resultatet. Stockfish tager den anden side og stiller det bedste forsvar op, der findes.',
          'Efter hvert træk kontrollerer træneren igen, om resultatet stadig kan nås — og hvis ikke, navngiver den det præcise træk, hvor det holdt op. Det er sætningen, der lærer noget: ikke „du gjorde remis“, men „du gjorde remis her“.',
        ],
        free: 'Fem om dagen med en gratis konto.',
        stat: 'øvelser, hvert resultat kontrolleret af motoren',
      },
      {
        title: 'Rush',
        lede: 'En runde på tid. Løs så mange du kan, før uret tager resten.',
        body: [
          'De samme opgaver, under ur, med en sværhedsgrad der stiger, så længe du bliver ved at finde dem. Det træner en anden muskel end en opgave, man må stirre på: den der skal se det nu.',
          'Runder gives point og gemmes, så tallet stiger over måneder i stedet for over én aften.',
        ],
        free: 'Fem runder om dagen med en gratis konto.',
      },
      {
        title: 'Gæt Elo',
        lede: 'Et virkeligt ratet parti, spillet igennem træk for træk. Hvor stærke var de to?',
        body: [
          'At læse niveauet i et parti er den samme færdighed som at bedømme sine egne træk: begge dele handler om at bemærke, hvilke fejl der bliver begået, og hvilke der ikke gør. Så partiet ruller, du ser på, og på et tidspunkt binder du dig til et tal.',
          'Partierne er virkelige, fra Lichess’ arkiver, med begge spillere inden for 150 point af hinanden — et gæt på „spillerne“ betyder kun noget, når der er ét niveau at gætte.',
        ],
        free: 'Fem om dagen med en gratis konto.',
        stat: 'ratede partier, fra 800 til 2599',
      },
      {
        title: 'Se',
        lede: 'Ni hundrede partier værd at se — og i det øjeblik du ville have spillet anderledes, overtager du.',
        body: [
          'Hvert parti i biblioteket er afgørende, mellem to spillere med navn, og enten slut inden for femogtyve træk eller berømt nok til at have sit eget navn. Ingen lærer noget af en halvfemstræks remis mellem mennesker, han aldrig har hørt om, og et bibliotek der indeholder det, er et bibliotek ingen åbner to gange.',
          'Slå en spiller op, eller en turnering, eller et år. Gå så partiet igennem i dit eget tempo. Det handler ikke om højdepunkterne: det handler om, at du ved et træk vil tænke <em>der ville jeg have slået</em> — og i det øjeblik kan du. Overtag stillingen og spil videre mod motoren fra præcis det felt, hvor du var uenig. At finde ud af, hvad din idé egentlig var værd, er hele øvelsen.',
        ],
        free: 'Gratis, ubegrænset, altid.',
        stat: 'partier, alle afgørende',
      },
      {
        title: 'Spil med coach',
        lede: 'Et helt parti på den styrke du vælger, med hvert af dine træk bedømt undervejs.',
        body: [
          'Sæt motoren et sted mellem 1400 og fuld styrke og spil partiet til ende. Hvert af dine træk bedømmes, mens partiet stadig kører, og coachen forklarer, hvad det bedre træk ville have opnået — med ord om stillingen, ikke som et tal.',
          'Til sidst får du præcision, antallet af bommerter, og det ene øjeblik der kostede mest.',
        ],
        free: 'Gratis, ubegrænset, altid.',
      },
      {
        title: 'Online',
        lede: 'To mennesker, ét ur, og ingen motor i nærheden.',
        body: [
          'Game Center finder en, der valgte den samme betænkningstid — 3, 5, 10, 15 eller 30 minutter. Det er den eneste tilstand uden motor i: ingen hint, ingen trækvurderinger, ingen coaching, for hjælp som kun den ene side får, er ikke et parti.',
          'Der er ingen server. De to enheder taler sammen, og begge håndhæver reglerne, så et træk bliver kun spillet, hvis det er lovligt i den stilling, den modtagende enhed allerede har. En modpart der lyver, giver en kasseret pakke, ikke et ulovligt bræt.',
        ],
        free: 'Gratis, ubegrænset, altid.',
      },
    ],
    watchLink: 'Hvad der kom med i biblioteket, og hvad der ikke gjorde →',
    pipeline: {
      slug: 'Hvordan en opgave bliver til',
      title: 'Udvundet, ikke afskrevet.',
      lede: 'At skrive stillinger af efter hukommelsen risikerer en opgave, hvis „løsning“ er forkert eller ikke entydig, og det træner præcis den forkerte refleks. Så ingen af dem er skrevet af efter hukommelsen. De findes og angribes derefter, indtil de overlever eller kasseres.',
      steps: [
        {
          title: 'Spil på menneskelig styrke',
          body: 'Stockfish spiller mod sig selv på bevidst menneskelig styrke — 1320 til 2500 Elo — og åbner med et tilfældigt valg blandt sine bedste lave kandidater, så partierne varierer i stedet for at gentage én variant i det uendelige.',
        },
        {
          title: 'Sigtning på egenskaben, ikke på bommerten',
          body: 'Hver stilling gennemsøges på dybde 12 med to kandidatvarianter. Signalet er ikke „nogen bommede“, men det en opgave faktisk kræver: ét træk der er meget bedre end enhver anden mulighed.',
        },
        {
          title: 'Ny dyb søgning, med margen',
          body: 'De overlevende gennemsøges igen på dybde 20 med MultiPV. En kandidat bliver kun, hvis det bedste træk slår det næstbedste med mindst 140 hundrededele bonde og desuden faktisk opnår noget.',
        },
        {
          title: 'Forlængelse indtil den forgrener sig',
          body: 'Løsningen forlænges træk for træk, så længe hvert træk fra løseren forbliver entydigt bedst. I det øjeblik der er to gode svar, slutter opgaven dér — den har altså aldrig en forgrening, hvor du kan tælles for forkert.',
        },
        {
          title: 'Kontrol med en frisk motor',
          body: 'Hele samlingen efterprøves på større dybde af et separat script med en ny motor. På den medfølgende udvundne samling forkastede det 6 ud af 172 opgaver, hvis løsninger holdt op med at være entydige to halvtræk dybere. De blev kasseret i stedet for leveret.',
        },
      ],
    },
    honest: {
      title: 'Og den samme mistro anvendt på slutspillene',
      body: [
        'Det angivne resultat for hver slutspilsøvelse kontrolleres mod en dyb søgning i stedet for at blive taget på ordet. En forkert mærket øvelse dumper kontrollen i stedet for stille at lære dig noget usandt.',
        'Kontrollen fanger også noget, de gængse skakbiblioteker ikke fortæller: om den side, der ikke er i trækket, står i skak. Sådan en stilling er ulovlig — intet parti kan nå den — men et bibliotek accepterer den villigt, og motoren svarer med bestmove (none), hvilket lyder som en motorfejl snarere end en dårlig stilling. Tre håndskrevne øvelser var i stykker på præcis den måde. Kontrollen fanger det nu.',
      ],
    },
    limits: {
      slug: 'Ærlige grænser',
      title: 'Hvad det her ikke gør.',
      items: [
        {
          title: 'Samlingen blander to ratingskalaer.',
          body: 'De {lichess} Lichess-opgaver bærer ratings kalibreret mod millioner af menneskelige forsøg. De {mined} lokalt udvundne opgaver bærer skøn ud fra løsningsdybde og motiv. Begge ordner fornuftigt, men en udvundet 1600 og en Lichess-1600 er ikke målt ens.',
        },
        {
          title: 'Opgaveratings er ikke brætratings.',
          body: 'De ligger flere hundrede point højere, og sådan bliver det ved. De måler fremgang mod dig selv, ikke styrke mod et felt af mennesker ved uret — {link}, for kløften er strukturel og ikke et tegn på, at du afslutter dårligt.',
        },
        {
          title: 'Der er ingen åbningstræning.',
          body: 'Med vilje. Åbningsstudier er udenadslære mod et repertoire, du selv vælger, og det er et andet værktøj med en anden form. Den positionelle tilstand dækker overgangen ud af åbningen, og det er den del, der virkelig lader sig generalisere.',
        },
        {
          title: 'Det her gør dig ikke til stormester.',
          body: 'Intet gør det alene. Titler kommer af tusinder af timer plus ratede turneringspartier mod mennesker. Det, du får her, er træningshalvdelen af det, struktureret, med et ærligt mål for, hvor du faktisk står.',
        },
      ],
      ratingsLink: 'værd at forstå ordentligt',
    },
    more: {
      motifs: 'De tyve motiver, defineret og talt →',
      engine: 'Hvordan motoren bruges →',
    },
  },

  tactics: {
    head: {
      slug: 'Ordliste',
      title: 'De tyve motiver',
      lede: 'Enhver taktik i skak er en af et lille antal former, og så snart du kan navngive dem, ser du dem et træk før. Det er de motiver, Brass Pawn mærker sine opgaver med — hvert efterfulgt af, hvor mange stillinger i det medfølgende bibliotek der faktisk drejer sig om det.',
      meta: 'Talt ud fra den medfølgende samling på 14.351 opgaver · Sidst kontrolleret 19. august 2026',
    },
    meta: {
      title: 'De tyve motiver',
      description:
        'Hvert taktisk motiv, Brass Pawn mærker sine opgaver med, defineret og talt op mod det medfølgende bibliotek, så du ved, hvilke du faktisk kan øve.',
    },
    indexLabel: 'Motiverne',
    puzzles: 'opgaver',
    motifs: [
      {
        name: 'Gaffel',
        short: 'Én brik angriber to ting på én gang, og kun den ene kan reddes.',
        body: 'Springeren er den berømte gaffelbrik, fordi den angriber felter, ingen anden brik dækker på samme måde, men alt gafler: en bonde der rammer to lette brikker, en dronning der rammer et tårn og en løs løber, en konge i slutspillet der træder ind mellem to bønder. Prøven er ikke „angriber jeg to ting“, men „kan de begge slippe væk“.',
      },
      {
        name: 'Binding',
        short: 'En brik kan ikke flytte, fordi noget mere værdifuldt står bag den.',
        body: 'Absolut når kongen står bag — at flytte er ulovligt, ikke bare dårligt. Relativ når en dronning eller et tårn står bag, hvor det er lovligt at flytte og blot koster materiale. Fortsættelsen vinder: en bundet brik er en brik der ikke kan dække, så læg flere angribere på den, eller slå på den med en bonde.',
      },
      {
        name: 'Spid',
        short: 'En binding omvendt: den værdifulde brik står forrest og skal flytte.',
        body: 'Giv kongen skak langs en linje med tårn, løber eller dronning, og det der stod bag, er dit, så snart kongen træder til side. Spid er sjældnere end bindinger, fordi de kræver to brikker allerede på samme linje med den værdifulde forrest — derfor dukker de som regel op, efter at en skak har tvunget kongen derhen.',
      },
      {
        name: 'Afdækket angreb',
        short: 'At flytte én brik blotter angrebet fra den, der stod bag.',
        body: 'Med bred margen den stærkeste taktik i skak, fordi brikken der går væk, er fri til at gøre noget for sig selv, mens det afdækkede angreb gør arbejdet. To trusler opstår i ét træk, og ingen af dem besvares ved at slå brikken der flyttede.',
      },
      {
        name: 'Afdækket skak',
        short: 'Det afdækkede angreb er en skak, så modstanderen har ikke tid til andet.',
        body: 'Et afdækket angreb hvor brikken bagved giver skak. Uanset hvad brikken der går væk gør — slår en dronning, stiller sig på et matfelt, stiller sig til slag — skal svaret først tage sig af skakken, så det sker gratis.',
      },
      {
        name: 'Dobbeltskak',
        short: 'To brikker giver skak samtidig, så kongen skal flytte. Ikke dække, ikke slå.',
        body: 'Den eneste taktik hvor der findes præcis én slags lovligt svar. At slå den ene skakgiver efterlader den anden; at dække én linje efterlader den anden åben. Derfor giver dobbeltskak matter der ser umulige ud — forsvareren kan have fem måder at stoppe hver skak for sig og ingen der stopper begge.',
      },
      {
        name: 'Bortledning',
        short: 'Tving en forsvarer væk fra det arbejde, den udfører.',
        body: 'En brik holder et matfelt, en grundlinje eller en anden brik. Angrib noget den vurderer højere, eller slå simpelthen noget den skal slå tilbage på, og dækningen den gav, forsvinder med den. Offeret ser ofte absurd ud, indtil man bemærker, hvad den tilbageslående brik ikke længere dækker.',
      },
      {
        name: 'Tiltrækning',
        short: 'Lok en brik — som regel kongen — hen på et felt hvor den kan rammes.',
        body: 'Et offer modstanderen er tvunget til at tage, spillet ikke for at vinde materiale, men for at stille en brik skæbnesvangert: en konge slæbt til et gaffelfelt, en dronning trukket ud på en linje med et tårn. Materialet kommer tilbage et træk senere med renter.',
      },
      {
        name: 'Rydning',
        short: 'Flyt din egen brik væk fra dit eget angrebs vej.',
        body: 'Linjen eller feltet er det rigtige, og der står en af dine egne på det. Rydningen flytter ham væk med tempo — som regel med skak eller slag, så modstanderen ikke når at omgruppere, mens vejen åbner sig.',
      },
      {
        name: 'Afskærmning',
        short: 'Skær linjen over mellem en forsvarer og det, den forsvarer.',
        body: 'Stil en brik — ofte ofret — præcis mellem et tårn og det felt, det vogter. Forsvareren står stadig på brættet, forsvarer i teorien stadig, og kan ikke længere. Sjældent, og et af de sværeste mønstre at se, fordi den afskærmende brik som regel ligner en bommert.',
      },
      {
        name: 'Røntgenangreb',
        short: 'En brik virker gennem en anden brik, langs den linje den vil besætte senere.',
        body: 'Et tårn der dækker sin egen brik gennem en fjendtlig brik, eller angriber gennem den. Endnu sker der intet; det der tæller, er hvad der sker, når brikken imellem flytter eller bliver slået. At se et røntgenangreb er som regel det, der gør at et slag som „taber materiale“ ikke taber materiale.',
      },
      {
        name: 'Mellemtræk',
        short: 'Trækket imellem: gør noget mere tvingende, før du slår tilbage.',
        body: 'Fra tysk „Zwischenzug“, og den hyppigste enkeltgrund til at en beregnet variant viser sig forkert. Du venter et modslag; i stedet kommer en skak eller en større trussel, og når modslaget så kommer, har stillingen ændret sig. Led efter et, hver gang en sekvens ser tvungen ud.',
      },
      {
        name: 'Træktvang',
        short: 'Selve pligten til at trække er problemet.',
        body: 'Ethvert lovligt træk gør stillingen værre, og at stå over er ikke tilladt. Først og fremmest en slutspilsidé — den afgør bondeslutspil — og grunden til at „oppositionen“ tæller: den der først skal træde til side, giver feltet fra sig. Næsten den eneste situation i skak hvor retten til at trække er en byrde.',
      },
      {
        name: 'Grundlinjemat',
        short: 'En konge lukket inde af sine egne bønder bliver mat på første række.',
        body: 'Den hyppigste mat mellem spillere der har rokeret og ladt bønderne være. Den optræder sjældent som mat på brættet — den optræder som en trussel der vinder materiale, fordi hvert forsvarstræk skal blive ved at dække rækken. Hele familien af bortledningstaktikker findes for at fjerne den dækning.',
      },
      {
        name: 'Kvælningsmat',
        short: 'En springer matter en konge som hans egne brikker har lukket inde.',
        body: 'Slutningen på Philidors legat: dronningoffer på g8, tårnet slår tilbage, springeren på f7 giver mat med kongen omgivet af sine egne. Sjælden i virkelige partier og alligevel værd at kende, for mønstret er det, der får dig til at kigge i hjørnet og tælle flugtfelter.',
      },
      {
        name: 'Hængende brik',
        short: 'Noget er simpelthen udækket og kan tages.',
        body: 'Ikke glamourøst, og det afgør flere partier end alt andet på listen tilsammen. De fleste nederlag under 1800 er den ene spiller der tager en gratis brik, den anden mistede af syne. Vanen der kurerer det, er at tjekke hvad der står løst — hos begge farver — før hvert træk.',
      },
      {
        name: 'Indespærret brik',
        short: 'En brik har intet sikkert felt og kan jages ned i ro og mag.',
        body: 'Som regel en løber der tog en bonde, den burde have ladt stå, eller en springer der drog på rov. Taktikken er ikke ét slag, men en kvælning: tag felterne ét ad gangen, så falder brikken uden at der skal ofres.',
      },
      {
        name: 'Stille træk',
        short: 'Det vindende træk er hverken skak, slag eller trussel.',
        body: 'Grunden til at stærke spillere finder kombinationer andre overser. Efter en tvungen sekvens er svaret et beskedent træk der tager det sidste flugtfelt, og det er usynligt for den der kun regner skakker og slag. Når en stilling ser vundet ud og intet tvingende virker, så led efter det stille.',
      },
      {
        name: 'Offer',
        short: 'Giv materiale for noget der er mere værd end materiale.',
        body: 'Tid, linjer, felter, eller fjendekongens stilling. Et virkeligt offer er ikke et væddemål; det er en beregning med en konkret slutning. Det der skiller et offer der virker fra et der ikke gør, er næsten altid, om de forsvarende brikker når tilbage i tide.',
      },
      {
        name: 'Fremskudt bonde',
        short: 'En bonde tæt på forvandling ændrer hvad enhver anden brik er værd.',
        body: 'En bonde på syvende række er ikke en bonde; den er en dronning som noget skal vogte, og det noget er ikke længere frit. De fleste slutspilstaktikker handler i virkeligheden om spændingen mellem at stoppe en bonde og at gøre noget som helst andet.',
      },
    ],
    after: {
      slug: 'Hvorfor tallene står her',
      title: 'En ordliste siger hvad en gaffel er. Et tal siger om du kan øve den.',
      body: [
        'At kende navnet på et mønster og at kunne finde det under uret er forskellige færdigheder, og kun den anden vinder partier. Hvert tal ovenfor er det virkelige antal stillinger i det medfølgende bibliotek der er mærket med det motiv — ikke et skøn, og ikke rundet op. Tres røntgenopgaver er tres; er det netop dét, du bliver ved at overse, er det godt at vide, at de ikke slipper op på én aften.',
        'Træneren holder styr på hvilke motiver du tager fejl af, så den efter et par hundrede opgaver kan fortælle dig ikke, at du er 1620, men at du er 1620 og gang på gang går i bortledninger.',
      ],
      more: 'Hvordan opgaverne udvindes og kontrolleres →',
    },
  },
};
