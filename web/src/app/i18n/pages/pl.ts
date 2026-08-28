import type { Pages } from './types';

/** The four commercial pages in Polish. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Pomoc',
      title: 'Zapytaj człowieka',
      lede: 'Nie ma systemu zgłoszeń, nie ma bota, nie ma centrum pomocy z czterystoma artykułami. Jest adres e-mail i lista usterek, a jedno i drugie trafia do osoby, która napisała tę aplikację.',
    },
    meta: {
      title: 'Pomoc',
      description:
        'Jak skontaktować się z człowiekiem w sprawie Brass Pawn, co dołączyć, gdy zadanie jest błędne, i pytania zadawane najczęściej.',
    },
    email: {
      slug: 'E-mail',
      body: 'W każdej sprawie: usterka, błędne zadanie, pytanie o zakup albo spór o ocenę. Pisz po angielsku lub po bułgarsku.',
    },
    tracker: {
      slug: 'Lista usterek',
      name: 'Zgłoszenia na GitHubie',
      body: 'Do wszystkiego, co wolisz mieć publicznie — i do wszystkiego, co inni powinni móc później znaleźć, co dotyczy większości zgłoszeń błędów.',
    },
    report: {
      slug: 'Gdy zadanie jest błędne',
      title: 'Przyślij cztery rzeczy, a sprawdzenie zajmie minutę.',
      checklist: [
        'FEN wyświetlony na ekranie zadania — przytrzymaj, żeby go skopiować.',
        'Ruch, który wykonałeś, i ruch, który aplikacja uznała za poprawny.',
        'W którym trybie to było.',
        'Wersja aplikacji, z ekranu informacyjnego.',
      ],
      caveat:
        'Zadania czasem przeczą głębszej analizie, a te sprzeczności gromadzą się w pozycjach długich, cichych i wysoko ocenionych, których sedno leży głębiej, niż sięgnęła weryfikacja. To granica weryfikacji, a nie błąd w zadaniu — ale warto wiedzieć, które to są, a jedyny sposób, żeby się dowiedzieć, to twoje zgłoszenie.',
    },
    faq: { slug: 'Pytania', title: 'Zadawane dość często, żeby je spisać.' },
    more: {
      ratings: 'Co mierzy ranking',
      tactics: 'Motywy',
      privacy: 'Polityka prywatności',
      terms: 'Warunki korzystania',
      licences: 'Licencje',
    },
  },

  pricing: {
    head: {
      slug: 'Ile to kosztuje',
      title: 'Gra jest darmowa. Sprzedawany jest trening.',
      lede: 'Gra z silnikiem i gra z człowiekiem, bez ograniczeń, bez reklam w żadnym miejscu aplikacji — to jest darmowe i takie zostanie. Sprzedawana jest biblioteka, ćwiczenia, zadania i wyścig z zegarem.',
    },
    meta: {
      title: 'Cennik',
      description:
        'Gra jest darmowa i nieograniczona — silnik, żywy przeciwnik i wszystkie 900 partii. Pro znosi limit pięciu dziennie: 3,99 dolara miesięcznie albo 49,99 jednorazowo.',
    },
    free: {
      name: 'Za darmo',
      note: 'Bez konta. Nie ma się do czego zapisywać.',
      items: [
        'Nieograniczona gra z silnikiem, od 1400 do pełnej siły',
        'Nieograniczone partie online przez Game Center',
        'Komentarz do każdego ruchu w każdej granej partii',
        'Pięć zadań taktycznych dziennie',
        'Pięć przebiegów Rush dziennie',
        'Po pięć z każdego: pozycyjne, końcówki, Zgadnij Elo',
        'Rankingi, serie i powtórki rozłożone w czasie, w całości',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Miesięcznie',
      per: 'miesięcznie',
      note: 'Anulowanie w dowolnej chwili w ustawieniach konta Apple.',
      items: [
        'Wszystkie limity dzienne zniesione',
        'Wszystkie {tactics} zadania taktyczne',
        'Wszystkie {positional} ćwiczenia pozycyjne',
        'Wszystkie {endgames} ćwiczenia końcówkowe',
        'Wszystkie {games} partie do oceny',
        'Rush bez limitu',
        'Wszystko z wersji darmowej, bez zmian',
      ],
    },
    lifetime: {
      name: 'Odblokowanie jednorazowe',
      once: 'raz na zawsze',
      note: 'Zakup niekonsumowalny. Nie odnawia się.',
      items: [
        'Dokładnie to samo co Pro miesięcznie',
        'Bez odnowień, bez daty wygaśnięcia, bez maili przypominających',
        'Przywraca się na twoich innych urządzeniach',
        'Dla tych, którzy wolą zdecydować raz',
      ],
    },
    table: {
      slug: 'Cała porcja',
      title: 'Co naprawdę daje wersja darmowa.',
      activity: 'Aktywność',
      freeCol: 'Za darmo',
      proCol: 'Pro',
      unlimited: 'Bez limitu',
      fiveADay: '5 dziennie',
      none: 'Brak',
      rows: [
        'Gra z silnikiem',
        'Partie online przez Game Center',
        'Oglądanie — biblioteka 900 partii',
        'Zadania taktyczne',
        'Przebiegi Rush',
        'Ćwiczenia pozycyjne',
        'Ćwiczenia końcówkowe',
        'Zgadnij Elo',
        'Reklamy',
      ],
      reset:
        'Porcje dzienne zerują się o dziewiątej rano czasu lokalnego — nie o północy, żeby wieczorna sesja nie została przecięta w połowie zmianą daty.',
    },
    why: {
      slug: 'Dlaczego ma taki kształt',
      title: 'Trzy decyzje i powód każdej z nich.',
      reasons: [
        {
          title: 'Liczone, nie zamknięte',
          body: [
            'Nikt nie płaci za trenera, którego nie używał, a tryb, który odmawia otwarcia, nie mówi nic o tym, co jest za nim. Więc każdy tryb się otwiera, codziennie, a ty dochodzisz na tyle daleko, żeby wyczuć rytm i zobaczyć, jak ranking się rusza.',
            'Ekran zakupu nigdy nie pojawia się przy uruchomieniu. Kiedy porcja dnia się skończy, ekran to mówi, a arkusz zakupu otwiera dopiero świadome dotknięcie.',
          ],
        },
        {
          title: 'Dwie ceny, nie trzy',
          body: [
            'Nie ma planu rocznego pomiędzy, bo trzecia cena to trzecia decyzja dokładnie w chwili, gdy ktoś chce rozwiązać zadanie. Miesięcznie, jeśli się wahasz. Jednorazowo, jeśli nie.',
          ],
        },
        {
          title: 'Gra nigdy nie jest na sprzedaż',
          body: [
            'Gra z silnikiem i z człowiekiem nic nie kosztuje w utrzymaniu i jest powodem, dla którego ta aplikacja istnieje. Sprzedawanie ich zamieniłoby to w szachową aplikację z rogatką zamiast w trenera.',
            'I nie ma reklam — częściowo z gustu, częściowo z licencji. Aplikacja łączy dwa silniki na copyleft, Stockfisha na GPLv3 i Recklessa na AGPLv3, a zamknięty SDK reklamowy w tym samym pliku binarnym uczyniłby całość nierozpowszechnialną. {link}',
          ],
        },
      ],
      licenceLink: 'Strona licencji wyjaśnia to po kolei.',
    },
    answers: {
      slug: 'Zakup, anulowanie, zwrot',
      title: 'Niewygodne pytania, odpowiedziane tutaj zamiast mailem.',
      items: [
        {
          q: 'Jak anulować?',
          a: 'Ustawienia → twoje imię → Subskrypcje → Brass Pawn. Nie możemy anulować za ciebie, bo subskrypcja jest między tobą a Apple i nigdy nie była u nas. Anulowanie zatrzymuje przyszłe odnowienia i nie skraca już opłaconego okresu.',
        },
        {
          q: 'Jak odzyskać pieniądze?',
          a: 'Przez Apple, na {link}. Nie możemy zwracać zakupów z App Store. Jeśli coś jest zepsute, napisz do nas — wolimy to naprawić.',
        },
        {
          q: 'Kupiłem odblokowanie i mam nowy telefon.',
          a: 'Zaloguj się na to samo konto Apple i dotknij „Przywróć zakupy” na ekranie zakupu. Aplikacja pyta StoreKit, co posiadasz; nic nie leży na naszym serwerze, bo nie ma naszego serwera.',
        },
        {
          q: 'Czy Pro zmienia mój ranking albo odblokowuje „lepsze” zadania?',
          a: 'Nie. System rankingowy jest identyczny, a każde zadanie w bibliotece jest osiągalne na darmowym koncie — pięć dziennie. Pro znosi licznik, a nie zasłonę.',
        },
        {
          q: 'Czy darmowa porcja się później zmniejszy?',
          a: 'Może się zmienić w obie strony, gdy biblioteka rośnie. Nieograniczona gra z silnikiem i z człowiekiem nie stanie się funkcją płatną; to jest zapisane w {link}, a nie tylko obiecane tutaj.',
        },
      ],
      termsLink: 'warunkach',
      more: 'Więcej pytań i jak dotrzeć do człowieka →',
    },
  },

  training: {
    head: {
      slug: 'Program',
      title: 'Osiem sposobów, żeby usłyszeć prawdę',
      lede: 'Trzy z nich są darmowe i nieograniczone na zawsze — gra, gra z kimś i dziewięćset partii w Oglądaniu. Pozostałe pięć to pięć dziennie na darmowym koncie i bez limitu z Pro. Każdy ocenia cię słowami o pozycji zamiast liczbą, którą trzeba dopiero rozszyfrować.',
    },
    meta: {
      title: 'Trening',
      description:
        'Osiem trybów: taktyka, ocena pozycyjna, końcówki, Rush, Zgadnij Elo, Oglądanie, gra z komentarzem i online. Jak działa każdy, jak zadania są wydobywane i weryfikowane, i czego trener nie robi.',
    },
    modes: [
      {
        title: 'Taktyka',
        lede: 'Pozycje z dokładnie jednym wygrywającym ruchem i wyrok w chwili, gdy go zagrasz.',
        body: [
          'Każde zadanie ma jedną odpowiedź i żadnych rozgałęzień. Zagraj ją na szachownicy, a trener od razu powie, czy trafiłeś; jeśli chybisz, pozycja wraca jutro, potem za cztery dni, potem za dziesięć — dopóki nadal cię łapie.',
          'Każde zadanie niesie motyw, wokół którego się obraca — widelec, związanie, szpila, mat na ostatniej linii, odciągnięcie, cichy ruch — żeby po kilkuset trener mógł ci powiedzieć nie tyle, że masz 1620, ile że masz 1620 i wciąż wchodzisz w odciągnięcia.',
        ],
        free: 'Pięć dziennie na darmowym koncie.',
        stat: 'zadań, ocenionych od 760 do 2800',
      },
      {
        title: 'Ocena pozycyjna',
        lede: 'Nie ma wymuszonej wygranej. Powiedz, kto stoi lepiej, a potem znajdź ruch, który mówi dlaczego.',
        body: [
          'To tryb zbudowany dla tego, co odróżnia silnych graczy od dobrych rachmistrzów. Najpierw oceniasz: wyraźnie lepiej, nieco lepiej, równowaga. Potem wybierasz ruch. Obie odpowiedzi są oceniane.',
          'Informacja zwrotna nazywa konkretne cechy zamiast nastrojów — otwarta linia i to, czy stoi na niej wieża, pole dla skoczka, którego żaden pion nie zakwestionuje, struktura pionowa, bezpieczeństwo króla, różnica w aktywności figur. Pozycja nie jest „przyjemna dla białych”; jest lepsza z czterech powodów, które da się wyliczyć.',
        ],
        free: 'Pięć dziennie na darmowym koncie.',
        stat: 'cichych pozycji, wstępnie wybranych przez silnik',
      },
      {
        title: 'Końcówki',
        lede: 'Kanoniczne pozycje, dogrywane do końca przeciwko silnikowi, który broni przyzwoicie.',
        body: [
          'Znać ideę to nie to samo co ją dowieźć, więc tutaj musisz naprawdę osiągnąć wynik. Stockfish bierze drugą stronę i stawia najlepszą obronę, jaka istnieje.',
          'Po każdym ruchu trener sprawdza od nowa, czy wynik nadal jest osiągalny — a jeśli nie, nazywa dokładny ruch, po którym przestał być. To zdanie, które czegoś uczy: nie „zremisowałeś”, tylko „zremisowałeś tutaj”.',
        ],
        free: 'Pięć dziennie na darmowym koncie.',
        stat: 'ćwiczeń, każdy wynik zweryfikowany przez silnik',
      },
      {
        title: 'Rush',
        lede: 'Przebieg na czas. Rozwiąż ich tyle, ile zdążysz, zanim zegar zabierze resztę.',
        body: [
          'Te same zadania, pod zegarem, z trudnością rosnącą tak długo, jak długo je znajdujesz. To trenuje inny mięsień niż zadanie, na które można się patrzeć: ten, który musi zobaczyć teraz.',
          'Przebiegi są punktowane i zapisywane, więc liczba rośnie przez miesiące, a nie przez jeden wieczór.',
        ],
        free: 'Pięć przebiegów dziennie na darmowym koncie.',
      },
      {
        title: 'Zgadnij Elo',
        lede: 'Prawdziwa partia rankingowa, odtwarzana ruch po ruchu. Jak silni byli ci dwaj?',
        body: [
          'Odczytanie poziomu partii to ta sama umiejętność co ocenianie własnych ruchów: obie sprowadzają się do zauważania, jakie błędy są popełniane, a jakie nie. Więc partia biegnie, ty patrzysz, a w pewnym momencie stawiasz liczbę.',
          'Partie są prawdziwe, z archiwów Lichess, z obydwoma graczami w przedziale 150 punktów od siebie — zgadywanie „poziomu graczy” ma sens tylko wtedy, gdy jest jeden poziom do zgadnięcia.',
        ],
        free: 'Pięć dziennie na darmowym koncie.',
        stat: 'partii rankingowych, od 800 do 2599',
      },
      {
        title: 'Oglądanie',
        lede: 'Dziewięćset partii wartych obejrzenia — a w chwili, gdy zagrałbyś inaczej, przejmujesz je.',
        body: [
          'Każda partia w bibliotece jest rozstrzygnięta, między dwoma graczami z nazwiskiem, i albo skończona w dwudziestu pięciu ruchach, albo dość sławna, żeby mieć własną nazwę. Nikt nie uczy się niczego z dziewięćdziesięcioruchowego remisu między ludźmi, o których nigdy nie słyszał, a biblioteka, która to zawiera, jest biblioteką, której nikt nie otwiera drugi raz.',
          'Wyszukaj gracza, turniej albo rok. Potem przejdź partię we własnym tempie. Nie chodzi o najlepsze momenty: chodzi o to, że przy którymś ruchu pomyślisz <em>ja bym tam bił</em> — i w tej chwili możesz. Przejmij pozycję i graj dalej z silnikiem dokładnie z tego pola, na którym się nie zgadzałeś. Sprawdzenie, ile twój pomysł naprawdę był wart, jest całym ćwiczeniem.',
        ],
        free: 'Za darmo, bez limitu, zawsze.',
        stat: 'partii, wszystkie rozstrzygnięte',
      },
      {
        title: 'Gra z trenerem',
        lede: 'Cała partia na wybranej przez ciebie sile, z każdym twoim ruchem ocenianym na bieżąco.',
        body: [
          'Ustaw silnik gdzieś między 1400 a pełną siłą i dograj partię. Każdy twój ruch jest oceniany, gdy partia jeszcze trwa, a trener wyjaśnia, co osiągnąłby lepszy ruch — słowami o pozycji, nie liczbą.',
          'Na koniec dostajesz celność, liczbę pomyłek i tę jedną chwilę, która kosztowała najwięcej.',
        ],
        free: 'Za darmo, bez limitu, zawsze.',
      },
      {
        title: 'Online',
        lede: 'Dwoje ludzi, jeden zegar i żadnego silnika w pobliżu.',
        body: [
          'Game Center znajduje kogoś, kto wybrał to samo tempo — 3, 5, 10, 15 albo 30 minut. To jedyny tryb bez silnika: bez podpowiedzi, bez ocen ruchów, bez trenowania, bo pomoc dostawana przez jedną stronę to nie jest partia.',
          'Nie ma serwera. Dwa urządzenia rozmawiają ze sobą i oba egzekwują reguły, więc ruch zostaje zagrany tylko wtedy, gdy jest legalny w pozycji, którą urządzenie odbierające już ma. Kłamiący przeciwnik daje odrzucony pakiet, a nie nielegalną szachownicę.',
        ],
        free: 'Za darmo, bez limitu, zawsze.',
      },
    ],
    watchLink: 'Co trafiło do biblioteki, a co nie →',
    pipeline: {
      slug: 'Jak powstaje zadanie',
      title: 'Wydobyte, nie przepisane.',
      lede: 'Spisywanie pozycji z pamięci grozi zadaniem, którego „rozwiązanie” jest błędne albo nie jest jedyne, a to trenuje dokładnie zły odruch. Więc żadna z nich nie została spisana z pamięci. Są znajdowane, a potem atakowane, aż przetrwają albo wylecą.',
      steps: [
        {
          title: 'Gra na ludzkiej sile',
          body: 'Stockfish gra sam ze sobą na celowo ludzkiej sile — od 1320 do 2500 Elo — otwierając losowym wyborem spośród swoich najlepszych płytkich kandydatów, żeby partie się różniły, zamiast powtarzać jedną linię w nieskończoność.',
        },
        {
          title: 'Przesiewanie po własności, nie po pomyłce',
          body: 'Każda pozycja jest przeszukiwana na głębokość 12 z dwiema liniami kandydackimi. Sygnałem nie jest „ktoś się pomylił”, tylko to, czego zadanie naprawdę potrzebuje: jeden ruch znacznie lepszy od każdej alternatywy.',
        },
        {
          title: 'Powtórne głębokie przeszukanie, z marginesem',
          body: 'Ocaleni są przeszukiwani ponownie na głębokość 20 z MultiPV. Kandydat zostaje tylko wtedy, gdy najlepszy ruch bije drugi o co najmniej 140 setnych piona i faktycznie coś osiąga.',
        },
        {
          title: 'Przedłużanie aż do rozgałęzienia',
          body: 'Rozwiązanie jest przedłużane ruch po ruchu tak długo, jak każdy ruch rozwiązującego pozostaje jednoznacznie najlepszy. W chwili, gdy są dwie dobre odpowiedzi, zadanie kończy się tam — więc nigdy nie ma rozgałęzienia, za które można by cię policzyć jako błąd.',
        },
        {
          title: 'Weryfikacja świeżym silnikiem',
          body: 'Cały zbiór jest sprawdzany na większej głębokości przez osobny skrypt z nowym silnikiem. Na dołączonym wydobytym zbiorze odrzucił 6 ze 172 zadań, których rozwiązania przestawały być jedyne dwa półruchy głębiej. Te zostały wyrzucone, a nie dostarczone.',
        },
      ],
    },
    honest: {
      title: 'I ta sama nieufność zastosowana do końcówek',
      body: [
        'Deklarowany wynik każdego ćwiczenia końcówkowego jest sprawdzany głębokim przeszukaniem, a nie przyjmowany na słowo. Źle opisane ćwiczenie oblewa weryfikację, zamiast po cichu uczyć cię nieprawdy.',
        'Weryfikator wyłapuje też coś, czego zwykłe biblioteki szachowe nie mówią: czy strona, która nie jest na posunięciu, stoi w szachu. Taka pozycja jest nielegalna — żadna partia nie może do niej dojść — ale biblioteka przyjmie ją bez sprzeciwu, a silnik odpowie bestmove (none), co brzmi jak awaria silnika, a nie jak zła pozycja. Trzy ręcznie napisane ćwiczenia były zepsute dokładnie w ten sposób. Weryfikacja teraz to wyłapuje.',
      ],
    },
    limits: {
      slug: 'Uczciwe granice',
      title: 'Czego to nie robi.',
      items: [
        {
          title: 'Zbiór miesza dwie skale rankingowe.',
          body: 'Zadania z {lichess} Lichess niosą rankingi skalibrowane na milionach ludzkich prób. {mined} zadań wydobytych lokalnie niesie oszacowania z głębokości rozwiązania i motywu. Obie skale porządkują sensownie, ale wydobyte 1600 i lichessowe 1600 nie są mierzone tak samo.',
        },
        {
          title: 'Rankingi zadań to nie rankingi zza szachownicy.',
          body: 'Leżą kilkaset punktów wyżej i tak zostanie. Mierzą postęp wobec ciebie samego, a nie siłę wobec pola ludzi przy zegarze — {link}, bo ta różnica jest strukturalna, a nie oznaką, że źle wykańczasz.',
        },
        {
          title: 'Nie ma treningu debiutów.',
          body: 'Celowo. Studiowanie debiutów to zapamiętywanie pod wybrany przez ciebie repertuar, a to inne narzędzie o innym kształcie. Tryb pozycyjny pokrywa przejście z debiutu, a to jest ta część, która naprawdę się uogólnia.',
        },
        {
          title: 'To nie zrobi z ciebie arcymistrza.',
          body: 'Nic tego nie robi samo. Tytuły biorą się z tysięcy godzin plus rankingowych partii turniejowych z ludźmi. To, co dostajesz tutaj, to treningowa połowa tego, uporządkowana, z uczciwą miarą tego, gdzie naprawdę stoisz.',
        },
      ],
      ratingsLink: 'warto to dobrze zrozumieć',
    },
    more: {
      motifs: 'Dwadzieścia motywów, zdefiniowanych i policzonych →',
      engine: 'Jak używany jest silnik →',
    },
  },

  tactics: {
    head: {
      slug: 'Słownik',
      title: 'Dwadzieścia motywów',
      lede: 'Każda taktyka w szachach jest jednym z niewielu kształtów, a gdy potrafisz je nazwać, widzisz je o ruch wcześniej. To są motywy, którymi Brass Pawn opisuje swoje zadania — po każdym liczba pozycji w dołączonej bibliotece, które naprawdę wokół niego się obracają.',
      meta: 'Policzone na dołączonym zbiorze 14 351 zadań · Ostatnio sprawdzone 19 sierpnia 2026',
    },
    meta: {
      title: 'Dwadzieścia motywów',
      description:
        'Każdy motyw taktyczny, którym Brass Pawn opisuje swoje zadania, zdefiniowany i policzony na dołączonej bibliotece, żebyś wiedział, które naprawdę możesz ćwiczyć.',
    },
    indexLabel: 'Motywy',
    puzzles: 'zadań',
    motifs: [
      {
        name: 'Widelec',
        short: 'Jedna bierka atakuje dwie rzeczy naraz, a uratować da się tylko jedną.',
        body: 'Skoczek jest słynnym widelcarzem, bo atakuje pola, których żadna inna bierka nie kryje w ten sam sposób, ale widelcuje wszystko: pion trafiający dwie lekkie figury, hetman trafiający wieżę i luźnego gońca, król w końcówce wchodzący między dwa piony. Sprawdzianem nie jest „czy atakuję dwie rzeczy”, tylko „czy obie mogą uciec”.',
      },
      {
        name: 'Związanie',
        short: 'Bierka nie może się ruszyć, bo za nią stoi coś cenniejszego.',
        body: 'Bezwzględne, gdy za nią stoi król — ruszenie jest nielegalne, a nie tylko złe. Względne, gdy stoi hetman albo wieża, gdzie ruszenie jest legalne i po prostu kosztuje materiał. Wygrywa kontynuacja: związana bierka to bierka, która nie może kryć, więc dołóż na nią napastników albo uderz ją pionem.',
      },
      {
        name: 'Szpila',
        short: 'Związanie na odwrót: cenna bierka stoi z przodu i musi się ruszyć.',
        body: 'Daj szach królowi na linii wieżą, gońcem albo hetmanem, a to, co stało za nim, jest twoje, gdy tylko król zejdzie w bok. Szpile są rzadsze od związań, bo wymagają dwóch bierek już na jednej linii z cenniejszą z przodu — dlatego zwykle pojawiają się po tym, jak szach zmusił króla na tę linię.',
      },
      {
        name: 'Atak odsłonięty',
        short: 'Ruszenie jednej bierki odsłania atak tej, która stała za nią.',
        body: 'Zdecydowanie najsilniejsza taktyka w szachach, bo bierka, która odchodzi, może robić coś swojego, podczas gdy odsłonięty atak wykonuje pracę. Dwie groźby powstają w jednym ruchu i żadnej nie da się odeprzeć zbiciem odchodzącej bierki.',
      },
      {
        name: 'Szach odsłonięty',
        short: 'Odsłonięty atak jest szachem, więc przeciwnik nie ma czasu na nic innego.',
        body: 'Atak odsłonięty, w którym bierka z tyłu daje szach. Cokolwiek zrobi odchodząca bierka — zbije hetmana, stanie na polu matującym, wystawi się na zbicie — odpowiedź musi najpierw zająć się szachem, więc dzieje się to za darmo.',
      },
      {
        name: 'Szach podwójny',
        short: 'Dwie bierki szachują naraz, więc król musi się ruszyć. Nie zasłonić, nie zbić.',
        body: 'Jedyna taktyka, na którą istnieje dokładnie jeden rodzaj legalnej odpowiedzi. Zbicie jednego szachującego zostawia drugiego; zasłonięcie jednej linii zostawia otwartą drugą. Dlatego szach podwójny daje maty wyglądające na niemożliwe — obrońca może mieć pięć sposobów na zatrzymanie każdego szacha z osobna i żadnego na oba naraz.',
      },
      {
        name: 'Odciągnięcie',
        short: 'Zmuś obrońcę do odejścia od pracy, którą wykonuje.',
        body: 'Bierka trzyma pole matujące, ostatnią linię albo inną bierkę. Zaatakuj coś, co ceni wyżej, albo po prostu zbij coś, co musi odbić, a krycie, które dawała, odchodzi razem z nią. Ofiara często wygląda absurdalnie, dopóki nie zauważysz, czego odbijająca bierka już nie broni.',
      },
      {
        name: 'Zwabienie',
        short: 'Zwab bierkę — zwykle króla — na pole, gdzie da się ją trafić.',
        body: 'Ofiara, którą przeciwnik musi przyjąć, grana nie po to, żeby wygrać materiał, tylko żeby postawić bierkę fatalnie: król wciągnięty na pole widelca, hetman wyciągnięty na linię z wieżą. Materiał wraca ruch później z odsetkami.',
      },
      {
        name: 'Oczyszczenie',
        short: 'Usuń własną bierkę z drogi własnemu atakowi.',
        body: 'Linia albo pole są właściwe, tylko stoi na nich twój człowiek. Oczyszczenie odsuwa go z tempem — zwykle z szachem albo biciem, żeby przeciwnik nie miał czasu na przegrupowanie, gdy droga się otwiera.',
      },
      {
        name: 'Przesłona',
        short: 'Przetnij linię między obrońcą a tym, czego broni.',
        body: 'Postaw bierkę — często poświęconą — dokładnie między wieżą a polem, którego pilnuje. Obrońca wciąż jest na szachownicy, w teorii wciąż broni i już nie może. Rzadkie i jeden z najtrudniejszych do zauważenia wzorców, bo przesłaniająca bierka zwykle wygląda na pomyłkę.',
      },
      {
        name: 'Atak rentgenowski',
        short: 'Bierka działa przez inną bierkę, wzdłuż linii, którą później zajmie.',
        body: 'Wieża broniąca własnej bierki przez bierkę przeciwnika albo atakująca przez nią. Jeszcze nic się nie dzieje; liczy się to, co się stanie, gdy bierka pośrodku odejdzie albo zostanie zbita. Rozpoznanie rentgena to zwykle to, co sprawia, że bicie „tracące materiał” materiału nie traci.',
      },
      {
        name: 'Posunięcie pośrednie',
        short: 'Ruch pomiędzy: przed odbiciem zrób coś bardziej wymuszającego.',
        body: 'Z niemieckiego „Zwischenzug” i najczęstszy pojedynczy powód, dla którego policzony wariant okazuje się błędny. Spodziewasz się odbicia; zamiast tego przychodzi szach albo większa groźba, a zanim odbicie nastąpi, pozycja się zmieniła. Szukaj go za każdym razem, gdy sekwencja wygląda na wymuszoną.',
      },
      {
        name: 'Zugzwang',
        short: 'Sam przymus ruchu jest problemem.',
        body: 'Każdy legalny ruch pogarsza pozycję, a spasować nie wolno. Głównie idea końcówkowa — rozstrzyga końcówki królów i pionów — i powód, dla którego liczy się „opozycja”: kto pierwszy musi zejść w bok, oddaje pole. Niemal jedyna sytuacja w szachach, w której prawo do ruchu jest ciężarem.',
      },
      {
        name: 'Mat na ostatniej linii',
        short: 'Król zamknięty własnymi pionami, mat na pierwszej linii.',
        body: 'Najczęstszy mat wśród graczy, którzy zrobili roszadę i zostawili piony w spokoju. Rzadko pojawia się jako mat na szachownicy — pojawia się jako groźba, która wygrywa materiał, bo każdy ruch obronny musi nadal kryć linię. Cała rodzina taktyk odciągających istnieje po to, żeby to krycie usunąć.',
      },
      {
        name: 'Mat duszony',
        short: 'Skoczek matuje króla zamkniętego przez własne bierki.',
        body: 'Finał legatu Philidora: ofiara hetmana na g8, wieża odbija, skoczek na f7 daje mata, a król jest otoczony własnymi ludźmi. Rzadki w prawdziwych partiach, a mimo to wart znajomości, bo ten wzorzec jest tym, co każe ci spojrzeć w róg i policzyć pola ucieczki.',
      },
      {
        name: 'Wisząca bierka',
        short: 'Coś jest po prostu niebronione i można to wziąć.',
        body: 'Bez blasku, a rozstrzyga więcej partii niż wszystko inne na tej liście razem wzięte. Większość porażek poniżej 1800 to jeden gracz biorący darmową figurę, którą drugi przeoczył. Nawyk, który to leczy, to sprawdzanie, co stoi luźno — u obu kolorów — przed każdym ruchem.',
      },
      {
        name: 'Uwięziona bierka',
        short: 'Bierka nie ma bezpiecznego pola i można ją spokojnie osaczyć.',
        body: 'Zwykle goniec, który wziął piona, którego powinien był zostawić, albo skoczek, który poszedł na łup. Taktyką nie jest jedno uderzenie, tylko duszenie: zabieraj pola po kolei, a bierka padnie bez potrzeby ofiary.',
      },
      {
        name: 'Cichy ruch',
        short: 'Wygrywający ruch nie jest szachem, biciem ani groźbą.',
        body: 'Powód, dla którego silni gracze znajdują kombinacje, które inni przeoczają. Po wymuszonej sekwencji odpowiedzią jest skromny ruch odbierający ostatnie pole ucieczki, niewidzialny dla kogoś, kto liczy tylko szachy i bicia. Gdy pozycja wygląda na wygraną, a nic wymuszającego nie działa, szukaj cichego.',
      },
      {
        name: 'Ofiara',
        short: 'Oddaj materiał za coś wartego więcej niż materiał.',
        body: 'Czas, linie, pola albo pozycję nieprzyjacielskiego króla. Prawdziwa ofiara nie jest zakładem; jest rachunkiem z konkretnym końcem. To, co odróżnia ofiarę działającą od niedziałającej, to niemal zawsze pytanie, czy broniące bierki zdążą wrócić.',
      },
      {
        name: 'Zaawansowany pion',
        short: 'Pion blisko promocji zmienia wartość każdej innej bierki.',
        body: 'Pion na siódmej to nie pion; to hetman, którego coś musi pilnować, a to coś przestaje być wolne. Większość taktyk końcówkowych naprawdę dotyczy napięcia między zatrzymywaniem piona a robieniem czegokolwiek innego.',
      },
    ],
    after: {
      slug: 'Dlaczego są tu liczby',
      title: 'Słownik mówi, czym jest widelec. Liczba mówi, czy da się go ćwiczyć.',
      body: [
        'Znać nazwę wzorca i umieć go znaleźć pod zegarem to różne umiejętności, a tylko druga wygrywa partie. Każda liczba powyżej to rzeczywista liczba pozycji w dołączonej bibliotece opisanych tym motywem — nie oszacowanie i nie zaokrąglenie w górę. Sześćdziesiąt zadań rentgenowskich to sześćdziesiąt; jeśli to jest ta rzecz, którą wciąż przeoczasz, dobrze wiedzieć, że nie skończą się w jeden wieczór.',
        'Trener śledzi, które motywy mylisz, żeby po kilkuset zadaniach mógł ci powiedzieć nie tyle, że masz 1620, ile że masz 1620 i wciąż wchodzisz w odciągnięcia.',
      ],
      more: 'Jak zadania są wydobywane i weryfikowane →',
    },
  },
};
