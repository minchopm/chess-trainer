import type { Pages } from './types';

/** The four commercial pages in Malay. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Sokongan',
      title: 'Tanyalah seorang manusia',
      lede: 'Tiada sistem tiket, tiada bot sembang, dan tiada pusat bantuan berisi empat ratus artikel. Yang ada ialah satu alamat e-mel dan satu senarai kerosakan, dan kedua-duanya sampai kepada orang yang menulis aplikasi ini.',
    },
    meta: {
      title: 'Sokongan',
      description:
        'Cara menghubungi seorang manusia tentang Brass Pawn, apa yang perlu dihantar apabila sesuatu teka-teki tersilap, dan soalan yang paling kerap timbul.',
    },
    email: {
      slug: 'E-mel',
      body: 'Untuk apa jua: pepijat, teka-teki yang tersilap, soalan tentang pembelian, atau tidak bersetuju dengan sesuatu penilaian. Tulislah dalam bahasa Inggeris atau Bulgaria.',
    },
    tracker: {
      slug: 'Senarai kerosakan',
      name: 'Isu di GitHub',
      body: 'Untuk apa jua yang anda lebih suka terbuka — dan untuk apa jua yang perlu ditemui orang lain kelak, yang berlaku bagi kebanyakan laporan pepijat.',
    },
    report: {
      slug: 'Apabila teka-teki tersilap',
      title: 'Hantar empat perkara, dan semakan mengambil masa satu minit.',
      checklist: [
        'FEN yang terpapar pada skrin teka-teki — tekan lama untuk menyalinnya.',
        'Langkah yang anda main, dan langkah yang aplikasi katakan betul.',
        'Anda berada dalam mod yang mana.',
        'Versi aplikasi, daripada skrin maklumat.',
      ],
      caveat:
        'Teka-teki sesekali bercanggah dengan carian yang lebih dalam, dan percanggahan itu berhimpun pada kedudukan yang panjang, sunyi dan bertaraf tinggi yang intipatinya terletak lebih dalam daripada jangkauan semakan. Itu had semakan, bukan kesilapan teka-teki — tetapi berbaloi untuk tahu yang mana satu, dan satu-satunya cara mengetahuinya ialah anda memberitahu.',
    },
    faq: { slug: 'Soalan', title: 'Cukup kerap ditanya sehingga perlu ditulis.' },
    more: {
      ratings: 'Apa yang diukur oleh taraf',
      tactics: 'Motifnya',
      privacy: 'Dasar privasi',
      terms: 'Terma penggunaan',
      licences: 'Lesen',
    },
  },

  pricing: {
    head: {
      slug: 'Berapa kosnya',
      title: 'Bermain itu percuma. Yang dijual ialah latihannya.',
      lede: 'Catur menentang enjin dan catur menentang manusia, tanpa had, tanpa iklan di mana-mana dalam aplikasi — itu percuma dan akan kekal begitu. Yang dijual ialah pustaka, latih tubi, teka-teki dan perlumbaan dengan jam.',
    },
    meta: {
      title: 'Harga',
      description:
        'Bermain itu percuma dan tanpa had — enjin, lawan manusia sebenar dan kesemua 900 perlawanan. Pro menanggalkan had lima sehari: 3,99 dolar sebulan atau 49,99 sekali bayar.',
    },
    free: {
      name: 'Percuma',
      note: 'Tiada akaun. Tiada apa untuk didaftarkan.',
      items: [
        'Permainan tanpa had menentang enjin, dari 1400 hingga kekuatan penuh',
        'Perlawanan dalam talian tanpa had melalui Game Center',
        'Ulasan langkah demi langkah dalam setiap perlawanan yang anda main',
        'Lima teka-teki taktik sehari',
        'Lima pusingan Rush sehari',
        'Lima setiap satu: kedudukan, penamat, Teka Elo',
        'Taraf, rentetan dan ulangan berjarak, sepenuhnya',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Bulanan',
      per: 'sebulan',
      note: 'Batalkan bila-bila masa dalam tetapan akaun Apple anda.',
      items: [
        'Semua had harian ditanggalkan',
        'Kesemua {tactics} teka-teki taktik',
        'Kesemua {positional} latih tubi kedudukan',
        'Kesemua {endgames} latih tubi penamat',
        'Kesemua {games} perlawanan untuk dinilai',
        'Rush tanpa had',
        'Semua yang ada dalam versi percuma, tanpa perubahan',
      ],
    },
    lifetime: {
      name: 'Buka kunci sekali bayar',
      once: 'sekali untuk selamanya',
      note: 'Pembelian yang tidak habis guna. Ia tidak diperbaharui.',
      items: [
        'Sama betul dengan Pro bulanan',
        'Tiada pembaharuan, tiada tarikh luput, tiada e-mel peringatan',
        'Dipulihkan pada peranti anda yang lain',
        'Untuk yang lebih suka membuat keputusan sekali sahaja',
      ],
    },
    table: {
      slug: 'Bahagian penuhnya',
      title: 'Apa yang sebenarnya diberi oleh versi percuma.',
      activity: 'Aktiviti',
      freeCol: 'Percuma',
      proCol: 'Pro',
      unlimited: 'Tanpa had',
      fiveADay: '5 sehari',
      none: 'Tiada',
      rows: [
        'Bermain menentang enjin',
        'Perlawanan dalam talian melalui Game Center',
        'Menonton — pustaka 900 perlawanan',
        'Teka-teki taktik',
        'Pusingan Rush',
        'Latih tubi kedudukan',
        'Latih tubi penamat',
        'Teka Elo',
        'Iklan',
      ],
      reset:
        'Bahagian harian ditetapkan semula pada pukul sembilan pagi waktu tempatan — bukan tengah malam, supaya sesi malam tidak terkerat dua oleh pertukaran tarikh.',
    },
    why: {
      slug: 'Kenapa bentuknya begini',
      title: 'Tiga keputusan, dan sebab bagi setiap satu.',
      reasons: [
        {
          title: 'Dikira, bukan dikunci',
          body: [
            'Tiada siapa membayar jurulatih yang tidak pernah digunakannya, dan mod yang enggan terbuka tidak memberitahu apa-apa tentang apa yang ada di sebaliknya. Maka setiap mod terbuka, setiap hari, dan anda melangkah cukup jauh untuk merasai iramanya dan melihat taraf bergerak.',
            'Skrin pembelian tidak pernah muncul semasa aplikasi dimulakan. Apabila bahagian hari itu habis, skrin memberitahunya, dan hanya ketikan yang sedar membuka helaian pembelian.',
          ],
        },
        {
          title: 'Dua harga, bukan tiga',
          body: [
            'Tiada pelan tahunan di tengah, kerana harga ketiga ialah keputusan ketiga tepat pada saat seseorang mahu menyelesaikan teka-teki. Bulanan jika anda teragak-agak. Sekali bayar jika tidak.',
          ],
        },
        {
          title: 'Bermain tidak pernah dijual',
          body: [
            'Catur menentang enjin dan menentang manusia tidak memakan kos untuk dijalankan dan merupakan sebab aplikasi ini wujud. Menjualnya akan menjadikannya aplikasi catur berpagar tol dan bukan seorang jurulatih.',
            'Dan tiada iklan — sebahagiannya cita rasa, sebahagiannya lesen. Aplikasi ini memaut dua enjin copyleft, Stockfish di bawah GPLv3 dan Reckless di bawah AGPLv3, dan SDK iklan hak milik dalam binari yang sama akan menjadikan keseluruhannya tidak boleh diedarkan. {link}',
          ],
        },
      ],
      licenceLink: 'Halaman lesen menerangkannya satu persatu.',
    },
    answers: {
      slug: 'Beli, batal, bayaran balik',
      title: 'Soalan yang janggal, dijawab di sini dan bukan melalui e-mel.',
      items: [
        {
          q: 'Bagaimana saya membatalkan?',
          a: 'Tetapan → nama anda → Langganan → Brass Pawn. Kami tidak boleh membatalkannya bagi pihak anda, kerana langganan itu antara anda dengan Apple dan tidak pernah berada pada kami. Pembatalan menghentikan pembaharuan akan datang dan tidak memendekkan tempoh yang telah dibayar.',
        },
        {
          q: 'Bagaimana saya mendapat wang saya kembali?',
          a: 'Melalui Apple, di {link}. Kami tidak boleh membayar balik pembelian App Store. Jika ada yang rosak, tulislah kepada kami — kami lebih suka membaikinya.',
        },
        {
          q: 'Saya membeli buka kunci dan kini bertukar telefon.',
          a: 'Log masuk dengan akaun Apple yang sama dan ketik “Pulihkan pembelian” pada skrin pembelian. Aplikasi bertanya kepada StoreKit apa yang anda miliki; tiada apa-apa tersimpan pada pelayan kami, kerana kami tiada pelayan.',
        },
        {
          q: 'Adakah Pro mengubah taraf saya atau membuka teka-teki yang “lebih baik”?',
          a: 'Tidak. Sistem taraf adalah sama, dan setiap teka-teki dalam pustaka boleh dicapai dengan akaun percuma — lima sehari. Pro menanggalkan pembilang, bukan tabir.',
        },
        {
          q: 'Adakah bahagian percuma akan mengecil kemudian?',
          a: 'Ia boleh berubah ke dua arah sambil pustaka membesar. Permainan tanpa had menentang enjin dan menentang manusia tidak akan menjadi ciri berbayar; itu tertulis dalam {link}, bukan sekadar dijanjikan di sini.',
        },
      ],
      termsLink: 'terma',
      more: 'Lebih banyak soalan, dan cara menghubungi seorang manusia →',
    },
  },

  training: {
    head: {
      slug: 'Programnya',
      title: 'Lapan cara untuk mendengar kebenaran',
      lede: 'Tiga daripadanya percuma dan tanpa had selamanya — bermain, bermain dengan seseorang, dan sembilan ratus perlawanan dalam Menonton. Lima yang lain adalah lima sehari dengan akaun percuma dan tanpa had dengan Pro. Setiap satu menilai anda dengan kata-kata tentang kedudukan dan bukan dengan nombor yang perlu ditafsirkan dahulu.',
    },
    meta: {
      title: 'Latihan',
      description:
        'Lapan mod: taktik, pertimbangan kedudukan, penamat, Rush, Teka Elo, Menonton, bermain dengan ulasan dan dalam talian. Cara setiap satu berfungsi, cara teka-teki dilombong dan disemak, dan apa yang tidak dilakukan oleh jurulatih.',
    },
    modes: [
      {
        title: 'Taktik',
        lede: 'Kedudukan dengan tepat satu langkah menang, dan keputusan pada saat anda memainkannya.',
        body: [
          'Setiap teka-teki mempunyai satu jawapan dan tiada cabang. Mainkannya di papan dan jurulatih terus memberitahu sama ada anda menemuinya; jika tersasar, kedudukan itu kembali esok, kemudian empat hari lagi, kemudian sepuluh — selagi ia masih menangkap anda.',
          'Setiap teka-teki membawa motif yang menjadi paksinya — cabang dua, ikatan, cucukan, mat baris belakang, pengalihan, langkah senyap — supaya selepas beberapa ratus, jurulatih boleh memberitahu anda bukan bahawa anda 1620, tetapi bahawa anda 1620 dan berkali-kali terjerat pengalihan.',
        ],
        free: 'Lima sehari dengan akaun percuma.',
        stat: 'teka-teki, bertaraf dari 760 hingga 2800',
      },
      {
        title: 'Pertimbangan kedudukan',
        lede: 'Tiada kemenangan paksa. Katakan siapa yang berdiri lebih baik, kemudian cari langkah yang menyatakan sebabnya.',
        body: [
          'Inilah mod yang dibina untuk perkara yang memisahkan pemain kuat daripada pengira yang baik. Mula-mula anda menilai: jelas lebih baik, sedikit lebih baik, seimbang. Kemudian anda memilih langkah. Kedua-dua jawapan dinilai.',
          'Maklum balasnya menamakan ciri yang konkrit dan bukan suasana — lajur terbuka dan sama ada ada tir di atasnya, petak kuda yang tiada bidak boleh mempertikaikan, struktur bidak, keselamatan raja, beza keaktifan buah. Sesuatu kedudukan bukan “selesa bagi putih”; ia lebih baik atas empat sebab yang boleh anda senaraikan.',
        ],
        free: 'Lima sehari dengan akaun percuma.',
        stat: 'kedudukan sunyi, dipilih terlebih dahulu oleh enjin',
      },
      {
        title: 'Penamat',
        lede: 'Kedudukan kanonik, dimainkan hingga tamat menentang enjin yang bertahan dengan wajar.',
        body: [
          'Mengetahui ideanya bukan sama dengan membawanya pulang, jadi di sini anda benar-benar perlu mencapai keputusannya. Stockfish mengambil pihak lawan dan mendirikan pertahanan terbaik yang wujud.',
          'Selepas setiap langkah jurulatih menyemak semula sama ada keputusan itu masih boleh dicapai — dan jika tidak, ia menamakan langkah tepat di mana ia berhenti boleh dicapai. Itulah ayat yang mengajar sesuatu: bukan “anda seri”, tetapi “anda seri di sini”.',
        ],
        free: 'Lima sehari dengan akaun percuma.',
        stat: 'latih tubi, setiap keputusan disemak enjin',
      },
      {
        title: 'Rush',
        lede: 'Satu pusingan berpacu masa. Selesaikan sebanyak yang anda mampu sebelum jam mengambil yang selebihnya.',
        body: [
          'Teka-teki yang sama, di bawah jam, dengan kesukaran yang naik selagi anda terus menemuinya. Itu melatih otot yang berbeza daripada teka-teki yang boleh direnung lama: otot yang mesti melihat sekarang.',
          'Pusingan diberi mata dan disimpan, jadi nombornya naik selama berbulan-bulan dan bukan dalam satu malam.',
        ],
        free: 'Lima pusingan sehari dengan akaun percuma.',
      },
      {
        title: 'Teka Elo',
        lede: 'Satu perlawanan bertaraf yang sebenar, dimainkan semula langkah demi langkah. Sekuat mana kedua-dua orang ini?',
        body: [
          'Membaca tahap sesuatu perlawanan ialah kemahiran yang sama dengan menilai langkah anda sendiri: kedua-duanya berpunca daripada memerhati kesilapan apa yang dibuat dan apa yang tidak. Maka perlawanan berjalan, anda memerhati, dan pada sesuatu titik anda menetapkan satu nombor.',
          'Perlawanannya sebenar, daripada arkib Lichess, dengan kedua-dua pemain berbeza kurang daripada 150 mata — tekaan tentang “para pemain” hanya bermakna apabila ada satu tahap untuk diteka.',
        ],
        free: 'Lima sehari dengan akaun percuma.',
        stat: 'perlawanan bertaraf, dari 800 hingga 2599',
      },
      {
        title: 'Menonton',
        lede: 'Sembilan ratus perlawanan yang berbaloi ditonton — dan pada saat anda akan bermain lain, anda mengambil alih.',
        body: [
          'Setiap perlawanan dalam pustaka adalah menentukan, antara dua pemain bernama, dan sama ada tamat dalam dua puluh lima langkah atau cukup masyhur sehingga mempunyai namanya sendiri. Tiada siapa belajar apa-apa daripada seri sembilan puluh langkah antara orang yang tidak pernah didengarinya, dan pustaka yang mengandunginya ialah pustaka yang tidak dibuka orang kali kedua.',
          'Carilah seorang pemain, satu kejohanan, atau satu tahun. Kemudian telusuri perlawanan itu mengikut rentak anda sendiri. Ini bukan tentang detik puncaknya: ini tentang bahawa pada sesuatu langkah anda akan berfikir <em>saya akan makan di situ</em> — dan pada saat itu anda boleh. Ambil alih kedudukan itu dan teruskan menentang enjin dari petak yang tepat tempat anda tidak bersetuju. Mengetahui apa nilai sebenar idea anda itulah keseluruhan latihannya.',
        ],
        free: 'Percuma, tanpa had, sentiasa.',
        stat: 'perlawanan, semuanya menentukan',
      },
      {
        title: 'Bermain dengan jurulatih',
        lede: 'Satu perlawanan penuh pada kekuatan yang anda pilih, dengan setiap langkah anda dinilai sepanjang jalan.',
        body: [
          'Tetapkan enjin di suatu tempat antara 1400 dan kekuatan penuh dan mainkan perlawanan hingga tamat. Setiap langkah anda dinilai semasa perlawanan masih berjalan, dan jurulatih menerangkan apa yang akan dicapai oleh langkah yang lebih baik — dengan kata-kata tentang kedudukan, bukan sebagai nombor.',
          'Di penghujungnya anda mendapat ketepatan, bilangan kesilapan besar, dan satu detik yang paling mahal harganya.',
        ],
        free: 'Percuma, tanpa had, sentiasa.',
      },
      {
        title: 'Dalam talian',
        lede: 'Dua manusia, satu jam, dan tiada enjin berhampiran.',
        body: [
          'Game Center mencari seseorang yang memilih tempo yang sama — 3, 5, 10, 15 atau 30 minit. Inilah satu-satunya mod tanpa enjin di dalamnya: tiada pembayang, tiada nilai langkah, tiada bimbingan, kerana bantuan yang diterima oleh satu pihak sahaja bukanlah suatu perlawanan.',
          'Tiada pelayan. Kedua-dua peranti bercakap sesama sendiri dan kedua-duanya menguatkuasakan peraturan, jadi sesuatu langkah hanya dimainkan jika ia sah dalam kedudukan yang sudah ada pada peranti penerima. Lawan yang menipu menghasilkan paket yang dibuang, bukan papan yang tidak sah.',
        ],
        free: 'Percuma, tanpa had, sentiasa.',
      },
    ],
    watchLink: 'Apa yang masuk ke dalam pustaka dan apa yang tidak →',
    pipeline: {
      slug: 'Bagaimana sesuatu teka-teki dibuat',
      title: 'Dilombong, bukan disalin.',
      lede: 'Menulis kedudukan daripada ingatan berisiko menghasilkan teka-teki yang “penyelesaiannya” salah atau tidak tunggal, dan itu melatih naluri yang tepat-tepat salah. Maka tiada satu pun ditulis daripada ingatan. Semuanya ditemui kemudian diserang sehingga terselamat atau dibuang.',
      steps: [
        {
          title: 'Bermain pada kekuatan manusia',
          body: 'Stockfish bermain menentang dirinya sendiri pada kekuatan yang sengaja manusiawi — 1320 hingga 2500 Elo — membuka dengan pilihan rawak antara calon cetek terbaiknya, supaya perlawanan berbeza-beza dan bukan mengulang satu variasi selama-lamanya.',
        },
        {
          title: 'Menapis mengikut sifat, bukan kesilapan',
          body: 'Setiap kedudukan dicari pada kedalaman 12 dengan dua barisan calon. Isyaratnya bukan “ada orang tersilap besar” tetapi apa yang sebenarnya diperlukan oleh sesuatu teka-teki: satu langkah yang jauh lebih baik daripada mana-mana alternatif.',
        },
        {
          title: 'Carian dalam sekali lagi, dengan jidar',
          body: 'Yang terselamat dicari semula pada kedalaman 20 dengan MultiPV. Seorang calon hanya kekal jika langkah terbaik mengatasi yang kedua sekurang-kurangnya 140 perseratus bidak dan turut benar-benar mencapai sesuatu.',
        },
        {
          title: 'Dipanjangkan sehingga bercabang',
          body: 'Penyelesaian dipanjangkan langkah demi langkah selagi setiap langkah penyelesai kekal satu-satunya yang terbaik. Pada saat terdapat dua jawapan yang baik, teka-teki itu tamat di situ — jadi ia tidak pernah mempunyai cabang yang boleh mengira anda salah.',
        },
        {
          title: 'Disemak dengan enjin baharu',
          body: 'Keseluruhan koleksi diperiksa semula pada kedalaman lebih besar oleh skrip berasingan dengan enjin baharu. Pada koleksi lombong yang disertakan, ia menolak 6 daripada 172 teka-teki yang penyelesaiannya berhenti menjadi tunggal dua separuh langkah lebih dalam. Semuanya dibuang dan bukan dihantar.',
        },
      ],
    },
    honest: {
      title: 'Dan syak yang sama dikenakan pada penamat',
      body: [
        'Keputusan yang dinyatakan bagi setiap latih tubi penamat disemak dengan carian dalam dan bukan diterima begitu sahaja. Latih tubi yang tersalah label gagal dalam semakan dan bukan diam-diam mengajar anda sesuatu yang tidak benar.',
        'Penyemak turut menangkap sesuatu yang tidak diberitahu oleh pustaka catur biasa: sama ada pihak yang bukan gilirannya sedang disyah. Kedudukan begitu tidak sah — tiada perlawanan boleh mencapainya — tetapi pustaka menerimanya dengan rela, dan enjin menjawab dengan bestmove (none), yang berbunyi seperti kegagalan enjin dan bukan kedudukan yang buruk. Tiga latih tubi tulisan tangan rosak tepat begitu. Semakan kini menangkapnya.',
      ],
    },
    limits: {
      slug: 'Had yang jujur',
      title: 'Apa yang tidak dilakukan oleh ini.',
      items: [
        {
          title: 'Koleksinya mencampurkan dua skala taraf.',
          body: '{lichess} teka-teki Lichess membawa taraf yang ditentukur terhadap berjuta-juta percubaan manusia. {mined} teka-teki yang dilombong secara tempatan membawa anggaran daripada kedalaman penyelesaian dan motif. Kedua-duanya menyusun secara munasabah, tetapi 1600 lombong dan 1600 Lichess tidak diukur dengan cara yang sama.',
        },
        {
          title: 'Taraf teka-teki bukan taraf papan.',
          body: 'Ia beberapa ratus mata lebih tinggi, dan akan kekal begitu. Ia mengukur kemajuan terhadap diri anda sendiri, bukan kekuatan menentang sekumpulan manusia di depan jam — {link}, kerana jurang itu bersifat struktur dan bukan tanda anda lemah menamatkan.',
        },
        {
          title: 'Tiada latihan pembukaan.',
          body: 'Sengaja. Kajian pembukaan ialah hafalan terhadap repertoir yang anda pilih sendiri, dan itu alat lain dengan bentuk lain. Mod kedudukan meliputi peralihan keluar daripada pembukaan, dan bahagian itulah yang benar-benar boleh diumumkan.',
        },
        {
          title: 'Ini tidak menjadikan anda pakar besar.',
          body: 'Tiada apa yang melakukannya bersendirian. Gelaran datang daripada ribuan jam ditambah perlawanan kejohanan bertaraf menentang manusia. Yang anda dapat di sini ialah separuh latihan bagi itu, tersusun, dengan ukuran jujur tentang di mana anda sebenarnya berdiri.',
        },
      ],
      ratingsLink: 'berbaloi difahami dengan betul',
    },
    more: {
      motifs: 'Dua puluh motif, ditakrifkan dan dikira →',
      engine: 'Bagaimana enjin digunakan →',
    },
  },

  tactics: {
    head: {
      slug: 'Glosari',
      title: 'Dua puluh motif',
      lede: 'Setiap taktik dalam catur ialah satu daripada bilangan bentuk yang sedikit, dan sebaik anda boleh menamakannya, anda melihatnya satu langkah lebih awal. Inilah motif yang digunakan Brass Pawn untuk melabel teka-tekinya — setiap satu diikuti berapa banyak kedudukan dalam pustaka sertaan yang benar-benar berpaksi padanya.',
      meta: 'Dikira daripada koleksi sertaan berjumlah 14,351 teka-teki · Disemak kali terakhir 19 Ogos 2026',
    },
    meta: {
      title: 'Dua puluh motif',
      description:
        'Setiap motif taktik yang digunakan Brass Pawn untuk melabel teka-tekinya, ditakrifkan dan dikira terhadap pustaka sertaan, supaya anda tahu yang mana benar-benar boleh dilatih.',
    },
    indexLabel: 'Motifnya',
    puzzles: 'teka-teki',
    motifs: [
      {
        name: 'Cabang dua',
        short: 'Satu buah menyerang dua perkara serentak, dan hanya satu boleh diselamatkan.',
        body: 'Kuda ialah pencabang yang masyhur kerana ia menyerang petak yang tidak dilindungi buah lain dengan cara sama, tetapi semuanya boleh mencabang: bidak yang mengena dua buah ringan, menteri yang mengena tir dan gajah terbiar, raja di penamat yang melangkah antara dua bidak. Ujiannya bukan “adakah saya menyerang dua perkara” tetapi “bolehkah kedua-duanya terlepas”.',
      },
      {
        name: 'Ikatan',
        short:
          'Sesuatu buah tidak boleh bergerak kerana di belakangnya berdiri sesuatu yang lebih berharga.',
        body: 'Mutlak apabila di belakangnya raja — bergerak menjadi tidak sah, bukan sekadar buruk. Nisbi apabila di belakangnya menteri atau tir, di mana bergerak itu sah dan hanya memakan bahan. Sambungannya yang menang: buah yang terikat ialah buah yang tidak boleh melindung, jadi timbunkan lebih banyak penyerang ke atasnya, atau pukul ia dengan bidak.',
      },
      {
        name: 'Cucukan',
        short: 'Ikatan secara terbalik: buah berharga berdiri di hadapan dan mesti bergerak.',
        body: 'Berikan syah kepada raja sepanjang satu garisan dengan tir, gajah atau menteri, dan apa yang berdiri di belakangnya menjadi milik anda sebaik raja mengelak. Cucukan lebih jarang daripada ikatan kerana ia memerlukan dua buah sudah berada pada garisan yang sama dengan yang berharga di hadapan — itulah sebabnya ia biasanya muncul selepas sesuatu syah memaksa raja ke situ.',
      },
      {
        name: 'Serangan terbuka',
        short: 'Menggerakkan satu buah mendedahkan serangan buah yang berdiri di belakangnya.',
        body: 'Jauh sekali taktik terkuat dalam catur, kerana buah yang berundur bebas melakukan sesuatu untuk dirinya sendiri sementara serangan yang terdedah menjalankan kerjanya. Dua ancaman lahir dalam satu langkah, dan tiada satu pun dijawab dengan memakan buah yang berundur.',
      },
      {
        name: 'Syah terbuka',
        short: 'Serangan yang terdedah itu ialah syah, jadi lawan tiada masa untuk apa-apa lagi.',
        body: 'Serangan terbuka di mana buah di belakang memberi syah. Apa jua yang dilakukan buah yang berundur — memakan menteri, berdiri di petak mat, membiarkan dirinya dimakan — jawapan mesti menguruskan syah dahulu, jadi semuanya berlaku secara percuma.',
      },
      {
        name: 'Syah berganda',
        short:
          'Dua buah memberi syah serentak, jadi raja mesti bergerak. Tidak boleh melindung, tidak boleh memakan.',
        body: 'Satu-satunya taktik yang terhadapnya wujud tepat satu jenis jawapan yang sah. Memakan seorang pemberi syah meninggalkan seorang lagi; menutup satu garisan meninggalkan satu lagi terbuka. Itulah sebabnya syah berganda menghasilkan mat yang kelihatan mustahil — pihak bertahan mungkin ada lima cara menghentikan setiap syah berasingan dan tiada satu pun yang menghentikan kedua-duanya.',
      },
      {
        name: 'Pengalihan',
        short: 'Paksa seorang pelindung meninggalkan kerja yang sedang dilakukannya.',
        body: 'Sesuatu buah memegang petak mat, baris belakang, atau buah lain. Serang sesuatu yang lebih dihargainya, atau sekadar makan sesuatu yang mesti dibalasnya, dan perlindungan yang diberinya turut pergi bersamanya. Pengorbanannya sering kelihatan karut sehinggalah anda perasan apa yang tidak lagi dilindungi oleh buah yang membalas.',
      },
      {
        name: 'Pemikatan',
        short: 'Pikat sesuatu buah — biasanya raja — ke petak tempat ia boleh dikena.',
        body: 'Pengorbanan yang wajib diterima lawan, dimainkan bukan untuk memenangi bahan tetapi untuk meletakkan sesuatu buah secara maut: raja diheret ke petak cabang, menteri ditarik ke satu garisan dengan tir. Bahannya kembali satu langkah kemudian dengan faedah.',
      },
      {
        name: 'Pembersihan',
        short: 'Alihkan buah anda sendiri daripada laluan serangan anda sendiri.',
        body: 'Garisan atau petaknya betul, cuma ada orang anda sendiri berdiri di situ. Pembersihan mengalihkannya dengan tempo — biasanya dengan syah atau makan, supaya lawan tiada masa menyusun semula sementara laluan terbuka.',
      },
      {
        name: 'Penghalangan',
        short: 'Potong garisan antara seorang pelindung dan apa yang dilindunginya.',
        body: 'Letakkan sesuatu buah — sering kali dikorbankan — tepat antara tir dengan petak yang dikawalnya. Pelindung itu masih di papan, secara teori masih melindung, dan sudah tidak boleh. Jarang, dan antara corak yang paling sukar dilihat, kerana buah penghalang biasanya kelihatan seperti kesilapan besar.',
      },
      {
        name: 'Serangan sinar-X',
        short:
          'Sesuatu buah bertindak menembusi buah lain, sepanjang garisan yang akan didudukinya kelak.',
        body: 'Tir yang melindungi buahnya sendiri menembusi buah lawan, atau menyerang menembusinya. Belum ada apa-apa berlaku; yang penting ialah apa yang berlaku apabila buah di tengah berundur atau dimakan. Melihat sinar-X biasanya itulah yang menjadikan pertukaran yang “hilang bahan” sebenarnya tidak hilang bahan.',
      },
      {
        name: 'Langkah selang',
        short: 'Langkah di tengah: sebelum membalas makan, buat sesuatu yang lebih memaksa.',
        body: 'Daripada perkataan Jerman “Zwischenzug”, dan sebab tunggal paling kerap sesuatu variasi yang telah dikira ternyata salah. Anda menjangka balasan makan; sebaliknya datang syah, atau ancaman lebih besar, dan menjelang balasan itu berlaku, kedudukan sudah berubah. Carilah satu setiap kali sesuatu rentetan kelihatan terpaksa.',
      },
      {
        name: 'Zugzwang',
        short: 'Kewajipan melangkah itu sendirilah masalahnya.',
        body: 'Setiap langkah yang sah memburukkan kedudukan, dan melangkau giliran tidak dibenarkan. Terutamanya idea penamat — ia yang memutuskan penamat bidak — dan sebab “oposisi” itu penting: sesiapa yang terpaksa mengelak dahulu menyerahkan petaknya. Hampir satu-satunya keadaan dalam catur di mana hak melangkah menjadi beban.',
      },
      {
        name: 'Mat baris belakang',
        short: 'Raja yang terkurung oleh bidaknya sendiri terkena mat di baris pertama.',
        body: 'Mat paling lazim antara pemain yang telah berkubu dan membiarkan bidaknya. Ia jarang muncul sebagai mat di papan — ia muncul sebagai ancaman yang memenangi bahan, kerana setiap langkah bertahan mesti terus melindungi baris itu. Seluruh keluarga taktik pengalihan wujud untuk mencabut perlindungan tersebut.',
      },
      {
        name: 'Mat tercekik',
        short: 'Seekor kuda mengenakan mat kepada raja yang dikurung oleh buahnya sendiri.',
        body: 'Penghujung warisan Philidor: pengorbanan menteri di g8, tir membalas makan, kuda di f7 memberi mat dengan raja dikelilingi orangnya sendiri. Jarang dalam perlawanan sebenar dan tetap berbaloi diketahui, kerana coraknya itulah yang membuat anda memandang ke penjuru dan mengira petak untuk lari.',
      },
      {
        name: 'Buah tergantung',
        short: 'Sesuatu itu sekadar tidak berlindung dan boleh diambil.',
        body: 'Tidak megah, dan ia memutuskan lebih banyak perlawanan daripada semua yang lain dalam senarai ini digabungkan. Kebanyakan kekalahan di bawah 1800 ialah seorang pemain mengambil buah percuma yang terlepas pandang oleh seorang lagi. Tabiat yang mengubatinya ialah menyemak apa yang berdiri terbiar — pada kedua-dua warna — sebelum setiap langkah.',
      },
      {
        name: 'Buah terperangkap',
        short: 'Sesuatu buah tiada petak selamat dan boleh diburu dengan tenang.',
        body: 'Biasanya gajah yang memakan bidak yang sepatutnya dibiarkan, atau kuda yang keluar merampas. Taktiknya bukan satu pukulan tetapi satu cekikan: ambil petak satu demi satu, dan buah itu jatuh tanpa perlu apa-apa pengorbanan.',
      },
      {
        name: 'Langkah senyap',
        short: 'Langkah yang menang itu bukan syah, bukan makan dan bukan ancaman.',
        body: 'Sebab pemain kuat menemui gabungan yang terlepas oleh orang lain. Selepas rentetan yang memaksa, jawapannya ialah langkah sederhana yang mencabut petak lari yang terakhir, dan ia tidak kelihatan oleh sesiapa yang hanya mengira syah dan makan. Apabila kedudukan kelihatan menang dan tiada yang memaksa berkesan, carilah yang senyap.',
      },
      {
        name: 'Pengorbanan',
        short: 'Berikan bahan demi sesuatu yang lebih bernilai daripada bahan.',
        body: 'Masa, garisan, petak, atau kedudukan raja lawan. Pengorbanan yang sebenar bukan pertaruhan; ia pengiraan dengan penghujung yang konkrit. Yang membezakan pengorbanan yang menjadi daripada yang tidak hampir selalunya ialah sama ada buah yang bertahan sempat kembali.',
      },
      {
        name: 'Bidak jauh ke hadapan',
        short: 'Bidak yang hampir naik pangkat mengubah nilai setiap buah lain.',
        body: 'Bidak di baris ketujuh bukanlah bidak; ia menteri yang mesti dikawal oleh sesuatu, dan sesuatu itu tidak lagi bebas. Kebanyakan taktik penamat sebenarnya tentang ketegangan antara menghentikan bidak dan melakukan apa-apa perkara lain.',
      },
    ],
    after: {
      slug: 'Kenapa nombornya ada di sini',
      title:
        'Glosari memberitahu apa itu cabang dua. Nombor memberitahu sama ada anda boleh melatihnya.',
      body: [
        'Mengetahui nama sesuatu corak dan mampu menemuinya di bawah jam ialah kemahiran yang berbeza, dan hanya yang kedua memenangi perlawanan. Setiap nombor di atas ialah bilangan sebenar kedudukan dalam pustaka sertaan yang dilabel dengan motif itu — bukan anggaran, dan tidak dibundarkan ke atas. Enam puluh teka-teki sinar-X memang enam puluh; jika itulah yang anda terus terlepas, baik untuk tahu bahawa ia tidak habis dalam satu malam.',
        'Jurulatih menjejak motif mana yang anda tersilap, supaya selepas beberapa ratus teka-teki ia boleh memberitahu anda bukan bahawa anda 1620, tetapi bahawa anda 1620 dan berkali-kali terjerat pengalihan.',
      ],
      more: 'Bagaimana teka-teki dilombong dan disemak →',
    },
  },
};
