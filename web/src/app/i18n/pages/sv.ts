import type { Pages } from './types';

/** The four commercial pages in Swedish. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Support',
      title: 'Fråga en människa',
      lede: 'Det finns inget ärendesystem, ingen chattbot och inget hjälpcenter med fyrahundra artiklar. Det finns en e-postadress och en lista över fel, och båda leder till den som skrev appen.',
    },
    meta: {
      title: 'Support',
      description:
        'Hur du når en människa om Brass Pawn, vad du skickar med när en övning är fel, och de frågor som kommer oftast.',
    },
    email: {
      slug: 'E-post',
      body: 'För allt: ett fel, en felaktig övning, en fråga om ett köp, eller oenighet med en bedömning. Skriv på engelska eller bulgariska.',
    },
    tracker: {
      slug: 'Fellista',
      name: 'GitHub-ärenden',
      body: 'För allt du hellre har offentligt — och för allt andra behöver kunna hitta senare, vilket gäller de flesta felrapporter.',
    },
    report: {
      slug: 'När en övning är fel',
      title: 'Skicka fyra saker så tar kontrollen en minut.',
      checklist: [
        'FEN:en som visas på övningsskärmen — håll ner för att kopiera den.',
        'Draget du gjorde, och draget appen kallade rätt.',
        'Vilket läge du var i.',
        'Appversionen, från informationsskärmen.',
      ],
      caveat:
        'Övningar motsäger då och då en djupare sökning, och de motsägelserna samlas i långa, tysta, högt värderade ställningar vars poäng ligger djupare än kontrollen nådde. Det är en gräns för kontrollen och inte ett fel i övningen — men det är värt att veta vilka de är, och enda sättet att veta det är att du säger till.',
    },
    faq: { slug: 'Frågor', title: 'Ställda tillräckligt ofta för att skrivas ner.' },
    more: {
      ratings: 'Vad en rating mäter',
      tactics: 'Motiven',
      privacy: 'Integritetspolicy',
      terms: 'Användarvillkor',
      licences: 'Licenser',
    },
  },

  pricing: {
    head: {
      slug: 'Vad det kostar',
      title: 'Att spela är gratis. Träningen säljs.',
      lede: 'Schack mot motorn och schack mot en människa, utan gräns, utan reklam någonstans i appen — det är gratis och förblir så. Det som säljs är biblioteket, övningarna, uppgifterna och kapplöpningen mot klockan.',
    },
    meta: {
      title: 'Priser',
      description:
        'Att spela är gratis och obegränsat — motorn, en levande motståndare och alla 900 partier. Pro tar bort gränsen på fem per dag: 3,99 dollar i månaden eller 49,99 en gång.',
    },
    free: {
      name: 'Gratis',
      note: 'Inget konto. Ingenting att registrera sig för.',
      items: [
        'Obegränsat spel mot motorn, 1400 till full styrka',
        'Obegränsade partier online via Game Center',
        'Kommentar drag för drag i varje parti du spelar',
        'Fem taktikövningar per dag',
        'Fem Rush-omgångar per dag',
        'Fem av varje: positionella, slutspel, Gissa Elo',
        'Ratingar, sviter och spridd repetition, i sin helhet',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Månadsvis',
      per: 'per månad',
      note: 'Avbryt när du vill i inställningarna för ditt Apple-konto.',
      items: [
        'Alla dagsgränser borta',
        'Alla {tactics} taktikövningar',
        'Alla {positional} positionella övningar',
        'Alla {endgames} slutspelsövningar',
        'Alla {games} partier att bedöma',
        'Rush utan gräns',
        'Allt från Gratis, oförändrat',
      ],
    },
    lifetime: {
      name: 'Engångsupplåsning',
      once: 'en gång för alla',
      note: 'Ett icke förbrukningsbart köp. Det förnyas inte.',
      items: [
        'Exakt samma sak som Pro månadsvis',
        'Ingen förnyelse, inget utgångsdatum, inga påminnelsemejl',
        'Återställs på dina andra enheter',
        'För den som hellre bestämmer sig en gång',
      ],
    },
    table: {
      slug: 'Hela portionen',
      title: 'Vad gratisversionen faktiskt ger.',
      activity: 'Aktivitet',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Obegränsat',
      fiveADay: '5 per dag',
      none: 'Ingen',
      rows: [
        'Spela mot motorn',
        'Partier online via Game Center',
        'Titta — biblioteket med 900 partier',
        'Taktikövningar',
        'Rush-omgångar',
        'Positionella övningar',
        'Slutspelsövningar',
        'Gissa Elo',
        'Reklam',
      ],
      reset:
        'Dagsportionerna nollställs klockan nio på morgonen lokal tid — inte vid midnatt, så att ett kvällspass inte skärs itu av ett datumbyte.',
    },
    why: {
      slug: 'Varför det ser ut så',
      title: 'Tre beslut, och skälet till vart och ett.',
      reasons: [
        {
          title: 'Räknat, inte låst',
          body: [
            'Ingen betalar för en tränare han inte har använt, och ett läge som vägrar öppna sig säger ingenting om vad som finns bakom. Så varje läge öppnas, varje dag, och du kommer tillräckligt långt för att känna rytmen och se ratingen röra sig.',
            'Köpskärmen dyker aldrig upp vid start. När dagens portion är slut säger skärmen det, och först en medveten tryckning öppnar köpbladet.',
          ],
        },
        {
          title: 'Två priser, inte tre',
          body: [
            'Det finns ingen årsplan däremellan, för ett tredje pris är ett tredje beslut precis när någon vill lösa en övning. Månadsvis om du tvekar. En gång om du inte gör det.',
          ],
        },
        {
          title: 'Att spela säljs aldrig',
          body: [
            'Schack mot motorn och mot en människa kostar ingenting att driva och är skälet till att appen finns. Att sälja dem skulle göra den till en schackapp med vägtull i stället för en tränare.',
            'Och det finns ingen reklam — dels smak, dels licens. Appen länkar två copyleft-motorer, Stockfish under GPLv3 och Reckless under AGPLv3, och ett proprietärt annons-SDK i samma binär skulle göra helheten omöjlig att distribuera. {link}',
          ],
        },
      ],
      licenceLink: 'Licenssidan går igenom det ordentligt.',
    },
    answers: {
      slug: 'Köp, uppsägning, återbetalning',
      title: 'De obekväma frågorna, besvarade här i stället för per mejl.',
      items: [
        {
          q: 'Hur säger jag upp?',
          a: 'Inställningar → ditt namn → Prenumerationer → Brass Pawn. Vi kan inte säga upp åt dig, eftersom prenumerationen är mellan dig och Apple och aldrig har varit hos oss. Uppsägning stoppar framtida förnyelser och förkortar inte den redan betalda perioden.',
        },
        {
          q: 'Hur får jag pengarna tillbaka?',
          a: 'Via Apple, på {link}. Vi kan inte återbetala köp från App Store. Om något är trasigt, skriv till oss — vi lagar hellre.',
        },
        {
          q: 'Jag köpte upplåsningen och har en ny telefon.',
          a: 'Logga in på samma Apple-konto och tryck på ”Återställ köp” på köpskärmen. Appen frågar StoreKit vad du äger; ingenting ligger på en server hos oss, för vi har ingen server.',
        },
        {
          q: 'Ändrar Pro min rating eller låser upp ”bättre” övningar?',
          a: 'Nej. Ratingsystemet är identiskt, och varje övning i biblioteket går att nå med ett gratiskonto — fem per dag. Pro tar bort räknaren, inte en ridå.',
        },
        {
          q: 'Krymper gratisportionen senare?',
          a: 'Den kan ändras åt båda hållen när biblioteket växer. Obegränsat spel mot motorn och mot en människa blir inte en betalfunktion; det står i {link} och är inte bara lovat här.',
        },
      ],
      termsLink: 'villkoren',
      more: 'Fler frågor, och hur du når en människa →',
    },
  },

  training: {
    head: {
      slug: 'Programmet',
      title: 'Åtta sätt att höra sanningen',
      lede: 'Tre av dem är gratis och obegränsade för alltid — att spela, att spela mot någon, och de niohundra partierna i Titta. De andra fem är fem per dag med ett gratiskonto och obegränsade med Pro. Var och en bedömer dig med ord om ställningen i stället för med en siffra du först måste tolka.',
    },
    meta: {
      title: 'Träning',
      description:
        'Åtta lägen: taktik, positionellt omdöme, slutspel, Rush, Gissa Elo, Titta, spel med kommentar och online. Hur vart och ett fungerar, hur övningarna bryts fram och kontrolleras, och vad tränaren inte gör.',
    },
    modes: [
      {
        title: 'Taktik',
        lede: 'Ställningar med precis ett vinnande drag, och en dom i samma stund du spelar det.',
        body: [
          'Varje övning har ett svar och inga förgreningar. Spela det på brädet så säger tränaren genast om du hittade det; missar du, kommer ställningen tillbaka i morgon, sedan om fyra dagar, sedan om tio — så länge den fortsätter att sätta dit dig.',
          'Varje övning bär motivet den kretsar kring — gaffel, bindning, spett, grundradsmatt, avledning, det tysta draget — så att tränaren efter några hundra kan säga dig inte att du är 1620, utan att du är 1620 och gång på gång går på avledningar.',
        ],
        free: 'Fem per dag med ett gratiskonto.',
        stat: 'övningar, värderade från 760 till 2800',
      },
      {
        title: 'Positionellt omdöme',
        lede: 'Det finns ingen framtvingad vinst. Säg vem som står bättre, och hitta sedan draget som säger varför.',
        body: [
          'Det här är läget byggt för det som skiljer starka spelare från goda räknare. Först bedömer du: klart bättre, något bättre, jämnt. Sedan väljer du ett drag. Båda svaren bedöms.',
          'Återkopplingen namnger konkreta drag i ställningen i stället för stämningar — den öppna linjen och om ett torn står på den, springarfältet ingen bonde kan bestrida, bondestrukturen, kungssäkerheten, skillnaden i pjäsaktivitet. En ställning är inte ”trevlig för vit”; den är bättre av fyra skäl du kan räkna upp.',
        ],
        free: 'Fem per dag med ett gratiskonto.',
        stat: 'tysta ställningar, förvalda av motorn',
      },
      {
        title: 'Slutspel',
        lede: 'Kanoniska ställningar, spelade till slut mot en motor som försvarar sig anständigt.',
        body: [
          'Att kunna idén är inte samma sak som att bärga den, så här måste du faktiskt nå resultatet. Stockfish tar andra sidan och ställer upp det bästa försvar som finns.',
          'Efter varje drag kontrollerar tränaren på nytt om resultatet fortfarande går att nå — och om inte, namnger den exakt det drag där det slutade gå. Det är meningen som lär något: inte ”du remiserade”, utan ”du remiserade här”.',
        ],
        free: 'Fem per dag med ett gratiskonto.',
        stat: 'övningar, varje resultat kontrollerat av motorn',
      },
      {
        title: 'Rush',
        lede: 'En omgång på tid. Lös så många du hinner innan klockan tar resten.',
        body: [
          'Samma övningar, under klocka, med en svårighet som stiger så länge du fortsätter hitta dem. Det tränar en annan muskel än en övning man får stirra på: den som måste se det nu.',
          'Omgångar poängsätts och sparas, så siffran stiger över månader i stället för över en kväll.',
        ],
        free: 'Fem omgångar per dag med ett gratiskonto.',
      },
      {
        title: 'Gissa Elo',
        lede: 'Ett verkligt ratat parti, uppspelat drag för drag. Hur starka var de här två?',
        body: [
          'Att läsa nivån i ett parti är samma färdighet som att bedöma dina egna drag: båda handlar om att märka vilka misstag som görs och vilka som inte görs. Så partiet rullar, du tittar, och vid någon punkt bestämmer du dig för en siffra.',
          'Partierna är verkliga, ur Lichess arkiv, med båda spelarna inom 150 poäng från varandra — en gissning om ”spelarna” betyder bara något när det finns en nivå att gissa.',
        ],
        free: 'Fem per dag med ett gratiskonto.',
        stat: 'ratade partier, från 800 till 2599',
      },
      {
        title: 'Titta',
        lede: 'Niohundra partier värda att se — och i det ögonblick du hade spelat annorlunda tar du över.',
        body: [
          'Varje parti i biblioteket är avgörande, mellan två spelare med namn, och antingen slut inom tjugofem drag eller berömt nog att ha ett eget namn. Ingen lär sig något av en nittiodragsremi mellan människor han aldrig hört talas om, och ett bibliotek som innehåller sådant är ett bibliotek ingen öppnar två gånger.',
          'Sök upp en spelare, en turnering eller ett år. Gå sedan igenom partiet i din egen takt. Det handlar inte om höjdpunkterna: det handlar om att du vid något drag kommer att tänka <em>där hade jag slagit</em> — och i det ögonblicket kan du. Ta över ställningen och spela vidare mot motorn från exakt den ruta där du inte höll med. Att ta reda på vad din idé egentligen var värd är hela övningen.',
        ],
        free: 'Gratis, obegränsat, alltid.',
        stat: 'partier, alla avgörande',
      },
      {
        title: 'Spela med coach',
        lede: 'Ett helt parti på den styrka du väljer, med varje drag du gör bedömt medan du spelar.',
        body: [
          'Sätt motorn någonstans mellan 1400 och full styrka och spela ut partiet. Varje drag du gör bedöms medan partiet ännu pågår, och coachen förklarar vad det bättre draget hade uppnått — med ord om ställningen, inte som en siffra.',
          'I slutet får du träffsäkerhet, antalet grova misstag, och det enda ögonblick som kostade mest.',
        ],
        free: 'Gratis, obegränsat, alltid.',
      },
      {
        title: 'Online',
        lede: 'Två människor, en klocka, och ingen motor i närheten.',
        body: [
          'Game Center hittar någon som valde samma betänketid — 3, 5, 10, 15 eller 30 minuter. Det är det enda läget utan motor i sig: ingen ledtråd, inga dragvärderingar, ingen coachning, för hjälp som bara den ena sidan får är inte ett parti.',
          'Det finns ingen server. De två enheterna talar med varandra och båda upprätthåller reglerna, så ett drag spelas bara om det är lagligt i den ställning den mottagande enheten redan har. En motpart som ljuger ger ett kasserat paket, inte ett olagligt bräde.',
        ],
        free: 'Gratis, obegränsat, alltid.',
      },
    ],
    watchLink: 'Vad som kom med i biblioteket och vad som inte gjorde det →',
    pipeline: {
      slug: 'Hur en övning blir till',
      title: 'Frambrutna, inte avskrivna.',
      lede: 'Att skriva av ställningar ur minnet riskerar en övning vars ”lösning” är fel eller inte unik, och det tränar precis fel instinkt. Så ingen av dem är avskriven ur minnet. De hittas och angrips sedan tills de överlever eller kastas.',
      steps: [
        {
          title: 'Spel på mänsklig styrka',
          body: 'Stockfish spelar mot sig själv på avsiktligt mänsklig styrka — 1320 till 2500 Elo — och öppnar med ett slumpvalt drag bland sina bästa grunda kandidater, så att partierna varierar i stället för att upprepa en variant i evighet.',
        },
        {
          title: 'Sållning på egenskapen, inte på misstaget',
          body: 'Varje ställning söks igenom på djup 12 med två kandidatvarianter. Signalen är inte ”någon gjorde bort sig” utan det en övning verkligen behöver: ett drag som är mycket bättre än varje alternativ.',
        },
        {
          title: 'Ny djup sökning, med marginal',
          body: 'De överlevande söks igenom på nytt på djup 20 med MultiPV. En kandidat stannar bara om bästa draget slår det näst bästa med minst 140 hundradels bonde och dessutom faktiskt uppnår något.',
        },
        {
          title: 'Förlängning tills den förgrenar sig',
          body: 'Lösningen förlängs drag för drag så länge varje drag från lösaren förblir unikt bäst. I det ögonblick det finns två goda svar slutar övningen där — den har alltså aldrig en förgrening där du kan räknas som fel.',
        },
        {
          title: 'Kontroll med en färsk motor',
          body: 'Hela samlingen granskas om på större djup av ett separat skript med en ny motor. På den medföljande frambrutna samlingen förkastade det 6 av 172 övningar vars lösningar upphörde att vara unika två halvdrag djupare. De kastades i stället för att levereras.',
        },
      ],
    },
    honest: {
      title: 'Och samma misstro tillämpad på slutspelen',
      body: [
        'Det angivna resultatet för varje slutspelsövning kontrolleras mot en djup sökning i stället för att tas på ord. En felmärkt övning underkänns i kontrollen i stället för att tyst lära dig något osant.',
        'Kontrollen fångar också något de vanliga schackbiblioteken inte berättar: om sidan som inte har draget står i schack. En sådan ställning är olaglig — inget parti kan nå den — men ett bibliotek godtar den villigt, och motorn svarar med bestmove (none), vilket låter som ett motorfel snarare än en dålig ställning. Tre handskrivna övningar var trasiga på just det sättet. Kontrollen fångar det nu.',
      ],
    },
    limits: {
      slug: 'Ärliga gränser',
      title: 'Vad det här inte gör.',
      items: [
        {
          title: 'Samlingen blandar två ratingskalor.',
          body: '{lichess} Lichess-övningar bär ratingar kalibrerade mot miljontals mänskliga försök. De {mined} lokalt frambrutna övningarna bär skattningar ur lösningsdjup och motiv. Båda ordnar vettigt, men en frambruten 1600 och en Lichess-1600 är inte mätta på samma sätt.',
        },
        {
          title: 'Övningsratingar är inte brädratingar.',
          body: 'De ligger flera hundra poäng högre, och så förblir det. De mäter framsteg mot dig själv, inte styrka mot ett fält människor vid klockan — {link}, för glappet är strukturellt och inget tecken på att du avslutar dåligt.',
        },
        {
          title: 'Det finns ingen öppningsträning.',
          body: 'Med avsikt. Öppningsstudier är memorering mot en repertoar du väljer, och det är ett annat verktyg med en annan form. Det positionella läget täcker övergången ur öppningen, och det är den del som verkligen låter sig generaliseras.',
        },
        {
          title: 'Det här gör dig inte till stormästare.',
          body: 'Ingenting gör det på egen hand. Titlar kommer ur tusentals timmar plus ratade turneringspartier mot människor. Det du får här är träningshalvan av det, strukturerad, med ett ärligt mått på var du faktiskt står.',
        },
      ],
      ratingsLink: 'värt att förstå ordentligt',
    },
    more: {
      motifs: 'De tjugo motiven, definierade och räknade →',
      engine: 'Hur motorn används →',
    },
  },

  tactics: {
    head: {
      slug: 'Ordlista',
      title: 'De tjugo motiven',
      lede: 'Varje taktik i schack är en av ett litet antal former, och så snart du kan namnge dem ser du dem ett drag tidigare. Det här är motiven Brass Pawn märker sina övningar med — vart och ett följt av hur många ställningar i det medföljande biblioteket som faktiskt kretsar kring det.',
      meta: 'Räknat ur den medföljande samlingen om 14 351 övningar · Senast kontrollerat 19 augusti 2026',
    },
    meta: {
      title: 'De tjugo motiven',
      description:
        'Varje taktiskt motiv Brass Pawn märker sina övningar med, definierat och räknat mot det medföljande biblioteket, så att du vet vilka du faktiskt kan öva.',
    },
    indexLabel: 'Motiven',
    puzzles: 'övningar',
    motifs: [
      {
        name: 'Gaffel',
        short: 'En pjäs angriper två saker samtidigt, och bara en av dem går att rädda.',
        body: 'Springaren är den berömda gafflaren eftersom den angriper fält ingen annan pjäs täcker på samma sätt, men allt gafflar: en bonde som träffar två lätta pjäser, en dam som träffar ett torn och en lös löpare, en kung i slutspelet som kliver in mellan två bönder. Provet är inte ”angriper jag två saker” utan ”kan båda komma undan”.',
      },
      {
        name: 'Bindning',
        short: 'En pjäs kan inte flytta för att något värdefullare står bakom den.',
        body: 'Absolut när kungen står bakom — att flytta är olagligt, inte bara dåligt. Relativ när en dam eller ett torn står bakom, där det är lagligt att flytta och helt enkelt kostar material. Fortsättningen vinner: en bunden pjäs är en pjäs som inte kan täcka, så lägg fler angripare på den, eller slå på den med en bonde.',
      },
      {
        name: 'Spett',
        short: 'En bindning bakvänt: den värdefulla pjäsen står främst och måste flytta.',
        body: 'Ge kungen schack längs en linje med torn, löpare eller dam, och det som stod bakom är ditt så snart kungen kliver undan. Spett är ovanligare än bindningar eftersom de kräver att två pjäser redan står på samma linje med den värdefulla främst — därför dyker de oftast upp efter att ett schack tvingat kungen dit.',
      },
      {
        name: 'Avdragsangrepp',
        short: 'Att flytta en pjäs blottar angreppet från den som stod bakom.',
        body: 'Med bred marginal den starkaste taktiken i schack, eftersom pjäsen som går undan är fri att göra något eget medan det blottade angreppet gör jobbet. Två hot uppstår i ett drag, och inget av dem besvaras med att slå pjäsen som flyttade.',
      },
      {
        name: 'Avdragsschack',
        short:
          'Det blottade angreppet är ett schack, så motståndaren har inte tid till något annat.',
        body: 'Ett avdragsangrepp där pjäsen bakom ger schack. Vad pjäsen som går undan än gör — slår en dam, ställer sig på ett mattfält, ställer sig i vägen — måste svaret först hantera schacket, så det sker gratis.',
      },
      {
        name: 'Dubbelschack',
        short: 'Två pjäser ger schack samtidigt, så kungen måste flytta. Inte skärma, inte slå.',
        body: 'Den enda taktik mot vilken det finns precis ett slags lagligt svar. Att slå den ena schackgivaren lämnar den andra; att skärma en linje lämnar den andra öppen. Därför ger dubbelschack matter som ser omöjliga ut — försvararen kan ha fem sätt att stoppa vart schack för sig och inget som stoppar båda.',
      },
      {
        name: 'Avledning',
        short: 'Tvinga en försvarare bort från arbetet den utför.',
        body: 'En pjäs håller ett mattfält, en grundrad eller en annan pjäs. Angrip något den värderar högre, eller slå helt enkelt något den måste ta tillbaka på, och täckningen den gav försvinner med den. Offret ser ofta orimligt ut tills du märker vad pjäsen som slår tillbaka inte längre täcker.',
      },
      {
        name: 'Framlockning',
        short: 'Lockar en pjäs — oftast kungen — till ett fält där den kan träffas.',
        body: 'Ett offer motståndaren är tvungen att ta, spelat inte för att vinna material utan för att ställa en pjäs ödesdigert: en kung släpad till ett gaffelfält, en dam dragen till en linje med ett torn. Materialet kommer tillbaka ett drag senare med ränta.',
      },
      {
        name: 'Röjning',
        short: 'Flytta undan din egen pjäs ur vägen för ditt eget angrepp.',
        body: 'Linjen eller fältet är rätt och det står en egen man där. Röjningen flyttar undan honom med tempo — oftast med schack eller slag, så att motståndaren inte hinner omgruppera medan vägen öppnas.',
      },
      {
        name: 'Avskärmning',
        short: 'Kapa linjen mellan en försvarare och det den försvarar.',
        body: 'Ställ en pjäs — ofta offrad — precis mellan ett torn och fältet det vaktar. Försvararen står kvar på brädet, försvarar i teorin fortfarande, och kan inte längre. Ovanligt, och ett av de svåraste mönstren att se, eftersom den avskärmande pjäsen oftast ser ut som ett grovt misstag.',
      },
      {
        name: 'Röntgenangrepp',
        short: 'En pjäs verkar genom en annan pjäs, längs linjen den kommer att besätta senare.',
        body: 'Ett torn som försvarar sin egen pjäs genom en fiendepjäs, eller angriper genom den. Ännu händer ingenting; det som räknas är vad som händer när pjäsen emellan flyttar eller slås. Att se ett röntgenangrepp är oftast det som gör att ett slag som ”förlorar material” inte förlorar material.',
      },
      {
        name: 'Mellandrag',
        short: 'Draget emellan: gör något mer tvingande innan du slår tillbaka.',
        body: 'Från tyskans ”Zwischenzug”, och det vanligaste enskilda skälet till att en uträknad variant visar sig vara fel. Du väntar ett återslag; i stället kommer ett schack, eller ett större hot, och när återslaget väl kommer har ställningen förändrats. Leta efter ett varje gång en sekvens ser tvingad ut.',
      },
      {
        name: 'Dragtvång',
        short: 'Själva tvånget att dra är problemet.',
        body: 'Varje lagligt drag gör ställningen sämre, och att stå över är inte tillåtet. Framför allt en slutspelsidé — den avgör bondeslutspel — och skälet till att ”oppositionen” räknas: den som först måste kliva åt sidan ger bort fältet. Nästan den enda situation i schack där rätten att dra är en börda.',
      },
      {
        name: 'Grundradsmatt',
        short: 'En kung instängd av sina egna bönder blir matt på första raden.',
        body: 'Den vanligaste matten mellan spelare som har rockerat och lämnat bönderna i fred. Den dyker sällan upp som matt på brädet — den dyker upp som ett hot som vinner material, eftersom varje försvarsdrag måste fortsätta täcka raden. Hela familjen av avledningstaktiker finns för att ta bort den täckningen.',
      },
      {
        name: 'Kvävmatt',
        short: 'En springare mattar en kung som hans egna pjäser har stängt in.',
        body: 'Slutet på Philidors legat: damoffer på g8, tornet slår tillbaka, springaren på f7 ger matt med kungen omgiven av sina egna. Ovanligt i verkliga partier och ändå värt att kunna, för mönstret är det som får dig att titta i hörnet och räkna flyktfält.',
      },
      {
        name: 'Hängande pjäs',
        short: 'Något är helt enkelt otäckt och går att ta.',
        body: 'Inte glamoröst, och det avgör fler partier än allt annat på den här listan tillsammans. De flesta förluster under 1800 är den ena spelaren som tar en gratis pjäs den andra tappade bort. Vanan som botar det är att kolla vad som står löst — hos båda färgerna — före varje drag.',
      },
      {
        name: 'Instängd pjäs',
        short: 'En pjäs har inget säkert fält och kan jagas ner i lugn och ro.',
        body: 'Oftast en löpare som tog en bonde den borde ha låtit stå, eller en springare som gav sig ut på rov. Taktiken är inte ett enda slag utan en strypning: ta fälten ett i taget, så faller pjäsen utan att något offer behövs.',
      },
      {
        name: 'Tyst drag',
        short: 'Det vinnande draget är varken schack, slag eller hot.',
        body: 'Skälet till att starka spelare hittar kombinationer andra missar. Efter en tvingad sekvens är svaret ett anspråkslöst drag som tar det sista flyktfältet, och det är osynligt för den som bara räknar schackar och slag. När en ställning ser vunnen ut och inget tvingande fungerar, leta efter det tysta.',
      },
      {
        name: 'Offer',
        short: 'Ge material för något som är värt mer än material.',
        body: 'Tid, linjer, fält, eller fiendekungens läge. Ett verkligt offer är inte ett vad; det är en uträkning med ett konkret slut. Det som skiljer ett offer som fungerar från ett som inte gör det är nästan alltid om de försvarande pjäserna hinner tillbaka.',
      },
      {
        name: 'Långt framskjuten bonde',
        short: 'En bonde nära förvandling ändrar vad varje annan pjäs är värd.',
        body: 'En bonde på sjunde raden är ingen bonde; den är en dam som något måste vakta, och det något är inte längre fritt. De flesta slutspelstaktiker handlar i själva verket om spänningen mellan att stoppa en bonde och att göra något annat.',
      },
    ],
    after: {
      slug: 'Varför siffrorna står här',
      title: 'En ordlista säger vad en gaffel är. En siffra säger om du kan öva den.',
      body: [
        'Att kunna namnet på ett mönster och att kunna hitta det under klocka är olika färdigheter, och bara den andra vinner partier. Varje siffra ovan är det verkliga antalet ställningar i det medföljande biblioteket som är märkta med det motivet — ingen skattning, och inte uppåtrundat. Sextio röntgenövningar är sextio; om det är just det du fortsätter missa är det bra att veta att de inte tar slut på en kväll.',
        'Tränaren håller reda på vilka motiv du får fel, så att den efter några hundra övningar kan säga dig inte att du är 1620, utan att du är 1620 och gång på gång går på avledningar.',
      ],
      more: 'Hur övningarna bryts fram och kontrolleras →',
    },
  },
};
