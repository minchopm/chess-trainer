import type { Pages } from './types';

/** The four commercial pages in Turkish. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Destek',
      title: 'Bir insana sorun',
      lede: 'Bilet sistemi yok, sohbet botu yok, dört yüz makalelik bir yardım merkezi yok. Bir e-posta adresi ve bir arıza listesi var; ikisi de uygulamayı yazan kişiye ulaşıyor.',
    },
    meta: {
      title: 'Destek',
      description:
        'Brass Pawn hakkında bir insana nasıl ulaşacağınız, bir problem hatalıysa neyi göndereceğiniz ve en sık gelen sorular.',
    },
    email: {
      slug: 'E-posta',
      body: 'Her şey için: bir hata, hatalı bir problem, bir satın alma sorusu ya da bir değerlendirmeye itiraz. İngilizce veya Bulgarca yazın.',
    },
    tracker: {
      slug: 'Arıza listesi',
      name: 'GitHub kayıtları',
      body: 'Herkese açık olmasını tercih ettiğiniz her şey için — ve başkalarının sonradan bulabilmesi gereken her şey için ki bu, hata bildirimlerinin çoğu için geçerlidir.',
    },
    report: {
      slug: 'Bir problem hatalıysa',
      title: 'Dört şey gönderin, kontrol bir dakika sürsün.',
      checklist: [
        'Problem ekranında görünen FEN — kopyalamak için basılı tutun.',
        'Yaptığınız hamle ve uygulamanın doğru dediği hamle.',
        'Hangi moddaydınız.',
        'Uygulama sürümü, bilgi ekranından.',
      ],
      caveat:
        'Problemler zaman zaman daha derin bir aramayla çelişir ve bu çelişkiler, özü kontrolün ulaştığından daha derinde yatan uzun, sessiz, yüksek puanlı konumlarda birikir. Bu, kontrolün sınırıdır, problemin hatası değil — ama hangileri olduğunu bilmek değerlidir ve bunu bilmenin tek yolu sizin söylemenizdir.',
    },
    faq: { slug: 'Sorular', title: 'Yazılacak kadar sık soruluyor.' },
    more: {
      ratings: 'Bir puan neyi ölçer',
      tactics: 'Motifler',
      privacy: 'Gizlilik politikası',
      terms: 'Kullanım koşulları',
      licences: 'Lisanslar',
    },
  },

  pricing: {
    head: {
      slug: 'Ne kadar',
      title: 'Oynamak ücretsiz. Satılan şey antrenman.',
      lede: 'Motora karşı satranç ve insana karşı satranç, sınırsız, uygulamanın hiçbir yerinde reklam olmadan — bu ücretsiz ve öyle kalacak. Satılan şey kütüphane, alıştırmalar, problemler ve saate karşı yarış.',
    },
    meta: {
      title: 'Fiyatlar',
      description:
        'Oynamak ücretsiz ve sınırsız — motor, canlı bir rakip ve 900 partinin tamamı. Pro günde beş sınırını kaldırır: ayda 3,99 dolar ya da tek seferde 49,99.',
    },
    free: {
      name: 'Ücretsiz',
      note: 'Hesap yok. Kaydolunacak bir şey yok.',
      items: [
        'Motora karşı sınırsız oyun, 1400’den tam güce',
        'Game Center üzerinden sınırsız çevrimiçi parti',
        'Oynadığınız her partide hamle hamle yorum',
        'Günde beş taktik problemi',
        'Günde beş Rush turu',
        'Her birinden beş: konumsal, oyun sonu, Elo’yu Tahmin Et',
        'Puanlar, seriler ve aralıklı tekrar, tümüyle',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Aylık',
      per: 'ayda',
      note: 'Apple hesabınızın ayarlarından istediğiniz zaman iptal edilir.',
      items: [
        'Tüm günlük sınırlar kalkar',
        '{tactics} taktik probleminin tamamı',
        '{positional} konumsal alıştırmanın tamamı',
        '{endgames} oyun sonu alıştırmasının tamamı',
        'Değerlendirilecek {games} partinin tamamı',
        'Sınırsız Rush',
        'Ücretsiz sürümdeki her şey, değişmeden',
      ],
    },
    lifetime: {
      name: 'Tek seferlik açma',
      once: 'bir kez ve temelli',
      note: 'Tüketilmeyen bir satın alma. Yenilenmez.',
      items: [
        'Aylık Pro ile tam olarak aynı',
        'Yenileme yok, bitiş tarihi yok, hatırlatma e-postası yok',
        'Diğer cihazlarınızda geri yüklenir',
        'Bir kez karar vermeyi yeğleyenler için',
      ],
    },
    table: {
      slug: 'Tam porsiyon',
      title: 'Ücretsiz sürüm gerçekte ne veriyor.',
      activity: 'Etkinlik',
      freeCol: 'Ücretsiz',
      proCol: 'Pro',
      unlimited: 'Sınırsız',
      fiveADay: 'Günde 5',
      none: 'Yok',
      rows: [
        'Motora karşı oyun',
        'Game Center üzerinden çevrimiçi partiler',
        'İzleme — 900 partilik kütüphane',
        'Taktik problemleri',
        'Rush turları',
        'Konumsal alıştırmalar',
        'Oyun sonu alıştırmaları',
        'Elo’yu Tahmin Et',
        'Reklamlar',
      ],
      reset:
        'Günlük porsiyonlar yerel saatle sabah dokuzda sıfırlanır — gece yarısında değil, ki akşam çalışması tarih değişimiyle ikiye bölünmesin.',
    },
    why: {
      slug: 'Neden bu biçimde',
      title: 'Üç karar ve her birinin nedeni.',
      reasons: [
        {
          title: 'Sayılıyor, kilitlenmiyor',
          body: [
            'Kimse kullanmadığı bir antrenör için para vermez ve açılmayı reddeden bir mod, arkasında ne olduğuna dair hiçbir şey söylemez. Bu yüzden her mod her gün açılır ve ritmi hissedip puanın hareket ettiğini görecek kadar ilerlersiniz.',
            'Satın alma ekranı açılışta asla belirmez. Günün porsiyonu bittiğinde ekran bunu söyler ve satın alma sayfasını yalnızca bilinçli bir dokunuş açar.',
          ],
        },
        {
          title: 'İki fiyat, üç değil',
          body: [
            'Arada yıllık plan yok, çünkü üçüncü bir fiyat, tam da birinin problem çözmek istediği anda üçüncü bir karardır. Kararsızsanız aylık. Değilseniz tek seferlik.',
          ],
        },
        {
          title: 'Oynamak asla satılmaz',
          body: [
            'Motora ve insana karşı satranç işletmesi hiçbir şeye mal olmaz ve uygulamanın var olma nedenidir. Bunları satmak, uygulamayı antrenör yerine paralı geçitli bir satranç uygulamasına çevirirdi.',
            'Ve reklam yok — kısmen zevk, kısmen lisans. Uygulama iki copyleft motoru bağlıyor: GPLv3 altındaki Stockfish ve AGPLv3 altındaki Reckless; aynı ikili dosyadaki tescilli bir reklam SDK’sı bütünü dağıtılamaz kılardı. {link}',
          ],
        },
      ],
      licenceLink: 'Lisans sayfası bunu sırayla açıklıyor.',
    },
    answers: {
      slug: 'Satın alma, iptal, iade',
      title: 'Rahatsız edici sorular, e-posta yerine burada yanıtlandı.',
      items: [
        {
          q: 'Nasıl iptal ederim?',
          a: 'Ayarlar → adınız → Abonelikler → Brass Pawn. Sizin adınıza iptal edemeyiz, çünkü abonelik sizinle Apple arasındadır ve hiçbir zaman bizde olmadı. İptal, gelecekteki yenilemeleri durdurur ve ödenmiş dönemi kısaltmaz.',
        },
        {
          q: 'Paramı nasıl geri alırım?',
          a: 'Apple üzerinden, şu adresten: {link}. App Store satın almalarını iade edemeyiz. Bir şey bozuksa bize yazın — onarmayı yeğleriz.',
        },
        {
          q: 'Açmayı satın aldım ve yeni telefonum var.',
          a: 'Aynı Apple hesabıyla giriş yapın ve satın alma ekranında “Satın almaları geri yükle”ye dokunun. Uygulama neye sahip olduğunuzu StoreKit’e sorar; bizim sunucumuzda hiçbir şey durmuyor, çünkü bizim sunucumuz yok.',
        },
        {
          q: 'Pro puanımı değiştirir mi ya da “daha iyi” problemleri açar mı?',
          a: 'Hayır. Puanlama sistemi aynıdır ve kütüphanedeki her probleme ücretsiz hesapla ulaşılır — günde beş. Pro sayacı kaldırır, perdeyi değil.',
        },
        {
          q: 'Ücretsiz porsiyon ileride küçülür mü?',
          a: 'Kütüphane büyüdükçe iki yönde de değişebilir. Motora ve insana karşı sınırsız oyun ücretli bir özellik olmayacak; bu yalnızca burada söz verilmiş değil, {link} yazılıdır.',
        },
      ],
      termsLink: 'koşullarda',
      more: 'Daha fazla soru ve bir insana nasıl ulaşılır →',
    },
  },

  training: {
    head: {
      slug: 'Program',
      title: 'Gerçeği duymanın sekiz yolu',
      lede: 'Bunlardan üçü sonsuza dek ücretsiz ve sınırsız — oynamak, biriyle oynamak ve İzleme’deki dokuz yüz parti. Diğer beşi ücretsiz hesapla günde beş, Pro ile sınırsız. Her biri sizi, önce çözmeniz gereken bir sayı yerine konum hakkındaki sözlerle değerlendirir.',
    },
    meta: {
      title: 'Antrenman',
      description:
        'Sekiz mod: taktik, konumsal yargı, oyun sonları, Rush, Elo’yu Tahmin Et, İzleme, yorumlu oyun ve çevrimiçi. Her birinin nasıl işlediği, problemlerin nasıl çıkarılıp doğrulandığı ve antrenörün ne yapmadığı.',
    },
    modes: [
      {
        title: 'Taktik',
        lede: 'Tam olarak bir kazanan hamlesi olan konumlar ve onu oynadığınız anda gelen hüküm.',
        body: [
          'Her problemin tek bir yanıtı vardır, dallanma yoktur. Tahtada oynayın, antrenör bulup bulmadığınızı hemen söyler; ıskalarsanız konum yarın döner, sonra dört gün sonra, sonra on gün sonra — sizi yakalamayı sürdürdükçe.',
          'Her problem döndüğü motifi taşır — çatal, bağlama, şiş, son sıra matı, saptırma, sessiz hamle — ki birkaç yüzün ardından antrenör size 1620 olduğunuzu değil, 1620 olduğunuzu ve saptırmalara tekrar tekrar düştüğünüzü söyleyebilsin.',
        ],
        free: 'Ücretsiz hesapla günde beş.',
        stat: 'problem, 760’tan 2800’e puanlanmış',
      },
      {
        title: 'Konumsal yargı',
        lede: 'Zorlanmış kazanç yok. Kimin daha iyi durduğunu söyleyin, sonra nedenini söyleyen hamleyi bulun.',
        body: [
          'Bu, güçlü oyuncuları iyi hesapçılardan ayıran şey için kurulmuş moddur. Önce değerlendirirsiniz: açıkça daha iyi, biraz daha iyi, denge. Sonra bir hamle seçersiniz. İki yanıt da değerlendirilir.',
          'Geri bildirim ruh hâlleri yerine somut özellikleri adlandırır — açık dikey ve üzerinde kale olup olmadığı, hiçbir piyonun tartışamayacağı at karesi, piyon yapısı, şah güvenliği, taş etkinliğindeki fark. Bir konum “beyaz için hoş” değildir; sayabileceğiniz dört nedenden ötürü daha iyidir.',
        ],
        free: 'Ücretsiz hesapla günde beş.',
        stat: 'sessiz konum, motor tarafından önceden seçilmiş',
      },
      {
        title: 'Oyun sonları',
        lede: 'Kanonik konumlar, düzgün savunan bir motora karşı sonuna kadar oynanır.',
        body: [
          'Fikri bilmek onu eve getirmekle aynı şey değildir, bu yüzden burada sonuca gerçekten ulaşmanız gerekir. Stockfish karşı tarafı alır ve var olan en iyi savunmayı kurar.',
          'Her hamleden sonra antrenör sonucun hâlâ ulaşılabilir olup olmadığını yeniden denetler — değilse, ulaşılabilir olmaktan çıktığı tam hamleyi adlandırır. Bir şey öğreten cümle budur: “berabere yaptınız” değil, “burada berabere yaptınız”.',
        ],
        free: 'Ücretsiz hesapla günde beş.',
        stat: 'alıştırma, her sonuç motorla doğrulanmış',
      },
      {
        title: 'Rush',
        lede: 'Süreli bir tur. Saat geri kalanını almadan önce yetişebildiğiniz kadarını çözün.',
        body: [
          'Aynı problemler, saat altında, siz bulmayı sürdürdükçe yükselen bir zorlukla. Bu, bakıp durmaya izin verilen bir problemden başka bir kası çalıştırır: şimdi görmesi gerekeni.',
          'Turlar puanlanır ve kaydedilir, böylece sayı bir akşam boyunca değil aylar boyunca yükselir.',
        ],
        free: 'Ücretsiz hesapla günde beş tur.',
      },
      {
        title: 'Elo’yu Tahmin Et',
        lede: 'Gerçek bir dereceli parti, hamle hamle oynatılır. Bu ikisi ne kadar güçlüydü?',
        body: [
          'Bir partinin düzeyini okumak, kendi hamlelerinizi değerlendirmekle aynı beceridir: ikisi de hangi hataların yapıldığını ve hangilerinin yapılmadığını fark etmeye iner. Parti akar, siz izlersiniz ve bir noktada bir sayıya bağlanırsınız.',
          'Partiler gerçektir, Lichess arşivlerinden, iki oyuncu birbirinden 150 puan içinde — “oyuncular” hakkındaki bir tahmin ancak tahmin edilecek tek bir düzey varken anlam taşır.',
        ],
        free: 'Ücretsiz hesapla günde beş.',
        stat: 'dereceli parti, 800’den 2599’a',
      },
      {
        title: 'İzleme',
        lede: 'Görülmeye değer dokuz yüz parti — ve başka türlü oynayacağınız anda partiyi siz devralırsınız.',
        body: [
          'Kütüphanedeki her parti kesin sonuçludur, adı olan iki oyuncu arasındadır ve ya yirmi beş hamlede bitmiştir ya da kendi adı olacak kadar ünlüdür. Kimse hiç duymadığı insanlar arasındaki doksan hamlelik bir beraberlikten bir şey öğrenmez ve bunu içeren bir kütüphane, kimsenin ikinci kez açmadığı bir kütüphanedir.',
          'Bir oyuncu, bir turnuva ya da bir yıl arayın. Sonra partiyi kendi hızınızda geçin. Mesele en parlak anlar değil: mesele bir hamlede <em>ben orada alırdım</em> diye düşünecek olmanız — ve o anda alabilirsiniz. Konumu devralın ve tam olarak katılmadığınız kareden motora karşı devam edin. Fikrinizin gerçekte ne ettiğini bulmak, alıştırmanın kendisidir.',
        ],
        free: 'Ücretsiz, sınırsız, her zaman.',
        stat: 'parti, hepsi kesin sonuçlu',
      },
      {
        title: 'Antrenörle oyun',
        lede: 'Seçtiğiniz güçte tam bir parti ve yol boyunca değerlendirilen her hamleniz.',
        body: [
          'Motoru 1400 ile tam güç arasında bir yere koyun ve partiyi sonuna dek oynayın. Her hamleniz parti sürerken değerlendirilir ve antrenör daha iyi hamlenin ne sağlayacağını açıklar — sayı olarak değil, konum hakkındaki sözlerle.',
          'Sonunda isabet oranını, kaba hata sayısını ve en pahalıya patlayan o tek anı alırsınız.',
        ],
        free: 'Ücretsiz, sınırsız, her zaman.',
      },
      {
        title: 'Çevrimiçi',
        lede: 'İki insan, bir saat ve yakınlarda hiçbir motor yok.',
        body: [
          'Game Center aynı tempoyu seçmiş birini bulur — 3, 5, 10, 15 ya da 30 dakika. İçinde motor olmayan tek moddur: ipucu yok, hamle değerleri yok, koçluk yok; çünkü yalnızca bir tarafın aldığı yardım parti değildir.',
          'Sunucu yok. İki cihaz birbiriyle konuşur ve ikisi de kuralları uygular, bu yüzden bir hamle ancak alıcı cihazın zaten sahip olduğu konumda kuralsa oynanır. Yalan söyleyen bir karşı taraf, kuraldışı bir tahta değil, atılan bir paket üretir.',
        ],
        free: 'Ücretsiz, sınırsız, her zaman.',
      },
    ],
    watchLink: 'Kütüphaneye ne girdi, ne girmedi →',
    pipeline: {
      slug: 'Bir problem nasıl yapılır',
      title: 'Çıkarıldı, kopyalanmadı.',
      lede: 'Konumları ezberden yazmak, “çözümü” yanlış ya da tek olmayan bir problem riski taşır ve bu tam da yanlış refleksi çalıştırır. Bu yüzden hiçbiri ezberden yazılmadı. Bulunurlar, sonra hayatta kalana ya da atılana kadar saldırıya uğrarlar.',
      steps: [
        {
          title: 'İnsan gücünde oyun',
          body: 'Stockfish kendine karşı bilerek insani güçte oynar — 1320’den 2500 Elo’ya — ve en iyi sığ adaylarından rastgele bir seçimle açar, böylece partiler tek bir varyantı sonsuza dek yinelemek yerine çeşitlenir.',
        },
        {
          title: 'Hataya değil, özelliğe göre eleme',
          body: 'Her konum, iki aday varyantla 12 derinlikte aranır. Sinyal “biri hata yaptı” değil, bir problemin gerçekten gerektirdiği şeydir: her seçenekten çok daha iyi tek bir hamle.',
        },
        {
          title: 'Yeniden derin arama, payla',
          body: 'Hayatta kalanlar MultiPV ile 20 derinlikte yeniden aranır. Bir aday ancak en iyi hamle ikinciyi en az 140 yüzde birlik piyonla geçiyorsa ve ayrıca gerçekten bir şey sağlıyorsa kalır.',
        },
        {
          title: 'Dallanana kadar uzatma',
          body: 'Çözüm, çözenin her hamlesi tek başına en iyi kaldığı sürece hamle hamle uzatılır. İki iyi yanıt olduğu anda problem orada biter — yani asla sizi yanlış saydırabilecek bir dallanması olmaz.',
        },
        {
          title: 'Taze bir motorla doğrulama',
          body: 'Bütün derleme, yeni bir motorla ayrı bir betik tarafından daha büyük derinlikte yeniden incelenir. Birlikte gelen çıkarılmış derlemede bu, çözümleri iki yarım hamle daha derinde tek olmaktan çıkan 172 problemin 6’sını reddetti. Bunlar teslim edilmek yerine atıldı.',
        },
      ],
    },
    honest: {
      title: 'Ve aynı kuşku oyun sonlarına uygulandı',
      body: [
        'Her oyun sonu alıştırmasının bildirilen sonucu, sözüne inanılmak yerine derin bir aramayla doğrulanır. Yanlış etiketlenmiş bir alıştırma, size sessizce doğru olmayan bir şey öğretmek yerine doğrulamada kalır.',
        'Doğrulayıcı, olağan satranç kütüphanelerinin size söylemediği bir şeyi de yakalar: sırası olmayan tarafın şahta olup olmadığını. Böyle bir konum kuraldışıdır — hiçbir parti ona ulaşamaz — ama bir kütüphane onu seve seve kabul eder ve motor bestmove (none) ile yanıt verir; bu, kötü bir konumdan çok motor arızası gibi duyulur. Elle yazılmış üç alıştırma tam olarak böyle bozuktu. Doğrulama bunu artık yakalıyor.',
      ],
    },
    limits: {
      slug: 'Dürüst sınırlar',
      title: 'Bunun yapmadıkları.',
      items: [
        {
          title: 'Derleme iki puan ölçeğini karıştırıyor.',
          body: '{lichess} Lichess problemi, milyonlarca insan denemesine göre ayarlanmış puanlar taşır. Yerel olarak çıkarılmış {mined} problem, çözüm derinliği ve motiften gelen tahminler taşır. İkisi de anlamlı sıralar, ama çıkarılmış bir 1600 ile Lichess 1600’ü aynı biçimde ölçülmemiştir.',
        },
        {
          title: 'Problem puanları tahta puanları değildir.',
          body: 'Birkaç yüz puan daha yüksektedir ve öyle kalacak. Kendinize karşı ilerlemeyi ölçerler, saat başındaki bir insan alanına karşı gücü değil — {link}, çünkü bu fark yapısaldır ve kötü bitirdiğinizin işareti değildir.',
        },
        {
          title: 'Açılış antrenmanı yok.',
          body: 'Kasten. Açılış çalışması, kendi seçtiğiniz bir repertuvara karşı ezberdir ve o, başka biçimde başka bir araçtır. Konumsal mod açılıştan çıkışı kapsar ve gerçekten genelleşen kısım odur.',
        },
        {
          title: 'Bu sizi büyükusta yapmaz.',
          body: 'Hiçbir şey bunu tek başına yapmaz. Unvanlar binlerce saatten artı insanlara karşı dereceli turnuva partilerinden gelir. Burada aldığınız şey bunun antrenman yarısıdır, düzenlenmiş hâlde, gerçekte nerede durduğunuzun dürüst bir ölçüsüyle.',
        },
      ],
      ratingsLink: 'doğru anlamaya değer',
    },
    more: {
      motifs: 'Yirmi motif, tanımlanmış ve sayılmış →',
      engine: 'Motor nasıl kullanılıyor →',
    },
  },

  tactics: {
    head: {
      slug: 'Sözlük',
      title: 'Yirmi motif',
      lede: 'Satrançtaki her taktik, az sayıda biçimden biridir ve onları adlandırabildiğiniz anda bir hamle önce görürsünüz. Bunlar, Brass Pawn’ın problemlerini etiketlediği motiflerdir — her birinin ardından, birlikte gelen kütüphanede kaç konumun gerçekten onun etrafında döndüğü.',
      meta: 'Birlikte gelen 14.351 problemlik derlemeden sayıldı · Son denetim 19 Ağustos 2026',
    },
    meta: {
      title: 'Yirmi motif',
      description:
        'Brass Pawn’ın problemlerini etiketlediği her taktik motif, birlikte gelen kütüphaneye göre tanımlanmış ve sayılmış; böylece hangilerini gerçekten çalışabileceğinizi bilirsiniz.',
    },
    indexLabel: 'Motifler',
    puzzles: 'problem',
    motifs: [
      {
        name: 'Çatal',
        short: 'Bir taş aynı anda iki şeye saldırır ve yalnızca biri kurtarılabilir.',
        body: 'At ünlü çatalcıdır, çünkü başka hiçbir taşın aynı biçimde örtmediği kareleri döver; ama çatal atan her şeydir: iki hafif taşa değen bir piyon, kaleye ve boştaki file değen bir vezir, oyun sonunda iki piyonun arasına giren bir şah. Sınav “iki şeye mi saldırıyorum” değil, “ikisi de kaçabiliyor mu”dur.',
      },
      {
        name: 'Bağlama',
        short: 'Bir taş kımıldayamaz, çünkü arkasında daha değerli bir şey duruyor.',
        body: 'Arkada şah varsa mutlaktır — kımıldamak kuraldışıdır, yalnızca kötü değil. Arkada vezir ya da kale varsa görecelidir; kımıldamak kuraldır ve sadece malzemeye mal olur. Devam kazanır: bağlanmış taş, örtemeyen taştır; üzerine daha çok saldırgan yığın ya da ona piyonla vurun.',
      },
      {
        name: 'Şiş',
        short: 'Bağlamanın tersi: değerli taş önde durur ve kımıldamak zorundadır.',
        body: 'Kale, fil ya da vezirle bir hat boyunca şah çekin; şah yana adım atar atmaz arkasında duran sizindir. Şişler bağlamalardan daha seyrektir, çünkü değerlisi önde olacak biçimde iki taşın zaten aynı hatta olmasını gerektirir — bu yüzden çoğunlukla bir şah, şahı oraya zorladıktan sonra belirirler.',
      },
      {
        name: 'Açma saldırısı',
        short: 'Bir taşı kaldırmak, arkasındakinin saldırısını açığa çıkarır.',
        body: 'Farkla satrançtaki en güçlü taktik, çünkü çekilen taş kendi işini yapmakta serbestken açığa çıkan saldırı işi görür. Tek hamleyle iki tehdit doğar ve hiçbiri çekilen taşı almakla yanıtlanmaz.',
      },
      {
        name: 'Açma şahı',
        short: 'Açığa çıkan saldırı bir şahtır, bu yüzden rakibin başka bir şeye vakti yoktur.',
        body: 'Arkadaki taşın şah çektiği bir açma saldırısı. Çekilen taş ne yaparsa yapsın — vezir alsın, mat karesine gitsin, kendini alınmaya bıraksın — yanıtın önce şahla ilgilenmesi gerekir, dolayısıyla bu bedavaya olur.',
      },
      {
        name: 'Çifte şah',
        short:
          'İki taş aynı anda şah çeker, bu yüzden şah kımıldamak zorundadır. Örtmek yok, almak yok.',
        body: 'Karşısında tam olarak tek tür kurallı yanıt bulunan tek taktik. Şah çekenlerden birini almak diğerini bırakır; bir hattı kapatmak diğerini açık bırakır. Bu yüzden çifte şah, olanaksız görünen matlar üretir — savunanın her şahı ayrı ayrı durduracak beş yolu olabilir ve ikisini birden durduracak hiçbiri olmayabilir.',
      },
      {
        name: 'Saptırma',
        short: 'Bir savunucuyu yaptığı işten uzaklaşmaya zorlayın.',
        body: 'Bir taş bir mat karesini, bir son sırayı ya da başka bir taşı tutuyordur. Daha çok değer verdiği bir şeye saldırın ya da yalnızca geri almak zorunda olduğu bir şeyi alın; verdiği örtü de onunla birlikte gider. Feda, geri alan taşın artık neyi örtmediğini fark edene dek çoğu zaman saçma görünür.',
      },
      {
        name: 'Çekme',
        short: 'Bir taşı — genellikle şahı — vurulabileceği bir kareye çekin.',
        body: 'Rakibin almak zorunda olduğu bir feda; malzeme kazanmak için değil, bir taşı ölümcül biçimde yerleştirmek için oynanır: çatal karesine sürüklenen bir şah, kaleyle aynı hatta çekilen bir vezir. Malzeme bir hamle sonra faiziyle geri gelir.',
      },
      {
        name: 'Hat açma',
        short: 'Kendi taşınızı kendi saldırınızın yolundan çekin.',
        body: 'Hat ya da kare doğrudur, üzerinde kendi adamınız durur. Hat açma onu tempoyla kaldırır — genellikle şah ya da alışla, ki yol açılırken rakip yeniden dizilmeye vakit bulamasın.',
      },
      {
        name: 'Araya girme',
        short: 'Bir savunucuyla savunduğu şey arasındaki hattı kesin.',
        body: 'Bir taşı — çoğu zaman feda edilmiş — kaleyle gözettiği karenin tam arasına koyun. Savunucu hâlâ tahtadadır, kuramda hâlâ savunur ve artık yapamaz. Seyrek ve görülmesi en güç desenlerden biri, çünkü araya giren taş genellikle hata gibi durur.',
      },
      {
        name: 'Röntgen saldırısı',
        short: 'Bir taş, sonradan işgal edeceği hat boyunca başka bir taşın içinden işler.',
        body: 'Kendi taşını düşman taşının içinden savunan ya da içinden saldıran bir kale. Henüz hiçbir şey olmaz; önemli olan, aradaki taş kalktığında ya da alındığında ne olacağıdır. Bir röntgeni görmek, çoğu zaman “malzeme kaybettiren” bir alışın malzeme kaybettirmemesini sağlayan şeydir.',
      },
      {
        name: 'Ara hamle',
        short: 'Aradaki hamle: geri almadan önce daha zorlayıcı bir şey yapın.',
        body: 'Almanca “Zwischenzug”dan gelir ve hesaplanmış bir varyantın yanlış çıkmasının en sık tek nedenidir. Bir geri alış beklersiniz; onun yerine bir şah ya da daha büyük bir tehdit gelir ve geri alış gerçekleştiğinde konum değişmiştir. Bir dizi zorunlu göründüğü her seferde bir tane arayın.',
      },
      {
        name: 'Zugzwang',
        short: 'Hamle yapma zorunluluğunun kendisi sorundur.',
        body: 'Her kurallı hamle konumu kötüleştirir ve pas geçmek yasaktır. Öncelikle bir oyun sonu fikridir — piyon oyun sonlarını o belirler — ve “muhalefetin” önemli olmasının nedenidir: ilk yana çekilmek zorunda kalan kareyi verir. Satrançta hamle hakkının yük olduğu neredeyse tek durum.',
      },
      {
        name: 'Son sıra matı',
        short: 'Kendi piyonlarınca kapatılmış bir şah birinci sırada mat olur.',
        body: 'Rok yapmış ve piyonlara dokunmamış oyuncular arasındaki en sık mat. Tahtada mat olarak seyrek belirir — malzeme kazandıran bir tehdit olarak belirir, çünkü her savunma hamlesinin sırayı örtmeyi sürdürmesi gerekir. Bütün saptırma taktikleri ailesi, o örtüyü kaldırmak için vardır.',
      },
      {
        name: 'Boğma mat',
        short: 'Bir at, kendi taşlarının kapattığı bir şahı mat eder.',
        body: 'Philidor mirasının sonu: g8’de vezir fedası, kale geri alır, f7’deki at mat eder ve şah kendi adamlarıyla çevrilidir. Gerçek partilerde seyrektir ve yine de bilmeye değer, çünkü sizi köşeye bakıp kaçış karelerini saymaya iten şey bu desendir.',
      },
      {
        name: 'Askıda taş',
        short: 'Bir şey yalnızca korumasızdır ve alınabilir.',
        body: 'Gösterişli değil, ama bu listedeki her şeyden daha çok parti belirler. 1800 altındaki yenilgilerin çoğu, birinin gözden kaçırdığı bedava taşı öbürünün almasıdır. Bunu iyileştiren alışkanlık, her hamleden önce neyin boşta durduğunu — iki renkte de — denetlemektir.',
      },
      {
        name: 'Tuzağa düşmüş taş',
        short: 'Bir taşın güvenli karesi yoktur ve rahat rahat avlanabilir.',
        body: 'Genellikle bırakması gereken bir piyonu alan bir fil ya da yağmaya çıkmış bir at. Taktik tek bir darbe değil, bir boğmadır: kareleri birer birer alın, taş fedaya gerek kalmadan düşer.',
      },
      {
        name: 'Sessiz hamle',
        short: 'Kazandıran hamle ne şahtır, ne alıştır, ne de tehdit.',
        body: 'Güçlü oyuncuların başkalarının kaçırdığı kombinezonları bulmasının nedeni. Zorunlu bir dizinin ardından yanıt, son kaçış karesini alan alçakgönüllü bir hamledir ve yalnızca şah ile alışları hesaplayan için görünmezdir. Bir konum kazanılmış görünüyor ve zorlayıcı hiçbir şey işe yaramıyorsa, sessiz olanı arayın.',
      },
      {
        name: 'Feda',
        short: 'Malzemeden daha değerli bir şey için malzeme verin.',
        body: 'Zaman, hatlar, kareler ya da düşman şahının konumu. Gerçek feda bir bahis değildir; somut bir sonu olan bir hesaptır. İşleyen bir fedayı işlemeyenden ayıran şey neredeyse her zaman, savunan taşların zamanında dönüp dönemeyeceğidir.',
      },
      {
        name: 'İlerlemiş piyon',
        short: 'Terfiye yakın bir piyon, her taşın ne ettiğini değiştirir.',
        body: 'Yedinci sıradaki piyon piyon değildir; bir şeyin gözetmesi gereken bir vezirdir ve o şey artık serbest değildir. Oyun sonu taktiklerinin çoğu gerçekte, bir piyonu durdurmakla başka herhangi bir şey yapmak arasındaki gerilimle ilgilidir.',
      },
    ],
    after: {
      slug: 'Sayılar neden burada',
      title: 'Sözlük çatalın ne olduğunu söyler. Sayı, onu çalışabilir misiniz onu söyler.',
      body: [
        'Bir desenin adını bilmek ile onu saat altında bulabilmek ayrı becerilerdir ve partileri yalnızca ikincisi kazanır. Yukarıdaki her sayı, birlikte gelen kütüphanede o motifle etiketlenmiş konumların gerçek sayısıdır — tahmin değil, yukarı yuvarlanmış değil. Altmış röntgen problemi altmıştır; sürekli kaçırdığınız şey buysa, bir akşamda tükenmeyeceklerini bilmek iyidir.',
        'Antrenör hangi motifleri yanlış yaptığınızı izler, ki birkaç yüz problemden sonra size 1620 olduğunuzu değil, 1620 olduğunuzu ve saptırmalara tekrar tekrar düştüğünüzü söyleyebilsin.',
      ],
      more: 'Problemler nasıl çıkarılıp doğrulanıyor →',
    },
  },
};
