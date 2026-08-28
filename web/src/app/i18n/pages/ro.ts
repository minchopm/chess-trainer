import type { Pages } from './types';

/** The four commercial pages in Romanian. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Asistență',
      title: 'Întreabă un om',
      lede: 'Nu există sistem de tichete, nu există chatbot și nu există un centru de ajutor cu patru sute de articole. Există o adresă de e-mail și o listă de defecte, iar amândouă ajung la cel care a scris aplicația.',
    },
    meta: {
      title: 'Asistență',
      description:
        'Cum ajungi la un om în privința Brass Pawn, ce trimiți când o problemă este greșită și întrebările care apar cel mai des.',
    },
    email: {
      slug: 'E-mail',
      body: 'Pentru orice: o eroare, o problemă greșită, o întrebare despre o achiziție sau un dezacord cu o evaluare. Scrie în engleză sau în bulgară.',
    },
    tracker: {
      slug: 'Lista de defecte',
      name: 'Issues pe GitHub',
      body: 'Pentru tot ce preferi să rămână public — și pentru tot ce trebuie să poată găsi alții mai târziu, ceea ce este valabil pentru majoritatea rapoartelor de eroare.',
    },
    report: {
      slug: 'Când o problemă este greșită',
      title: 'Trimite patru lucruri și verificarea durează un minut.',
      checklist: [
        'FEN-ul afișat pe ecranul problemei — ține apăsat ca să îl copiezi.',
        'Mutarea pe care ai făcut-o și mutarea pe care aplicația a numit-o corectă.',
        'În ce mod erai.',
        'Versiunea aplicației, din ecranul de informații.',
      ],
      caveat:
        'Problemele contrazic din când în când o căutare mai adâncă, iar aceste contraziceri se adună în poziții lungi, liniștite, cotate sus, al căror rost stă mai adânc decât a ajuns verificarea. Este o limită a verificării, nu o greșeală în problemă — dar merită să știm care sunt, iar singurul mod de a ști este să ne spui.',
    },
    faq: { slug: 'Întrebări', title: 'Puse destul de des încât să fie scrise.' },
    more: {
      ratings: 'Ce măsoară un rating',
      tactics: 'Motivele',
      privacy: 'Politica de confidențialitate',
      terms: 'Condiții de utilizare',
      licences: 'Licențe',
    },
  },

  pricing: {
    head: {
      slug: 'Cât costă',
      title: 'Jocul e gratuit. Antrenamentul se vinde.',
      lede: 'Șah împotriva motorului și șah împotriva unui om, fără limită, fără reclame nicăieri în aplicație — asta e gratuit și așa rămâne. Ceea ce se vinde este biblioteca, exercițiile, problemele și cursa contra ceasului.',
    },
    meta: {
      title: 'Prețuri',
      description:
        'Jocul e gratuit și nelimitat — motorul, un adversar viu și toate cele 900 de partide. Pro scoate limita de cinci pe zi: 3,99 dolari pe lună sau 49,99 o singură dată.',
    },
    free: {
      name: 'Gratuit',
      note: 'Fără cont. Nu e nimic la care să te înscrii.',
      items: [
        'Joc nelimitat împotriva motorului, de la 1400 la forță deplină',
        'Partide online nelimitate prin Game Center',
        'Comentariu mutare cu mutare în fiecare partidă pe care o joci',
        'Cinci probleme tactice pe zi',
        'Cinci runde Rush pe zi',
        'Câte cinci din fiecare: poziționale, finaluri, Ghicește Elo',
        'Ratinguri, serii și repetiție eșalonată, în întregime',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Lunar',
      per: 'pe lună',
      note: 'Anulezi oricând din setările contului tău Apple.',
      items: [
        'Toate limitele zilnice dispar',
        'Toate cele {tactics} probleme tactice',
        'Toate cele {positional} exerciții poziționale',
        'Toate cele {endgames} exerciții de final',
        'Toate cele {games} partide de evaluat',
        'Rush fără limită',
        'Tot ce e în versiunea gratuită, neschimbat',
      ],
    },
    lifetime: {
      name: 'Deblocare unică',
      once: 'o dată pentru totdeauna',
      note: 'O achiziție neconsumabilă. Nu se reînnoiește.',
      items: [
        'Exact același lucru ca Pro lunar',
        'Fără reînnoiri, fără dată de expirare, fără e-mailuri de reamintire',
        'Se restaurează pe celelalte dispozitive ale tale',
        'Pentru cine preferă să decidă o singură dată',
      ],
    },
    table: {
      slug: 'Porția întreagă',
      title: 'Ce oferă de fapt versiunea gratuită.',
      activity: 'Activitate',
      freeCol: 'Gratuit',
      proCol: 'Pro',
      unlimited: 'Nelimitat',
      fiveADay: '5 pe zi',
      none: 'Niciuna',
      rows: [
        'Joc împotriva motorului',
        'Partide online prin Game Center',
        'Vizionare — biblioteca de 900 de partide',
        'Probleme tactice',
        'Runde Rush',
        'Exerciții poziționale',
        'Exerciții de final',
        'Ghicește Elo',
        'Reclame',
      ],
      reset:
        'Porțiile zilnice se resetează la ora nouă dimineața, ora locală — nu la miezul nopții, ca o sesiune de seară să nu fie tăiată în două de schimbarea datei.',
    },
    why: {
      slug: 'De ce are forma asta',
      title: 'Trei decizii și motivul fiecăreia.',
      reasons: [
        {
          title: 'Numărat, nu încuiat',
          body: [
            'Nimeni nu plătește pentru un antrenor pe care nu l-a folosit, iar un mod care refuză să se deschidă nu spune nimic despre ce e în spatele lui. Așa că fiecare mod se deschide, în fiecare zi, și ajungi destul de departe cât să simți ritmul și să vezi ratingul mișcându-se.',
            'Ecranul de cumpărare nu apare niciodată la pornire. Când porția zilei s-a terminat, ecranul o spune, și abia o atingere conștientă deschide foaia de cumpărare.',
          ],
        },
        {
          title: 'Două prețuri, nu trei',
          body: [
            'Nu există un plan anual la mijloc, pentru că un al treilea preț este o a treia decizie exact în clipa în care cineva vrea să rezolve o problemă. Lunar dacă eziți. O dată dacă nu.',
          ],
        },
        {
          title: 'Jocul nu se vinde niciodată',
          body: [
            'Șahul împotriva motorului și împotriva unui om nu costă nimic să fie ținut în funcțiune și este motivul pentru care aplicația există. Să le vindem ar transforma-o într-o aplicație de șah cu barieră în loc de antrenor.',
            'Și nu există reclame — parte gust, parte licență. Aplicația leagă două motoare copyleft, Stockfish sub GPLv3 și Reckless sub AGPLv3, iar un SDK de publicitate proprietar în același binar ar face întregul imposibil de distribuit. {link}',
          ],
        },
      ],
      licenceLink: 'Pagina de licențe explică asta pe îndelete.',
    },
    answers: {
      slug: 'Cumpărare, anulare, rambursare',
      title: 'Întrebările incomode, cu răspuns aici în loc de pe e-mail.',
      items: [
        {
          q: 'Cum anulez?',
          a: 'Setări → numele tău → Abonamente → Brass Pawn. Nu putem anula în locul tău, fiindcă abonamentul e între tine și Apple și n-a fost niciodată la noi. Anularea oprește reînnoirile viitoare și nu scurtează perioada deja plătită.',
        },
        {
          q: 'Cum îmi primesc banii înapoi?',
          a: 'Prin Apple, la {link}. Nu putem rambursa achiziții din App Store. Dacă ceva e stricat, scrie-ne — preferăm să reparăm.',
        },
        {
          q: 'Am cumpărat deblocarea și am telefon nou.',
          a: 'Autentifică-te cu același cont Apple și atinge „Restaurează achizițiile” pe ecranul de cumpărare. Aplicația întreabă StoreKit ce deții; nimic nu stă pe un server al nostru, pentru că nu avem niciun server.',
        },
        {
          q: 'Schimbă Pro ratingul meu sau deblochează probleme „mai bune”?',
          a: 'Nu. Sistemul de rating este identic, iar orice problemă din bibliotecă e accesibilă cu un cont gratuit — cinci pe zi. Pro ia contorul, nu o cortină.',
        },
        {
          q: 'Se va micșora porția gratuită mai târziu?',
          a: 'Se poate schimba în ambele sensuri pe măsură ce biblioteca crește. Jocul nelimitat împotriva motorului și împotriva unui om nu va deveni funcție cu plată; asta e scris în {link}, nu doar promis aici.',
        },
      ],
      termsLink: 'condiții',
      more: 'Mai multe întrebări și cum ajungi la un om →',
    },
  },

  training: {
    head: {
      slug: 'Programul',
      title: 'Opt feluri de a auzi adevărul',
      lede: 'Trei dintre ele sunt gratuite și nelimitate pentru totdeauna — jocul, jocul cu cineva și cele nouă sute de partide din Vizionare. Celelalte cinci sunt cinci pe zi cu un cont gratuit și nelimitate cu Pro. Fiecare te judecă în cuvinte despre poziție, nu printr-un număr pe care trebuie mai întâi să-l descifrezi.',
    },
    meta: {
      title: 'Antrenament',
      description:
        'Opt moduri: tactică, judecată pozițională, finaluri, Rush, Ghicește Elo, Vizionare, joc cu comentariu și online. Cum funcționează fiecare, cum sunt extrase și verificate problemele și ce nu face antrenorul.',
    },
    modes: [
      {
        title: 'Tactică',
        lede: 'Poziții cu exact o mutare câștigătoare și o sentință în clipa în care o joci.',
        body: [
          'Fiecare problemă are un singur răspuns și nicio ramificație. Joacă-l pe tablă și antrenorul îți spune imediat dacă l-ai găsit; dacă ratezi, poziția revine mâine, apoi peste patru zile, apoi peste zece — cât timp continuă să te prindă.',
          'Fiecare problemă poartă motivul în jurul căruia se învârte — furculiță, legare, frigare, mat pe ultima linie, deviere, mutarea liniștită — ca după câteva sute antrenorul să-ți poată spune nu că ai 1620, ci că ai 1620 și intri iar și iar în devieri.',
        ],
        free: 'Cinci pe zi cu un cont gratuit.',
        stat: 'probleme, cotate de la 760 la 2800',
      },
      {
        title: 'Judecată pozițională',
        lede: 'Nu există câștig forțat. Spune cine stă mai bine, apoi găsește mutarea care spune de ce.',
        body: [
          'Acesta e modul construit pentru ceea ce îi desparte pe jucătorii puternici de bunii calculatori. Întâi evaluezi: clar mai bine, ceva mai bine, echilibru. Apoi alegi o mutare. Ambele răspunsuri sunt evaluate.',
          'Feedbackul numește trăsături concrete în loc de stări — coloana deschisă și dacă stă un turn pe ea, câmpul de cal pe care niciun pion nu-l poate contesta, structura de pioni, siguranța regelui, diferența de activitate a pieselor. O poziție nu e „plăcută pentru alb”; e mai bună din patru motive pe care le poți enumera.',
        ],
        free: 'Cinci pe zi cu un cont gratuit.',
        stat: 'poziții liniștite, preselectate de motor',
      },
      {
        title: 'Finaluri',
        lede: 'Poziții canonice, jucate până la capăt împotriva unui motor care se apără decent.',
        body: [
          'A cunoaște ideea nu e totuna cu a o duce acasă, așa că aici trebuie chiar să ajungi la rezultat. Stockfish ia cealaltă parte și ridică cea mai bună apărare care există.',
          'După fiecare mutare antrenorul verifică din nou dacă rezultatul mai e accesibil — iar dacă nu, numește mutarea exactă în care a încetat să fie. Asta e propoziția care învață ceva: nu „ai făcut remiză”, ci „ai făcut remiză aici”.',
        ],
        free: 'Cinci pe zi cu un cont gratuit.',
        stat: 'exerciții, fiecare rezultat verificat de motor',
      },
      {
        title: 'Rush',
        lede: 'O rundă contra timp. Rezolvă câte apuci înainte ca ceasul să ia restul.',
        body: [
          'Aceleași probleme, sub ceas, cu o dificultate care urcă atâta timp cât continui să le găsești. Asta antrenează alt mușchi decât o problemă la care ai voie să te uiți: pe cel care trebuie să vadă acum.',
          'Rundele sunt punctate și salvate, așa că numărul crește peste luni, nu peste o singură seară.',
        ],
        free: 'Cinci runde pe zi cu un cont gratuit.',
      },
      {
        title: 'Ghicește Elo',
        lede: 'O partidă cotată reală, derulată mutare cu mutare. Cât de puternici au fost cei doi?',
        body: [
          'A citi nivelul unei partide este aceeași deprindere ca a-ți evalua propriile mutări: ambele se reduc la a observa ce greșeli se fac și ce greșeli nu. Deci partida curge, tu privești, și la un moment dat te angajezi la un număr.',
          'Partidele sunt reale, din arhivele Lichess, cu ambii jucători la mai puțin de 150 de puncte unul de altul — o ghicire despre „jucători” înseamnă ceva doar când e un singur nivel de ghicit.',
        ],
        free: 'Cinci pe zi cu un cont gratuit.',
        stat: 'partide cotate, de la 800 la 2599',
      },
      {
        title: 'Vizionare',
        lede: 'Nouă sute de partide care merită văzute — iar în clipa în care ai fi jucat altfel, preiei tu.',
        body: [
          'Fiecare partidă din bibliotecă este decisivă, între doi jucători cu nume, și fie s-a terminat în douăzeci și cinci de mutări, fie e destul de faimoasă cât să aibă un nume al ei. Nimeni nu învață nimic dintr-o remiză de nouăzeci de mutări între oameni de care n-a auzit niciodată, iar o bibliotecă ce conține așa ceva e o bibliotecă pe care nimeni n-o deschide a doua oară.',
          'Caută un jucător, un turneu sau un an. Apoi parcurge partida în ritmul tău. Nu e vorba de momentele de vârf: e vorba că la o anume mutare vei gândi <em>eu aș fi luat acolo</em> — și în clipa aceea poți. Preia poziția și joacă mai departe împotriva motorului exact de pe câmpul unde n-ai fost de acord. A afla cât a valorat de fapt ideea ta e tot exercițiul.',
        ],
        free: 'Gratuit, nelimitat, întotdeauna.',
        stat: 'partide, toate decisive',
      },
      {
        title: 'Joc cu antrenor',
        lede: 'O partidă întreagă la forța pe care o alegi, cu fiecare mutare a ta evaluată pe parcurs.',
        body: [
          'Pune motorul undeva între 1400 și forță deplină și joacă partida până la capăt. Fiecare mutare a ta e evaluată cât timp partida încă se joacă, iar antrenorul explică ce ar fi obținut mutarea mai bună — în cuvinte despre poziție, nu ca număr.',
          'La final primești acuratețea, numărul de gafe și acel singur moment care a costat cel mai mult.',
        ],
        free: 'Gratuit, nelimitat, întotdeauna.',
      },
      {
        title: 'Online',
        lede: 'Doi oameni, un ceas și niciun motor prin apropiere.',
        body: [
          'Game Center găsește pe cineva care a ales același ritm — 3, 5, 10, 15 sau 30 de minute. E singurul mod fără motor în el: fără indiciu, fără evaluări ale mutărilor, fără antrenare, pentru că ajutorul primit de o singură parte nu e o partidă.',
          'Nu există server. Cele două dispozitive vorbesc între ele și amândouă impun regulile, deci o mutare se joacă doar dacă e legală în poziția pe care dispozitivul care primește o are deja. Un adversar care minte produce un pachet aruncat, nu o tablă ilegală.',
        ],
        free: 'Gratuit, nelimitat, întotdeauna.',
      },
    ],
    watchLink: 'Ce a intrat în bibliotecă și ce nu →',
    pipeline: {
      slug: 'Cum se face o problemă',
      title: 'Extrase, nu copiate.',
      lede: 'Scrierea pozițiilor din memorie riscă o problemă a cărei „soluție” e greșită sau nu e unică, iar asta antrenează exact instinctul greșit. Așa că niciuna nu e scrisă din memorie. Sunt găsite și apoi atacate până supraviețuiesc sau sunt aruncate.',
      steps: [
        {
          title: 'Joc la forță omenească',
          body: 'Stockfish joacă împotriva lui însuși la o forță intenționat omenească — 1320 până la 2500 Elo — deschizând cu o alegere aleatorie dintre cei mai buni candidați superficiali, ca partidele să varieze în loc să repete o singură linie la nesfârșit.',
        },
        {
          title: 'Cernere după însușire, nu după gafă',
          body: 'Fiecare poziție e căutată la adâncimea 12 cu două linii candidate. Semnalul nu e „cineva a greșit grav”, ci ceea ce o problemă chiar cere: o mutare mult mai bună decât orice alternativă.',
        },
        {
          title: 'Căutare adâncă din nou, cu marjă',
          body: 'Supraviețuitorii sunt căutați iar la adâncimea 20 cu MultiPV. Un candidat rămâne doar dacă cea mai bună mutare o bate pe a doua cu cel puțin 140 de sutimi de pion și, în plus, chiar obține ceva.',
        },
        {
          title: 'Prelungire până se ramifică',
          body: 'Soluția e prelungită mutare cu mutare atâta timp cât fiecare mutare a rezolvatorului rămâne unic cea mai bună. În clipa în care sunt două răspunsuri bune, problema se termină acolo — deci nu are niciodată o ramificație pentru care să poți fi socotit greșit.',
        },
        {
          title: 'Verificare cu un motor proaspăt',
          body: 'Întreaga colecție e reexaminată la adâncime mai mare de un script separat, cu un motor nou. Pe colecția extrasă livrată, asta a respins 6 din 172 de probleme ale căror soluții încetau să fie unice cu două semi-mutări mai adânc. Acelea au fost aruncate, nu livrate.',
        },
      ],
    },
    honest: {
      title: 'Și aceeași neîncredere aplicată finalurilor',
      body: [
        'Rezultatul declarat al fiecărui exercițiu de final e verificat printr-o căutare adâncă în loc să fie luat pe cuvânt. Un exercițiu etichetat greșit pică verificarea în loc să te învețe pe tăcute ceva neadevărat.',
        'Verificatorul prinde și ceva ce bibliotecile obișnuite de șah nu-ți spun: dacă partea care nu e la mutare stă în șah. O astfel de poziție e ilegală — nicio partidă n-o poate atinge — dar o bibliotecă o acceptă docil, iar motorul răspunde cu bestmove (none), ceea ce sună a defecțiune de motor, nu a poziție proastă. Trei exerciții scrise de mână erau stricate exact așa. Verificarea prinde asta acum.',
      ],
    },
    limits: {
      slug: 'Limite oneste',
      title: 'Ce nu face asta.',
      items: [
        {
          title: 'Colecția amestecă două scale de rating.',
          body: 'Cele {lichess} probleme Lichess poartă ratinguri calibrate pe milioane de încercări omenești. Cele {mined} probleme extrase local poartă estimări din adâncimea soluției și motiv. Ambele ordonează sensibil, dar un 1600 extras și un 1600 de pe Lichess nu sunt măsurate la fel.',
        },
        {
          title: 'Ratingurile de probleme nu sunt ratinguri de tablă.',
          body: 'Stau cu câteva sute de puncte mai sus și așa vor rămâne. Măsoară progresul față de tine însuți, nu forța într-un câmp de oameni la ceas — {link}, fiindcă decalajul e structural și nu un semn că finalizezi prost.',
        },
        {
          title: 'Nu există antrenament de deschideri.',
          body: 'Intenționat. Studiul deschiderilor e memorare față de un repertoriu pe care ți-l alegi, iar acela e alt instrument, de altă formă. Modul pozițional acoperă ieșirea din deschidere, și tocmai partea aceea se generalizează cu adevărat.',
        },
        {
          title: 'Asta nu te face mare maestru.',
          body: 'Nimic nu face asta de unul singur. Titlurile vin din mii de ore plus partide cotate de turneu împotriva oamenilor. Ce primești aici e jumătatea de antrenament a acestora, structurată, cu o măsură onestă a locului unde stai de fapt.',
        },
      ],
      ratingsLink: 'merită înțeles bine',
    },
    more: {
      motifs: 'Cele douăzeci de motive, definite și numărate →',
      engine: 'Cum e folosit motorul →',
    },
  },

  tactics: {
    head: {
      slug: 'Glosar',
      title: 'Cele douăzeci de motive',
      lede: 'Orice tactică în șah e una dintr-un număr mic de forme, iar de îndată ce le poți numi, le vezi cu o mutare mai devreme. Acestea sunt motivele cu care Brass Pawn își etichetează problemele — fiecare urmat de câte poziții din biblioteca livrată se învârt de fapt în jurul lui.',
      meta: 'Numărate din colecția livrată de 14.351 de probleme · Verificat ultima oară pe 19 august 2026',
    },
    meta: {
      title: 'Cele douăzeci de motive',
      description:
        'Fiecare motiv tactic cu care Brass Pawn își etichetează problemele, definit și numărat față de biblioteca livrată, ca să știi pe care le poți exersa cu adevărat.',
    },
    indexLabel: 'Motivele',
    puzzles: 'probleme',
    motifs: [
      {
        name: 'Furculiță',
        short: 'O piesă atacă două lucruri deodată și numai unul poate fi salvat.',
        body: 'Calul e furculițarul faimos fiindcă atacă câmpuri pe care nicio altă piesă nu le acoperă la fel, dar furculiță face orice: un pion care atinge doi ușori, o damă care atinge un turn și un nebun liber, un rege în final care pășește între doi pioni. Testul nu e „atac două lucruri”, ci „pot scăpa amândouă”.',
      },
      {
        name: 'Legare',
        short: 'O piesă nu se poate mișca fiindcă în spatele ei stă ceva mai valoros.',
        body: 'Absolută când în spate stă regele — mutarea e ilegală, nu doar slabă. Relativă când în spate stă o damă sau un turn, unde mutarea e legală și pur și simplu costă material. Continuarea câștigă: o piesă legată e o piesă care nu poate apăra, deci pune mai mulți atacatori pe ea sau lovește-o cu un pion.',
      },
      {
        name: 'Frigare',
        short: 'Legarea pe dos: piesa valoroasă stă în față și trebuie să se miște.',
        body: 'Dă șah regelui pe o linie cu turn, nebun sau damă, iar ce stătea în spate e al tău de îndată ce regele se dă la o parte. Frigările sunt mai rare decât legările fiindcă au nevoie de două piese deja pe aceeași linie cu cea valoroasă în față — de aceea apar de obicei după ce un șah a împins regele acolo.',
      },
      {
        name: 'Atac descoperit',
        short: 'Mutarea unei piese descoperă atacul celei din spate.',
        body: 'De departe cea mai puternică tactică din șah, fiindcă piesa care pleacă e liberă să facă ceva al ei în timp ce atacul descoperit face treaba. Două amenințări apar dintr-o singură mutare, și niciuna nu se rezolvă luând piesa care a plecat.',
      },
      {
        name: 'Șah descoperit',
        short: 'Atacul descoperit e un șah, deci adversarul n-are timp de altceva.',
        body: 'Un atac descoperit în care piesa din spate dă șah. Orice ar face piesa care pleacă — ia o damă, se așază pe un câmp de mat, se pune în bătaie — răspunsul trebuie să se ocupe întâi de șah, deci totul se întâmplă gratis.',
      },
      {
        name: 'Șah dublu',
        short:
          'Două piese dau șah deodată, deci regele trebuie să se miște. Nu să pareze, nu să ia.',
        body: 'Singura tactică față de care există exact un fel de răspuns legal. Luarea unuia dintre cei care dau șah îl lasă pe celălalt; blocarea unei linii o lasă pe cealaltă deschisă. De aceea șahul dublu produce maturi care par imposibile — apărătorul poate avea cinci feluri de a opri fiecare șah separat și niciunul care să le oprească pe amândouă.',
      },
      {
        name: 'Deviere',
        short: 'Silește un apărător să plece de la treaba pe care o face.',
        body: 'O piesă ține un câmp de mat, o ultimă linie sau altă piesă. Atacă ceva pe care îl prețuiește mai mult, sau pur și simplu ia ceva la care trebuie să reia, iar acoperirea pe care o dădea pleacă odată cu ea. Sacrificiul pare adesea absurd până observi ce nu mai apără piesa care a reluat.',
      },
      {
        name: 'Atragere',
        short: 'Momește o piesă — de obicei regele — pe un câmp unde poate fi atinsă.',
        body: 'Un sacrificiu pe care adversarul e obligat să-l accepte, jucat nu pentru a câștiga material, ci pentru a așeza o piesă fatal: un rege târât pe un câmp de furculiță, o damă trasă pe o linie cu un turn. Materialul se întoarce o mutare mai târziu, cu dobândă.',
      },
      {
        name: 'Eliberare',
        short: 'Scoate-ți propria piesă din calea propriului tău atac.',
        body: 'Linia sau câmpul e cel bun și pe el stă un om de-al tău. Eliberarea îl mută cu tempo — de obicei cu șah sau cu luare, ca adversarul să n-aibă timp să se regrupeze în timp ce drumul se deschide.',
      },
      {
        name: 'Interceptare',
        short: 'Taie linia dintre un apărător și ceea ce apără.',
        body: 'Așază o piesă — adesea sacrificată — exact între un turn și câmpul pe care îl păzește. Apărătorul e încă pe tablă, în teorie tot apără, și nu mai poate. Rar, și unul dintre cele mai greu de văzut tipare, fiindcă piesa care interceptează arată de obicei ca o gafă.',
      },
      {
        name: 'Atac cu raze X',
        short: 'O piesă lucrează prin altă piesă, pe linia pe care o va ocupa mai târziu.',
        body: 'Un turn care își apără propria piesă printr-o piesă inamică, sau atacă prin ea. Încă nu se întâmplă nimic; contează ce se întâmplă când piesa din mijloc pleacă sau e luată. A vedea o rază X e de obicei ceea ce face ca o luare care „pierde material” să nu piardă material.',
      },
      {
        name: 'Mutare intermediară',
        short: 'Mutarea dintre: înainte să reiei, fă ceva mai forțant.',
        body: 'Din germanul „Zwischenzug”, și cel mai frecvent motiv singular pentru care o variantă calculată se dovedește greșită. Aștepți o reluare; în loc de asta vine un șah sau o amenințare mai mare, iar când reluarea se produce, poziția s-a schimbat. Caut-o de fiecare dată când o secvență pare forțată.',
      },
      {
        name: 'Zugzwang',
        short: 'Obligația însăși de a muta e problema.',
        body: 'Orice mutare legală înrăutățește poziția, iar pasul nu e permis. Mai ales o idee de final — decide finalurile de pioni — și motivul pentru care „opoziția” contează: cine trebuie să se dea la o parte primul cedează câmpul. Aproape singura situație din șah în care dreptul de a muta e o povară.',
      },
      {
        name: 'Mat pe ultima linie',
        short: 'Un rege închis de proprii pioni primește mat pe prima linie.',
        body: 'Cel mai frecvent mat între jucători care au rocat și au lăsat pionii în pace. Apare rareori ca mat pe tablă — apare ca amenințare care câștigă material, fiindcă fiecare mutare de apărare trebuie să continue să acopere linia. Toată familia tacticilor de deviere există ca să înlăture acea acoperire.',
      },
      {
        name: 'Mat sufocat',
        short: 'Un cal dă mat unui rege pe care propriile piese l-au închis.',
        body: 'Sfârșitul moștenirii lui Philidor: sacrificiu de damă pe g8, turnul reia, calul de pe f7 dă mat cu regele înconjurat de ai lui. Rar în partidele reale și totuși de știut, fiindcă tiparul e ceea ce te face să te uiți în colț și să numeri câmpurile de scăpare.',
      },
      {
        name: 'Piesă atârnată',
        short: 'Ceva e pur și simplu neapărat și poate fi luat.',
        body: 'Fără strălucire, și decide mai multe partide decât tot restul acestei liste la un loc. Majoritatea înfrângerilor sub 1800 sunt un jucător care ia o piesă gratuită pe care celălalt a pierdut-o din vedere. Obiceiul care vindecă asta e să verifici ce stă liber — la ambele culori — înainte de fiecare mutare.',
      },
      {
        name: 'Piesă prinsă',
        short: 'O piesă n-are niciun câmp sigur și poate fi hăituită pe îndelete.',
        body: 'De obicei un nebun care a luat un pion pe care trebuia să-l lase, sau un cal plecat la pradă. Tactica nu e o singură lovitură, ci o sufocare: ia câmpurile unul câte unul și piesa cade fără să fie nevoie de vreun sacrificiu.',
      },
      {
        name: 'Mutare liniștită',
        short: 'Mutarea câștigătoare nu e nici șah, nici luare, nici amenințare.',
        body: 'Motivul pentru care jucătorii puternici găsesc combinații pe care alții le ratează. După o secvență forțată, răspunsul e o mutare modestă care ia ultimul câmp de scăpare, și e invizibilă pentru cine calculează doar șahuri și luări. Când o poziție pare câștigată și nimic forțant nu merge, caută mutarea liniștită.',
      },
      {
        name: 'Sacrificiu',
        short: 'Dă material pentru ceva ce valorează mai mult decât materialul.',
        body: 'Timp, linii, câmpuri sau poziția regelui advers. Un sacrificiu adevărat nu e un pariu; e un calcul cu un capăt concret. Ce desparte un sacrificiu care merge de unul care nu merge e aproape întotdeauna dacă piesele care apără apucă să se întoarcă.',
      },
      {
        name: 'Pion avansat',
        short: 'Un pion aproape de transformare schimbă cât valorează orice altă piesă.',
        body: 'Un pion pe a șaptea nu e un pion; e o damă pe care ceva trebuie s-o păzească, iar acel ceva nu mai e liber. Majoritatea tacticilor de final sunt de fapt despre tensiunea dintre a opri un pion și a face orice altceva.',
      },
    ],
    after: {
      slug: 'De ce stau aici numerele',
      title: 'Un glosar spune ce e o furculiță. Un număr spune dacă o poți exersa.',
      body: [
        'A ști numele unui tipar și a-l putea găsi sub ceas sunt deprinderi diferite, și numai a doua câștigă partide. Fiecare număr de mai sus e numărul real de poziții din biblioteca livrată etichetate cu acel motiv — nu o estimare și nu rotunjit în sus. Șaizeci de probleme cu raze X sunt șaizeci; dacă tocmai asta e ce ratezi mereu, e bine să știi că nu se termină într-o singură seară.',
        'Antrenorul ține evidența motivelor pe care le greșești, ca după câteva sute de probleme să-ți poată spune nu că ai 1620, ci că ai 1620 și intri iar și iar în devieri.',
      ],
      more: 'Cum sunt extrase și verificate problemele →',
    },
  },
};
