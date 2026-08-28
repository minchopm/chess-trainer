import type { Pages } from './types';

/** The four commercial pages in German. Informal, as the app addresses its player. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Hilfe',
      title: 'Frag einen Menschen',
      lede: 'Es gibt kein Ticketsystem, keinen Chatbot und kein Hilfe-Center mit 400 Artikeln darin. Es gibt eine E-Mail-Adresse und einen Fehler-Tracker, und beide erreichen den Menschen, der die App geschrieben hat.',
    },
    meta: {
      title: 'Hilfe',
      description:
        'Wie du bei Brass Pawn einen Menschen erreichst, was du mitschickst, wenn eine Aufgabe falsch ist, und die Fragen, die am häufigsten gestellt werden.',
    },
    email: {
      slug: 'E-Mail',
      body: 'Für alles: ein Fehler, eine falsche Aufgabe, eine Frage zu einem Kauf oder Widerspruch gegen eine Bewertung. Schreib auf Englisch oder Bulgarisch.',
    },
    tracker: {
      slug: 'Fehler-Tracker',
      name: 'GitHub Issues',
      body: 'Für alles, was dir lieber öffentlich wäre — und für alles, was andere später finden können sollen, was auf die meisten Fehlermeldungen zutrifft.',
    },
    report: {
      slug: 'Wenn eine Aufgabe falsch ist',
      title: 'Schick vier Dinge, dann ist es in einer Minute geprüft.',
      checklist: [
        'Die FEN, die auf dem Aufgabenbildschirm steht — tippen und halten kopiert sie.',
        'Den Zug, den du gespielt hast, und den Zug, den die App für richtig hielt.',
        'In welchem Modus du warst.',
        'Die App-Version, aus dem Info-Bildschirm.',
      ],
      caveat:
        'Aufgaben widersprechen gelegentlich einer tieferen Suche, und die Widersprüche häufen sich bei langen, ruhigen, hoch bewerteten Stellungen, deren Pointe tiefer liegt, als die Prüfung gesucht hat. Das ist eine Grenze der Prüfung und kein Fehler der Aufgabe — aber es lohnt sich zu wissen, welche es sind, und der einzige Weg dorthin ist, dass du es sagst.',
    },
    faq: { slug: 'Fragen', title: 'Oft genug gestellt, um sie aufzuschreiben.' },
    more: {
      ratings: 'Was eine Wertung misst',
      tactics: 'Die Motive',
      privacy: 'Datenschutzerklärung',
      terms: 'Nutzungsbedingungen',
      licences: 'Lizenzen',
    },
  },

  pricing: {
    head: {
      slug: 'Was es kostet',
      title: 'Spielen ist gratis. Das Training wird verkauft.',
      lede: 'Schach gegen die Engine und Schach gegen einen Menschen, unbegrenzt, ohne Werbung irgendwo in der App — das ist gratis und bleibt es. Verkauft werden die Bibliothek, die Übungen, die Aufgaben und der Lauf gegen die Uhr.',
    },
    meta: {
      title: 'Preise',
      description:
        'Spielen ist gratis und unbegrenzt — die Engine, ein echter Gegner und alle 900 Partien. Pro hebt das Tageslimit von fünf auf: 3,99 $ im Monat oder 49,99 $ einmalig.',
    },
    free: {
      name: 'Gratis',
      note: 'Kein Konto. Nichts anzumelden.',
      items: [
        'Unbegrenzt gegen die Engine spielen, 1400 bis volle Stärke',
        'Unbegrenzt Online-Partien über Game Center',
        'Zug für Zug Coaching in jeder Partie, die du spielst',
        'Fünf Taktikaufgaben am Tag',
        'Fünf Rush-Läufe am Tag',
        'Je fünf: positionell, Endspiel, Elo schätzen',
        'Wertungen, Serien und verteilte Wiederholung, vollständig',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Monatlich',
      per: 'pro Monat',
      note: 'Jederzeit in den Einstellungen deines Apple-Accounts kündbar.',
      items: [
        'Jedes Tageslimit entfernt',
        'Alle {tactics} Taktikaufgaben',
        'Alle {positional} Stellungsübungen',
        'Alle {endgames} Endspielübungen',
        'Alle {games} Partien zum Einschätzen',
        'Unbegrenzt Rush',
        'Alles aus Gratis, unverändert',
      ],
    },
    lifetime: {
      name: 'Einmalige Freischaltung',
      once: 'einmalig',
      note: 'Ein nicht verbrauchbarer Kauf. Er verlängert sich nicht.',
      items: [
        'Genau dasselbe wie Pro monatlich',
        'Keine Verlängerung, kein Ablauf, keine Erinnerungs-Mails',
        'Wird auf deinen anderen Geräten wiederhergestellt',
        'Für Leute, die lieber einmal entscheiden',
      ],
    },
    table: {
      slug: 'Das ganze Kontingent',
      title: 'Was die Gratisstufe tatsächlich gibt.',
      activity: 'Tätigkeit',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Unbegrenzt',
      fiveADay: '5 am Tag',
      none: 'Keine',
      rows: [
        'Gegen die Engine spielen',
        'Online-Partien über Game Center',
        'Ansehen — die Bibliothek mit 900 Partien',
        'Taktikaufgaben',
        'Rush-Läufe',
        'Stellungsübungen',
        'Endspielübungen',
        'Elo schätzen',
        'Werbung',
      ],
      reset:
        'Die Tageskontingente setzen sich um neun Uhr morgens Ortszeit zurück — nicht um Mitternacht, damit ein Abend nicht von einem Datumswechsel halbiert wird.',
    },
    why: {
      slug: 'Warum es so geschnitten ist',
      title: 'Drei Entscheidungen, und der Grund für jede.',
      reasons: [
        {
          title: 'Gezählt, nicht verschlossen',
          body: [
            'Niemand zahlt für einen Trainer, den er nicht benutzt hat, und ein Modus, der sich nicht öffnet, lehrt nichts über das, was dahinter liegt. Also öffnet sich jeder Modus, jeden Tag, und du kommst weit genug hinein, um den Ablauf zu spüren und die Wertung wandern zu sehen.',
            'Die Bezahlschranke erscheint nie beim Start. Ist das Tageskontingent aufgebraucht, sagt der Bildschirm das, und erst ein bewusstes Tippen öffnet das Kaufblatt.',
          ],
        },
        {
          title: 'Zwei Preise, nicht drei',
          body: [
            'Es gibt keinen Jahresplan dazwischen, denn ein dritter Preis ist eine dritte Entscheidung in genau dem Moment, in dem jemand eine Aufgabe lösen will. Monatlich, wenn du unsicher bist. Einmalig, wenn nicht.',
          ],
        },
        {
          title: 'Spielen wird nie verkauft',
          body: [
            'Schach gegen die Engine und Schach gegen einen Menschen kosten im Betrieb nichts und sind der Grund, warum es die App gibt. Sie zu verkaufen würde daraus eine Schach-App mit Mautstelle machen statt eines Trainers.',
            'Und es gibt keine Werbung — teils Geschmack, teils Lizenz. Die App bindet zwei Copyleft-Engines ein, Stockfish unter der GPLv3 und Reckless unter der AGPLv3, und ein proprietäres Werbe-SDK im selben Binary würde das Ganze unverteilbar machen. {link}',
          ],
        },
      ],
      licenceLink: 'Die Lizenzseite erklärt es ordentlich.',
    },
    answers: {
      slug: 'Kaufen, kündigen, erstatten',
      title: 'Die unangenehmen Fragen, hier beantwortet statt per E-Mail.',
      items: [
        {
          q: 'Wie kündige ich?',
          a: 'Einstellungen → dein Name → Abonnements → Brass Pawn. Wir können es nicht für dich kündigen, denn das Abo besteht zwischen dir und Apple und lag nie bei uns. Kündigen stoppt künftige Verlängerungen und verkürzt den bereits bezahlten Zeitraum nicht.',
        },
        {
          q: 'Wie bekomme ich mein Geld zurück?',
          a: 'Über Apple, auf {link}. Wir können für App-Store-Käufe nichts erstatten. Wenn etwas kaputt ist, schreib uns — wir reparieren es lieber.',
        },
        {
          q: 'Ich habe freigeschaltet und ein neues Telefon.',
          a: 'Melde dich mit demselben Apple-Account an und tippe auf „Käufe wiederherstellen" im Kaufbildschirm. Die App fragt StoreKit, was dir gehört; auf einem Server von uns liegt nichts, weil es keinen Server von uns gibt.',
        },
        {
          q: 'Ändert Pro meine Wertung oder schaltet „bessere" Aufgaben frei?',
          a: 'Nein. Das Wertungssystem ist identisch, und jede Aufgabe der Bibliothek ist mit einem Gratiskonto erreichbar — fünf am Tag. Pro entfernt den Zähler, keinen Vorhang.',
        },
        {
          q: 'Wird das Gratiskontingent später kleiner?',
          a: 'Es kann sich in beide Richtungen ändern, während die Bibliothek wächst. Unbegrenztes Spielen gegen die Engine und gegen Menschen wird keine bezahlte Funktion; das steht in den {link} und ist nicht bloß hier versprochen.',
        },
      ],
      termsLink: 'Nutzungsbedingungen',
      more: 'Mehr Fragen, und wie du einen Menschen erreichst →',
    },
  },

  training: {
    head: {
      slug: 'Das Programm',
      title: 'Acht Arten, die Wahrheit zu hören',
      lede: 'Drei davon sind für immer gratis und unbegrenzt — Spielen, gegen jemanden spielen und die neunhundert Partien in Ansehen. Die anderen fünf sind fünf am Tag mit einem Gratiskonto und unbegrenzt mit Pro. Jeder einzelne bewertet dich mit Worten über die Stellung statt mit einer Zahl, die du deuten musst.',
    },
    meta: {
      title: 'Training',
      description:
        'Acht Modi: Taktik, Stellungsurteil, Endspiele, Rush, Elo schätzen, Ansehen, betreutes Spiel und Online. Wie jeder funktioniert, wie die Aufgaben gewonnen und geprüft werden, und was der Trainer nicht tut.',
    },
    modes: [
      {
        title: 'Taktik',
        lede: 'Stellungen mit genau einem gewinnenden Zug, und ein Urteil in dem Moment, in dem du ihn spielst.',
        body: [
          'Jede Aufgabe hat eine Antwort und keine Verzweigungen. Spiel sie auf dem Brett, und der Trainer sagt dir sofort, ob du sie gefunden hast; verfehlst du sie, kommt die Stellung morgen wieder, dann in vier Tagen, dann in zehn — so lange, wie sie dich weiter erwischt.',
          'Jede Aufgabe trägt das Motiv, um das sie sich dreht — Gabel, Fesselung, Spieß, Grundreihenmatt, Ablenkung, der stille Zug — sodass der Trainer dir nach ein paar hundert nicht sagen kann, dass du 1620 bist, sondern dass du 1620 bist und immer wieder an Ablenkungen vorbeiläufst.',
        ],
        free: 'Fünf am Tag mit einem Gratiskonto.',
        stat: 'Aufgaben, gewertet von 760 bis 2800',
      },
      {
        title: 'Stellungsurteil',
        lede: 'Es gibt keinen erzwungenen Gewinn. Sag, wer besser steht, und finde dann den Zug, der erklärt warum.',
        body: [
          'Das ist der Modus für das, was starke Spieler von guten Rechnern trennt. Zuerst beurteilst du: klar besser, etwas besser, ausgeglichen. Dann wählst du einen Zug. Beide Antworten werden bewertet.',
          'Die Rückmeldung benennt konkrete Merkmale statt Stimmungen — die offene Linie und ob ein Turm darauf steht, der Springer-Vorposten, den kein Bauer angreifen kann, die Bauernstruktur, die Königssicherheit, den Unterschied in der Figurenaktivität. Eine Stellung ist nicht „angenehm für Weiß"; sie ist besser wegen vier Dingen, die du aufzählen kannst.',
        ],
        free: 'Fünf am Tag mit einem Gratiskonto.',
        stat: 'ruhige Stellungen, von der Engine vorsortiert',
      },
      {
        title: 'Endspiele',
        lede: 'Kanonische Stellungen, ausgespielt gegen eine Engine, die ordentlich verteidigt.',
        body: [
          'Die Idee zu kennen ist nicht dasselbe, wie sie zu verwerten, also musst du hier das Ergebnis tatsächlich erreichen. Stockfish übernimmt die andere Seite und leistet die beste Verteidigung, die es gibt.',
          'Nach jedem Zug prüft der Trainer erneut, ob das Ergebnis noch erreichbar ist — und wenn nicht, nennt er dir den genauen Zug, an dem es aufhörte, es zu sein. Das ist der Satz, der lehrt: nicht „du hast remis gemacht", sondern „du hast hier remis gemacht".',
        ],
        free: 'Fünf am Tag mit einem Gratiskonto.',
        stat: 'Übungen, jedes Ergebnis von der Engine geprüft',
      },
      {
        title: 'Rush',
        lede: 'Ein Lauf auf Zeit. Löse so viele du kannst, bevor die Uhr den Rest nimmt.',
        body: [
          'Dieselben Aufgaben, gegen die Uhr, mit steigender Schwierigkeit, solange du sie weiter triffst. Das trainiert einen anderen Muskel als eine Aufgabe, die du anstarren darfst: den, der es jetzt sehen muss.',
          'Läufe werden gewertet und aufbewahrt, sodass die Zahl über Monate steigt statt über einen Abend.',
        ],
        free: 'Fünf Läufe am Tag mit einem Gratiskonto.',
      },
      {
        title: 'Elo schätzen',
        lede: 'Eine echte gewertete Partie, Zug für Zug abgespielt. Wie stark waren diese beiden?',
        body: [
          'Das Niveau einer Partie zu lesen ist dieselbe Fähigkeit wie die eigenen Züge zu beurteilen: beides läuft darauf hinaus zu bemerken, welche Fehler gemacht werden und welche nicht. Also läuft die Partie, du siehst zu, und irgendwann legst du dich auf eine Zahl fest.',
          'Die Partien sind echt, aus den Lichess-Archiven, wobei beide Spieler höchstens 150 Punkte auseinanderliegen — eine Schätzung über „die Spieler" bedeutet nur dann etwas, wenn es ein Niveau zu schätzen gibt.',
        ],
        free: 'Fünf am Tag mit einem Gratiskonto.',
        stat: 'gewertete Partien, von 800 bis 2599',
      },
      {
        title: 'Ansehen',
        lede: 'Neunhundert sehenswerte Partien — und in dem Moment, in dem du anders gespielt hättest, übernimm sie.',
        body: [
          'Jede Partie der Bibliothek ist entschieden, zwischen zwei benannten Spielern, und entweder innerhalb von fünfundzwanzig Zügen zu Ende oder berühmt genug, um einen eigenen Namen zu haben. Aus einem neunzigzügigen Remis zwischen Leuten, von denen man nie gehört hat, lernt niemand etwas, und eine Bibliothek, die sie enthält, ist eine, die niemand ein zweites Mal öffnet.',
          'Schlag einen Spieler nach, oder ein Turnier, oder ein Jahr. Dann spiel die Partie in deinem Tempo durch. Es geht nicht um die Höhepunkte: es geht darum, dass du bei irgendeinem Zug denken wirst <em>ich hätte dort geschlagen</em> — und in diesem Moment kannst du es. Übernimm die Stellung und spiel gegen die Engine weiter, von genau dem Feld an, bei dem du anderer Meinung warst. Herauszufinden, was deine Idee tatsächlich wert war, ist die ganze Übung.',
        ],
        free: 'Gratis, unbegrenzt, immer.',
        stat: 'Partien, jede entschieden',
      },
      {
        title: 'Spielen & Coaching',
        lede: 'Eine ganze Partie in der Stärke deiner Wahl, mit einer Bewertung jedes deiner Züge, während du spielst.',
        body: [
          'Stell die Engine irgendwo zwischen 1400 und volle Stärke und spiel sie aus. Jeder deiner Züge wird bewertet, während die Partie noch läuft, und der Coach erklärt, was der bessere Zug erreicht hätte — in Worten über die Stellung, nicht als Zahl.',
          'Am Ende bekommst du Genauigkeit, die Zahl der groben Fehler und den einen Moment, der dich am meisten gekostet hat.',
        ],
        free: 'Gratis, unbegrenzt, immer.',
      },
      {
        title: 'Online',
        lede: 'Zwei Menschen, eine Uhr, und keine Engine in der Nähe.',
        body: [
          'Game Center findet jemanden, der dieselbe Bedenkzeit gewählt hat — 3, 5, 10, 15 oder 30 Minuten. Es ist der eine Modus ohne Engine darin: kein Hinweis, keine Zugbewertungen, kein Coaching, denn Hilfe, die nur eine Seite bekommt, ist kein Spiel.',
          'Es gibt keinen Server. Die beiden Geräte reden miteinander und beide führen die Regeln aus, sodass ein Zug nur dann gespielt wird, wenn er in der Stellung erlaubt ist, die das empfangende Gerät bereits hält. Ein Gegenüber, das lügt, erzeugt ein verworfenes Paket, kein illegales Brett.',
        ],
        free: 'Gratis, unbegrenzt, immer.',
      },
    ],
    watchLink: 'Was in die Bibliothek kam und was nicht →',
    pipeline: {
      slug: 'Wie eine Aufgabe entsteht',
      title: 'Gewonnen, nicht abgeschrieben.',
      lede: 'Stellungen aus dem Gedächtnis aufzuschreiben riskiert eine Aufgabe, deren „Lösung" falsch oder nicht eindeutig ist, und das trainiert genau den falschen Instinkt. Also ist keine von ihnen aus dem Gedächtnis aufgeschrieben. Sie werden gefunden und dann angegriffen, bis sie entweder überleben oder weggeworfen werden.',
      steps: [
        {
          title: 'Spielen, in menschlicher Stärke',
          body: 'Stockfish spielt gegen sich selbst in bewusst menschenähnlicher Stärke — 1320 bis 2500 Elo — und eröffnet mit einer zufälligen Wahl unter seinen besten flachen Kandidaten, damit die Partien variieren statt eine Linie ewig zu wiederholen.',
        },
        {
          title: 'Auf die Eigenschaft sieben, nicht auf den Patzer',
          body: 'Jede Stellung wird in Tiefe 12 mit zwei Kandidatenlinien durchsucht. Das Signal ist nicht „jemand hat gepatzt", sondern das, was eine Aufgabe wirklich braucht: ein Zug ist weit besser als jede Alternative.',
        },
        {
          title: 'Tief nachsuchen, mit Abstand',
          body: 'Die Überlebenden werden erneut in Tiefe 20 mit MultiPV durchsucht. Ein Kandidat bleibt nur, wenn der beste Zug den zweitbesten um mindestens 140 Hundertstelbauern schlägt und tatsächlich etwas erreicht.',
        },
        {
          title: 'Verlängern, bis es sich verzweigt',
          body: 'Die Lösung wird Zug um Zug verlängert, solange jeder Zug des Lösers eindeutig der beste bleibt. In dem Moment, in dem es zwei gute Antworten gibt, endet die Aufgabe dort — sie hat also nie eine Verzweigung, für die du falsch bewertet werden könntest.',
        },
        {
          title: 'Mit einer frischen Engine prüfen',
          body: 'Der ganze Satz wird von einem eigenen Skript mit einer neuen Engine-Instanz in größerer Tiefe nachgeprüft. Am mitgelieferten gewonnenen Satz verwarf das 6 von 172 Aufgaben, deren Lösungen zwei Halbzüge tiefer aufhörten eindeutig zu sein. Die wurden verworfen statt ausgeliefert.',
        },
      ],
    },
    honest: {
      title: 'Und derselbe Argwohn, angewandt auf die Endspiele',
      body: [
        'Das angegebene Ergebnis jeder Endspielübung wird gegen eine tiefe Suche geprüft statt geglaubt. Eine falsch beschriftete Übung fällt bei der Prüfung durch, statt dir still etwas Falsches beizubringen.',
        'Der Prüfer fängt auch etwas ab, was die üblichen Schachbibliotheken dir nicht sagen: ob die Seite, die nicht am Zug ist, im Schach steht. Eine solche Stellung ist illegal — keine Partie kann sie erreichen — aber eine Bibliothek nimmt sie bereitwillig an, und die Engine antwortet mit bestmove (none), was wie ein Versagen der Engine klingt statt wie eine schlechte Stellung. Drei handgeschriebene Übungen waren genau so falsch. Die Prüfung fängt es jetzt ab.',
      ],
    },
    limits: {
      slug: 'Ehrliche Grenzen',
      title: 'Was das hier nicht tut.',
      items: [
        {
          title: 'Der Satz mischt zwei Wertungsskalen.',
          body: 'Die {lichess} Lichess-Aufgaben tragen Wertungen, die an Millionen menschlicher Versuche geeicht sind. Die {mined} lokal gewonnenen tragen Schätzungen aus Lösungstiefe und Motiv. Beide ordnen sinnvoll, aber ein gewonnenes 1600 und ein Lichess-1600 sind nicht gleich gemessen.',
        },
        {
          title: 'Aufgabenwertungen sind keine Turnierwertungen.',
          body: 'Sie liegen mehrere hundert Punkte höher, und das wird so bleiben. Sie messen Fortschritt gegen dich selbst, nicht Stärke gegen ein Feld von Menschen an der Uhr — {link}, denn die Lücke ist strukturell und kein Zeichen dafür, dass du schlecht verwertest.',
        },
        {
          title: 'Es gibt kein Eröffnungstraining.',
          body: 'Mit Absicht. Eröffnungsstudium ist Auswendiglernen gegen ein Repertoire, das du wählst, und das ist ein anderes Werkzeug mit einer anderen Form. Der Stellungsmodus deckt den Übergang aus der Eröffnung ab, und das ist der Teil, der sich tatsächlich verallgemeinern lässt.',
        },
        {
          title: 'Das macht dich nicht zum Großmeister.',
          body: 'Nichts tut das für sich allein. Titel kommen aus tausenden Stunden plus gewerteten Turnierpartien gegen Menschen. Was du hier bekommst, ist die Trainingshälfte davon, strukturiert, mit einem ehrlichen Maß dafür, wo du tatsächlich stehst.',
        },
      ],
      ratingsLink: 'was sich ordentlich zu verstehen lohnt',
    },
    more: {
      motifs: 'Die zwanzig Motive, definiert und gezählt →',
      engine: 'Wie die Engine benutzt wird →',
    },
  },

  tactics: {
    head: {
      slug: 'Glossar',
      title: 'Die zwanzig Motive',
      lede: 'Jede Taktik im Schach ist eine aus einer kleinen Zahl von Formen, und sobald du sie benennen kannst, siehst du sie einen Zug früher. Das sind die, mit denen Brass Pawn seine Aufgaben markiert — jedes gefolgt davon, wie viele Stellungen der mitgelieferten Bibliothek sich tatsächlich darum drehen.',
      meta: 'Gezählt aus dem mitgelieferten Satz von 14.351 Aufgaben · Zuletzt geprüft am 19. August 2026',
    },
    meta: {
      title: 'Die zwanzig Motive',
      description:
        'Jedes taktische Motiv, mit dem Brass Pawn seine Aufgaben markiert, definiert und gegen die mitgelieferte Bibliothek gezählt, damit du weißt, welche du wirklich üben kannst.',
    },
    indexLabel: 'Die Motive',
    puzzles: 'Aufgaben',
    motifs: [
      {
        name: 'Gabel',
        short: 'Eine Figur greift zwei Dinge auf einmal an, und nur eines lässt sich retten.',
        body: 'Der Springer ist der berühmte Gabler, weil er Felder angreift, die keine andere Figur auf dieselbe Weise deckt, aber jede Figur gabelt: ein Bauer, der zwei Leichtfiguren trifft, eine Dame, die Turm und losen Läufer trifft, ein König im Endspiel, der zwischen zwei Bauern tritt. Die Prüfung lautet nicht „greife ich zwei Dinge an", sondern „können beide entkommen".',
      },
      {
        name: 'Fesselung',
        short: 'Eine Figur kann nicht ziehen, weil hinter ihr etwas Wertvolleres steht.',
        body: 'Absolut, wenn der König dahintersteht — Ziehen ist illegal, nicht bloß schlecht. Relativ, wenn eine Dame oder ein Turm dahintersteht, wo Ziehen erlaubt ist und schlicht Material kostet. Die Fortsetzung gewinnt: eine gefesselte Figur ist eine Figur, die nicht decken kann, also häufe mehr Angreifer auf sie oder triff sie mit einem Bauern.',
      },
      {
        name: 'Spieß',
        short: 'Eine Fesselung andersherum: die wertvolle Figur steht vorn und muss ziehen.',
        body: 'Gib dem König auf einer Linie Schach mit Turm, Läufer oder Dame, und was dahinterstand, gehört dir, sobald der König zur Seite tritt. Spieße sind seltener als Fesselungen, weil sie die beiden Figuren bereits auf einer Linie brauchen, mit der wertvollen vorn — weshalb sie meist auftauchen, nachdem ein Schach den König auf die Linie gezwungen hat.',
      },
      {
        name: 'Abzugsangriff',
        short: 'Das Ziehen einer Figur legt den Angriff der Figur dahinter frei.',
        body: 'Die mit Abstand stärkste Taktik im Schach, weil die ziehende Figur frei ist, etwas Eigenes zu tun, während der freigelegte Angriff die Arbeit macht. Zwei Drohungen entstehen in einem Zug, und keine davon lässt sich durch Schlagen der ziehenden Figur beantworten.',
      },
      {
        name: 'Abzugsschach',
        short:
          'Der freigelegte Angriff ist ein Schach, also hat der Gegner für nichts anderes Zeit.',
        body: 'Ein Abzugsangriff, bei dem die Figur dahinter Schach gibt. Was auch immer die ziehende Figur tut — eine Dame schlagen, auf ein Mattfeld gehen, sich selbst ins Schlagen stellen — die Antwort muss zuerst das Schach behandeln, also geschieht es umsonst.',
      },
      {
        name: 'Doppelschach',
        short:
          'Zwei Figuren geben gleichzeitig Schach, also muss der König ziehen. Kein Block, kein Schlagen.',
        body: 'Die einzige Taktik, gegen die es genau eine erlaubte Art von Antwort gibt. Einen Schachbieter zu schlagen lässt den anderen stehen; eine Linie zu blockieren lässt die andere offen. Deshalb liefert das Doppelschach Matts, die unmöglich aussehen — der Verteidiger mag fünf Wege haben, jedes Schach einzeln zu stoppen, und keinen, der beide stoppt.',
      },
      {
        name: 'Ablenkung',
        short: 'Zwing einen Verteidiger von der Aufgabe weg, die er erfüllt.',
        body: 'Eine Figur hält ein Mattfeld, eine Grundreihe oder eine andere Figur. Greif etwas an, das sie höher schätzt, oder schlag einfach etwas, das sie zurückschlagen muss, und die Deckung, die sie leistete, verschwindet mit ihr. Oft sieht das Opfer absurd aus, bis man bemerkt, was die zurückschlagende Figur nicht mehr deckt.',
      },
      {
        name: 'Hinlenkung',
        short: 'Lock eine Figur — meist den König — auf ein Feld, wo sie getroffen werden kann.',
        body: 'Auch Köder genannt. Ein Opfer, das der Gegner annehmen muss, gespielt nicht um Material zu gewinnen, sondern um eine Figur irgendwohin Tödliches zu setzen: ein König, auf ein Gabelfeld gezerrt, eine Dame, auf eine Linie mit einem Turm gezogen. Das Material kommt einen Zug später mit Zinsen zurück.',
      },
      {
        name: 'Räumung',
        short: 'Schaff die eigene Figur aus dem Weg des eigenen Angriffs.',
        body: 'Die Linie oder das Feld stimmt, und der eigene Mann steht darauf. Die Räumung bewegt ihn mit Tempo — meist mit Schach oder Schlagen, damit der Gegner keine Zeit hat, sich neu zu ordnen, während der Weg aufgeht.',
      },
      {
        name: 'Unterbrechung',
        short: 'Durchtrenne die Linie zwischen einem Verteidiger und dem, was er deckt.',
        body: 'Setz eine Figur — oft eine geopferte — genau zwischen einen Turm und das Feld, das er bewacht. Der Verteidiger steht noch auf dem Brett, deckt nominell noch und kann es nicht mehr. Selten, und eines der am schwersten zu sehenden Muster, weil die unterbrechende Figur meist wie ein Patzer aussieht.',
      },
      {
        name: 'Röntgenangriff',
        short:
          'Eine Figur wirkt durch eine andere hindurch, entlang der Linie, die sie später besetzen wird.',
        body: 'Ein Turm, der seine eigene Figur durch eine feindliche hindurch deckt, oder durch eine hindurch angreift. Noch geschieht nichts; wichtig ist, was in dem Moment geschieht, in dem die Figur dazwischen zieht oder geschlagen wird. Ein Röntgenangriff zu erkennen ist meist das, was ein Schlagen, das „Material verliert", eben doch nicht verlieren lässt.',
      },
      {
        name: 'Zwischenzug',
        short: 'Der Zug dazwischen: bevor du zurückschlägst, tu etwas Forcierenderes.',
        body: 'Der häufigste einzelne Grund dafür, dass eine berechnete Variante sich als falsch erweist. Du erwartest ein Zurückschlagen; stattdessen kommt ein Schach oder eine größere Drohung, und bis das Zurückschlagen geschieht, hat sich die Stellung geändert. Such jedes Mal nach einem, wenn eine Folge erzwungen scheint.',
      },
      {
        name: 'Zugzwang',
        short: 'Ziehen zu müssen ist selbst das Problem.',
        body: 'Jeder erlaubte Zug verschlechtert die Stellung, und Passen ist nicht erlaubt. Überwiegend eine Endspielidee — Königs- und Bauernendspiele werden davon entschieden — und der Grund, warum „die Opposition" zählt: wer zuerst zur Seite treten muss, verliert das Feld. Fast die einzige Lage im Schach, in der das Recht zu ziehen eine Last ist.',
      },
      {
        name: 'Grundreihenmatt',
        short: 'Ein König, von den eigenen Bauern eingesperrt, auf der ersten Reihe mattgesetzt.',
        body: 'Das häufigste Matt zwischen Spielern, die rochiert und die Bauern in Ruhe gelassen haben. Es erscheint selten als Matt auf dem Brett — es erscheint als Drohung, die Material gewinnt, weil jeder Verteidigungszug die Reihe weiter decken muss. Die ganze Familie der Ablenkungstaktiken existiert, um diese Deckung zu entfernen.',
      },
      {
        name: 'Ersticktes Matt',
        short: 'Ein Springer mattet einen König, den die eigenen Figuren eingeschlossen haben.',
        body: 'Der Abschluss von Philidors Vermächtnis: Damenopfer auf g8, der Turm schlägt zurück, der Springer auf f7 setzt matt, mit dem König von den eigenen Leuten umringt. In echten Partien selten und trotzdem wissenswert, weil das Muster das ist, was dich eine Ecke ansehen und Fluchtfelder zählen lässt.',
      },
      {
        name: 'Hängende Figur',
        short: 'Etwas ist schlicht ungedeckt und kann genommen werden.',
        body: 'Nicht glanzvoll, und es entscheidet mehr Partien als alles andere auf dieser Liste zusammen. Die meisten Niederlagen unter 1800 sind der eine Spieler, der eine freie Figur nimmt, die der andere aus den Augen verloren hat. Die Gewohnheit, die das behebt, ist vor jedem Zug zu prüfen, was lose steht — bei beiden Farben.',
      },
      {
        name: 'Gefangene Figur',
        short: 'Eine Figur hat kein sicheres Feld und lässt sich in Ruhe erlegen.',
        body: 'Meist ein Läufer, der einen Bauern nahm, den er hätte stehen lassen sollen, oder ein Springer auf Raubzug. Die Taktik ist kein einzelner Schlag, sondern ein Würgegriff: nimm die Felder eines nach dem anderen weg, und die Figur fällt ohne jedes Opfer.',
      },
      {
        name: 'Stiller Zug',
        short: 'Der gewinnende Zug ist kein Schach, kein Schlagen und keine Drohung.',
        body: 'Der Grund, warum starke Spieler Kombinationen finden, die andere übersehen. Nach einer forcierten Folge ist die Antwort ein bescheidener Zug, der das letzte Fluchtfeld nimmt, und er ist unsichtbar für jeden, der nur Schachs und Schläge rechnet. Wenn eine Stellung gewonnen aussieht und nichts Forcierendes klappt, such den stillen.',
      },
      {
        name: 'Opfer',
        short: 'Gib Material für etwas, das mehr wert ist als Material.',
        body: 'Zeit, Linien, Felder oder die Lage des feindlichen Königs. Ein echtes Opfer ist kein Glücksspiel; es ist eine Rechnung mit konkretem Ende. Was ein funktionierendes von einem nicht funktionierenden trennt, ist fast immer, ob die verteidigenden Figuren rechtzeitig zurückkommen.',
      },
      {
        name: 'Weit vorgerückter Bauer',
        short: 'Ein Bauer nahe der Umwandlung ändert, was jede andere Figur wert ist.',
        body: 'Ein Bauer auf der siebten ist kein Bauer; er ist eine Dame, die von etwas bewacht werden muss, und dieses Etwas ist nicht mehr frei. Die meisten Endspieltaktiken drehen sich in Wahrheit um die Spannung zwischen einen Bauern aufzuhalten und irgendetwas anderes zu tun.',
      },
    ],
    after: {
      slug: 'Warum die Zahlen hier stehen',
      title: 'Ein Glossar sagt dir, was eine Gabel ist. Eine Zahl sagt dir, ob du sie üben kannst.',
      body: [
        'Den Namen eines Musters zu kennen und es unter der Uhr zu finden sind verschiedene Fähigkeiten, und nur die zweite gewinnt Partien. Jede Zahl oben ist die tatsächliche Anzahl der Stellungen in der mitgelieferten Bibliothek, die mit diesem Motiv markiert sind — keine Schätzung und nicht aufgerundet. Sechzig Röntgen-Aufgaben sind sechzig; wenn das die Sache ist, die du immer verfehlst, ist es gut zu wissen, dass sie dir an einem Abend nicht ausgehen.',
        'Der Trainer verfolgt, welche Motive du falsch machst, sodass er dir nach ein paar hundert Aufgaben nicht sagen kann, dass du 1620 bist, sondern dass du 1620 bist und immer wieder an Ablenkungen vorbeiläufst.',
      ],
      more: 'Wie die Aufgaben gewonnen und geprüft werden →',
    },
  },
};
