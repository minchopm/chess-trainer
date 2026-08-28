import type { Pages } from './types';

/** The four commercial pages in French. Vouvoiement, as the app addresses its player. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Assistance',
      title: 'Demandez à quelqu’un',
      lede: 'Il n’y a pas de système de tickets, pas de robot de discussion et pas de centre d’aide avec 400 articles dedans. Il y a une adresse e-mail et un suivi d’anomalies, et les deux atteignent la personne qui a écrit l’application.',
    },
    meta: {
      title: 'Assistance',
      description:
        'Comment joindre un être humain au sujet de Brass Pawn, quoi joindre en signalant un exercice erroné, et les questions qui reviennent le plus.',
    },
    email: {
      slug: 'E-mail',
      body: 'Pour tout : une anomalie, un exercice faux, une question sur un achat, ou un désaccord avec une évaluation. Écrivez en anglais ou en bulgare.',
    },
    tracker: {
      slug: 'Suivi d’anomalies',
      name: 'Tickets GitHub',
      body: 'Pour tout ce que vous préféreriez voir public — et pour tout ce que vous voulez que d’autres puissent retrouver ensuite, ce qui est le cas de la plupart des rapports d’anomalie.',
    },
    report: {
      slug: 'Si un exercice est faux',
      title: 'Envoyez quatre choses et cela se vérifie en une minute.',
      checklist: [
        'La FEN affichée sur l’écran de l’exercice — appuyez longuement pour la copier.',
        'Le coup que vous avez joué, et celui que l’application a donné pour juste.',
        'Dans quel mode vous étiez.',
        'La version de l’application, depuis l’écran À propos.',
      ],
      caveat:
        'Les exercices contredisent parfois une recherche plus profonde, et les contradictions se concentrent sur des positions longues, calmes et haut cotées dont la pointe est plus profonde que ce qu’a exploré la vérification. C’est une limite du contrôle et non un défaut de l’exercice — mais il vaut la peine de savoir lesquels, et le seul moyen de le savoir est que vous le disiez.',
    },
    faq: { slug: 'Questions', title: 'Posées assez souvent pour être écrites.' },
    more: {
      ratings: 'Ce que mesure un classement',
      tactics: 'Les motifs',
      privacy: 'Politique de confidentialité',
      terms: 'Conditions d’utilisation',
      licences: 'Licences',
    },
  },

  pricing: {
    head: {
      slug: 'Ce que cela coûte',
      title: 'Jouer est gratuit. L’entraînement se vend.',
      lede: 'Les échecs contre le moteur et les échecs contre une personne, sans limite, sans publicité nulle part dans l’application — c’est gratuit et cela le reste. Ce qui se vend, c’est la bibliothèque, les exercices, les problèmes et la course contre la montre.',
    },
    meta: {
      title: 'Tarifs',
      description:
        'Jouer est gratuit et sans limite — le moteur, un adversaire réel et les 900 parties. Pro lève la limite de cinq par jour : 3,99 $ par mois ou 49,99 $ une fois.',
    },
    free: {
      name: 'Gratuit',
      note: 'Pas de compte. Rien à créer.',
      items: [
        'Jeu illimité contre le moteur, de 1400 à pleine force',
        'Parties en ligne illimitées via Game Center',
        'Un commentaire coup par coup dans chaque partie que vous jouez',
        'Cinq exercices tactiques par jour',
        'Cinq courses Rush par jour',
        'Cinq de chaque : positionnel, finale, Devinez l’Elo',
        'Classements, séries et répétition espacée, au complet',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Mensuel',
      per: 'par mois',
      note: 'Résiliable à tout moment dans les réglages de votre compte Apple.',
      items: [
        'Toutes les limites quotidiennes levées',
        'Les {tactics} exercices tactiques',
        'Les {positional} exercices positionnels',
        'Les {endgames} exercices de finale',
        'Les {games} parties à évaluer',
        'Rush sans limite',
        'Tout ce que contient Gratuit, inchangé',
      ],
    },
    lifetime: {
      name: 'Déverrouillage unique',
      once: 'une fois',
      note: 'Un achat non consommable. Il ne se renouvelle pas.',
      items: [
        'Exactement la même chose que Pro mensuel',
        'Pas de renouvellement, pas d’expiration, pas d’e-mails de rappel',
        'Se restaure sur vos autres appareils',
        'Pour ceux qui préfèrent décider une seule fois',
      ],
    },
    table: {
      slug: 'Le quota complet',
      title: 'Ce que la formule gratuite donne réellement.',
      activity: 'Activité',
      freeCol: 'Gratuit',
      proCol: 'Pro',
      unlimited: 'Sans limite',
      fiveADay: '5 par jour',
      none: 'Aucune',
      rows: [
        'Jouer contre le moteur',
        'Parties en ligne via Game Center',
        'Regarder — la bibliothèque de 900 parties',
        'Exercices tactiques',
        'Courses Rush',
        'Exercices positionnels',
        'Exercices de finale',
        'Devinez l’Elo',
        'Publicité',
      ],
      reset:
        'Les quotas quotidiens se réinitialisent à neuf heures du matin, heure locale — pas à minuit, pour qu’une séance du soir ne soit pas coupée en deux par un changement de date.',
    },
    why: {
      slug: 'Pourquoi c’est fait ainsi',
      title: 'Trois décisions, et la raison de chacune.',
      reasons: [
        {
          title: 'Compté, pas verrouillé',
          body: [
            'Personne ne paie pour un entraîneur qu’il n’a pas utilisé, et un mode qui refuse de s’ouvrir n’apprend rien de ce qu’il y a derrière. Alors chaque mode s’ouvre, chaque jour, et vous entrez assez loin pour sentir le rythme et voir le classement bouger.',
            'Le mur payant n’apparaît jamais au lancement. Quand le quota du jour est épuisé, l’écran le dit, et seule une touche délibérée ouvre la feuille d’achat.',
          ],
        },
        {
          title: 'Deux prix, pas trois',
          body: [
            'Il n’y a pas de formule annuelle entre les deux, parce qu’un troisième prix est une troisième décision au moment précis où quelqu’un veut résoudre un exercice. Mensuel si vous hésitez. Unique si vous n’hésitez pas.',
          ],
        },
        {
          title: 'Jouer ne se vend jamais',
          body: [
            'Les échecs contre le moteur et contre une personne ne coûtent rien à faire tourner et sont la raison d’être de l’application. Les vendre en ferait une application d’échecs avec un péage plutôt qu’un entraîneur.',
            'Et il n’y a pas de publicité — en partie par goût, en partie par licence. L’application lie deux moteurs copyleft, Stockfish sous GPLv3 et Reckless sous AGPLv3, et un SDK publicitaire propriétaire dans le même binaire rendrait l’ensemble non distribuable. {link}',
          ],
        },
      ],
      licenceLink: 'La page des licences l’explique comme il faut.',
    },
    answers: {
      slug: 'Acheter, résilier, se faire rembourser',
      title: 'Les questions gênantes, traitées ici plutôt que par e-mail.',
      items: [
        {
          q: 'Comment je résilie ?',
          a: 'Réglages → votre nom → Abonnements → Brass Pawn. Nous ne pouvons pas le résilier à votre place, parce que l’abonnement est entre vous et Apple et n’a jamais été chez nous. Résilier arrête les renouvellements à venir et ne raccourcit pas la période déjà payée.',
        },
        {
          q: 'Comment je me fais rembourser ?',
          a: 'Par Apple, sur {link}. Nous ne pouvons pas rembourser des achats de l’App Store. Si quelque chose est cassé, écrivez-nous — nous préférons le réparer.',
        },
        {
          q: 'J’ai acheté le déverrouillage et j’ai changé de téléphone.',
          a: 'Connectez-vous avec le même compte Apple et touchez « Restaurer les achats » sur l’écran d’achat. L’application demande à StoreKit ce que vous possédez ; rien n’est stocké sur un serveur à nous, parce qu’il n’y a pas de serveur à nous.',
        },
        {
          q: 'Pro change-t-il mon classement ou débloque-t-il de « meilleurs » exercices ?',
          a: 'Non. Le système de classement est identique et chaque exercice de la bibliothèque est atteignable avec un compte gratuit — cinq par jour. Pro retire le compteur, pas un rideau.',
        },
        {
          q: 'Le quota gratuit va-t-il diminuer plus tard ?',
          a: 'Il peut évoluer dans les deux sens à mesure que la bibliothèque grandit. Le jeu illimité contre le moteur et contre une personne ne deviendra pas payant ; c’est écrit dans les {link} et pas seulement promis ici.',
        },
      ],
      termsLink: 'Conditions',
      more: 'Plus de questions, et comment joindre un être humain →',
    },
  },

  training: {
    head: {
      slug: 'Le programme',
      title: 'Huit façons de s’entendre dire la vérité',
      lede: 'Trois d’entre elles sont gratuites et illimitées pour toujours — jouer, jouer contre quelqu’un, et les neuf cents parties de Regarder. Les cinq autres sont à cinq par jour sur un compte gratuit et illimitées avec Pro. Chacune vous note avec des mots sur la position plutôt qu’avec un nombre à interpréter.',
    },
    meta: {
      title: 'Entraînement',
      description:
        'Huit modes : tactique, jugement positionnel, finales, Rush, Devinez l’Elo, Regarder, jeu commenté et en ligne. Comment fonctionne chacun, comment les exercices sont extraits et vérifiés, et ce que l’entraîneur ne fait pas.',
    },
    modes: [
      {
        title: 'Tactique',
        lede: 'Des positions avec exactement un coup gagnant, et un verdict à l’instant où vous le jouez.',
        body: [
          'Chaque exercice a une réponse et aucune ramification. Jouez-la sur l’échiquier et l’entraîneur vous dit aussitôt si vous l’avez trouvée ; manquez-la et la position revient demain, puis dans quatre jours, puis dans dix — aussi longtemps qu’elle continue de vous prendre.',
          'Chaque exercice porte l’étiquette du motif sur lequel il tourne — fourchette, clouage, enfilade, mat du couloir, déviation, le coup tranquille — de sorte qu’après quelques centaines l’entraîneur peut vous dire non pas que vous êtes à 1620, mais que vous êtes à 1620 et que vous passez sans cesse à côté des déviations.',
        ],
        free: 'Cinq par jour sur un compte gratuit.',
        stat: 'exercices, cotés de 760 à 2800',
      },
      {
        title: 'Jugement positionnel',
        lede: 'Aucun gain forcé n’existe. Dites qui se tient mieux, puis trouvez le coup qui dit pourquoi.',
        body: [
          'C’est le mode fait pour ce qui sépare les joueurs forts des bons calculateurs. D’abord vous évaluez : nettement mieux, un peu mieux, équilibré. Puis vous choisissez un coup. Les deux réponses sont notées.',
          'Le retour nomme des traits concrets plutôt que des humeurs — la colonne ouverte et si une tour s’y trouve, l’avant-poste de cavalier qu’aucun pion ne peut contester, la structure de pions, la sécurité du roi, la différence d’activité des pièces. Une position n’est pas « agréable pour les Blancs » ; elle est meilleure à cause de quatre choses que vous pouvez énumérer.',
        ],
        free: 'Cinq par jour sur un compte gratuit.',
        stat: 'positions calmes, filtrées par le moteur',
      },
      {
        title: 'Finales',
        lede: 'Des positions canoniques, jouées jusqu’au bout contre un moteur qui défend correctement.',
        body: [
          'Connaître l’idée n’est pas la même chose que la convertir, alors ici il faut vraiment obtenir le résultat. Stockfish prend l’autre camp et oppose la meilleure défense qui existe.',
          'Après chaque coup l’entraîneur revérifie si le résultat reste atteignable — et s’il ne l’est plus, il vous dit le coup exact où il a cessé de l’être. C’est la phrase qui apprend : non pas « vous avez fait nulle », mais « vous avez fait nulle ici ».',
        ],
        free: 'Cinq par jour sur un compte gratuit.',
        stat: 'exercices, chaque résultat vérifié par le moteur',
      },
      {
        title: 'Rush',
        lede: 'Une course chronométrée. Résolvez-en autant que vous pouvez avant que la pendule prenne le reste.',
        body: [
          'Les mêmes exercices, contre la pendule, avec une difficulté qui monte tant que vous continuez de trouver. Cela entraîne un autre muscle que celui d’un exercice qu’on peut fixer : celui qui doit voir maintenant.',
          'Les courses sont notées et conservées, si bien que le nombre monte sur des mois plutôt que sur une soirée.',
        ],
        free: 'Cinq courses par jour sur un compte gratuit.',
      },
      {
        title: 'Devinez l’Elo',
        lede: 'Une vraie partie classée, déroulée coup par coup. Quelle était la force de ces deux-là ?',
        body: [
          'Lire le niveau d’une partie est la même compétence que juger ses propres coups : les deux reviennent à remarquer quelles fautes sont commises et lesquelles ne le sont pas. Alors la partie se déroule, vous regardez, et à un moment vous vous engagez sur un nombre.',
          'Les parties sont réelles, tirées des archives de Lichess, les deux joueurs étant à moins de 150 points l’un de l’autre — une estimation sur « les joueurs » ne veut dire quelque chose que lorsqu’il y a un seul niveau à deviner.',
        ],
        free: 'Cinq par jour sur un compte gratuit.',
        stat: 'parties classées, de 800 à 2599',
      },
      {
        title: 'Regarder',
        lede: 'Neuf cents parties qui valent le coup d’œil — et à l’instant où vous auriez joué autrement, reprenez-la.',
        body: [
          'Chaque partie de la bibliothèque est décisive, entre deux joueurs nommés, et soit terminée avant le vingt-cinquième coup, soit assez célèbre pour avoir un nom à elle. Personne n’apprend rien d’une nulle de quatre-vingt-dix coups entre des gens dont il n’a jamais entendu parler, et une bibliothèque qui les contient est une bibliothèque que personne n’ouvre deux fois.',
          'Cherchez un joueur, un tournoi ou une année. Puis déroulez la partie à votre rythme. L’intérêt n’est pas le résumé des beaux moments : c’est qu’à un coup vous penserez <em>j’aurais pris là</em> — et à cet instant vous le pouvez. Reprenez la position et continuez contre le moteur depuis exactement la case où vous n’étiez pas d’accord. Découvrir ce que valait vraiment votre idée, c’est tout l’exercice.',
        ],
        free: 'Gratuit, sans limite, toujours.',
        stat: 'parties, toutes décisives',
      },
      {
        title: 'Jouer et être conseillé',
        lede: 'Une partie entière à la force de votre choix, chacun de vos coups noté pendant que vous jouez.',
        body: [
          'Réglez le moteur n’importe où entre 1400 et la pleine force et jouez la partie. Chacun de vos coups est noté pendant que la partie se poursuit, et l’entraîneur explique ce que le meilleur coup aurait obtenu — avec des mots sur la position, pas un nombre.',
          'À la fin vous obtenez la précision, le nombre de bourdes, et le seul moment qui vous a le plus coûté.',
        ],
        free: 'Gratuit, sans limite, toujours.',
      },
      {
        title: 'En ligne',
        lede: 'Deux personnes, une pendule, et aucun moteur à proximité.',
        body: [
          'Game Center vous trouve quelqu’un qui a choisi la même cadence — 3, 5, 10, 15 ou 30 minutes. C’est le seul mode sans moteur dedans : pas d’indice, pas de valeurs de coups, pas de conseils, parce qu’une aide qu’un seul camp reçoit n’est pas une partie.',
          'Il n’y a pas de serveur. Les deux appareils se parlent et appliquent tous deux les règles, si bien qu’un coup n’est joué que s’il est légal dans la position que l’appareil qui reçoit détient déjà. Un pair qui ment produit un paquet rejeté, pas un échiquier illégal.',
        ],
        free: 'Gratuit, sans limite, toujours.',
      },
    ],
    watchLink: 'Ce qui est entré dans la bibliothèque et ce qui n’y est pas →',
    pipeline: {
      slug: 'Comment se fabrique un exercice',
      title: 'Extraits, pas recopiés.',
      lede: 'Noter des positions de mémoire risque de livrer un exercice dont la « solution » est fausse ou non unique, ce qui entraîne exactement le mauvais réflexe. Aucun n’est donc noté de mémoire. Ils sont trouvés, puis attaqués jusqu’à ce qu’ils survivent ou soient jetés.',
      steps: [
        {
          title: 'Jouer, à force humaine',
          body: 'Stockfish joue contre lui-même à une force délibérément proche de l’humaine — de 1320 à 2500 Elo — en ouvrant par un choix au hasard parmi ses meilleures options peu profondes, pour que les parties varient au lieu de répéter une ligne indéfiniment.',
        },
        {
          title: 'Filtrer sur la propriété, pas sur la bourde',
          body: 'Chaque position est cherchée à la profondeur 12 avec deux lignes candidates. Le signal n’est pas « quelqu’un a gaffé » mais ce dont un exercice a réellement besoin : un coup nettement supérieur à toutes les autres possibilités.',
        },
        {
          title: 'Rechercher en profondeur, avec une marge',
          body: 'Les survivantes sont cherchées de nouveau à la profondeur 20 avec MultiPV. Une candidate n’est gardée que si le meilleur coup devance le deuxième d’au moins 140 centipions et obtient réellement quelque chose.',
        },
        {
          title: 'Prolonger jusqu’à la ramification',
          body: 'La solution est prolongée coup par coup tant que chaque coup du solveur reste uniquement le meilleur. À l’instant où deux bonnes réponses existent, l’exercice s’arrête là — il n’a donc jamais de branche pour laquelle on pourrait vous compter faux.',
        },
        {
          title: 'Vérifier avec un moteur neuf',
          body: 'L’ensemble est recontrôlé à une profondeur supérieure par un script distinct avec une nouvelle instance du moteur. Sur l’ensemble extrait livré, cela a rejeté 6 exercices sur 172 dont les solutions cessaient d’être uniques deux demi-coups plus loin. Ils ont été écartés plutôt que livrés.',
        },
      ],
    },
    honest: {
      title: 'Et la même méfiance appliquée aux finales',
      body: [
        'Le résultat annoncé de chaque exercice de finale est vérifié contre une recherche profonde plutôt que cru sur parole. Un exercice mal étiqueté échoue au contrôle au lieu de vous apprendre discrètement quelque chose de faux.',
        'Le vérificateur attrape aussi une chose que les bibliothèques d’échecs habituelles ne vous diront pas : si le camp qui n’a pas le trait est en échec. Une telle position est illégale — aucune partie ne peut l’atteindre — mais une bibliothèque l’accepte volontiers, et le moteur répond bestmove (none), ce qui ressemble à une défaillance du moteur plutôt qu’à une mauvaise position. Trois exercices écrits à la main étaient faux exactement ainsi. Le contrôle l’attrape désormais.',
      ],
    },
    limits: {
      slug: 'Limites honnêtes',
      title: 'Ce que ceci ne fait pas.',
      items: [
        {
          title: 'L’ensemble mélange deux échelles de classement.',
          body: 'Les {lichess} exercices Lichess portent des cotes étalonnées sur des millions de tentatives humaines. Les {mined} extraits localement portent des estimations tirées de la profondeur de la solution et du motif. Les deux classent sensément, mais un 1600 extrait et un 1600 Lichess ne sont pas mesurés de la même façon.',
        },
        {
          title: 'Les cotes d’exercices ne sont pas des classements sur échiquier.',
          body: 'Elles courent plusieurs centaines de points plus haut, et cela restera ainsi. Elles mesurent le progrès contre vous-même, pas la force contre un peloton d’humains à la pendule — {link}, car l’écart est structurel et non le signe que vous convertissez mal.',
        },
        {
          title: 'Il n’y a pas d’entraînement aux ouvertures.',
          body: 'Délibérément. L’étude des ouvertures est une mémorisation contre un répertoire que vous choisissez, et c’est un autre outil d’une autre forme. Le mode positionnel couvre la sortie d’ouverture, qui est la partie qui se généralise vraiment.',
        },
        {
          title: 'Ceci ne fera pas de vous un grand maître.',
          body: 'Rien ne le fait à soi seul. Les titres viennent de milliers d’heures plus des parties de tournoi classées contre des humains. Ce que ceci vous donne, c’est la moitié entraînement de tout cela, structurée, avec une mesure honnête d’où vous en êtes réellement.',
        },
      ],
      ratingsLink: 'ce qui vaut la peine d’être bien compris',
    },
    more: {
      motifs: 'Les vingt motifs, définis et comptés →',
      engine: 'Comment le moteur est utilisé →',
    },
  },

  tactics: {
    head: {
      slug: 'Glossaire',
      title: 'Les vingt motifs',
      lede: 'Toute tactique aux échecs est l’une d’un petit nombre de formes, et dès que vous savez les nommer vous commencez à les voir un coup plus tôt. Voici ceux dont Brass Pawn étiquette ses exercices — chacun suivi du nombre de positions de la bibliothèque livrée qui tournent réellement autour de lui.',
      meta: 'Comptés sur l’ensemble livré de 14 351 exercices · Dernière révision le 19 août 2026',
    },
    meta: {
      title: 'Les vingt motifs',
      description:
        'Chaque motif tactique dont Brass Pawn étiquette ses exercices, défini et compté sur la bibliothèque livrée pour que vous sachiez lesquels vous pouvez réellement travailler.',
    },
    indexLabel: 'Les motifs',
    puzzles: 'exercices',
    motifs: [
      {
        name: 'Fourchette',
        short: 'Une pièce attaque deux choses à la fois, et une seule peut être sauvée.',
        body: 'Le cavalier est le fourcheur célèbre parce qu’il attaque des cases qu’aucune autre pièce ne défend de la même manière, mais toutes les pièces fourchent : un pion frappant deux pièces mineures, une dame frappant une tour et un fou en l’air, un roi en finale se glissant entre deux pions. Le test n’est pas « est-ce que j’attaque deux choses » mais « peuvent-elles s’en sortir toutes les deux ».',
      },
      {
        name: 'Clouage',
        short:
          'Une pièce ne peut pas bouger parce que quelque chose de plus précieux est derrière.',
        body: 'Absolu quand le roi est derrière — bouger est illégal, pas seulement mauvais. Relatif quand c’est une dame ou une tour, où bouger est légal et perd simplement du matériel. La suite est ce qui gagne : une pièce clouée est une pièce qui ne peut pas défendre, alors accumulez les attaquants dessus, ou frappez-la d’un pion.',
      },
      {
        name: 'Enfilade',
        short: 'Un clouage à l’envers : la pièce précieuse est devant et doit bouger.',
        body: 'Donnez échec au roi sur une ligne avec tour, fou ou dame, et ce qui se tenait derrière est à vous dès que le roi s’écarte. Les enfilades sont plus rares que les clouages parce qu’elles exigent les deux pièces déjà alignées avec la précieuse devant — d’où leur apparition, le plus souvent, après qu’un échec a forcé le roi sur la ligne.',
      },
      {
        name: 'Attaque à la découverte',
        short: 'Bouger une pièce démasque l’attaque de celle qui est derrière.',
        body: 'La tactique la plus forte des échecs et de loin, parce que la pièce qui bouge est libre de faire quelque chose pour son compte pendant que l’attaque découverte fait le travail. Deux menaces apparaissent en un coup et aucune ne se répond en capturant la pièce qui a bougé.',
      },
      {
        name: 'Échec à la découverte',
        short:
          'L’attaque démasquée est un échec, l’adversaire n’a donc de temps pour rien d’autre.',
        body: 'Une attaque à la découverte où la pièce de derrière donne échec. Quoi que fasse la pièce qui bouge — prendre une dame, aller sur une case de mat, se mettre en prise — la réponse doit d’abord parer l’échec, si bien que cela se produit gratuitement.',
      },
      {
        name: 'Échec double',
        short:
          'Deux pièces donnent échec en même temps, le roi doit donc bouger. Ni parade, ni prise.',
        body: 'La seule tactique contre laquelle il existe exactement une classe de réponse légale. Prendre l’un des donneurs d’échec laisse l’autre ; obstruer une ligne laisse l’autre. Voilà pourquoi l’échec double délivre des mats qui semblent impossibles — le défenseur peut avoir cinq façons d’arrêter chaque échec séparément et aucune qui les arrête tous deux.',
      },
      {
        name: 'Déviation',
        short: 'Forcez un défenseur à quitter la tâche qu’il accomplit.',
        body: 'Une pièce tient une case de mat, une première rangée ou une autre pièce. Attaquez quelque chose qu’elle estime davantage, ou prenez simplement quelque chose qu’elle doit reprendre, et la défense qu’elle assurait disparaît avec elle. Le sacrifice paraît souvent absurde jusqu’à ce qu’on remarque ce que la pièce qui reprend cesse de couvrir.',
      },
      {
        name: 'Attraction',
        short: 'Attirez une pièce — souvent le roi — sur une case où elle peut être frappée.',
        body: 'Aussi appelée leurre. Un sacrifice que l’adversaire est obligé d’accepter, joué non pour gagner du matériel mais pour placer une pièce quelque part de fatal : un roi traîné sur une case de fourchette, une dame tirée sur une ligne avec une tour. Le matériel revient avec les intérêts un coup plus tard.',
      },
      {
        name: 'Dégagement',
        short: 'Ôtez votre propre pièce du chemin de votre propre attaque.',
        body: 'La ligne ou la case est la bonne et l’un des vôtres se tient dessus. Le dégagement le déplace avec tempo — le plus souvent par un échec ou une prise, pour que l’adversaire n’ait pas le temps de se réorganiser pendant que la route s’ouvre.',
      },
      {
        name: 'Interception',
        short: 'Coupez la ligne entre un défenseur et ce qu’il défend.',
        body: 'Posez une pièce — souvent sacrifiée — exactement entre une tour et la case qu’elle garde. Le défenseur est encore sur l’échiquier, défend encore en théorie, et ne le peut plus. Rare, et l’un des motifs les plus difficiles à voir, parce que la pièce qui intercepte ressemble d’ordinaire à une bourde.',
      },
      {
        name: 'Rayon X',
        short: 'Une pièce agit à travers une autre, le long de la ligne qu’elle occupera ensuite.',
        body: 'Une tour défendant sa propre pièce à travers une pièce ennemie, ou attaquant à travers elle. Rien ne se passe encore ; ce qui compte est ce qui se passera dès que la pièce intermédiaire bougera ou sera prise. Reconnaître un rayon X est en général ce qui fait qu’une prise qui « perd du matériel » n’en perd pas.',
      },
      {
        name: 'Coup intermédiaire',
        short: 'Le zwischenzug : avant de reprendre, faites quelque chose de plus forçant.',
        body: 'De l’allemand « coup intermédiaire », et la raison unique la plus fréquente pour laquelle une variante calculée se révèle fausse. Vous attendez une reprise ; à la place vient un échec, ou une menace plus grande, et le temps que la reprise arrive, la position a changé. Cherchez-en un chaque fois qu’une séquence semble forcée.',
      },
      {
        name: 'Zugzwang',
        short: 'Devoir jouer est en soi le problème.',
        body: 'Chaque coup légal aggrave la position, et passer n’est pas permis. Surtout une idée de finale — les finales de roi et pions se décident par elle — et la raison pour laquelle « l’opposition » compte : celui qui doit s’écarter le premier perd la case. Presque la seule situation aux échecs où le droit de jouer est un fardeau.',
      },
      {
        name: 'Mat du couloir',
        short: 'Un roi enfermé par ses propres pions, maté sur la première rangée.',
        body: 'Le mat le plus courant entre joueurs qui ont roqué et laissé les pions tranquilles. Il apparaît rarement comme mat sur l’échiquier — il apparaît comme une menace qui gagne du matériel, parce que chaque coup défensif doit continuer de garder la rangée. Toute la famille des tactiques de déviation existe pour ôter cette garde.',
      },
      {
        name: 'Mat de l’étouffé',
        short: 'Un cavalier mate un roi que ses propres pièces ont enfermé.',
        body: 'La conclusion du legs de Philidor : sacrifice de dame en g8, la tour reprend, le cavalier en f7 donne mat, le roi entouré des siens. Rare en partie réelle et méritant d’être connu quand même, parce que le motif est ce qui vous fait regarder un coin et compter les cases de fuite.',
      },
      {
        name: 'Pièce en prise',
        short: 'Quelque chose est simplement sans défense et peut être pris.',
        body: 'Rien de glorieux, et cela décide plus de parties que tout le reste de cette liste réuni. La plupart des défaites en dessous de 1800 sont un joueur prenant une pièce gratuite que l’autre a cessé de surveiller. L’habitude qui corrige cela est de vérifier ce qui est en l’air — des deux couleurs — avant chaque coup.',
      },
      {
        name: 'Pièce piégée',
        short: 'Une pièce n’a plus de case sûre et peut être traquée à loisir.',
        body: 'D’ordinaire un fou qui a pris un pion qu’il aurait dû laisser, ou un cavalier parti en razzia. La tactique n’est pas un coup unique mais un étau : ôtez les cases une à une et la pièce tombe sans qu’aucun sacrifice soit nécessaire.',
      },
      {
        name: 'Coup tranquille',
        short: 'Le coup gagnant n’est ni un échec, ni une prise, ni une menace.',
        body: 'La raison pour laquelle les joueurs forts trouvent des combinaisons que d’autres manquent. Après une séquence forcée, la réponse est un coup modeste qui ôte la dernière case de fuite, et il est invisible pour qui ne calcule qu’échecs et prises. Si une position semble gagnante et que rien de forçant ne marche, cherchez le coup tranquille.',
      },
      {
        name: 'Sacrifice',
        short: 'Donnez du matériel pour quelque chose qui vaut plus que du matériel.',
        body: 'Du temps, des lignes, des cases, ou la position du roi adverse. Un vrai sacrifice n’est pas un pari ; c’est un calcul dont la fin est concrète. Ce qui sépare celui qui marche de celui qui ne marche pas est presque toujours de savoir si les pièces défensives peuvent revenir à temps.',
      },
      {
        name: 'Pion avancé',
        short: 'Un pion près de la promotion change ce que vaut toute autre pièce.',
        body: 'Un pion en septième n’est pas un pion ; c’est une dame que quelque chose doit surveiller, et ce quelque chose n’est plus libre. La plupart des tactiques de finale portent en réalité sur la tension entre arrêter un pion et faire quoi que ce soit d’autre.',
      },
    ],
    after: {
      slug: 'Pourquoi les nombres sont là',
      title:
        'Un glossaire vous dit ce qu’est une fourchette. Un nombre vous dit si vous pouvez la travailler.',
      body: [
        'Connaître le nom d’un motif et savoir le trouver à la pendule sont deux compétences différentes, et seule la seconde gagne des parties. Chaque compte ci-dessus est le nombre réel de positions de la bibliothèque livrée étiquetées de ce motif — pas une estimation, et pas arrondi au-dessus. Soixante exercices de rayon X font soixante ; si c’est la chose que vous manquez sans cesse, il vaut la peine de savoir que vous n’en manquerez pas en une soirée.',
        'L’entraîneur suit les motifs que vous ratez, si bien qu’après quelques centaines d’exercices il peut vous dire non pas que vous êtes à 1620, mais que vous êtes à 1620 et que vous passez sans cesse à côté des déviations.',
      ],
      more: 'Comment les exercices sont extraits et vérifiés →',
    },
  },
};
