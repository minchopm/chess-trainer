import type { Pages } from './types';

/** The four commercial pages in Italian. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Assistenza',
      title: 'Chiedi a una persona',
      lede: 'Non c’è un sistema di ticket, non c’è un chatbot e non c’è un centro assistenza con 400 articoli dentro. C’è un indirizzo e-mail e un registro dei problemi, ed entrambi arrivano alla persona che ha scritto l’app.',
    },
    meta: {
      title: 'Assistenza',
      description:
        'Come raggiungere una persona vera per Brass Pawn, cosa allegare quando un esercizio è sbagliato, e le domande che vengono fatte più spesso.',
    },
    email: {
      slug: 'E-mail',
      body: 'Per qualsiasi cosa: un difetto, un esercizio sbagliato, una domanda su un acquisto o un disaccordo con una valutazione. Scrivi in inglese o in bulgaro.',
    },
    tracker: {
      slug: 'Registro dei problemi',
      name: 'Issue su GitHub',
      body: 'Per tutto ciò che preferiresti fosse pubblico — e per tutto ciò che vuoi che altri possano ritrovare dopo, il che vale per la maggior parte delle segnalazioni.',
    },
    report: {
      slug: 'Se un esercizio è sbagliato',
      title: 'Manda quattro cose e si può verificare in un minuto.',
      checklist: [
        'La FEN mostrata nella schermata dell’esercizio — tieni premuto per copiarla.',
        'La mossa che hai giocato e quella che l’app ha dato per buona.',
        'In quale modalità ti trovavi.',
        'La versione dell’app, dalla schermata Informazioni.',
      ],
      caveat:
        'Gli esercizi ogni tanto contraddicono una ricerca più profonda, e le contraddizioni si concentrano su posizioni lunghe, tranquille e con valutazione alta, il cui punto sta più in fondo di quanto la verifica abbia cercato. È un limite del controllo, non un difetto dell’esercizio — ma vale la pena sapere quali sono, e l’unico modo per saperlo è che tu lo dica.',
    },
    faq: { slug: 'Domande', title: 'Fatte abbastanza spesso da meritare di essere scritte.' },
    more: {
      ratings: 'Che cosa misura una valutazione',
      tactics: 'I motivi',
      privacy: 'Informativa sulla privacy',
      terms: 'Termini di servizio',
      licences: 'Licenze',
    },
  },

  pricing: {
    head: {
      slug: 'Quanto costa',
      title: 'Giocare è gratis. L’allenamento si vende.',
      lede: 'Scacchi contro il motore e scacchi contro una persona, senza limiti, senza pubblicità in nessuna parte dell’app — questo è gratis e resta gratis. Quello che si vende è la biblioteca, gli esercizi, i problemi e la corsa contro il tempo.',
    },
    meta: {
      title: 'Prezzi',
      description:
        'Giocare è gratis e senza limiti — il motore, un avversario vero e tutte le 900 partite. Pro toglie il limite di cinque al giorno: 3,99 dollari al mese oppure 49,99 una volta sola.',
    },
    free: {
      name: 'Gratis',
      note: 'Nessun account. Niente a cui iscriversi.',
      items: [
        'Gioco illimitato contro il motore, da 1400 a piena forza',
        'Partite online illimitate tramite Game Center',
        'Commento mossa per mossa in ogni partita che giochi',
        'Cinque esercizi tattici al giorno',
        'Cinque corse Rush al giorno',
        'Cinque di ciascuno: posizionale, finale, Indovina l’Elo',
        'Valutazioni, serie e ripetizione dilazionata, per intero',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Mensile',
      per: 'al mese',
      note: 'Disdici quando vuoi nelle impostazioni del tuo account Apple.',
      items: [
        'Ogni limite giornaliero rimosso',
        'Tutti i {tactics} esercizi tattici',
        'Tutti i {positional} esercizi posizionali',
        'Tutti i {endgames} esercizi di finale',
        'Tutte le {games} partite da valutare',
        'Rush senza limiti',
        'Tutto quello di Gratis, invariato',
      ],
    },
    lifetime: {
      name: 'Sblocco una tantum',
      once: 'una volta',
      note: 'Un acquisto non consumabile. Non si rinnova.',
      items: [
        'Esattamente come Pro mensile',
        'Nessun rinnovo, nessuna scadenza, nessuna e-mail di promemoria',
        'Si ripristina sugli altri tuoi dispositivi',
        'Per chi preferisce decidere una volta sola',
      ],
    },
    table: {
      slug: 'La dotazione completa',
      title: 'Che cosa dà davvero il piano gratuito.',
      activity: 'Attività',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Senza limiti',
      fiveADay: '5 al giorno',
      none: 'Nessuna',
      rows: [
        'Giocare contro il motore',
        'Partite online tramite Game Center',
        'Guardare — la biblioteca di 900 partite',
        'Esercizi tattici',
        'Corse Rush',
        'Esercizi posizionali',
        'Esercizi di finale',
        'Indovina l’Elo',
        'Pubblicità',
      ],
      reset:
        'Le dotazioni giornaliere si azzerano alle nove del mattino, ora locale — non a mezzanotte, così una sessione serale non viene tagliata in due da un cambio di data.',
    },
    why: {
      slug: 'Perché è fatto così',
      title: 'Tre decisioni, e la ragione di ciascuna.',
      reasons: [
        {
          title: 'Contato, non chiuso a chiave',
          body: [
            'Nessuno paga per un allenatore che non ha usato, e una modalità che si rifiuta di aprirsi non insegna nulla su ciò che c’è dietro. Quindi ogni modalità si apre, ogni giorno, ed entri abbastanza dentro da sentire il ritmo e vedere la valutazione muoversi.',
            'Il muro di pagamento non compare mai all’avvio. Quando la dotazione del giorno è finita, la schermata lo dice, e solo un tocco deliberato apre il foglio d’acquisto.',
          ],
        },
        {
          title: 'Due prezzi, non tre',
          body: [
            'Non c’è un piano annuale in mezzo, perché un terzo prezzo è una terza decisione proprio nel momento in cui qualcuno vuole risolvere un esercizio. Mensile se non sei sicuro. Una tantum se lo sei.',
          ],
        },
        {
          title: 'Giocare non si vende mai',
          body: [
            'Gli scacchi contro il motore e contro una persona non costano nulla da far girare e sono la ragione per cui l’app esiste. Venderli la renderebbe un’app di scacchi con un casello invece che un allenatore.',
            'E non c’è pubblicità — in parte per gusto, in parte per licenza. L’app collega due motori copyleft, Stockfish sotto GPLv3 e Reckless sotto AGPLv3, e un SDK pubblicitario proprietario nello stesso binario renderebbe il tutto non distribuibile. {link}',
          ],
        },
      ],
      licenceLink: 'La pagina delle licenze lo spiega per bene.',
    },
    answers: {
      slug: 'Acquisto, disdetta, rimborsi',
      title: 'Le domande scomode, risposte qui e non per e-mail.',
      items: [
        {
          q: 'Come disdico?',
          a: 'Impostazioni → il tuo nome → Abbonamenti → Brass Pawn. Non possiamo disdirlo al posto tuo, perché l’abbonamento è fra te e Apple e non è mai stato nostro. Disdire ferma i rinnovi futuri e non accorcia il periodo che hai già pagato.',
        },
        {
          q: 'Come ottengo un rimborso?',
          a: 'Tramite Apple, su {link}. Non possiamo emettere rimborsi per acquisti dell’App Store. Se qualcosa è rotto, scrivici — preferiamo aggiustarlo.',
        },
        {
          q: 'Ho comprato lo sblocco e ho cambiato telefono.',
          a: 'Accedi con lo stesso account Apple e tocca «Ripristina acquisti» nella schermata d’acquisto. L’app chiede a StoreKit che cosa possiedi; non c’è nulla su un nostro server perché non c’è un nostro server.',
        },
        {
          q: 'Pro cambia la mia valutazione o sblocca esercizi «migliori»?',
          a: 'No. Il sistema di valutazione è identico e ogni esercizio della biblioteca è raggiungibile con un account gratuito — cinque al giorno. Pro toglie il contatore, non una tenda.',
        },
        {
          q: 'La dotazione gratuita si ridurrà più avanti?',
          a: 'Può cambiare in entrambe le direzioni mentre la biblioteca cresce. Il gioco illimitato contro il motore e contro una persona non diventerà a pagamento; è scritto nei {link} e non soltanto promesso qui.',
        },
      ],
      termsLink: 'Termini',
      more: 'Altre domande, e come raggiungere una persona →',
    },
  },

  training: {
    head: {
      slug: 'Il programma',
      title: 'Otto modi per sentirsi dire la verità',
      lede: 'Tre di questi sono gratis e senza limiti per sempre — giocare, giocare contro qualcun altro e le novecento partite in Guardare. Gli altri cinque sono cinque al giorno con un account gratuito e senza limiti con Pro. Ognuno ti valuta con parole sulla posizione invece che con un numero da interpretare.',
    },
    meta: {
      title: 'Allenamento',
      description:
        'Otto modalità: tattica, giudizio posizionale, finali, Rush, Indovina l’Elo, Guardare, gioco commentato e online. Come funziona ciascuna, come gli esercizi vengono estratti e verificati, e che cosa l’allenatore non fa.',
    },
    modes: [
      {
        title: 'Tattica',
        lede: 'Posizioni con esattamente una mossa vincente, e un verdetto nell’istante in cui la giochi.',
        body: [
          'Ogni esercizio ha una risposta e nessuna diramazione. Giocala sulla scacchiera e l’allenatore ti dice subito se l’hai trovata; sbagliala e la posizione torna domani, poi fra quattro giorni, poi fra dieci — finché continua a coglierti.',
          'Ogni esercizio porta l’etichetta del motivo su cui ruota — forchetta, inchiodatura, infilata, matto del corridoio, deviazione, la mossa tranquilla — così dopo qualche centinaio l’allenatore può dirti non che sei 1620, ma che sei 1620 e continui a passare accanto alle deviazioni.',
        ],
        free: 'Cinque al giorno con un account gratuito.',
        stat: 'esercizi, valutati da 760 a 2800',
      },
      {
        title: 'Giudizio posizionale',
        lede: 'Non esiste una vittoria forzata. Di’ chi sta meglio, poi trova la mossa che spiega perché.',
        body: [
          'Questa è la modalità fatta per ciò che separa i giocatori forti dai buoni calcolatori. Prima valuti: chiaramente meglio, un po’ meglio, in equilibrio. Poi scegli una mossa. Entrambe le risposte vengono valutate.',
          'Il riscontro nomina caratteristiche concrete invece di stati d’animo — la colonna aperta e se c’è una torre sopra, l’avamposto del cavallo che nessun pedone può contestare, la struttura pedonale, la sicurezza del re, la differenza di attività dei pezzi. Una posizione non è «gradevole per il Bianco»; è migliore per quattro cose che puoi elencare.',
        ],
        free: 'Cinque al giorno con un account gratuito.',
        stat: 'posizioni tranquille, filtrate dal motore',
      },
      {
        title: 'Finali',
        lede: 'Posizioni canoniche, giocate fino in fondo contro un motore che difende come si deve.',
        body: [
          'Conoscere l’idea non è come realizzarla, quindi qui devi ottenere davvero il risultato. Stockfish prende l’altra parte e oppone la miglior difesa che esista.',
          'Dopo ogni mossa l’allenatore ricontrolla se il risultato è ancora raggiungibile — e se non lo è, ti dice la mossa esatta in cui ha smesso di esserlo. È la frase che insegna: non «hai pattato», ma «hai pattato qui».',
        ],
        free: 'Cinque al giorno con un account gratuito.',
        stat: 'esercizi, ogni risultato verificato dal motore',
      },
      {
        title: 'Rush',
        lede: 'Una corsa a tempo. Risolvine quanti puoi prima che l’orologio si prenda il resto.',
        body: [
          'Gli stessi esercizi, contro l’orologio, con la difficoltà che sale finché continui a indovinare. Allena un muscolo diverso da quello di un esercizio che puoi fissare: quello che deve vedere adesso.',
          'Le corse vengono conteggiate e conservate, così il numero sale nell’arco di mesi invece che di una serata.',
        ],
        free: 'Cinque corse al giorno con un account gratuito.',
      },
      {
        title: 'Indovina l’Elo',
        lede: 'Una vera partita valutata, giocata mossa per mossa. Quanto erano forti questi due?',
        body: [
          'Leggere il livello di una partita è la stessa abilità che serve a giudicare le proprie mosse: entrambe si riducono a notare quali errori vengono commessi e quali no. Così la partita scorre, tu guardi, e a un certo punto ti impegni con un numero.',
          'Le partite sono vere, dagli archivi di Lichess, con i due giocatori entro 150 punti l’uno dall’altro — una stima su «i giocatori» significa qualcosa solo quando c’è un livello unico da indovinare.',
        ],
        free: 'Cinque al giorno con un account gratuito.',
        stat: 'partite valutate, da 800 a 2599',
      },
      {
        title: 'Guardare',
        lede: 'Novecento partite che vale la pena guardare — e nell’istante in cui avresti giocato diversamente, prendila in mano.',
        body: [
          'Ogni partita della biblioteca è decisiva, fra due giocatori con un nome, e o è finita entro la venticinquesima mossa o è abbastanza celebre da avere un nome proprio. Nessuno impara nulla da una patta di novanta mosse fra persone di cui non ha mai sentito parlare, e una biblioteca che le contiene è una biblioteca che nessuno apre due volte.',
          'Cerca un giocatore, un torneo o un anno. Poi scorri la partita al tuo ritmo. Il punto non è il montaggio dei momenti migliori: è che a una certa mossa penserai <em>io lì avrei preso</em> — e in quel momento puoi. Prendi la posizione e prosegui contro il motore esattamente dalla casa in cui non eri d’accordo. Scoprire quanto valeva davvero la tua idea è tutto l’esercizio.',
        ],
        free: 'Gratis, senza limiti, sempre.',
        stat: 'partite, tutte decisive',
      },
      {
        title: 'Gioca e fatti seguire',
        lede: 'Una partita intera alla forza che scegli, con ogni tua mossa valutata mentre giochi.',
        body: [
          'Imposta il motore ovunque fra 1400 e la piena forza e gioca la partita. Ogni tua mossa viene valutata mentre la partita è ancora in corso, e l’allenatore spiega che cosa avrebbe ottenuto la mossa migliore — con parole sulla posizione, non con un numero.',
          'Alla fine ottieni la precisione, il numero di errori gravi e l’unico momento che ti è costato di più.',
        ],
        free: 'Gratis, senza limiti, sempre.',
      },
      {
        title: 'Online',
        lede: 'Due persone, un orologio e nessun motore nei paraggi.',
        body: [
          'Game Center ti trova qualcuno che ha scelto lo stesso tempo di gioco — 3, 5, 10, 15 o 30 minuti. È l’unica modalità senza motore dentro: nessun suggerimento, nessun valore delle mosse, nessun commento, perché un aiuto che riceve una sola parte non è una partita.',
          'Non c’è un server. I due dispositivi si parlano ed entrambi applicano le regole, così una mossa viene giocata solo se è lecita nella posizione che il dispositivo ricevente già possiede. Un interlocutore che mente produce un pacchetto scartato, non una scacchiera illegale.',
        ],
        free: 'Gratis, senza limiti, sempre.',
      },
    ],
    watchLink: 'Che cosa è entrato nella biblioteca e che cosa no →',
    pipeline: {
      slug: 'Come nasce un esercizio',
      title: 'Estratti, non trascritti.',
      lede: 'Annotare posizioni a memoria rischia di far uscire un esercizio la cui «soluzione» è sbagliata o non unica, e questo allena esattamente l’istinto sbagliato. Perciò nessuno di essi è annotato a memoria. Vengono trovati, e poi attaccati finché non sopravvivono o vengono buttati.',
      steps: [
        {
          title: 'Giocare, a forza umana',
          body: 'Stockfish gioca contro se stesso a una forza deliberatamente simile a quella umana — da 1320 a 2500 Elo — aprendo con una scelta casuale fra le sue migliori candidate poco profonde, così le partite variano invece di ripetere una linea all’infinito.',
        },
        {
          title: 'Filtrare per la proprietà, non per la svista',
          body: 'Ogni posizione viene cercata a profondità 12 con due linee candidate. Il segnale non è «qualcuno ha sbagliato di grosso» ma ciò di cui un esercizio ha davvero bisogno: una mossa nettamente migliore di ogni alternativa.',
        },
        {
          title: 'Ricercare in profondità, con un margine',
          body: 'Le sopravvissute vengono cercate di nuovo a profondità 20 con MultiPV. Una candidata resta solo se la mossa migliore supera la seconda di almeno 140 centesimi di pedone e ottiene davvero qualcosa.',
        },
        {
          title: 'Prolungare finché si dirama',
          body: 'La soluzione viene prolungata mossa dopo mossa finché ogni mossa del solutore resta l’unica migliore. Nell’istante in cui ci sono due buone risposte, l’esercizio finisce lì — così non ha mai una diramazione per cui potresti essere segnato come in errore.',
        },
        {
          title: 'Verificare con un motore nuovo',
          body: 'L’intero insieme viene ricontrollato a profondità maggiore da uno script separato con una nuova istanza del motore. Sull’insieme estratto incluso questo ha respinto 6 esercizi su 172, le cui soluzioni smettevano di essere uniche due semimosse più in là. Sono stati scartati invece che pubblicati.',
        },
      ],
    },
    honest: {
      title: 'E lo stesso sospetto applicato ai finali',
      body: [
        'Il risultato dichiarato di ogni esercizio di finale viene verificato contro una ricerca profonda invece che preso per buono. Un esercizio etichettato male non passa il controllo, anziché insegnarti in silenzio qualcosa di falso.',
        'Il verificatore coglie anche una cosa che le solite librerie di scacchi non ti dicono: se la parte che non ha il tratto è sotto scacco. Una posizione simile è illegale — nessuna partita può raggiungerla — ma una libreria l’accetta volentieri, e il motore risponde bestmove (none), che suona come un guasto del motore anziché come una posizione sbagliata. Tre esercizi scritti a mano erano sbagliati esattamente così. Il controllo ora lo coglie.',
      ],
    },
    limits: {
      slug: 'Limiti onesti',
      title: 'Che cosa questo non fa.',
      items: [
        {
          title: 'L’insieme mescola due scale di valutazione.',
          body: 'I {lichess} esercizi di Lichess portano valutazioni calibrate su milioni di tentativi umani. I {mined} estratti in locale portano stime ricavate dalla profondità della soluzione e dal motivo. Entrambe ordinano con senso, ma un 1600 estratto e un 1600 di Lichess non sono misurati allo stesso modo.',
        },
        {
          title: 'Le valutazioni degli esercizi non sono valutazioni da torneo.',
          body: 'Corrono diverse centinaia di punti più in alto, e sarà sempre così. Misurano il progresso contro te stesso, non la forza contro un campo di esseri umani con l’orologio — {link}, perché il divario è strutturale e non un segno che converti male.',
        },
        {
          title: 'Non c’è allenamento sulle aperture.',
          body: 'Di proposito. Lo studio delle aperture è memorizzazione contro un repertorio che scegli tu, ed è un altro strumento con un’altra forma. La modalità posizionale copre l’uscita dall’apertura, che è la parte che davvero si generalizza.',
        },
        {
          title: 'Questo non ti renderà un gran maestro.',
          body: 'Nulla lo fa da solo. I titoli vengono da migliaia di ore più partite di torneo valutate contro esseri umani. Quello che questo ti dà è la metà di allenamento, strutturata, con una misura onesta di dove sei davvero.',
        },
      ],
      ratingsLink: 'cosa che vale la pena capire per bene',
    },
    more: {
      motifs: 'I venti motivi, definiti e contati →',
      engine: 'Come viene usato il motore →',
    },
  },

  tactics: {
    head: {
      slug: 'Glossario',
      title: 'I venti motivi',
      lede: 'Ogni tattica negli scacchi è una fra un piccolo numero di forme, e appena sai nominarle cominci a vederle una mossa prima. Questi sono quelli con cui Brass Pawn etichetta i suoi esercizi — ciascuno seguito da quante posizioni della biblioteca inclusa ruotano davvero su di esso.',
      meta: 'Contati sull’insieme incluso di 14.351 esercizi · Ultima revisione 19 agosto 2026',
    },
    meta: {
      title: 'I venti motivi',
      description:
        'Ogni motivo tattico con cui Brass Pawn etichetta i suoi esercizi, definito e contato sulla biblioteca inclusa, così sai quali puoi davvero allenare.',
    },
    indexLabel: 'I motivi',
    puzzles: 'esercizi',
    motifs: [
      {
        name: 'Forchetta',
        short: 'Un pezzo attacca due cose insieme, e solo una si può salvare.',
        body: 'Il cavallo è il forchettatore famoso perché attacca case che nessun altro pezzo difende allo stesso modo, ma tutti i pezzi forchettano: un pedone che colpisce due pezzi leggeri, una donna che colpisce torre e alfiere sciolto, un re in finale che si infila fra due pedoni. La prova non è «sto attaccando due cose» ma «possono uscirne entrambe».',
      },
      {
        name: 'Inchiodatura',
        short: 'Un pezzo non può muoversi perché dietro c’è qualcosa di più prezioso.',
        body: 'Assoluta quando dietro c’è il re — muoversi è illegale, non solo brutto. Relativa quando dietro c’è una donna o una torre, dove muoversi è lecito e semplicemente perde materiale. Il seguito è ciò che vince: un pezzo inchiodato è un pezzo che non può difendere, quindi accumula altri attaccanti su di esso, oppure colpiscilo con un pedone.',
      },
      {
        name: 'Infilata',
        short: 'Un’inchiodatura al contrario: il pezzo prezioso sta davanti e deve muoversi.',
        body: 'Dai scacco al re su una linea con torre, alfiere o donna, e ciò che stava dietro è tuo appena il re si sposta. Le infilate sono più rare delle inchiodature perché richiedono i due pezzi già allineati con il prezioso davanti — ecco perché di solito compaiono dopo che uno scacco ha costretto il re sulla linea.',
      },
      {
        name: 'Attacco di scoperta',
        short: 'Muovere un pezzo smaschera l’attacco di quello che sta dietro.',
        body: 'La tattica più forte degli scacchi e di gran lunga, perché il pezzo che si muove è libero di fare qualcosa di suo mentre l’attacco che scopre fa il lavoro. Due minacce compaiono in una mossa e nessuna delle due si risponde catturando il pezzo che si è mosso.',
      },
      {
        name: 'Scacco di scoperta',
        short: 'L’attacco smascherato è uno scacco, quindi l’avversario non ha tempo per altro.',
        body: 'Un attacco di scoperta in cui il pezzo dietro dà scacco. Qualunque cosa faccia il pezzo che si muove — prendere una donna, andare su una casa di matto, mettersi in presa — la risposta deve prima occuparsi dello scacco, quindi accade gratis.',
      },
      {
        name: 'Scacco doppio',
        short:
          'Due pezzi danno scacco insieme, quindi il re deve muoversi. Niente parata, niente cattura.',
        body: 'L’unica tattica contro cui esiste esattamente una classe di risposta lecita. Catturare uno dei due che danno scacco lascia l’altro; ostruire una linea lascia l’altra. Per questo lo scacco doppio produce matti che sembrano impossibili — il difensore può avere cinque modi di fermare ogni scacco separatamente e nessuno che li fermi entrambi.',
      },
      {
        name: 'Deviazione',
        short: 'Costringi un difensore ad abbandonare il compito che sta svolgendo.',
        body: 'Un pezzo tiene una casa di matto, una traversa di fondo o un altro pezzo. Attacca qualcosa che stima di più, oppure prendi semplicemente qualcosa che deve riprendere, e la difesa che dava sparisce con lui. Spesso il sacrificio sembra assurdo finché non noti che cosa smette di coprire il pezzo che riprende.',
      },
      {
        name: 'Adescamento',
        short: 'Attira un pezzo — di solito il re — su una casa dove può essere colpito.',
        body: 'Detto anche esca. Un sacrificio che l’avversario è obbligato ad accettare, giocato non per vincere materiale ma per mettere un pezzo in un posto fatale: un re trascinato su una casa di forchetta, una donna tirata su una linea con una torre. Il materiale torna con gli interessi una mossa dopo.',
      },
      {
        name: 'Sgombero',
        short: 'Togli il tuo pezzo dalla strada del tuo attacco.',
        body: 'La linea o la casa è quella giusta e sopra c’è un tuo uomo. Lo sgombero lo muove con tempo — di solito con uno scacco o una cattura, così l’avversario non ha tempo di riorganizzarsi mentre la strada si apre.',
      },
      {
        name: 'Interferenza',
        short: 'Taglia la linea fra un difensore e ciò che difende.',
        body: 'Metti un pezzo — spesso sacrificato — esattamente fra una torre e la casa che sorveglia. Il difensore è ancora sulla scacchiera, difende ancora in teoria, e non può più. Rara, e uno dei motivi più difficili da vedere, perché il pezzo che interferisce di solito sembra una svista.',
      },
      {
        name: 'Raggi X',
        short: 'Un pezzo agisce attraverso un altro, lungo la linea che occuperà poi.',
        body: 'Una torre che difende il proprio pezzo attraverso uno avversario, o che attacca attraverso di esso. Ancora non succede nulla; ciò che conta è che cosa succede appena il pezzo in mezzo si muove o viene preso. Riconoscere dei raggi X è di solito ciò che fa sì che una cattura che «perde materiale» non lo perda.',
      },
      {
        name: 'Mossa intermedia',
        short: 'Lo zwischenzug: prima di riprendere, fai qualcosa di più forzante.',
        body: 'Dal tedesco «mossa intermedia», e la singola ragione più frequente per cui una variante calcolata risulta sbagliata. Ti aspetti una ripresa; invece arriva uno scacco, o una minaccia più grande, e quando la ripresa avviene la posizione è cambiata. Cercane una ogni volta che una sequenza sembra forzata.',
      },
      {
        name: 'Zugzwang',
        short: 'Dover muovere è di per sé il problema.',
        body: 'Ogni mossa lecita peggiora la posizione, e passare non è permesso. Soprattutto un’idea di finale — i finali di re e pedoni si decidono così — e la ragione per cui «l’opposizione» conta: chi è costretto a spostarsi per primo perde la casa. Quasi l’unica situazione negli scacchi in cui il diritto di muovere è un peso.',
      },
      {
        name: 'Matto del corridoio',
        short: 'Un re chiuso dai suoi stessi pedoni, mattato sulla prima traversa.',
        body: 'Il matto più comune fra giocatori che hanno arroccato e lasciato stare i pedoni. Raramente compare come matto sulla scacchiera — compare come minaccia che vince materiale, perché ogni mossa difensiva deve continuare a sorvegliare la traversa. L’intera famiglia delle tattiche di deviazione esiste per togliere quella guardia.',
      },
      {
        name: 'Matto affogato',
        short: 'Un cavallo matta un re che i suoi stessi pezzi hanno rinchiuso.',
        body: 'La conclusione del lascito di Philidor: sacrificio di donna in g8, la torre riprende, il cavallo in f7 dà matto con il re circondato dai suoi. Raro nelle partite vere e comunque da sapere, perché il motivo è ciò che ti fa guardare un angolo e contare le case di fuga.',
      },
      {
        name: 'Pezzo in presa',
        short: 'Qualcosa è semplicemente indifeso e si può prendere.',
        body: 'Nulla di affascinante, e decide più partite di tutto il resto di questo elenco messo insieme. La maggior parte delle sconfitte sotto 1800 è un giocatore che prende un pezzo gratis che l’altro ha smesso di guardare. L’abitudine che lo risolve è controllare che cosa è sciolto — in entrambi i colori — prima di ogni mossa.',
      },
      {
        name: 'Pezzo intrappolato',
        short: 'Un pezzo non ha case sicure e lo si può braccare con calma.',
        body: 'Di solito un alfiere che ha preso un pedone che avrebbe dovuto lasciare, o un cavallo andato in scorreria. La tattica non è un colpo solo ma una stretta: togli le case una alla volta e il pezzo cade senza bisogno di alcun sacrificio.',
      },
      {
        name: 'Mossa tranquilla',
        short: 'La mossa vincente non è uno scacco, non è una cattura e non è una minaccia.',
        body: 'La ragione per cui i giocatori forti trovano combinazioni che altri mancano. Dopo una sequenza forzata la risposta è una mossa modesta che toglie l’ultima casa di fuga, ed è invisibile a chi calcola solo scacchi e catture. Se una posizione sembra vinta e nulla di forzante funziona, cerca quella tranquilla.',
      },
      {
        name: 'Sacrificio',
        short: 'Dai materiale per qualcosa che vale più del materiale.',
        body: 'Tempo, linee, case, o la posizione del re avversario. Un vero sacrificio non è una scommessa; è un calcolo il cui esito è concreto. Ciò che separa quello che funziona da quello che no è quasi sempre se i pezzi difensori riescono a tornare in tempo.',
      },
      {
        name: 'Pedone avanzato',
        short: 'Un pedone vicino alla promozione cambia quanto vale ogni altro pezzo.',
        body: 'Un pedone in settima non è un pedone; è una donna che qualcosa deve sorvegliare, e quel qualcosa non è più libero. La maggior parte delle tattiche di finale riguarda in realtà la tensione fra fermare un pedone e fare qualunque altra cosa.',
      },
    ],
    after: {
      slug: 'Perché i numeri stanno qui',
      title: 'Un glossario ti dice che cos’è una forchetta. Un numero ti dice se puoi allenarla.',
      body: [
        'Sapere il nome di un motivo e saperlo trovare sotto l’orologio sono abilità diverse, e solo la seconda vince partite. Ogni conteggio qui sopra è il numero reale di posizioni della biblioteca inclusa etichettate con quel motivo — non una stima, e non arrotondato per eccesso. Sessanta esercizi di raggi X sono sessanta; se è quella la cosa che continui a mancare, vale la pena sapere che non finiranno in una sera.',
        'L’allenatore tiene traccia di quali motivi sbagli, così dopo qualche centinaio di esercizi può dirti non che sei 1620, ma che sei 1620 e continui a passare accanto alle deviazioni.',
      ],
      more: 'Come gli esercizi vengono estratti e verificati →',
    },
  },
};
