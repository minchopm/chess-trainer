import type { Pages } from './types';

/** The four commercial pages in Spanish. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Soporte',
      title: 'Pregunta a una persona',
      lede: 'No hay sistema de tickets, ni chatbot, ni centro de ayuda con 400 artículos dentro. Hay una dirección de correo y un registro de incidencias, y ambos llegan a la persona que escribió la aplicación.',
    },
    meta: {
      title: 'Soporte',
      description:
        'Cómo llegar a una persona real por Brass Pawn, qué incluir al informar de un ejercicio erróneo, y las preguntas que más se hacen.',
    },
    email: {
      slug: 'Correo',
      body: 'Para cualquier cosa: un fallo, un ejercicio equivocado, una duda sobre una compra o un desacuerdo con una evaluación. Escribe en inglés o en búlgaro.',
    },
    tracker: {
      slug: 'Registro de incidencias',
      name: 'Incidencias en GitHub',
      body: 'Para todo lo que prefieras que sea público — y para todo lo que quieras que otros puedan encontrar después, que es la mayoría de los informes de fallos.',
    },
    report: {
      slug: 'Si un ejercicio está mal',
      title: 'Manda cuatro cosas y se puede comprobar en un minuto.',
      checklist: [
        'El FEN que aparece en la pantalla del ejercicio — mantén pulsado para copiarlo.',
        'La jugada que hiciste, y la jugada que la aplicación dio por buena.',
        'En qué modo estabas.',
        'La versión de la aplicación, desde la pantalla de información.',
      ],
      caveat:
        'Los ejercicios sí discrepan de vez en cuando con una búsqueda más profunda, y las discrepancias se agrupan en posiciones largas, tranquilas y de valoración alta cuya idea está más honda de lo que llegó la verificación. Eso es un límite de la comprobación, no un defecto del ejercicio — pero vale la pena saber cuáles son, y la única manera de saberlo es que lo digas.',
    },
    faq: { slug: 'Preguntas', title: 'Hechas lo bastante a menudo como para escribirlas.' },
    more: {
      ratings: 'Qué mide una valoración',
      tactics: 'Los motivos',
      privacy: 'Política de privacidad',
      terms: 'Términos del servicio',
      licences: 'Licencias',
    },
  },

  pricing: {
    head: {
      slug: 'Lo que cuesta',
      title: 'Jugar es gratis. El entrenamiento se vende.',
      lede: 'Ajedrez contra el motor y ajedrez contra una persona, sin límite, sin publicidad en ninguna parte de la aplicación — eso es gratis y seguirá siéndolo. Lo que se vende es la biblioteca, los ejercicios, las prácticas y la carrera contra el reloj.',
    },
    meta: {
      title: 'Precios',
      description:
        'Jugar es gratis e ilimitado — el motor, un rival de verdad y las 900 partidas. Pro levanta el límite de cinco al día: 3,99 dólares al mes o 49,99 una sola vez.',
    },
    free: {
      name: 'Gratis',
      note: 'Sin cuenta. Nada que registrar.',
      items: [
        'Juego ilimitado contra el motor, de 1400 a fuerza máxima',
        'Partidas en línea ilimitadas por Game Center',
        'Comentario jugada a jugada en cada partida que juegas',
        'Cinco ejercicios tácticos al día',
        'Cinco carreras de Rush al día',
        'Cinco de cada: posicional, final, Adivina el Elo',
        'Valoraciones, rachas y repetición espaciada, completas',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Mensual',
      per: 'al mes',
      note: 'Cancela cuando quieras en los ajustes de tu cuenta de Apple.',
      items: [
        'Todos los límites diarios eliminados',
        'Los {tactics} ejercicios tácticos',
        'Los {positional} ejercicios posicionales',
        'Los {endgames} ejercicios de finales',
        'Las {games} partidas para valorar',
        'Rush sin límite',
        'Todo lo de Gratis, sin cambios',
      ],
    },
    lifetime: {
      name: 'Desbloqueo único',
      once: 'una vez',
      note: 'Una compra no consumible. No se renueva.',
      items: [
        'Exactamente lo mismo que Pro mensual',
        'Sin renovación, sin caducidad, sin correos recordatorios',
        'Se restaura en tus otros dispositivos',
        'Para quien prefiere decidir una sola vez',
      ],
    },
    table: {
      slug: 'La asignación completa',
      title: 'Lo que el plan gratuito da de verdad.',
      activity: 'Actividad',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Sin límite',
      fiveADay: '5 al día',
      none: 'Ninguna',
      rows: [
        'Jugar contra el motor',
        'Partidas en línea por Game Center',
        'Ver — la biblioteca de 900 partidas',
        'Ejercicios tácticos',
        'Carreras de Rush',
        'Ejercicios posicionales',
        'Ejercicios de finales',
        'Adivina el Elo',
        'Publicidad',
      ],
      reset:
        'Las asignaciones diarias se reinician a las nueve de la mañana, hora local — no a medianoche, para que una sesión de tarde no quede partida en dos por un cambio de fecha.',
    },
    why: {
      slug: 'Por qué tiene esta forma',
      title: 'Tres decisiones, y la razón de cada una.',
      reasons: [
        {
          title: 'Contado, no cerrado',
          body: [
            'Nadie paga por un entrenador que no ha usado, y un modo que se niega a abrirse no enseña nada de lo que hay detrás. Así que todos los modos se abren, todos los días, y entras lo bastante como para sentir el ritmo y ver moverse la valoración.',
            'El muro de pago no aparece nunca al arrancar. Cuando la asignación del día se agota, la pantalla lo dice, y solo un toque deliberado abre la hoja de compra.',
          ],
        },
        {
          title: 'Dos precios, no tres',
          body: [
            'No hay plan anual en medio, porque un tercer precio es una tercera decisión justo en el momento en que alguien quiere resolver un ejercicio. Mensual si no lo tienes claro. Único si sí.',
          ],
        },
        {
          title: 'Jugar nunca se vende',
          body: [
            'El ajedrez contra el motor y contra una persona no cuestan nada de mantener y son la razón de que la aplicación exista. Venderlos la convertiría en una aplicación de ajedrez con peaje en vez de un entrenador.',
            'Y no hay publicidad — en parte por gusto, en parte por licencia. La aplicación enlaza dos motores copyleft, Stockfish bajo GPLv3 y Reckless bajo AGPLv3, y un SDK publicitario propietario en el mismo binario haría todo el conjunto indistribuible. {link}',
          ],
        },
      ],
      licenceLink: 'La página de licencias lo explica como es debido.',
    },
    answers: {
      slug: 'Comprar, cancelar, devoluciones',
      title: 'Las preguntas incómodas, respondidas aquí y no en un correo.',
      items: [
        {
          q: '¿Cómo cancelo?',
          a: 'Ajustes → tu nombre → Suscripciones → Brass Pawn. No podemos cancelarla por ti, porque la suscripción es entre tú y Apple y nunca estuvo en nuestras manos. Cancelar detiene las renovaciones futuras y no acorta el periodo que ya has pagado.',
        },
        {
          q: '¿Cómo consigo un reembolso?',
          a: 'A través de Apple, en {link}. No podemos emitir reembolsos por compras del App Store. Si algo está roto, escríbenos — preferimos arreglarlo.',
        },
        {
          q: 'Compré el desbloqueo y tengo un teléfono nuevo.',
          a: 'Inicia sesión con la misma cuenta de Apple y toca «Restaurar compras» en la pantalla de compra. La aplicación le pregunta a StoreKit qué posees; no hay nada guardado en un servidor nuestro porque no hay servidor nuestro.',
        },
        {
          q: '¿Pro cambia mi valoración o desbloquea ejercicios «mejores»?',
          a: 'No. El sistema de valoración es idéntico y todos los ejercicios de la biblioteca son accesibles con una cuenta gratuita — cinco al día. Pro quita el contador, no una cortina.',
        },
        {
          q: '¿Se reducirá la asignación gratuita más adelante?',
          a: 'Puede cambiar en cualquier dirección conforme crezca la biblioteca. El juego ilimitado contra el motor y contra una persona no se convertirá en función de pago; eso está escrito en los {link} y no solo prometido aquí.',
        },
      ],
      termsLink: 'Términos',
      more: 'Más preguntas, y cómo llegar a una persona →',
    },
  },

  training: {
    head: {
      slug: 'El programa',
      title: 'Ocho maneras de que te digan la verdad',
      lede: 'Tres de ellas son gratis e ilimitadas para siempre — jugar, jugar contra otra persona y las novecientas partidas de Ver. Las otras cinco son cinco al día con una cuenta gratuita e ilimitadas con Pro. Cada una te califica con palabras sobre la posición en vez de con un número que tengas que interpretar.',
    },
    meta: {
      title: 'Entrenamiento',
      description:
        'Ocho modos: táctica, juicio posicional, finales, Rush, Adivina el Elo, Ver, juego con entrenador y en línea. Cómo funciona cada uno, cómo se extraen y verifican los ejercicios, y qué no hace el entrenador.',
    },
    modes: [
      {
        title: 'Táctica',
        lede: 'Posiciones con exactamente una jugada ganadora, y un veredicto en el momento en que la haces.',
        body: [
          'Cada ejercicio tiene una respuesta y ninguna ramificación. Hazla en el tablero y el entrenador te dice al instante si la encontraste; si la fallas, la posición vuelve mañana, luego a los cuatro días, luego a los diez — mientras te siga pillando.',
          'Cada ejercicio lleva la etiqueta del motivo sobre el que gira — horquilla, clavada, enfilada, mate del pasillo, desviación, la jugada tranquila — así que tras unos cuantos cientos el entrenador puede decirte no que eres 1620, sino que eres 1620 y sigues pasando de largo ante las desviaciones.',
        ],
        free: 'Cinco al día con una cuenta gratuita.',
        stat: 'ejercicios, valorados de 760 a 2800',
      },
      {
        title: 'Juicio posicional',
        lede: 'No existe ganancia forzada. Di quién está mejor, y luego encuentra la jugada que explica por qué.',
        body: [
          'Este es el modo hecho para lo que separa a los jugadores fuertes de los buenos calculadores. Primero valoras: claramente mejor, algo mejor, igualado. Después eliges una jugada. Se califican ambas respuestas.',
          'La respuesta nombra rasgos concretos en vez de estados de ánimo — la columna abierta y si hay una torre en ella, el puesto avanzado del caballo que ningún peón puede discutir, la estructura de peones, la seguridad del rey, la diferencia en actividad de las piezas. Una posición no es «cómoda para las blancas»; es mejor por cuatro cosas que puedes enumerar.',
        ],
        free: 'Cinco al día con una cuenta gratuita.',
        stat: 'posiciones tranquilas, cribadas por el motor',
      },
      {
        title: 'Finales',
        lede: 'Posiciones canónicas, jugadas hasta el final contra un motor que defiende como es debido.',
        body: [
          'Conocer la idea no es lo mismo que convertirla, así que aquí tienes que lograr el resultado de verdad. Stockfish toma el otro bando y opone la mejor defensa que existe.',
          'Tras cada jugada el entrenador vuelve a comprobar si el resultado sigue siendo alcanzable — y si no lo es, te dice la jugada exacta en la que dejó de serlo. Esa es la frase que enseña: no «has hecho tablas», sino «has hecho tablas aquí».',
        ],
        free: 'Cinco al día con una cuenta gratuita.',
        stat: 'ejercicios, cada resultado verificado por el motor',
      },
      {
        title: 'Rush',
        lede: 'Una carrera cronometrada. Resuelve cuantos puedas antes de que el reloj se lleve el resto.',
        body: [
          'Los mismos ejercicios, contra reloj, con la dificultad subiendo mientras sigas acertando. Entrena un músculo distinto del de un ejercicio que puedes mirar fijamente: el que tiene que verlo ahora.',
          'Las carreras se puntúan y se guardan, así que el número sube a lo largo de meses en vez de a lo largo de una tarde.',
        ],
        free: 'Cinco carreras al día con una cuenta gratuita.',
      },
      {
        title: 'Adivina el Elo',
        lede: 'Una partida valorada real, jugada movimiento a movimiento. ¿Cómo de fuertes eran estos dos?',
        body: [
          'Leer el nivel de una partida es la misma habilidad que juzgar tus propias jugadas: ambas se reducen a notar qué errores se cometen y cuáles no. Así que la partida corre, tú miras, y en algún momento te comprometes con un número.',
          'Las partidas son reales, de los archivos de Lichess, con los dos jugadores dentro de 150 puntos el uno del otro — una conjetura sobre «los jugadores» solo significa algo cuando hay un nivel que adivinar.',
        ],
        free: 'Cinco al día con una cuenta gratuita.',
        stat: 'partidas valoradas, de 800 a 2599',
      },
      {
        title: 'Ver',
        lede: 'Novecientas partidas que vale la pena ver — y en el momento en que hubieras jugado otra cosa, tómala.',
        body: [
          'Todas las partidas de la biblioteca son decisivas, entre dos jugadores con nombre, y o bien acabaron antes del movimiento veinticinco o son lo bastante célebres como para tener nombre propio. Nadie aprende nada de unas tablas de noventa jugadas entre gente de la que no ha oído hablar, y una biblioteca que las incluye es una biblioteca que nadie abre dos veces.',
          'Busca un jugador, un torneo o un año. Luego juega la partida a tu ritmo. La gracia no es el resumen de lo mejor: es que en alguna jugada pensarás <em>yo habría capturado ahí</em> — y en ese momento puedes. Toma la posición y sigue contra el motor desde exactamente la casilla en la que discrepaste. Averiguar cuánto valía tu idea es todo el ejercicio.',
        ],
        free: 'Gratis, sin límite, siempre.',
        stat: 'partidas, todas decisivas',
      },
      {
        title: 'Jugar y entrenar',
        lede: 'Una partida entera a la fuerza que elijas, con cada jugada tuya calificada mientras juegas.',
        body: [
          'Pon el motor en cualquier punto entre 1400 y la fuerza máxima y juega la partida. Cada una de tus jugadas se califica mientras la partida sigue viva, y el entrenador explica qué habría conseguido la jugada mejor — con palabras sobre la posición, no con un número.',
          'Al final obtienes precisión, número de errores graves y el único momento que más te costó.',
        ],
        free: 'Gratis, sin límite, siempre.',
      },
      {
        title: 'En línea',
        lede: 'Dos personas, un reloj y ningún motor cerca.',
        body: [
          'Game Center te encuentra a alguien que eligió el mismo ritmo — 3, 5, 10, 15 o 30 minutos. Es el único modo sin motor dentro: sin pistas, sin valores de jugada, sin entrenador, porque una ayuda que solo recibe un bando no es una partida.',
          'No hay servidor. Los dos dispositivos hablan entre sí y ambos aplican las reglas, así que una jugada solo se realiza si es legal en la posición que el dispositivo receptor ya tiene. Un par que miente produce un paquete descartado, no un tablero ilegal.',
        ],
        free: 'Gratis, sin límite, siempre.',
      },
    ],
    watchLink: 'Qué entró en la biblioteca y qué no →',
    pipeline: {
      slug: 'Cómo se hace un ejercicio',
      title: 'Extraídos, no transcritos.',
      lede: 'Anotar posiciones de memoria arriesga publicar un ejercicio cuya «solución» es errónea o no es única, y eso entrena justo el instinto equivocado. Así que ninguno está anotado de memoria. Se encuentran, y después se atacan hasta que sobreviven o se tiran.',
      steps: [
        {
          title: 'Jugar, a fuerza humana',
          body: 'Stockfish juega contra sí mismo a una fuerza deliberadamente parecida a la humana — de 1320 a 2500 Elo — abriendo con una elección al azar entre sus mejores candidatas poco profundas, para que las partidas varíen en vez de repetir una línea eternamente.',
        },
        {
          title: 'Cribar por la propiedad, no por el error garrafal',
          body: 'Cada posición se busca a profundidad 12 con dos líneas candidatas. La señal no es «alguien la ha pifiado» sino lo que un ejercicio necesita de verdad: que una jugada sea muy superior a cualquier alternativa.',
        },
        {
          title: 'Volver a buscar en profundidad, con margen',
          body: 'Las supervivientes se buscan otra vez a profundidad 20 con MultiPV. Una candidata se conserva solo si la mejor jugada supera a la segunda por al menos 140 centipeones y además consigue algo.',
        },
        {
          title: 'Extender hasta que se ramifique',
          body: 'La solución se extiende jugada a jugada mientras cada movimiento del solucionador siga siendo el único mejor. En el instante en que hay dos buenas respuestas, el ejercicio termina ahí — así que nunca tiene una ramificación por la que puedan darte por equivocado.',
        },
        {
          title: 'Verificar con un motor nuevo',
          body: 'Todo el conjunto se vuelve a comprobar a mayor profundidad con un script aparte y una instancia nueva del motor. Sobre el conjunto extraído incluido, eso rechazó 6 de 172 ejercicios cuyas soluciones dejaban de ser únicas dos medias jugadas más abajo. Se descartaron en vez de publicarse.',
        },
      ],
    },
    honest: {
      title: 'Y la misma sospecha aplicada a los finales',
      body: [
        'El resultado declarado de cada ejercicio de finales se comprueba contra una búsqueda profunda en vez de darse por bueno. Un ejercicio mal etiquetado suspende la comprobación en lugar de enseñarte algo falso en silencio.',
        'El verificador también detecta algo que las bibliotecas de ajedrez habituales no te dirán: si el bando que no está en juego está en jaque. Una posición así es ilegal — ninguna partida puede alcanzarla — pero una biblioteca la acepta encantada, y el motor responde con bestmove (none), que suena a fallo del motor y no a mala posición. Tres ejercicios escritos a mano estaban mal exactamente así. La comprobación ya lo detecta.',
      ],
    },
    limits: {
      slug: 'Límites honestos',
      title: 'Lo que esto no hace.',
      items: [
        {
          title: 'El conjunto mezcla dos escalas de valoración.',
          body: 'Los {lichess} ejercicios de Lichess llevan valoraciones calibradas contra millones de intentos humanos. Los {mined} extraídos localmente llevan estimaciones derivadas de la profundidad de la solución y del motivo. Ambas ordenan con sentido, pero un 1600 extraído y un 1600 de Lichess no se miden igual.',
        },
        {
          title: 'Las valoraciones de ejercicios no son valoraciones de tablero.',
          body: 'Van varios cientos de puntos más altas, y siempre irán. Miden progreso contra ti mismo, no fuerza contra un campo de humanos con reloj — {link}, porque la diferencia es estructural y no señal de que conviertas mal.',
        },
        {
          title: 'No hay entrenamiento de aperturas.',
          body: 'Deliberadamente. El estudio de aperturas es memorización contra un repertorio que tú eliges, y eso es otra herramienta con otra forma. El modo posicional cubre la transición al salir de la apertura, que es la parte que sí se generaliza.',
        },
        {
          title: 'Esto no te hará gran maestro.',
          body: 'Nada lo hace por sí solo. Los títulos vienen de miles de horas más partidas de torneo valoradas contra humanos. Lo que esto te da es la mitad de entrenamiento de eso, estructurada, con una medida honesta de dónde estás realmente.',
        },
      ],
      ratingsLink: 'lo cual vale la pena entender como es debido',
    },
    more: {
      motifs: 'Los veinte motivos, definidos y contados →',
      engine: 'Cómo se usa el motor →',
    },
  },

  tactics: {
    head: {
      slug: 'Glosario',
      title: 'Los veinte motivos',
      lede: 'Toda táctica en ajedrez es una de un número pequeño de formas, y en cuanto sabes nombrarlas empiezas a verlas una jugada antes. Estos son los que Brass Pawn usa para etiquetar sus ejercicios — cada uno seguido de cuántas posiciones de la biblioteca incluida giran realmente sobre él.',
      meta: 'Contados sobre el conjunto incluido de 14.351 ejercicios · Última revisión 19 de agosto de 2026',
    },
    meta: {
      title: 'Los veinte motivos',
      description:
        'Todos los motivos tácticos con que Brass Pawn etiqueta sus ejercicios, definidos y contados contra la biblioteca incluida para que sepas cuáles puedes practicar de verdad.',
    },
    indexLabel: 'Los motivos',
    puzzles: 'ejercicios',
    motifs: [
      {
        name: 'Horquilla',
        short: 'Una pieza ataca dos cosas a la vez, y solo una puede salvarse.',
        body: 'El caballo es el horquillador célebre porque ataca casillas que ninguna otra pieza defiende del mismo modo, pero horquillan todas: un peón golpeando dos piezas menores, una dama golpeando torre y alfil suelto, un rey en el final metiéndose entre dos peones. La prueba no es «¿estoy atacando dos cosas?» sino «¿pueden escapar las dos?».',
      },
      {
        name: 'Clavada',
        short: 'Una pieza no puede moverse porque detrás hay algo más valioso.',
        body: 'Absoluta cuando detrás está el rey — moverse es ilegal, no solo malo. Relativa cuando detrás hay dama o torre, donde moverse es legal y simplemente pierde material. La continuación es lo que gana: una pieza clavada es una pieza que no puede defender, así que amontona más atacantes sobre ella, o golpéala con un peón.',
      },
      {
        name: 'Enfilada',
        short: 'Una clavada al revés: la pieza valiosa va delante y tiene que moverse.',
        body: 'Da jaque al rey en una línea con torre, alfil o dama, y lo que estuviera detrás es tuyo en cuanto el rey se aparta. Las enfiladas son más raras que las clavadas porque necesitan las dos piezas ya alineadas con la valiosa delante — por eso suelen aparecer después de que un jaque haya forzado al rey a la línea.',
      },
      {
        name: 'Ataque a la descubierta',
        short: 'Mover una pieza destapa el ataque de la que estaba detrás.',
        body: 'La táctica más fuerte del ajedrez por mucho, porque la pieza que se mueve queda libre para hacer algo suyo mientras el ataque que descubre hace el trabajo. Aparecen dos amenazas en una jugada y ninguna se responde capturando la pieza que se movió.',
      },
      {
        name: 'Jaque a la descubierta',
        short: 'El ataque destapado es un jaque, así que el rival no tiene tiempo para nada más.',
        body: 'Un ataque a la descubierta en el que la pieza de detrás da jaque. Haga lo que haga la pieza que se mueve — llevarse una dama, ir a una casilla de mate, ponerse en toma — la respuesta debe atender primero al jaque, así que sale gratis.',
      },
      {
        name: 'Jaque doble',
        short: 'Dos piezas dan jaque a la vez, así que el rey debe moverse. Ni tapar, ni capturar.',
        body: 'La única táctica contra la que existe exactamente una clase de respuesta legal. Capturar a uno de los que dan jaque deja al otro; tapar una línea deja la otra. Por eso el jaque doble entrega mates que parecen imposibles — el defensor puede tener cinco maneras de parar cada jaque por separado y ninguna que pare ambos.',
      },
      {
        name: 'Desviación',
        short: 'Fuerza a un defensor a abandonar el trabajo que está haciendo.',
        body: 'Una pieza sostiene una casilla de mate, una primera fila u otra pieza. Ataca algo que valore más, o simplemente llévate algo que deba recapturar, y la defensa que prestaba desaparece con ella. A menudo el sacrificio parece absurdo hasta que reparas en lo que deja de cubrir la pieza que recaptura.',
      },
      {
        name: 'Atracción',
        short: 'Atrae una pieza — normalmente el rey — a una casilla donde pueda ser golpeada.',
        body: 'También llamada señuelo. Un sacrificio que el rival está obligado a aceptar, jugado no para ganar material sino para poner una pieza en un sitio fatal: un rey arrastrado a una casilla de horquilla, una dama tirada a una línea con torre. El material vuelve con intereses una jugada después.',
      },
      {
        name: 'Despeje',
        short: 'Quita tu propia pieza de en medio de tu propio ataque.',
        body: 'La línea o la casilla es la buena y hay un hombre tuyo encima. El despeje lo mueve con tempo — normalmente con jaque o captura, para que el rival no tenga tiempo de reorganizarse mientras se abre el camino.',
      },
      {
        name: 'Interferencia',
        short: 'Corta la línea entre un defensor y lo que defiende.',
        body: 'Pon una pieza — a menudo sacrificada — justo entre una torre y la casilla que vigila. El defensor sigue en el tablero, sigue defendiendo en teoría, y ya no puede. Rara, y uno de los patrones más difíciles de ver, porque la pieza que interfiere suele parecer un error garrafal.',
      },
      {
        name: 'Rayos X',
        short: 'Una pieza actúa a través de otra, por la línea que ocupará más tarde.',
        body: 'Una torre defendiendo su propia pieza a través de una enemiga, o atacando a través de ella. Todavía no pasa nada; lo que importa es lo que ocurre en cuanto la pieza de en medio se mueve o cae. Reconocer unos rayos X suele ser lo que hace que una captura que «pierde material» no lo pierda.',
      },
      {
        name: 'Jugada intermedia',
        short: 'El zwischenzug: antes de recapturar, haz algo más forzado.',
        body: 'Del alemán «jugada intermedia», y la razón única más frecuente de que una línea calculada resulte errónea. Esperas una recaptura; en su lugar llega un jaque, o una amenaza mayor, y para cuando ocurre la recaptura la posición ha cambiado. Busca una cada vez que una secuencia parezca forzada.',
      },
      {
        name: 'Zugzwang',
        short: 'Tener que mover es en sí mismo el problema.',
        body: 'Toda jugada legal empeora la posición, y pasar no está permitido. Sobre todo una idea de finales — los finales de rey y peones se deciden por ella — y la razón de que «la oposición» importe: quien está obligado a apartarse primero pierde la casilla. Casi la única situación en ajedrez en la que el derecho a mover es una carga.',
      },
      {
        name: 'Mate del pasillo',
        short: 'Un rey encerrado por sus propios peones, mateado en la primera fila.',
        body: 'El mate más común entre jugadores que han enrocado y han dejado los peones quietos. Rara vez aparece como mate en el tablero — aparece como amenaza que gana material, porque toda jugada defensiva tiene que seguir guardando la fila. Toda la familia de tácticas de desviación existe para quitar esa guardia.',
      },
      {
        name: 'Mate de la coz',
        short: 'Un caballo matea a un rey al que sus propias piezas han encerrado.',
        body: 'El final del legado de Philidor: sacrificio de dama en g8, la torre recaptura, el caballo en f7 da mate con el rey rodeado de los suyos. Raro en partidas reales y merece saberse igualmente, porque el patrón es lo que te hace mirar una esquina y contar casillas de escape.',
      },
      {
        name: 'Pieza colgada',
        short: 'Algo está sencillamente indefenso y se puede tomar.',
        body: 'Nada glamuroso, y decide más partidas que todo lo demás de esta lista junto. La mayoría de las derrotas por debajo de 1800 son un jugador llevándose una pieza gratis que el otro dejó de mirar. El hábito que lo arregla es comprobar qué está suelto — en los dos colores — antes de cada jugada.',
      },
      {
        name: 'Pieza atrapada',
        short: 'Una pieza no tiene casilla segura y se la puede cazar con calma.',
        body: 'Normalmente un alfil que tomó un peón que debió dejar, o un caballo que se fue de correría. La táctica no es un golpe único sino un estrangulamiento: le quitas las casillas una a una y la pieza cae sin necesidad de sacrificio.',
      },
      {
        name: 'Jugada tranquila',
        short: 'La jugada ganadora no es jaque, ni captura, ni amenaza.',
        body: 'La razón de que los jugadores fuertes encuentren combinaciones que otros no ven. Tras una secuencia forzada, la respuesta es una jugada modesta que quita la última casilla de escape, y resulta invisible para quien solo calcula jaques y capturas. Si una posición parece ganada y nada forzado funciona, busca la tranquila.',
      },
      {
        name: 'Sacrificio',
        short: 'Da material por algo que vale más que material.',
        body: 'Tiempo, líneas, casillas o la posición del rey enemigo. Un sacrificio de verdad no es una apuesta; es un cálculo cuyo final es concreto. Lo que separa uno que funciona de otro que no es casi siempre si las piezas defensoras pueden volver a tiempo.',
      },
      {
        name: 'Peón avanzado',
        short: 'Un peón cerca de coronar cambia lo que vale cualquier otra pieza.',
        body: 'Un peón en séptima no es un peón; es una dama que alguien tiene que vigilar, y ese alguien ya no está libre. La mayoría de las tácticas de final tratan en realidad de la tensión entre parar un peón y hacer cualquier otra cosa.',
      },
    ],
    after: {
      slug: 'Por qué están aquí los números',
      title: 'Un glosario te dice qué es una horquilla. Un número te dice si puedes practicarla.',
      body: [
        'Saber el nombre de un patrón y ser capaz de encontrarlo bajo el reloj son habilidades distintas, y solo la segunda gana partidas. Cada cuenta de arriba es el número real de posiciones de la biblioteca incluida etiquetadas con ese motivo — no una estimación, y sin redondear al alza. Sesenta ejercicios de rayos X son sesenta; si eso es lo que sigues fallando, vale la pena saber que no se te acabarán en una tarde.',
        'El entrenador lleva la cuenta de qué motivos fallas, así que tras unos cuantos cientos de ejercicios puede decirte no que eres 1620, sino que eres 1620 y sigues pasando de largo ante las desviaciones.',
      ],
      more: 'Cómo se extraen y verifican los ejercicios →',
    },
  },
};
