import type { Pages } from './types';

/** The four commercial pages in Brazilian Portuguese. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Suporte',
      title: 'Pergunte a uma pessoa',
      lede: 'Não há sistema de chamados, nem chatbot, nem central de ajuda com 400 artigos dentro. Há um endereço de e-mail e um registro de problemas, e os dois chegam à pessoa que escreveu o aplicativo.',
    },
    meta: {
      title: 'Suporte',
      description:
        'Como falar com uma pessoa de verdade sobre o Brass Pawn, o que enviar ao relatar um exercício errado, e as perguntas que mais aparecem.',
    },
    email: {
      slug: 'E-mail',
      body: 'Para qualquer coisa: um defeito, um exercício errado, uma dúvida sobre uma compra ou uma discordância com alguma avaliação. Escreva em inglês ou em búlgaro.',
    },
    tracker: {
      slug: 'Registro de problemas',
      name: 'Issues no GitHub',
      body: 'Para tudo o que você preferir que seja público — e para tudo o que queira que outras pessoas encontrem depois, o que vale para a maioria dos relatos de defeito.',
    },
    report: {
      slug: 'Se um exercício estiver errado',
      title: 'Mande quatro coisas e dá para conferir em um minuto.',
      checklist: [
        'O FEN mostrado na tela do exercício — toque e segure para copiar.',
        'A jogada que você fez e a jogada que o aplicativo deu como certa.',
        'Em que modo você estava.',
        'A versão do aplicativo, na tela Sobre.',
      ],
      caveat:
        'Os exercícios de fato às vezes discordam de uma busca mais profunda, e as discordâncias se concentram em posições longas, tranquilas e de avaliação alta, cujo ponto está mais fundo do que a verificação chegou. Isso é um limite da checagem, não um defeito do exercício — mas vale saber quais são, e o único jeito de saber é você dizer.',
    },
    faq: { slug: 'Perguntas', title: 'Feitas com frequência suficiente para serem escritas.' },
    more: {
      ratings: 'O que uma classificação mede',
      tactics: 'Os motivos',
      privacy: 'Política de privacidade',
      terms: 'Termos de serviço',
      licences: 'Licenças',
    },
  },

  pricing: {
    head: {
      slug: 'Quanto custa',
      title: 'Jogar é grátis. O treino é vendido.',
      lede: 'Xadrez contra o motor e xadrez contra uma pessoa, sem limite, sem publicidade em lugar nenhum do aplicativo — isso é grátis e continua grátis. O que se vende é a biblioteca, os exercícios, os problemas e a corrida contra o relógio.',
    },
    meta: {
      title: 'Preços',
      description:
        'Jogar é grátis e sem limite — o motor, um adversário de verdade e as 900 partidas. O Pro tira o limite de cinco por dia: 3,99 dólares por mês ou 49,99 uma vez só.',
    },
    free: {
      name: 'Grátis',
      note: 'Sem conta. Nada para cadastrar.',
      items: [
        'Jogo ilimitado contra o motor, de 1400 até a força máxima',
        'Partidas on-line ilimitadas pelo Game Center',
        'Comentário jogada a jogada em toda partida que você joga',
        'Cinco exercícios táticos por dia',
        'Cinco corridas do Rush por dia',
        'Cinco de cada: posicional, final, Adivinhe o Elo',
        'Classificações, sequências e repetição espaçada, por inteiro',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Mensal',
      per: 'por mês',
      note: 'Cancele quando quiser nos ajustes da sua conta Apple.',
      items: [
        'Todo limite diário removido',
        'Todos os {tactics} exercícios táticos',
        'Todos os {positional} exercícios posicionais',
        'Todos os {endgames} exercícios de final',
        'Todas as {games} partidas para avaliar',
        'Rush sem limite',
        'Tudo do Grátis, sem mudanças',
      ],
    },
    lifetime: {
      name: 'Desbloqueio único',
      once: 'uma vez',
      note: 'Uma compra não consumível. Não se renova.',
      items: [
        'Exatamente igual ao Pro mensal',
        'Sem renovação, sem validade, sem e-mails de lembrete',
        'Restaura nos seus outros aparelhos',
        'Para quem prefere decidir uma vez só',
      ],
    },
    table: {
      slug: 'A cota completa',
      title: 'O que o plano grátis dá de verdade.',
      activity: 'Atividade',
      freeCol: 'Grátis',
      proCol: 'Pro',
      unlimited: 'Sem limite',
      fiveADay: '5 por dia',
      none: 'Nenhuma',
      rows: [
        'Jogar contra o motor',
        'Partidas on-line pelo Game Center',
        'Assistir — a biblioteca de 900 partidas',
        'Exercícios táticos',
        'Corridas do Rush',
        'Exercícios posicionais',
        'Exercícios de final',
        'Adivinhe o Elo',
        'Publicidade',
      ],
      reset:
        'As cotas diárias voltam às nove da manhã, hora local — não à meia-noite, para que uma sessão à noite não seja cortada ao meio por uma virada de data.',
    },
    why: {
      slug: 'Por que tem esse formato',
      title: 'Três decisões, e a razão de cada uma.',
      reasons: [
        {
          title: 'Contado, não trancado',
          body: [
            'Ninguém paga por um treinador que não usou, e um modo que se recusa a abrir não ensina nada sobre o que há atrás dele. Então todo modo abre, todo dia, e você entra o bastante para sentir o ritmo e ver a classificação se mexer.',
            'O aviso de pagamento nunca aparece ao abrir. Quando a cota do dia acaba, a tela diz isso, e só um toque deliberado abre a folha de compra.',
          ],
        },
        {
          title: 'Dois preços, não três',
          body: [
            'Não há plano anual no meio, porque um terceiro preço é uma terceira decisão exatamente no momento em que alguém quer resolver um exercício. Mensal se você está em dúvida. Único se não está.',
          ],
        },
        {
          title: 'Jogar nunca é vendido',
          body: [
            'O xadrez contra o motor e contra uma pessoa não custam nada para rodar e são a razão de o aplicativo existir. Vendê-los faria disto um aplicativo de xadrez com pedágio em vez de um treinador.',
            'E não há publicidade — em parte gosto, em parte licença. O aplicativo liga dois motores copyleft, Stockfish sob GPLv3 e Reckless sob AGPLv3, e um SDK de anúncios proprietário no mesmo binário tornaria o conjunto indistribuível. {link}',
          ],
        },
      ],
      licenceLink: 'A página de licenças explica isso direito.',
    },
    answers: {
      slug: 'Comprar, cancelar, reembolsos',
      title: 'As perguntas incômodas, respondidas aqui e não por e-mail.',
      items: [
        {
          q: 'Como eu cancelo?',
          a: 'Ajustes → seu nome → Assinaturas → Brass Pawn. Não podemos cancelar por você, porque a assinatura é entre você e a Apple e nunca esteve conosco. Cancelar interrompe as renovações futuras e não encurta o período que você já pagou.',
        },
        {
          q: 'Como consigo reembolso?',
          a: 'Pela Apple, em {link}. Não podemos emitir reembolsos de compras da App Store. Se algo estiver quebrado, escreva para a gente — preferimos consertar.',
        },
        {
          q: 'Comprei o desbloqueio e troquei de telefone.',
          a: 'Entre com a mesma conta Apple e toque em «Restaurar compras» na tela de compra. O aplicativo pergunta à StoreKit o que você possui; nada fica em servidor nosso porque não existe servidor nosso.',
        },
        {
          q: 'O Pro muda minha classificação ou libera exercícios «melhores»?',
          a: 'Não. O sistema de classificação é idêntico e todo exercício da biblioteca é alcançável com uma conta grátis — cinco por dia. O Pro tira o contador, não uma cortina.',
        },
        {
          q: 'A cota grátis vai diminuir depois?',
          a: 'Pode mudar nas duas direções conforme a biblioteca cresce. O jogo ilimitado contra o motor e contra uma pessoa não vai virar recurso pago; isso está escrito nos {link} e não apenas prometido aqui.',
        },
      ],
      termsLink: 'Termos',
      more: 'Mais perguntas, e como falar com uma pessoa →',
    },
  },

  training: {
    head: {
      slug: 'O programa',
      title: 'Oito jeitos de ouvir a verdade',
      lede: 'Três deles são grátis e ilimitados para sempre — jogar, jogar contra outra pessoa e as novecentas partidas em Assistir. Os outros cinco são cinco por dia numa conta grátis e ilimitados com o Pro. Cada um avalia você com palavras sobre a posição, e não com um número que você precise interpretar.',
    },
    meta: {
      title: 'Treino',
      description:
        'Oito modos: tática, julgamento posicional, finais, Rush, Adivinhe o Elo, Assistir, jogo comentado e on-line. Como cada um funciona, como os exercícios são extraídos e verificados, e o que o treinador não faz.',
    },
    modes: [
      {
        title: 'Tática',
        lede: 'Posições com exatamente uma jogada vencedora, e um veredito no instante em que você a faz.',
        body: [
          'Todo exercício tem uma resposta e nenhuma ramificação. Faça a jogada no tabuleiro e o treinador diz na hora se você achou; erre e a posição volta amanhã, depois em quatro dias, depois em dez — enquanto continuar te pegando.',
          'Cada exercício vem marcado com o motivo em que gira — garfo, cravada, espeto, mate do corredor, desvio, o lance quieto — de modo que, depois de algumas centenas, o treinador consegue dizer não que você é 1620, mas que você é 1620 e continua passando batido pelos desvios.',
        ],
        free: 'Cinco por dia numa conta grátis.',
        stat: 'exercícios, avaliados de 760 a 2800',
      },
      {
        title: 'Julgamento posicional',
        lede: 'Não existe ganho forçado. Diga quem está melhor e depois ache a jogada que explica por quê.',
        body: [
          'Este é o modo feito para aquilo que separa jogadores fortes de bons calculistas. Primeiro você avalia: claramente melhor, um pouco melhor, equilibrado. Depois escolhe uma jogada. As duas respostas são avaliadas.',
          'O retorno nomeia características concretas em vez de humores — a coluna aberta e se há uma torre nela, o posto avançado de cavalo que nenhum peão pode contestar, a estrutura de peões, a segurança do rei, a diferença de atividade das peças. Uma posição não é «agradável para as brancas»; ela é melhor por quatro coisas que você consegue listar.',
        ],
        free: 'Cinco por dia numa conta grátis.',
        stat: 'posições tranquilas, filtradas pelo motor',
      },
      {
        title: 'Finais',
        lede: 'Posições canônicas, jogadas até o fim contra um motor que defende direito.',
        body: [
          'Saber a ideia não é o mesmo que converter, então aqui você precisa atingir o resultado de fato. O Stockfish assume o outro lado e opõe a melhor defesa que existe.',
          'Depois de cada jogada o treinador confere de novo se o resultado ainda é alcançável — e, se não for, diz a jogada exata em que deixou de ser. É a frase que ensina: não «você empatou», mas «você empatou aqui».',
        ],
        free: 'Cinco por dia numa conta grátis.',
        stat: 'exercícios, cada resultado verificado pelo motor',
      },
      {
        title: 'Rush',
        lede: 'Uma corrida cronometrada. Resolva quantos conseguir antes de o relógio levar o resto.',
        body: [
          'Os mesmos exercícios, contra o relógio, com a dificuldade subindo enquanto você continua acertando. Treina um músculo diferente do de um exercício que dá para encarar: aquele que precisa ver agora.',
          'As corridas são pontuadas e guardadas, então o número sobe ao longo de meses e não de uma noite.',
        ],
        free: 'Cinco corridas por dia numa conta grátis.',
      },
      {
        title: 'Adivinhe o Elo',
        lede: 'Uma partida valendo rating de verdade, jogada lance a lance. Quão fortes eram esses dois?',
        body: [
          'Ler o nível de uma partida é a mesma habilidade de julgar as próprias jogadas: as duas se resumem a perceber quais erros estão sendo cometidos e quais não. Então a partida corre, você assiste, e em algum momento se compromete com um número.',
          'As partidas são reais, dos arquivos do Lichess, com os dois jogadores dentro de 150 pontos um do outro — um palpite sobre «os jogadores» só significa alguma coisa quando há um nível a adivinhar.',
        ],
        free: 'Cinco por dia numa conta grátis.',
        stat: 'partidas valendo rating, de 800 a 2599',
      },
      {
        title: 'Assistir',
        lede: 'Novecentas partidas que valem a pena ver — e no instante em que você teria jogado diferente, assuma.',
        body: [
          'Toda partida da biblioteca é decisiva, entre dois jogadores com nome, e ou terminou até o vigésimo quinto lance ou é famosa o bastante para ter nome próprio. Ninguém aprende nada com um empate de noventa lances entre gente de quem nunca ouviu falar, e uma biblioteca que os inclui é uma biblioteca que ninguém abre duas vezes.',
          'Procure um jogador, um torneio ou um ano. Depois percorra a partida no seu ritmo. A graça não é o compilado dos melhores momentos: é que em algum lance você vai pensar <em>eu teria capturado ali</em> — e nesse momento você pode. Assuma a posição e siga contra o motor exatamente da casa em que discordou. Descobrir quanto sua ideia valia de fato é o exercício inteiro.',
        ],
        free: 'Grátis, sem limite, sempre.',
        stat: 'partidas, todas decisivas',
      },
      {
        title: 'Jogar com treinador',
        lede: 'Uma partida inteira na força que você escolher, com cada jogada sua avaliada enquanto joga.',
        body: [
          'Ponha o motor em qualquer ponto entre 1400 e a força máxima e jogue até o fim. Cada jogada sua é avaliada com a partida ainda em andamento, e o treinador explica o que a jogada melhor teria conseguido — com palavras sobre a posição, não com um número.',
          'No fim você recebe precisão, número de erros graves e o único momento que mais te custou.',
        ],
        free: 'Grátis, sem limite, sempre.',
      },
      {
        title: 'On-line',
        lede: 'Duas pessoas, um relógio e nenhum motor por perto.',
        body: [
          'O Game Center acha alguém que escolheu o mesmo ritmo — 3, 5, 10, 15 ou 30 minutos. É o único modo sem motor dentro: sem dica, sem valores de jogada, sem treinador, porque ajuda que só um lado recebe não é partida.',
          'Não há servidor. Os dois aparelhos conversam entre si e ambos aplicam as regras, então uma jogada só acontece se for legal na posição que o aparelho que recebe já tem. Um par que mente produz um pacote descartado, não um tabuleiro ilegal.',
        ],
        free: 'Grátis, sem limite, sempre.',
      },
    ],
    watchLink: 'O que entrou na biblioteca e o que não →',
    pipeline: {
      slug: 'Como um exercício é feito',
      title: 'Extraídos, não transcritos.',
      lede: 'Anotar posições de memória arrisca publicar um exercício cuja «solução» está errada ou não é única, e isso treina exatamente o instinto errado. Então nenhum deles é anotado de memória. Eles são encontrados e depois atacados até sobreviverem ou serem jogados fora.',
      steps: [
        {
          title: 'Jogar, em força humana',
          body: 'O Stockfish joga contra si mesmo numa força deliberadamente parecida com a humana — de 1320 a 2500 Elo — abrindo com uma escolha aleatória entre suas melhores opções rasas, para que as partidas variem em vez de repetir uma linha para sempre.',
        },
        {
          title: 'Filtrar pela propriedade, não pelo vacilo',
          body: 'Toda posição é buscada na profundidade 12 com duas linhas candidatas. O sinal não é «alguém vacilou», e sim o que um exercício realmente precisa: uma jogada muito melhor do que qualquer alternativa.',
        },
        {
          title: 'Buscar de novo, fundo e com margem',
          body: 'As sobreviventes são buscadas outra vez na profundidade 20 com MultiPV. Uma candidata só fica se a melhor jogada superar a segunda por pelo menos 140 centipeões e de fato conseguir alguma coisa.',
        },
        {
          title: 'Estender até ramificar',
          body: 'A solução é estendida lance a lance enquanto cada jogada de quem resolve continuar sendo a única melhor. No instante em que existem duas boas respostas, o exercício termina ali — assim ele nunca tem uma ramificação pela qual você possa ser marcado como errado.',
        },
        {
          title: 'Verificar com um motor novo',
          body: 'O conjunto inteiro é reconferido em profundidade maior por um script separado com uma nova instância do motor. No conjunto extraído incluído, isso rejeitou 6 de 172 exercícios cujas soluções deixavam de ser únicas dois meios-lances adiante. Foram descartados em vez de publicados.',
        },
      ],
    },
    honest: {
      title: 'E a mesma desconfiança aplicada aos finais',
      body: [
        'O resultado declarado de cada exercício de final é conferido contra uma busca profunda em vez de aceito de boa-fé. Um exercício mal rotulado reprova na conferência em vez de te ensinar algo falso em silêncio.',
        'O verificador também pega uma coisa que as bibliotecas de xadrez comuns não contam: se o lado que não está na vez está em xeque. Uma posição assim é ilegal — nenhuma partida chega a ela — mas uma biblioteca aceita numa boa, e o motor responde bestmove (none), o que soa como falha do motor e não como posição ruim. Três exercícios escritos à mão estavam errados exatamente assim. A conferência já pega isso.',
      ],
    },
    limits: {
      slug: 'Limites honestos',
      title: 'O que isto não faz.',
      items: [
        {
          title: 'O conjunto mistura duas escalas de classificação.',
          body: 'Os {lichess} exercícios do Lichess trazem classificações calibradas contra milhões de tentativas humanas. Os {mined} extraídos localmente trazem estimativas derivadas da profundidade da solução e do motivo. As duas ordenam com sentido, mas um 1600 extraído e um 1600 do Lichess não são medidos do mesmo jeito.',
        },
        {
          title: 'Classificação de exercício não é rating de tabuleiro.',
          body: 'Elas correm várias centenas de pontos acima, e sempre vão correr. Medem progresso contra você mesmo, não força contra um campo de humanos no relógio — {link}, porque a diferença é estrutural e não sinal de que você converte mal.',
        },
        {
          title: 'Não há treino de aberturas.',
          body: 'De propósito. Estudo de abertura é memorização contra um repertório que você escolhe, e isso é outra ferramenta com outro formato. O modo posicional cobre a saída da abertura, que é a parte que realmente se generaliza.',
        },
        {
          title: 'Isto não vai te fazer grande mestre.',
          body: 'Nada faz, sozinho. Títulos vêm de milhares de horas mais partidas de torneio valendo rating contra humanos. O que isto te dá é a metade de treino disso, estruturada, com uma medida honesta de onde você está de fato.',
        },
      ],
      ratingsLink: 'o que vale a pena entender direito',
    },
    more: {
      motifs: 'Os vinte motivos, definidos e contados →',
      engine: 'Como o motor é usado →',
    },
  },

  tactics: {
    head: {
      slug: 'Glossário',
      title: 'Os vinte motivos',
      lede: 'Toda tática no xadrez é uma de um número pequeno de formas, e assim que você sabe nomeá-las começa a vê-las um lance antes. Estes são os que o Brass Pawn usa para marcar seus exercícios — cada um seguido de quantas posições da biblioteca incluída realmente giram nele.',
      meta: 'Contados sobre o conjunto incluído de 14.351 exercícios · Última revisão em 19 de agosto de 2026',
    },
    meta: {
      title: 'Os vinte motivos',
      description:
        'Todo motivo tático com que o Brass Pawn marca seus exercícios, definido e contado contra a biblioteca incluída, para você saber quais dá para treinar de verdade.',
    },
    indexLabel: 'Os motivos',
    puzzles: 'exercícios',
    motifs: [
      {
        name: 'Garfo',
        short: 'Uma peça ataca duas coisas ao mesmo tempo, e só uma pode ser salva.',
        body: 'O cavalo é o garfeador famoso porque ataca casas que nenhuma outra peça defende do mesmo jeito, mas toda peça garfa: um peão atingindo duas peças menores, uma dama atingindo torre e bispo solto, um rei no final se metendo entre dois peões. O teste não é «estou atacando duas coisas» e sim «as duas conseguem sair».',
      },
      {
        name: 'Cravada',
        short: 'Uma peça não pode se mexer porque atrás dela há algo mais valioso.',
        body: 'Absoluta quando o rei está atrás — mexer é ilegal, não apenas ruim. Relativa quando atrás está uma dama ou uma torre, onde mexer é legal e simplesmente perde material. A continuação é o que ganha: uma peça cravada é uma peça que não pode defender, então empilhe mais atacantes sobre ela, ou bata nela com um peão.',
      },
      {
        name: 'Espeto',
        short: 'Uma cravada ao contrário: a peça valiosa está na frente e precisa se mexer.',
        body: 'Dê xeque no rei numa linha com torre, bispo ou dama, e o que estava atrás é seu assim que o rei sair. Espetos são mais raros que cravadas porque exigem as duas peças já alinhadas com a valiosa na frente — por isso costumam aparecer depois de um xeque ter forçado o rei para a linha.',
      },
      {
        name: 'Ataque descoberto',
        short: 'Mexer uma peça desmascara o ataque da peça que está atrás.',
        body: 'A tática mais forte do xadrez, de longe, porque a peça que se mexe fica livre para fazer algo próprio enquanto o ataque descoberto faz o trabalho. Duas ameaças aparecem num lance e nenhuma delas se responde capturando a peça que se mexeu.',
      },
      {
        name: 'Xeque descoberto',
        short: 'O ataque desmascarado é um xeque, então o adversário não tem tempo para mais nada.',
        body: 'Um ataque descoberto em que a peça de trás dá xeque. Faça o que fizer a peça que se mexe — levar uma dama, ir para uma casa de mate, se pôr em tomada — a resposta precisa cuidar do xeque primeiro, então aquilo sai de graça.',
      },
      {
        name: 'Xeque duplo',
        short:
          'Duas peças dão xeque ao mesmo tempo, então o rei precisa se mexer. Sem tapar, sem capturar.',
        body: 'A única tática contra a qual existe exatamente uma classe de resposta legal. Capturar um dos que dão xeque deixa o outro; tapar uma linha deixa a outra. Por isso o xeque duplo entrega mates que parecem impossíveis — o defensor pode ter cinco jeitos de parar cada xeque separadamente e nenhum que pare os dois.',
      },
      {
        name: 'Desvio',
        short: 'Force um defensor a largar o trabalho que está fazendo.',
        body: 'Uma peça segura uma casa de mate, uma primeira fileira ou outra peça. Ataque algo que ela valorize mais, ou simplesmente leve algo que ela precise recapturar, e a defesa que ela dava some junto. Muitas vezes o sacrifício parece absurdo até você notar o que a peça que recaptura deixa de cobrir.',
      },
      {
        name: 'Atração',
        short: 'Atraia uma peça — em geral o rei — para uma casa onde possa ser atingida.',
        body: 'Também chamada de isca. Um sacrifício que o adversário é obrigado a aceitar, jogado não para ganhar material mas para pôr uma peça em algum lugar fatal: um rei arrastado para uma casa de garfo, uma dama puxada para uma linha com torre. O material volta com juros um lance depois.',
      },
      {
        name: 'Desobstrução',
        short: 'Tire sua própria peça do caminho do seu próprio ataque.',
        body: 'A linha ou a casa é a certa e tem um homem seu em cima. A desobstrução o move com tempo — normalmente com xeque ou captura, para o adversário não ter tempo de se reorganizar enquanto o caminho abre.',
      },
      {
        name: 'Interferência',
        short: 'Corte a linha entre um defensor e aquilo que ele defende.',
        body: 'Ponha uma peça — muitas vezes sacrificada — bem entre uma torre e a casa que ela guarda. O defensor continua no tabuleiro, continua defendendo na teoria, e já não consegue. Rara, e um dos padrões mais difíceis de ver, porque a peça que interfere costuma parecer um vacilo.',
      },
      {
        name: 'Raio X',
        short: 'Uma peça age através de outra, pela linha que vai ocupar depois.',
        body: 'Uma torre defendendo a própria peça através de uma peça inimiga, ou atacando através dela. Ainda não acontece nada; o que importa é o que acontece assim que a peça do meio se mexer ou for tomada. Reconhecer um raio X costuma ser o que faz uma captura que «perde material» não perder.',
      },
      {
        name: 'Lance intermediário',
        short: 'O zwischenzug: antes de recapturar, faça algo mais forçante.',
        body: 'Do alemão «lance intermediário», e a razão isolada mais comum de uma linha calculada acabar errada. Você espera uma recaptura; em vez dela vem um xeque, ou uma ameaça maior, e quando a recaptura enfim ocorre a posição mudou. Procure um toda vez que uma sequência parecer forçada.',
      },
      {
        name: 'Zugzwang',
        short: 'Ter de jogar é, em si, o problema.',
        body: 'Toda jogada legal piora a posição, e passar não é permitido. Sobretudo uma ideia de final — finais de rei e peões se decidem por ela — e a razão de «a oposição» importar: quem é obrigado a sair primeiro perde a casa. Quase a única situação no xadrez em que o direito de jogar é um peso.',
      },
      {
        name: 'Mate do corredor',
        short: 'Um rei preso pelos próprios peões, matado na primeira fileira.',
        body: 'O mate mais comum entre jogadores que rocaram e deixaram os peões quietos. Raramente aparece como mate no tabuleiro — aparece como ameaça que ganha material, porque toda jogada defensiva precisa continuar guardando a fileira. A família inteira das táticas de desvio existe para tirar essa guarda.',
      },
      {
        name: 'Mate afogado',
        short: 'Um cavalo mata um rei que as próprias peças cercaram.',
        body: 'O fim do legado de Philidor: sacrifício de dama em g8, a torre recaptura, o cavalo em f7 dá mate com o rei cercado pelos seus. Raro em partidas reais e vale saber assim mesmo, porque o padrão é o que faz você olhar um canto e contar casas de fuga.',
      },
      {
        name: 'Peça pendurada',
        short: 'Alguma coisa está simplesmente indefesa e dá para tomar.',
        body: 'Nada glamouroso, e decide mais partidas do que todo o resto desta lista junto. A maioria das derrotas abaixo de 1800 é um jogador levando uma peça de graça que o outro parou de olhar. O hábito que resolve é conferir o que está solto — nas duas cores — antes de cada lance.',
      },
      {
        name: 'Peça presa',
        short: 'Uma peça não tem casa segura e pode ser caçada com calma.',
        body: 'Em geral um bispo que tomou um peão que devia ter deixado, ou um cavalo que foi para a pilhagem. A tática não é um golpe único e sim um aperto: tire as casas uma a uma e a peça cai sem precisar de sacrifício.',
      },
      {
        name: 'Lance quieto',
        short: 'A jogada vencedora não é xeque, não é captura e não é ameaça.',
        body: 'A razão de jogadores fortes acharem combinações que outros perdem. Depois de uma sequência forçada, a resposta é um lance modesto que tira a última casa de fuga, e ele é invisível para quem só calcula xeques e capturas. Se a posição parece ganha e nada forçante funciona, procure o quieto.',
      },
      {
        name: 'Sacrifício',
        short: 'Dê material por algo que vale mais do que material.',
        body: 'Tempo, linhas, casas ou a posição do rei adversário. Um sacrifício de verdade não é aposta; é um cálculo com um fim concreto. O que separa o que funciona do que não funciona é quase sempre se as peças defensoras conseguem voltar a tempo.',
      },
      {
        name: 'Peão avançado',
        short: 'Um peão perto da promoção muda quanto vale qualquer outra peça.',
        body: 'Um peão na sétima não é um peão; é uma dama que alguma coisa precisa vigiar, e essa coisa deixou de estar livre. A maioria das táticas de final trata, na verdade, da tensão entre parar um peão e fazer qualquer outra coisa.',
      },
    ],
    after: {
      slug: 'Por que os números estão aqui',
      title: 'Um glossário diz o que é um garfo. Um número diz se dá para treinar.',
      body: [
        'Saber o nome de um padrão e conseguir achá-lo sob o relógio são habilidades diferentes, e só a segunda ganha partidas. Cada contagem acima é o número real de posições da biblioteca incluída marcadas com aquele motivo — não uma estimativa, e sem arredondar para cima. Sessenta exercícios de raio X são sessenta; se é isso que você continua errando, vale saber que não vão acabar numa noite.',
        'O treinador acompanha quais motivos você erra, então depois de algumas centenas de exercícios consegue dizer não que você é 1620, mas que você é 1620 e continua passando batido pelos desvios.',
      ],
      more: 'Como os exercícios são extraídos e verificados →',
    },
  },
};
