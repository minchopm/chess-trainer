import type { Pages } from './types';

/** The four commercial pages in Norwegian (bokmål). */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Støtte',
      title: 'Spør et menneske',
      lede: 'Det finnes ikke noe sakssystem, ingen chatbot og ikke noe hjelpesenter med fire hundre artikler. Det finnes en e-postadresse og en liste over feil, og begge ender hos den som skrev appen.',
    },
    meta: {
      title: 'Støtte',
      description:
        'Hvordan du når et menneske om Brass Pawn, hva du sender med når en oppgave er feil, og spørsmålene som kommer oftest.',
    },
    email: {
      slug: 'E-post',
      body: 'Om alt: en feil, en gal oppgave, et spørsmål om et kjøp, eller uenighet med en vurdering. Skriv på engelsk eller bulgarsk.',
    },
    tracker: {
      slug: 'Feilliste',
      name: 'GitHub-issues',
      body: 'Til alt du heller vil ha offentlig — og til alt andre må kunne finne senere, som gjelder de fleste feilmeldinger.',
    },
    report: {
      slug: 'Når en oppgave er feil',
      title: 'Send fire ting, så tar kontrollen ett minutt.',
      checklist: [
        'FEN-en som vises på oppgaveskjermen — hold nede for å kopiere den.',
        'Trekket du gjorde, og trekket appen kalte riktig.',
        'Hvilken modus du var i.',
        'Appversjonen, fra informasjonsskjermen.',
      ],
      caveat:
        'Oppgaver motsier nå og da et dypere søk, og de motsigelsene samler seg i lange, stille, høyt vurderte stillinger hvis poeng ligger dypere enn kontrollen nådde. Det er en grense for kontrollen og ikke en feil i oppgaven — men det er verdt å vite hvilke det er, og den eneste måten å vite det på er at du sier fra.',
    },
    faq: { slug: 'Spørsmål', title: 'Stilt ofte nok til å bli skrevet ned.' },
    more: {
      ratings: 'Hva en rating måler',
      tactics: 'Motivene',
      privacy: 'Personvernerklæring',
      terms: 'Bruksvilkår',
      licences: 'Lisenser',
    },
  },

  pricing: {
    head: {
      slug: 'Hva det koster',
      title: 'Å spille er gratis. Treningen selges.',
      lede: 'Sjakk mot motoren og sjakk mot et menneske, uten grense, uten reklame noe sted i appen — det er gratis og forblir det. Det som selges, er biblioteket, øvelsene, oppgavene og kappløpet med klokka.',
    },
    meta: {
      title: 'Priser',
      description:
        'Å spille er gratis og ubegrenset — motoren, en levende motstander og alle 900 partier. Pro fjerner grensen på fem om dagen: 3,99 dollar i måneden eller 49,99 én gang.',
    },
    free: {
      name: 'Gratis',
      note: 'Ingen konto. Ingenting å registrere seg for.',
      items: [
        'Ubegrenset spill mot motoren, 1400 til full styrke',
        'Ubegrensede partier på nett via Game Center',
        'Kommentar trekk for trekk i hvert parti du spiller',
        'Fem taktikkoppgaver om dagen',
        'Fem Rush-runder om dagen',
        'Fem av hver: posisjonelle, sluttspill, Gjett Elo',
        'Ratinger, serier og spredt repetisjon, i sin helhet',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Månedlig',
      per: 'per måned',
      note: 'Avslutt når som helst i innstillingene for Apple-kontoen din.',
      items: [
        'Alle dagsgrenser borte',
        'Alle {tactics} taktikkoppgaver',
        'Alle {positional} posisjonelle øvelser',
        'Alle {endgames} sluttspillsøvelser',
        'Alle {games} partier å vurdere',
        'Rush uten grense',
        'Alt fra Gratis, uendret',
      ],
    },
    lifetime: {
      name: 'Engangsopplåsing',
      once: 'én gang for alle',
      note: 'Et ikke-forbrukbart kjøp. Det fornyes ikke.',
      items: [
        'Nøyaktig det samme som Pro månedlig',
        'Ingen fornyelser, ingen utløpsdato, ingen påminnelsesepost',
        'Gjenopprettes på de andre enhetene dine',
        'For den som heller vil bestemme seg én gang',
      ],
    },
    table: {
      slug: 'Hele porsjonen',
      title: 'Hva gratisversjonen faktisk gir.',
      activity: 'Aktivitet',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Ubegrenset',
      fiveADay: '5 om dagen',
      none: 'Ingen',
      rows: [
        'Spill mot motoren',
        'Partier på nett via Game Center',
        'Se — biblioteket med 900 partier',
        'Taktikkoppgaver',
        'Rush-runder',
        'Posisjonelle øvelser',
        'Sluttspillsøvelser',
        'Gjett Elo',
        'Reklame',
      ],
      reset:
        'Dagsporsjonene nullstilles klokka ni om morgenen lokal tid — ikke ved midnatt, så en kveldsøkt ikke blir kuttet i to av et datoskifte.',
    },
    why: {
      slug: 'Hvorfor det er formet slik',
      title: 'Tre avgjørelser, og grunnen til hver av dem.',
      reasons: [
        {
          title: 'Talt, ikke låst',
          body: [
            'Ingen betaler for en trener han ikke har brukt, og en modus som nekter å åpne seg, sier ingenting om hva som ligger bak. Så hver modus åpner, hver dag, og du kommer langt nok til å kjenne rytmen og se ratingen bevege seg.',
            'Kjøpsskjermen dukker aldri opp ved oppstart. Når dagens porsjon er brukt opp, sier skjermen det, og først et bevisst trykk åpner kjøpsarket.',
          ],
        },
        {
          title: 'To priser, ikke tre',
          body: [
            'Det finnes ingen årsplan imellom, for en tredje pris er en tredje avgjørelse akkurat idet noen vil løse en oppgave. Månedlig hvis du er i tvil. Én gang hvis du ikke er det.',
          ],
        },
        {
          title: 'Å spille selges aldri',
          body: [
            'Sjakk mot motoren og mot et menneske koster ingenting å drifte og er grunnen til at appen finnes. Å selge dem ville gjort den til en sjakkapp med bomstasjon i stedet for en trener.',
            'Og det finnes ingen reklame — dels smak, dels lisens. Appen lenker to copyleft-motorer, Stockfish under GPLv3 og Reckless under AGPLv3, og et proprietært annonse-SDK i samme binærfil ville gjort helheten umulig å distribuere. {link}',
          ],
        },
      ],
      licenceLink: 'Lisenssiden går gjennom det ordentlig.',
    },
    answers: {
      slug: 'Kjøp, oppsigelse, refusjon',
      title: 'De ubehagelige spørsmålene, besvart her i stedet for på e-post.',
      items: [
        {
          q: 'Hvordan sier jeg opp?',
          a: 'Innstillinger → navnet ditt → Abonnementer → Brass Pawn. Vi kan ikke si opp for deg, fordi abonnementet er mellom deg og Apple og aldri har vært hos oss. Oppsigelse stopper framtidige fornyelser og forkorter ikke den allerede betalte perioden.',
        },
        {
          q: 'Hvordan får jeg pengene tilbake?',
          a: 'Via Apple, på {link}. Vi kan ikke refundere kjøp fra App Store. Er noe ødelagt, så skriv til oss — vi reparerer heller.',
        },
        {
          q: 'Jeg kjøpte opplåsingen og har ny telefon.',
          a: 'Logg inn på den samme Apple-kontoen og trykk «Gjenopprett kjøp» på kjøpsskjermen. Appen spør StoreKit hva du eier; ingenting ligger på en server hos oss, for vi har ingen server.',
        },
        {
          q: 'Endrer Pro ratingen min eller låser opp «bedre» oppgaver?',
          a: 'Nei. Ratingsystemet er identisk, og enhver oppgave i biblioteket er tilgjengelig med en gratiskonto — fem om dagen. Pro fjerner telleren, ikke et forheng.',
        },
        {
          q: 'Krymper gratisporsjonen senere?',
          a: 'Den kan endre seg begge veier etter hvert som biblioteket vokser. Ubegrenset spill mot motoren og mot et menneske blir ikke en betalt funksjon; det står i {link} og er ikke bare lovet her.',
        },
      ],
      termsLink: 'vilkårene',
      more: 'Flere spørsmål, og hvordan du når et menneske →',
    },
  },

  training: {
    head: {
      slug: 'Programmet',
      title: 'Åtte måter å høre sannheten på',
      lede: 'Tre av dem er gratis og ubegrensede for alltid — å spille, å spille mot noen, og de ni hundre partiene i Se. De øvrige fem er fem om dagen med en gratiskonto og ubegrensede med Pro. Hver av dem vurderer deg med ord om stillingen i stedet for med et tall du først må tyde.',
    },
    meta: {
      title: 'Trening',
      description:
        'Åtte moduser: taktikk, posisjonell vurdering, sluttspill, Rush, Gjett Elo, Se, spill med kommentar og på nett. Hvordan hver enkelt fungerer, hvordan oppgavene utvinnes og kontrolleres, og hva treneren ikke gjør.',
    },
    modes: [
      {
        title: 'Taktikk',
        lede: 'Stillinger med nøyaktig ett vinnende trekk, og en dom i samme øyeblikk du spiller det.',
        body: [
          'Hver oppgave har ett svar og ingen forgreninger. Spill det på brettet, så sier treneren straks om du fant det; bommer du, kommer stillingen tilbake i morgen, så om fire dager, så om ti — så lenge den fortsetter å ta deg.',
          'Hver oppgave bærer motivet den dreier seg om — gaffel, binding, spidding, grunnlinjematt, avledning, det stille trekket — så treneren etter noen hundre kan si deg ikke at du er 1620, men at du er 1620 og gang på gang går på avledninger.',
        ],
        free: 'Fem om dagen med en gratiskonto.',
        stat: 'oppgaver, vurdert fra 760 til 2800',
      },
      {
        title: 'Posisjonell vurdering',
        lede: 'Det finnes ingen tvungen gevinst. Si hvem som står best, og finn så trekket som sier hvorfor.',
        body: [
          'Dette er modusen bygget for det som skiller sterke spillere fra gode regnere. Først vurderer du: klart bedre, litt bedre, jevnt. Så velger du et trekk. Begge svar vurderes.',
          'Tilbakemeldingen navngir konkrete trekk ved stillingen i stedet for stemninger — den åpne linjen og om et tårn står på den, springerfeltet ingen bonde kan bestride, bondestrukturen, kongesikkerheten, forskjellen i brikkeaktivitet. En stilling er ikke «hyggelig for hvit»; den er bedre av fire grunner du kan ramse opp.',
        ],
        free: 'Fem om dagen med en gratiskonto.',
        stat: 'stille stillinger, forhåndsvalgt av motoren',
      },
      {
        title: 'Sluttspill',
        lede: 'Kanoniske stillinger, spilt ut mot en motor som forsvarer seg anstendig.',
        body: [
          'Å kunne idéen er ikke det samme som å hente den hjem, så her må du faktisk nå resultatet. Stockfish tar den andre siden og stiller opp det beste forsvaret som finnes.',
          'Etter hvert trekk kontrollerer treneren på nytt om resultatet fortsatt kan nås — og hvis ikke, navngir den det nøyaktige trekket der det sluttet å kunne det. Det er setningen som lærer noe: ikke «du remiserte», men «du remiserte her».',
        ],
        free: 'Fem om dagen med en gratiskonto.',
        stat: 'øvelser, hvert resultat kontrollert av motoren',
      },
      {
        title: 'Rush',
        lede: 'En runde på tid. Løs så mange du rekker før klokka tar resten.',
        body: [
          'De samme oppgavene, under klokke, med en vanskelighetsgrad som stiger så lenge du fortsetter å finne dem. Det trener en annen muskel enn en oppgave man får stirre på: den som må se det nå.',
          'Runder får poeng og lagres, så tallet stiger over måneder i stedet for over én kveld.',
        ],
        free: 'Fem runder om dagen med en gratiskonto.',
      },
      {
        title: 'Gjett Elo',
        lede: 'Et virkelig ratet parti, spilt gjennom trekk for trekk. Hvor sterke var disse to?',
        body: [
          'Å lese nivået i et parti er den samme ferdigheten som å vurdere sine egne trekk: begge handler om å legge merke til hvilke feil som blir gjort, og hvilke som ikke blir det. Så partiet ruller, du ser på, og på et tidspunkt binder du deg til et tall.',
          'Partiene er ekte, fra Lichess-arkivene, med begge spillerne innenfor 150 poeng av hverandre — en gjetning om «spillerne» betyr bare noe når det er ett nivå å gjette.',
        ],
        free: 'Fem om dagen med en gratiskonto.',
        stat: 'ratede partier, fra 800 til 2599',
      },
      {
        title: 'Se',
        lede: 'Ni hundre partier verdt å se — og i det øyeblikket du ville spilt annerledes, overtar du.',
        body: [
          'Hvert parti i biblioteket er avgjørende, mellom to spillere med navn, og enten slutt innen tjuefem trekk eller berømt nok til å ha sitt eget navn. Ingen lærer noe av en nittitrekks remis mellom folk han aldri har hørt om, og et bibliotek som inneholder det, er et bibliotek ingen åpner to ganger.',
          'Slå opp en spiller, en turnering eller et år. Gå så gjennom partiet i ditt eget tempo. Det handler ikke om høydepunktene: det handler om at du ved et trekk vil tenke <em>der ville jeg slått</em> — og i det øyeblikket kan du. Overta stillingen og spill videre mot motoren fra nøyaktig det feltet der du var uenig. Å finne ut hva idéen din egentlig var verdt, er hele øvelsen.',
        ],
        free: 'Gratis, ubegrenset, alltid.',
        stat: 'partier, alle avgjørende',
      },
      {
        title: 'Spill med trener',
        lede: 'Et helt parti på styrken du velger, med hvert trekk du gjør vurdert underveis.',
        body: [
          'Sett motoren et sted mellom 1400 og full styrke og spill partiet ut. Hvert trekk du gjør vurderes mens partiet ennå går, og treneren forklarer hva det bedre trekket ville oppnådd — med ord om stillingen, ikke som et tall.',
          'Til slutt får du presisjon, antall bommerter, og det ene øyeblikket som kostet mest.',
        ],
        free: 'Gratis, ubegrenset, alltid.',
      },
      {
        title: 'På nett',
        lede: 'To mennesker, én klokke, og ingen motor i nærheten.',
        body: [
          'Game Center finner noen som valgte samme betenkningstid — 3, 5, 10, 15 eller 30 minutter. Det er den eneste modusen uten motor i seg: ingen hint, ingen trekkvurderinger, ingen trening, for hjelp som bare den ene siden får, er ikke et parti.',
          'Det finnes ingen server. De to enhetene snakker med hverandre, og begge håndhever reglene, så et trekk spilles bare hvis det er lovlig i stillingen den mottakende enheten allerede har. En motpart som lyver, gir en forkastet pakke, ikke et ulovlig brett.',
        ],
        free: 'Gratis, ubegrenset, alltid.',
      },
    ],
    watchLink: 'Hva som kom med i biblioteket og hva som ikke gjorde det →',
    pipeline: {
      slug: 'Hvordan en oppgave blir til',
      title: 'Utvunnet, ikke avskrevet.',
      lede: 'Å skrive av stillinger etter hukommelsen risikerer en oppgave hvis «løsning» er feil eller ikke entydig, og det trener nøyaktig feil refleks. Så ingen av dem er skrevet av etter hukommelsen. De finnes og angripes deretter til de overlever eller kastes.',
      steps: [
        {
          title: 'Spill på menneskelig styrke',
          body: 'Stockfish spiller mot seg selv på bevisst menneskelig styrke — 1320 til 2500 Elo — og åpner med et tilfeldig valg blant sine beste grunne kandidater, så partiene varierer i stedet for å gjenta én variant i evighet.',
        },
        {
          title: 'Sikting på egenskapen, ikke på bommerten',
          body: 'Hver stilling søkes gjennom på dybde 12 med to kandidatvarianter. Signalet er ikke «noen bommet», men det en oppgave faktisk trenger: ett trekk som er mye bedre enn ethvert alternativ.',
        },
        {
          title: 'Nytt dypt søk, med margin',
          body: 'De overlevende søkes gjennom på nytt på dybde 20 med MultiPV. En kandidat blir bare hvis det beste trekket slår det nest beste med minst 140 hundredels bonde og dessuten faktisk oppnår noe.',
        },
        {
          title: 'Forlengelse til den forgrener seg',
          body: 'Løsningen forlenges trekk for trekk så lenge hvert trekk fra løseren forblir entydig best. I det øyeblikket det finnes to gode svar, slutter oppgaven der — den har altså aldri en forgrening der du kan telles for feil.',
        },
        {
          title: 'Kontroll med en fersk motor',
          body: 'Hele samlingen etterprøves på større dybde av et eget skript med en ny motor. På den medfølgende utvunne samlingen forkastet det 6 av 172 oppgaver hvis løsninger sluttet å være entydige to halvtrekk dypere. De ble kastet i stedet for levert.',
        },
      ],
    },
    honest: {
      title: 'Og den samme mistroen brukt på sluttspillene',
      body: [
        'Det oppgitte resultatet for hver sluttspillsøvelse kontrolleres mot et dypt søk i stedet for å bli tatt på ordet. En feilmerket øvelse stryker i kontrollen i stedet for stille å lære deg noe usant.',
        'Kontrollen fanger også noe de vanlige sjakkbibliotekene ikke forteller: om siden som ikke har trekket, står i sjakk. En slik stilling er ulovlig — ingen partier kan nå den — men et bibliotek godtar den villig, og motoren svarer med bestmove (none), som høres ut som en motorfeil snarere enn en dårlig stilling. Tre håndskrevne øvelser var ødelagt på nøyaktig den måten. Kontrollen fanger det nå.',
      ],
    },
    limits: {
      slug: 'Ærlige grenser',
      title: 'Hva dette ikke gjør.',
      items: [
        {
          title: 'Samlingen blander to ratingskalaer.',
          body: 'De {lichess} Lichess-oppgavene bærer ratinger kalibrert mot millioner av menneskelige forsøk. De {mined} lokalt utvunne oppgavene bærer anslag ut fra løsningsdybde og motiv. Begge ordner fornuftig, men en utvunnet 1600 og en Lichess-1600 er ikke målt på samme måte.',
        },
        {
          title: 'Oppgaveratinger er ikke brettratinger.',
          body: 'De ligger flere hundre poeng høyere, og slik forblir det. De måler framgang mot deg selv, ikke styrke mot et felt av mennesker ved klokka — {link}, for gapet er strukturelt og ikke et tegn på at du avslutter dårlig.',
        },
        {
          title: 'Det finnes ingen åpningstrening.',
          body: 'Med hensikt. Åpningsstudier er pugging mot et repertoar du selv velger, og det er et annet verktøy med en annen form. Den posisjonelle modusen dekker overgangen ut av åpningen, og det er den delen som virkelig lar seg generalisere.',
        },
        {
          title: 'Dette gjør deg ikke til stormester.',
          body: 'Ingenting gjør det alene. Titler kommer av tusenvis av timer pluss ratede turneringspartier mot mennesker. Det du får her, er treningshalvdelen av det, strukturert, med et ærlig mål på hvor du faktisk står.',
        },
      ],
      ratingsLink: 'verdt å forstå ordentlig',
    },
    more: {
      motifs: 'De tjue motivene, definert og talt →',
      engine: 'Hvordan motoren brukes →',
    },
  },

  tactics: {
    head: {
      slug: 'Ordliste',
      title: 'De tjue motivene',
      lede: 'Enhver taktikk i sjakk er en av et lite antall former, og så snart du kan navngi dem, ser du dem ett trekk før. Dette er motivene Brass Pawn merker oppgavene sine med — hvert etterfulgt av hvor mange stillinger i det medfølgende biblioteket som faktisk dreier seg om det.',
      meta: 'Talt ut fra den medfølgende samlingen på 14 351 oppgaver · Sist kontrollert 19. august 2026',
    },
    meta: {
      title: 'De tjue motivene',
      description:
        'Hvert taktiske motiv Brass Pawn merker oppgavene sine med, definert og talt opp mot det medfølgende biblioteket, så du vet hvilke du faktisk kan øve på.',
    },
    indexLabel: 'Motivene',
    puzzles: 'oppgaver',
    motifs: [
      {
        name: 'Gaffel',
        short: 'Én brikke angriper to ting samtidig, og bare den ene kan reddes.',
        body: 'Springeren er den berømte gaffelbrikken fordi den angriper felter ingen annen brikke dekker på samme måte, men alt gaffler: en bonde som treffer to lette brikker, en dronning som treffer et tårn og en løs løper, en konge i sluttspillet som går inn mellom to bønder. Prøven er ikke «angriper jeg to ting», men «kan begge komme unna».',
      },
      {
        name: 'Binding',
        short: 'En brikke kan ikke flytte fordi noe mer verdifullt står bak den.',
        body: 'Absolutt når kongen står bak — å flytte er ulovlig, ikke bare dårlig. Relativ når en dronning eller et tårn står bak, der det er lovlig å flytte og bare koster materiell. Fortsettelsen vinner: en bundet brikke er en brikke som ikke kan dekke, så legg flere angripere på den, eller slå på den med en bonde.',
      },
      {
        name: 'Spidding',
        short: 'En binding omvendt: den verdifulle brikken står først og må flytte.',
        body: 'Gi kongen sjakk langs en linje med tårn, løper eller dronning, og det som sto bak, er ditt så snart kongen går til side. Spidding er sjeldnere enn binding fordi den krever to brikker allerede på samme linje med den verdifulle først — derfor dukker den som regel opp etter at en sjakk har tvunget kongen dit.',
      },
      {
        name: 'Avdekket angrep',
        short: 'Å flytte én brikke blottlegger angrepet fra den som sto bak.',
        body: 'Med god margin den sterkeste taktikken i sjakk, fordi brikken som går unna, står fritt til å gjøre noe eget mens det avdekkede angrepet gjør jobben. To trusler oppstår i ett trekk, og ingen av dem besvares ved å slå brikken som flyttet.',
      },
      {
        name: 'Avdekket sjakk',
        short: 'Det avdekkede angrepet er en sjakk, så motstanderen har ikke tid til noe annet.',
        body: 'Et avdekket angrep der brikken bak gir sjakk. Uansett hva brikken som går unna gjør — slår en dronning, stiller seg på et mattfelt, stiller seg til slag — må svaret først håndtere sjakken, så det skjer gratis.',
      },
      {
        name: 'Dobbeltsjakk',
        short: 'To brikker gir sjakk samtidig, så kongen må flytte. Ikke dekke, ikke slå.',
        body: 'Den eneste taktikken der det finnes nøyaktig én slags lovlig svar. Å slå den ene sjakkgiveren etterlater den andre; å dekke én linje lar den andre stå åpen. Derfor gir dobbeltsjakk matter som ser umulige ut — forsvareren kan ha fem måter å stoppe hver sjakk hver for seg og ingen som stopper begge.',
      },
      {
        name: 'Avledning',
        short: 'Tving en forsvarer bort fra arbeidet den gjør.',
        body: 'En brikke holder et mattfelt, en grunnlinje eller en annen brikke. Angrip noe den vurderer høyere, eller slå rett og slett noe den må slå tilbake på, og dekningen den ga, forsvinner med den. Offeret ser ofte absurd ut til du merker hva brikken som slår tilbake, ikke lenger dekker.',
      },
      {
        name: 'Tiltrekning',
        short: 'Lokk en brikke — som regel kongen — til et felt der den kan treffes.',
        body: 'Et offer motstanderen er tvunget til å ta, spilt ikke for å vinne materiell, men for å plassere en brikke skjebnesvangert: en konge dratt til et gaffelfelt, en dronning trukket ut på en linje med et tårn. Materiellet kommer tilbake et trekk senere med renter.',
      },
      {
        name: 'Rydding',
        short: 'Flytt din egen brikke ut av veien for ditt eget angrep.',
        body: 'Linjen eller feltet er det rette, og det står en av dine egne der. Ryddingen flytter ham unna med tempo — som regel med sjakk eller slag, så motstanderen ikke rekker å omgruppere mens veien åpner seg.',
      },
      {
        name: 'Avskjæring',
        short: 'Kutt linjen mellom en forsvarer og det den forsvarer.',
        body: 'Sett en brikke — ofte ofret — nøyaktig mellom et tårn og feltet det vokter. Forsvareren står fortsatt på brettet, forsvarer i teorien fortsatt, og kan ikke lenger. Sjeldent, og et av de vanskeligste mønstrene å se, fordi den avskjærende brikken som regel ser ut som en bommert.',
      },
      {
        name: 'Røntgenangrep',
        short: 'En brikke virker gjennom en annen brikke, langs linjen den vil besette senere.',
        body: 'Et tårn som dekker sin egen brikke gjennom en fiendtlig brikke, eller angriper gjennom den. Ennå skjer ingenting; det som teller, er hva som skjer når brikken imellom flytter eller blir slått. Å se et røntgenangrep er som regel det som gjør at et slag som «taper materiell», ikke taper materiell.',
      },
      {
        name: 'Mellomtrekk',
        short: 'Trekket imellom: gjør noe mer tvingende før du slår tilbake.',
        body: 'Fra tysk «Zwischenzug», og den vanligste enkeltgrunnen til at en utregnet variant viser seg feil. Du venter et gjenslag; i stedet kommer en sjakk, eller en større trussel, og når gjenslaget først kommer, har stillingen endret seg. Se etter et hver gang en sekvens ser tvunget ut.',
      },
      {
        name: 'Trekktvang',
        short: 'Selve plikten til å trekke er problemet.',
        body: 'Hvert lovlige trekk gjør stillingen verre, og å stå over er ikke tillatt. Framfor alt en sluttspillsidé — den avgjør bondesluttspill — og grunnen til at «opposisjonen» teller: den som først må gå til side, gir fra seg feltet. Nesten den eneste situasjonen i sjakk der retten til å trekke er en byrde.',
      },
      {
        name: 'Grunnlinjematt',
        short: 'En konge stengt inne av sine egne bønder blir matt på første rad.',
        body: 'Den vanligste matten mellom spillere som har rokert og latt bøndene være. Den dukker sjelden opp som matt på brettet — den dukker opp som en trussel som vinner materiell, fordi hvert forsvarstrekk må fortsette å dekke raden. Hele familien av avledningstaktikker finnes for å fjerne den dekningen.',
      },
      {
        name: 'Kvelningsmatt',
        short: 'En springer matter en konge som hans egne brikker har stengt inne.',
        body: 'Slutten på Philidors legat: dronningoffer på g8, tårnet slår tilbake, springeren på f7 gir matt med kongen omgitt av sine egne. Sjelden i virkelige partier og likevel verdt å kunne, for mønsteret er det som får deg til å se i hjørnet og telle fluktfelter.',
      },
      {
        name: 'Hengende brikke',
        short: 'Noe er rett og slett udekket og kan tas.',
        body: 'Ikke glamorøst, og det avgjør flere partier enn alt annet på denne lista til sammen. De fleste tap under 1800 er den ene spilleren som tar en gratis brikke den andre mistet av syne. Vanen som kurerer det, er å sjekke hva som står løst — hos begge farger — før hvert trekk.',
      },
      {
        name: 'Innestengt brikke',
        short: 'En brikke har ikke noe trygt felt og kan jages ned i ro og mak.',
        body: 'Som regel en løper som tok en bonde den burde latt stå, eller en springer som dro på rov. Taktikken er ikke ett slag, men en kvelning: ta feltene ett om gangen, så faller brikken uten at det trengs noe offer.',
      },
      {
        name: 'Stille trekk',
        short: 'Det vinnende trekket er verken sjakk, slag eller trussel.',
        body: 'Grunnen til at sterke spillere finner kombinasjoner andre overser. Etter en tvunget sekvens er svaret et beskjedent trekk som tar det siste fluktfeltet, og det er usynlig for den som bare regner sjakker og slag. Når en stilling ser vunnet ut og ingenting tvingende virker, se etter det stille.',
      },
      {
        name: 'Offer',
        short: 'Gi materiell for noe som er verdt mer enn materiell.',
        body: 'Tid, linjer, felter, eller fiendekongens stilling. Et virkelig offer er ikke et veddemål; det er en utregning med en konkret slutt. Det som skiller et offer som virker fra et som ikke gjør det, er nesten alltid om de forsvarende brikkene rekker tilbake.',
      },
      {
        name: 'Framskutt bonde',
        short: 'En bonde nær forvandling endrer hva enhver annen brikke er verdt.',
        body: 'En bonde på sjuende rad er ingen bonde; den er en dronning noe må vokte, og det noe er ikke lenger fritt. De fleste sluttspillstaktikker handler i virkeligheten om spenningen mellom å stoppe en bonde og å gjøre hva som helst annet.',
      },
    ],
    after: {
      slug: 'Hvorfor tallene står her',
      title: 'En ordliste sier hva en gaffel er. Et tall sier om du kan øve på den.',
      body: [
        'Å kunne navnet på et mønster og å kunne finne det under klokka er ulike ferdigheter, og bare den andre vinner partier. Hvert tall over er det virkelige antallet stillinger i det medfølgende biblioteket som er merket med det motivet — ikke et anslag, og ikke rundet opp. Seksti røntgenoppgaver er seksti; er det nettopp det du stadig bommer på, er det godt å vite at de ikke tar slutt på én kveld.',
        'Treneren holder styr på hvilke motiver du tar feil av, så den etter noen hundre oppgaver kan si deg ikke at du er 1620, men at du er 1620 og gang på gang går på avledninger.',
      ],
      more: 'Hvordan oppgavene utvinnes og kontrolleres →',
    },
  },
};
