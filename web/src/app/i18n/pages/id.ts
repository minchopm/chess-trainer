import type { Pages } from './types';

/** The four commercial pages in Indonesian. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Dukungan',
      title: 'Tanyakan pada manusia',
      lede: 'Tidak ada sistem tiket, tidak ada chatbot, dan tidak ada pusat bantuan dengan empat ratus artikel. Yang ada adalah satu alamat surel dan satu daftar kerusakan, dan keduanya bermuara pada orang yang menulis aplikasi ini.',
    },
    meta: {
      title: 'Dukungan',
      description:
        'Cara menghubungi manusia soal Brass Pawn, apa yang perlu dikirim saat sebuah soal keliru, dan pertanyaan yang paling sering muncul.',
    },
    email: {
      slug: 'Surel',
      body: 'Untuk apa saja: kesalahan program, soal yang keliru, pertanyaan tentang pembelian, atau ketidaksetujuan dengan sebuah penilaian. Tulis dalam bahasa Inggris atau Bulgaria.',
    },
    tracker: {
      slug: 'Daftar kerusakan',
      name: 'Issue di GitHub',
      body: 'Untuk semua yang Anda lebih suka terbuka — dan untuk semua yang perlu ditemukan orang lain nanti, yang berlaku bagi sebagian besar laporan kesalahan.',
    },
    report: {
      slug: 'Kalau sebuah soal keliru',
      title: 'Kirim empat hal, dan pemeriksaannya memakan waktu satu menit.',
      checklist: [
        'FEN yang tampil di layar soal — tekan lama untuk menyalinnya.',
        'Langkah yang Anda mainkan, dan langkah yang disebut benar oleh aplikasi.',
        'Anda sedang berada di mode yang mana.',
        'Versi aplikasi, dari layar informasi.',
      ],
      caveat:
        'Soal sesekali bertentangan dengan pencarian yang lebih dalam, dan pertentangan itu menumpuk pada posisi panjang, tenang, berperingkat tinggi yang inti persoalannya terletak lebih dalam daripada jangkauan pemeriksaan. Itu batas pemeriksaan, bukan kesalahan soal — tetapi ada gunanya tahu yang mana saja, dan satu-satunya cara mengetahuinya adalah bila Anda memberi tahu.',
    },
    faq: { slug: 'Pertanyaan', title: 'Cukup sering ditanyakan sampai perlu ditulis.' },
    more: {
      ratings: 'Apa yang diukur sebuah peringkat',
      tactics: 'Motif-motifnya',
      privacy: 'Kebijakan privasi',
      terms: 'Ketentuan penggunaan',
      licences: 'Lisensi',
    },
  },

  pricing: {
    head: {
      slug: 'Berapa biayanya',
      title: 'Bermain itu gratis. Yang dijual adalah latihannya.',
      lede: 'Catur melawan mesin dan catur melawan manusia, tanpa batas, tanpa iklan di mana pun dalam aplikasi — itu gratis dan akan tetap begitu. Yang dijual adalah pustaka, latihan, soal, dan lomba dengan jam.',
    },
    meta: {
      title: 'Harga',
      description:
        'Bermain itu gratis dan tanpa batas — mesin, lawan manusia, dan seluruh 900 partai. Pro menghapus batas lima per hari: 3,99 dolar per bulan atau 49,99 sekali bayar.',
    },
    free: {
      name: 'Gratis',
      note: 'Tanpa akun. Tidak ada yang perlu didaftari.',
      items: [
        'Bermain tanpa batas melawan mesin, dari 1400 sampai kekuatan penuh',
        'Partai daring tanpa batas lewat Game Center',
        'Komentar langkah demi langkah di setiap partai yang Anda mainkan',
        'Lima soal taktik per hari',
        'Lima putaran Rush per hari',
        'Lima dari masing-masing: posisional, akhir permainan, Tebak Elo',
        'Peringkat, rentetan, dan pengulangan berjarak, seluruhnya',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Bulanan',
      per: 'per bulan',
      note: 'Batalkan kapan saja di pengaturan akun Apple Anda.',
      items: [
        'Semua batas harian hilang',
        'Seluruh {tactics} soal taktik',
        'Seluruh {positional} latihan posisional',
        'Seluruh {endgames} latihan akhir permainan',
        'Seluruh {games} partai untuk dinilai',
        'Rush tanpa batas',
        'Semua isi versi gratis, tanpa perubahan',
      ],
    },
    lifetime: {
      name: 'Pembukaan sekali bayar',
      once: 'sekali untuk selamanya',
      note: 'Pembelian yang tidak habis pakai. Tidak diperpanjang.',
      items: [
        'Persis sama dengan Pro bulanan',
        'Tanpa perpanjangan, tanpa tanggal kedaluwarsa, tanpa surel pengingat',
        'Dipulihkan di perangkat Anda yang lain',
        'Untuk yang lebih suka memutuskan sekali saja',
      ],
    },
    table: {
      slug: 'Porsi utuhnya',
      title: 'Apa yang sebenarnya diberikan versi gratis.',
      activity: 'Kegiatan',
      freeCol: 'Gratis',
      proCol: 'Pro',
      unlimited: 'Tanpa batas',
      fiveADay: '5 per hari',
      none: 'Tidak ada',
      rows: [
        'Bermain melawan mesin',
        'Partai daring lewat Game Center',
        'Menonton — pustaka 900 partai',
        'Soal taktik',
        'Putaran Rush',
        'Latihan posisional',
        'Latihan akhir permainan',
        'Tebak Elo',
        'Iklan',
      ],
      reset:
        'Porsi harian disetel ulang pukul sembilan pagi waktu setempat — bukan tengah malam, supaya sesi malam tidak terpotong dua oleh pergantian tanggal.',
    },
    why: {
      slug: 'Mengapa bentuknya begini',
      title: 'Tiga keputusan, dan alasan masing-masing.',
      reasons: [
        {
          title: 'Dihitung, bukan dikunci',
          body: [
            'Tidak ada yang membayar pelatih yang belum pernah dipakainya, dan mode yang menolak terbuka tidak mengatakan apa pun tentang isi di baliknya. Maka setiap mode terbuka, setiap hari, dan Anda melangkah cukup jauh untuk merasakan iramanya dan melihat peringkat bergerak.',
            'Layar pembelian tidak pernah muncul saat aplikasi dijalankan. Ketika porsi hari itu habis, layar mengatakannya, dan hanya ketukan sadar yang membuka lembar pembelian.',
          ],
        },
        {
          title: 'Dua harga, bukan tiga',
          body: [
            'Tidak ada paket tahunan di tengah, sebab harga ketiga adalah keputusan ketiga tepat pada saat seseorang ingin memecahkan sebuah soal. Bulanan bila Anda ragu. Sekali bayar bila tidak.',
          ],
        },
        {
          title: 'Bermain tidak pernah dijual',
          body: [
            'Catur melawan mesin dan melawan manusia tidak memakan biaya untuk dijalankan dan merupakan alasan keberadaan aplikasi ini. Menjualnya akan mengubahnya menjadi aplikasi catur bergerbang tol alih-alih seorang pelatih.',
            'Dan tidak ada iklan — sebagian soal selera, sebagian soal lisensi. Aplikasi ini menautkan dua mesin copyleft, Stockfish di bawah GPLv3 dan Reckless di bawah AGPLv3, dan SDK iklan berpemilik dalam biner yang sama akan membuat keseluruhannya tidak dapat disebarkan. {link}',
          ],
        },
      ],
      licenceLink: 'Halaman lisensi menjelaskannya dengan runut.',
    },
    answers: {
      slug: 'Membeli, membatalkan, pengembalian dana',
      title: 'Pertanyaan yang canggung, dijawab di sini alih-alih lewat surel.',
      items: [
        {
          q: 'Bagaimana cara membatalkan?',
          a: 'Pengaturan → nama Anda → Langganan → Brass Pawn. Kami tidak dapat membatalkannya untuk Anda, sebab langganan itu antara Anda dan Apple dan tidak pernah ada pada kami. Pembatalan menghentikan perpanjangan berikutnya dan tidak memperpendek masa yang sudah dibayar.',
        },
        {
          q: 'Bagaimana saya mendapatkan uang saya kembali?',
          a: 'Lewat Apple, di {link}. Kami tidak dapat mengembalikan dana pembelian App Store. Kalau ada yang rusak, tulis kepada kami — kami lebih suka memperbaikinya.',
        },
        {
          q: 'Saya sudah membeli pembukaannya dan punya ponsel baru.',
          a: 'Masuk dengan akun Apple yang sama dan ketuk “Pulihkan pembelian” di layar pembelian. Aplikasi bertanya kepada StoreKit apa yang Anda miliki; tidak ada yang tersimpan di server kami, sebab kami tidak punya server.',
        },
        {
          q: 'Apakah Pro mengubah peringkat saya atau membuka soal yang “lebih baik”?',
          a: 'Tidak. Sistem peringkatnya sama persis, dan setiap soal di pustaka dapat dijangkau dengan akun gratis — lima per hari. Pro menghapus pencacah, bukan tirai.',
        },
        {
          q: 'Apakah porsi gratis akan menyusut nanti?',
          a: 'Ia bisa berubah ke dua arah seiring pustaka bertumbuh. Bermain tanpa batas melawan mesin dan melawan manusia tidak akan menjadi fitur berbayar; itu tertulis dalam {link}, bukan sekadar dijanjikan di sini.',
        },
      ],
      termsLink: 'ketentuan',
      more: 'Pertanyaan lain, dan cara menghubungi manusia →',
    },
  },

  training: {
    head: {
      slug: 'Programnya',
      title: 'Delapan cara mendengar kebenaran',
      lede: 'Tiga di antaranya gratis dan tanpa batas selamanya — bermain, bermain melawan seseorang, dan sembilan ratus partai di Menonton. Lima sisanya lima per hari dengan akun gratis dan tanpa batas dengan Pro. Masing-masing menilai Anda dengan kata-kata tentang posisi, bukan dengan angka yang masih harus ditafsirkan.',
    },
    meta: {
      title: 'Latihan',
      description:
        'Delapan mode: taktik, penilaian posisional, akhir permainan, Rush, Tebak Elo, Menonton, bermain dengan komentar, dan daring. Cara kerja masing-masing, cara soal ditambang dan diperiksa, serta apa yang tidak dilakukan pelatih.',
    },
    modes: [
      {
        title: 'Taktik',
        lede: 'Posisi dengan tepat satu langkah yang menang, dan putusan pada saat Anda memainkannya.',
        body: [
          'Setiap soal punya satu jawaban dan tanpa percabangan. Mainkan di papan dan pelatih langsung mengatakan apakah Anda menemukannya; kalau meleset, posisi itu kembali besok, lalu empat hari lagi, lalu sepuluh — selama ia masih menjebak Anda.',
          'Setiap soal membawa motif yang menjadi porosnya — garpu, ikatan, tusukan, mat baris belakang, pengalihan, langkah senyap — supaya setelah beberapa ratus soal pelatih dapat memberi tahu Anda bukan bahwa Anda 1620, melainkan bahwa Anda 1620 dan berulang kali terjebak pengalihan.',
        ],
        free: 'Lima per hari dengan akun gratis.',
        stat: 'soal, berperingkat dari 760 sampai 2800',
      },
      {
        title: 'Penilaian posisional',
        lede: 'Tidak ada kemenangan paksa. Katakan siapa yang berdiri lebih baik, lalu temukan langkah yang mengatakan mengapa.',
        body: [
          'Inilah mode yang dibangun untuk hal yang memisahkan pemain kuat dari penghitung yang baik. Pertama Anda menilai: jelas lebih baik, sedikit lebih baik, seimbang. Lalu Anda memilih langkah. Kedua jawaban dinilai.',
          'Umpan baliknya menyebut ciri yang konkret alih-alih suasana hati — lajur terbuka dan apakah ada benteng di atasnya, petak kuda yang tak dapat digugat pion mana pun, struktur pion, keamanan raja, selisih keaktifan buah. Sebuah posisi bukan “nyaman bagi putih”; ia lebih baik karena empat alasan yang dapat Anda sebutkan.',
        ],
        free: 'Lima per hari dengan akun gratis.',
        stat: 'posisi tenang, dipilih lebih dulu oleh mesin',
      },
      {
        title: 'Akhir permainan',
        lede: 'Posisi kanonik, dimainkan sampai tuntas melawan mesin yang bertahan dengan pantas.',
        body: [
          'Mengetahui gagasannya tidak sama dengan membawanya pulang, jadi di sini Anda benar-benar harus mencapai hasilnya. Stockfish mengambil pihak lain dan menyusun pertahanan terbaik yang ada.',
          'Setelah setiap langkah pelatih memeriksa ulang apakah hasilnya masih dapat dicapai — dan bila tidak, ia menyebut langkah persis di mana hal itu berhenti. Itulah kalimat yang mengajarkan sesuatu: bukan “Anda membuat remis”, melainkan “Anda membuat remis di sini”.',
        ],
        free: 'Lima per hari dengan akun gratis.',
        stat: 'latihan, tiap hasil diperiksa mesin',
      },
      {
        title: 'Rush',
        lede: 'Putaran melawan waktu. Pecahkan sebanyak yang Anda bisa sebelum jam mengambil sisanya.',
        body: [
          'Soal yang sama, di bawah jam, dengan kesulitan yang naik selama Anda terus menemukannya. Itu melatih otot yang berbeda dari soal yang boleh dipandangi lama: otot yang harus melihat sekarang.',
          'Putaran diberi skor dan disimpan, sehingga angkanya naik selama berbulan-bulan alih-alih dalam satu malam.',
        ],
        free: 'Lima putaran per hari dengan akun gratis.',
      },
      {
        title: 'Tebak Elo',
        lede: 'Partai berperingkat sungguhan, diputar langkah demi langkah. Seberapa kuat kedua orang ini?',
        body: [
          'Membaca level sebuah partai adalah keterampilan yang sama dengan menilai langkah Anda sendiri: keduanya bermuara pada memperhatikan kesalahan apa yang dibuat dan apa yang tidak. Jadi partai berjalan, Anda menonton, dan pada suatu titik Anda memutuskan sebuah angka.',
          'Partainya nyata, dari arsip Lichess, dengan kedua pemain berjarak kurang dari 150 poin — tebakan tentang “para pemain” baru berarti bila ada satu level untuk ditebak.',
        ],
        free: 'Lima per hari dengan akun gratis.',
        stat: 'partai berperingkat, dari 800 sampai 2599',
      },
      {
        title: 'Menonton',
        lede: 'Sembilan ratus partai yang layak ditonton — dan pada saat Anda akan bermain lain, Anda mengambil alih.',
        body: [
          'Setiap partai di pustaka berakhir menentukan, antara dua pemain bernama, dan entah selesai dalam dua puluh lima langkah atau cukup terkenal sampai punya nama sendiri. Tak ada yang belajar apa pun dari remis sembilan puluh langkah antara orang-orang yang tak pernah ia dengar, dan pustaka yang memuat itu adalah pustaka yang tak dibuka orang untuk kedua kalinya.',
          'Cari seorang pemain, sebuah turnamen, atau sebuah tahun. Lalu telusuri partainya dengan kecepatan Anda sendiri. Ini bukan soal momen puncaknya: ini soal bahwa pada suatu langkah Anda akan berpikir <em>saya akan memakan di sana</em> — dan pada saat itu Anda bisa. Ambil alih posisinya dan lanjutkan melawan mesin dari petak persis tempat Anda tidak setuju. Mencari tahu berapa nilai gagasan Anda sebenarnya adalah keseluruhan latihannya.',
        ],
        free: 'Gratis, tanpa batas, selalu.',
        stat: 'partai, semuanya menentukan',
      },
      {
        title: 'Bermain dengan pelatih',
        lede: 'Satu partai penuh pada kekuatan yang Anda pilih, dengan setiap langkah Anda dinilai sambil jalan.',
        body: [
          'Setel mesin di suatu titik antara 1400 dan kekuatan penuh lalu mainkan partainya sampai habis. Setiap langkah Anda dinilai selagi partai masih berjalan, dan pelatih menjelaskan apa yang akan dicapai langkah yang lebih baik — dengan kata-kata tentang posisi, bukan sebagai angka.',
          'Di akhir Anda mendapat ketepatan, jumlah blunder, dan satu momen yang paling mahal harganya.',
        ],
        free: 'Gratis, tanpa batas, selalu.',
      },
      {
        title: 'Daring',
        lede: 'Dua manusia, satu jam, dan tak ada mesin di dekatnya.',
        body: [
          'Game Center mencarikan orang yang memilih tempo yang sama — 3, 5, 10, 15, atau 30 menit. Inilah satu-satunya mode tanpa mesin di dalamnya: tanpa petunjuk, tanpa nilai langkah, tanpa pelatihan, sebab bantuan yang hanya didapat satu pihak bukanlah sebuah partai.',
          'Tidak ada server. Kedua perangkat berbicara satu sama lain dan keduanya menegakkan aturan, jadi sebuah langkah baru dimainkan bila sah dalam posisi yang sudah dimiliki perangkat penerima. Lawan yang berbohong menghasilkan paket yang dibuang, bukan papan yang tidak sah.',
        ],
        free: 'Gratis, tanpa batas, selalu.',
      },
    ],
    watchLink: 'Apa yang masuk pustaka dan apa yang tidak →',
    pipeline: {
      slug: 'Bagaimana sebuah soal dibuat',
      title: 'Ditambang, bukan disalin.',
      lede: 'Menuliskan posisi dari ingatan berisiko menghasilkan soal yang “solusinya” salah atau tidak tunggal, dan itu melatih persis naluri yang keliru. Maka tidak satu pun ditulis dari ingatan. Semuanya ditemukan lalu diserang sampai bertahan atau dibuang.',
      steps: [
        {
          title: 'Bermain pada kekuatan manusia',
          body: 'Stockfish bermain melawan dirinya sendiri pada kekuatan yang sengaja manusiawi — 1320 sampai 2500 Elo — membuka dengan pilihan acak di antara kandidat dangkal terbaiknya, sehingga partainya beragam alih-alih mengulang satu variasi selamanya.',
        },
        {
          title: 'Menyaring berdasarkan sifat, bukan blunder',
          body: 'Setiap posisi dicari pada kedalaman 12 dengan dua garis kandidat. Sinyalnya bukan “seseorang blunder” melainkan apa yang benar-benar dibutuhkan sebuah soal: satu langkah yang jauh lebih baik daripada semua alternatif.',
        },
        {
          title: 'Pencarian dalam lagi, dengan margin',
          body: 'Yang bertahan dicari ulang pada kedalaman 20 dengan MultiPV. Sebuah kandidat hanya bertahan bila langkah terbaik mengungguli yang kedua sedikitnya 140 perseratus pion dan juga benar-benar mencapai sesuatu.',
        },
        {
          title: 'Diperpanjang sampai bercabang',
          body: 'Solusi diperpanjang langkah demi langkah selama setiap langkah pemecah tetap satu-satunya yang terbaik. Pada saat ada dua jawaban yang baik, soal berakhir di situ — jadi ia tidak pernah punya percabangan yang membuat Anda bisa dihitung salah.',
        },
        {
          title: 'Diperiksa dengan mesin baru',
          body: 'Seluruh koleksi diperiksa ulang pada kedalaman lebih besar oleh skrip terpisah dengan mesin baru. Pada koleksi tambang yang disertakan, itu menolak 6 dari 172 soal yang solusinya berhenti menjadi tunggal dua setengah-langkah lebih dalam. Semuanya dibuang alih-alih dikirimkan.',
        },
      ],
    },
    honest: {
      title: 'Dan kecurigaan yang sama diterapkan pada akhir permainan',
      body: [
        'Hasil yang dinyatakan untuk setiap latihan akhir permainan diperiksa dengan pencarian dalam alih-alih diterima begitu saja. Latihan yang salah label gagal dalam pemeriksaan alih-alih diam-diam mengajari Anda hal yang tidak benar.',
        'Pemeriksanya juga menangkap sesuatu yang tidak diberitahukan pustaka catur biasa: apakah pihak yang tidak sedang melangkah sedang dalam keadaan skak. Posisi semacam itu tidak sah — tidak ada partai yang bisa mencapainya — tetapi sebuah pustaka menerimanya dengan patuh, dan mesin menjawab dengan bestmove (none), yang terdengar seperti kegagalan mesin alih-alih posisi yang buruk. Tiga latihan tulisan tangan rusak persis seperti itu. Pemeriksaan sekarang menangkapnya.',
      ],
    },
    limits: {
      slug: 'Batas yang jujur',
      title: 'Apa yang tidak dilakukan ini.',
      items: [
        {
          title: 'Koleksinya mencampur dua skala peringkat.',
          body: '{lichess} soal Lichess membawa peringkat yang dikalibrasi terhadap jutaan percobaan manusia. {mined} soal yang ditambang secara lokal membawa perkiraan dari kedalaman solusi dan motif. Keduanya mengurutkan dengan masuk akal, tetapi 1600 hasil tambang dan 1600 Lichess tidak diukur dengan cara yang sama.',
        },
        {
          title: 'Peringkat soal bukan peringkat papan.',
          body: 'Ia beberapa ratus poin lebih tinggi, dan akan tetap begitu. Ia mengukur kemajuan terhadap diri Anda sendiri, bukan kekuatan melawan sekumpulan manusia di depan jam — {link}, sebab jurangnya bersifat struktural dan bukan tanda bahwa Anda buruk dalam menuntaskan.',
        },
        {
          title: 'Tidak ada latihan pembukaan.',
          body: 'Disengaja. Belajar pembukaan adalah menghafal terhadap repertoar yang Anda pilih sendiri, dan itu alat lain dengan bentuk lain. Mode posisional mencakup peralihan keluar dari pembukaan, dan justru bagian itulah yang benar-benar dapat digeneralisasi.',
        },
        {
          title: 'Ini tidak menjadikan Anda grandmaster.',
          body: 'Tak ada yang melakukannya sendirian. Gelar datang dari ribuan jam ditambah partai turnamen berperingkat melawan manusia. Yang Anda dapat di sini adalah separuh latihannya, tertata, dengan ukuran yang jujur tentang posisi Anda sebenarnya.',
        },
      ],
      ratingsLink: 'layak dipahami dengan benar',
    },
    more: {
      motifs: 'Dua puluh motif, didefinisikan dan dihitung →',
      engine: 'Bagaimana mesin digunakan →',
    },
  },

  tactics: {
    head: {
      slug: 'Glosarium',
      title: 'Dua puluh motif',
      lede: 'Setiap taktik dalam catur adalah salah satu dari sejumlah kecil bentuk, dan begitu Anda bisa menamainya, Anda melihatnya satu langkah lebih awal. Inilah motif yang dipakai Brass Pawn untuk melabeli soalnya — masing-masing diikuti berapa banyak posisi dalam pustaka bawaan yang benar-benar berporos padanya.',
      meta: 'Dihitung dari koleksi bawaan berisi 14.351 soal · Terakhir diperiksa 19 Agustus 2026',
    },
    meta: {
      title: 'Dua puluh motif',
      description:
        'Setiap motif taktik yang dipakai Brass Pawn untuk melabeli soalnya, didefinisikan dan dihitung terhadap pustaka bawaan, supaya Anda tahu mana yang benar-benar bisa dilatih.',
    },
    indexLabel: 'Motif-motifnya',
    puzzles: 'soal',
    motifs: [
      {
        name: 'Garpu',
        short: 'Satu buah menyerang dua hal sekaligus, dan hanya satu yang bisa diselamatkan.',
        body: 'Kuda adalah penggarpu yang termasyhur karena ia menyerang petak yang tak ditutup buah lain dengan cara sama, tetapi semua bisa menggarpu: pion yang mengenai dua buah ringan, menteri yang mengenai benteng dan gajah yang tak terjaga, raja di akhir permainan yang melangkah di antara dua pion. Ujiannya bukan “apakah saya menyerang dua hal”, melainkan “apakah keduanya bisa lolos”.',
      },
      {
        name: 'Ikatan',
        short:
          'Sebuah buah tidak bisa bergerak karena di belakangnya berdiri sesuatu yang lebih berharga.',
        body: 'Mutlak bila di belakangnya raja — bergerak menjadi tidak sah, bukan sekadar buruk. Relatif bila di belakangnya menteri atau benteng, di mana bergerak itu sah dan sekadar memakan ongkos material. Kelanjutannya yang menang: buah yang terikat adalah buah yang tak bisa menjaga, maka tumpuk penyerang di atasnya, atau pukul dengan pion.',
      },
      {
        name: 'Tusukan',
        short: 'Ikatan yang terbalik: buah berharga berdiri di depan dan harus bergerak.',
        body: 'Beri skak pada raja sepanjang satu garis dengan benteng, gajah, atau menteri, dan apa pun yang berdiri di belakangnya menjadi milik Anda begitu raja menyingkir. Tusukan lebih jarang daripada ikatan karena menuntut dua buah sudah berada pada satu garis dengan yang berharga di depan — karena itu ia biasanya muncul setelah sebuah skak memaksa raja ke sana.',
      },
      {
        name: 'Serangan terbuka',
        short: 'Menggeser satu buah membuka serangan buah yang berdiri di belakangnya.',
        body: 'Sejauh ini taktik terkuat dalam catur, sebab buah yang menyingkir bebas melakukan sesuatu untuk dirinya sendiri sementara serangan yang terbuka mengerjakan tugasnya. Dua ancaman lahir dalam satu langkah, dan tak satu pun terjawab dengan memakan buah yang menyingkir.',
      },
      {
        name: 'Skak terbuka',
        short:
          'Serangan yang terbuka itu berupa skak, jadi lawan tak punya waktu untuk apa pun lagi.',
        body: 'Serangan terbuka di mana buah di belakang memberi skak. Apa pun yang dilakukan buah yang menyingkir — memakan menteri, berdiri di petak mat, membiarkan dirinya dimakan — jawaban harus mengurus skaknya lebih dulu, jadi semuanya terjadi cuma-cuma.',
      },
      {
        name: 'Skak ganda',
        short:
          'Dua buah memberi skak sekaligus, jadi raja harus bergerak. Tak bisa menutup, tak bisa memakan.',
        body: 'Satu-satunya taktik yang terhadapnya hanya ada satu jenis jawaban yang sah. Memakan salah satu pemberi skak menyisakan yang lain; menutup satu garis menyisakan garis satunya terbuka. Karena itu skak ganda menghasilkan mat yang tampak mustahil — pihak bertahan bisa punya lima cara menghentikan tiap skak secara terpisah dan tak satu pun yang menghentikan keduanya.',
      },
      {
        name: 'Pengalihan',
        short: 'Paksa seorang penjaga meninggalkan tugas yang sedang dikerjakannya.',
        body: 'Sebuah buah menahan petak mat, baris belakang, atau buah lain. Serang sesuatu yang lebih dihargainya, atau cukup makan sesuatu yang harus dibalasnya, dan penjagaan yang diberikannya ikut pergi bersamanya. Pengorbanannya sering tampak absurd sampai Anda menyadari apa yang tak lagi dijaga buah yang membalas.',
      },
      {
        name: 'Pemikatan',
        short: 'Pikat sebuah buah — biasanya raja — ke petak tempat ia bisa dikenai.',
        body: 'Pengorbanan yang wajib diterima lawan, dimainkan bukan untuk memenangkan material melainkan untuk menempatkan sebuah buah secara fatal: raja diseret ke petak garpu, menteri ditarik ke satu garis dengan benteng. Materialnya kembali satu langkah kemudian dengan bunga.',
      },
      {
        name: 'Pembersihan',
        short: 'Singkirkan buah Anda sendiri dari jalan serangan Anda sendiri.',
        body: 'Garis atau petaknya sudah benar, hanya saja ada orang Anda sendiri di sana. Pembersihan menyingkirkannya dengan tempo — biasanya dengan skak atau makan, supaya lawan tak sempat menata ulang saat jalan itu terbuka.',
      },
      {
        name: 'Penghalangan',
        short: 'Potong garis antara seorang penjaga dan apa yang dijaganya.',
        body: 'Taruh sebuah buah — sering kali dikorbankan — persis di antara benteng dan petak yang dijaganya. Penjaganya masih di papan, secara teori masih menjaga, dan sudah tidak bisa. Jarang, dan salah satu pola yang paling sulit dilihat, sebab buah penghalang biasanya tampak seperti blunder.',
      },
      {
        name: 'Serangan sinar-X',
        short:
          'Sebuah buah bekerja menembus buah lain, sepanjang garis yang akan ditempatinya nanti.',
        body: 'Benteng yang menjaga buahnya sendiri menembus buah lawan, atau menyerang menembusnya. Belum ada yang terjadi; yang penting adalah apa yang terjadi ketika buah di tengah menyingkir atau dimakan. Melihat sinar-X biasanya yang membuat sebuah pertukaran yang “kehilangan material” ternyata tidak kehilangan material.',
      },
      {
        name: 'Langkah antara',
        short: 'Langkah di tengah: sebelum membalas makan, lakukan sesuatu yang lebih memaksa.',
        body: 'Dari bahasa Jerman “Zwischenzug”, dan alasan tunggal paling sering sebuah variasi yang sudah dihitung ternyata salah. Anda menunggu balasan makan; alih-alih itu datang skak, atau ancaman yang lebih besar, dan ketika balasan itu akhirnya terjadi, posisinya sudah berubah. Carilah satu setiap kali sebuah rangkaian tampak dipaksakan.',
      },
      {
        name: 'Zugzwang',
        short: 'Kewajiban melangkah itu sendirilah masalahnya.',
        body: 'Setiap langkah yang sah memperburuk posisi, dan melewatkan giliran tidak diperbolehkan. Terutama gagasan akhir permainan — ia yang menentukan akhir permainan pion — dan alasan mengapa “oposisi” penting: yang lebih dulu harus menyingkir menyerahkan petaknya. Nyaris satu-satunya keadaan dalam catur di mana hak melangkah adalah beban.',
      },
      {
        name: 'Mat baris belakang',
        short: 'Raja yang terkurung pionnya sendiri kena mat di baris pertama.',
        body: 'Mat paling umum di antara pemain yang sudah rokade dan membiarkan pionnya. Ia jarang muncul sebagai mat di papan — ia muncul sebagai ancaman yang memenangkan material, sebab setiap langkah bertahan harus terus menjaga baris itu. Seluruh keluarga taktik pengalihan ada untuk mencabut penjagaan tersebut.',
      },
      {
        name: 'Mat tercekik',
        short: 'Seekor kuda mematikan raja yang dikurung buah-buahnya sendiri.',
        body: 'Akhir dari warisan Philidor: pengorbanan menteri di g8, benteng membalas makan, kuda di f7 memberi mat dengan raja dikelilingi orang-orangnya sendiri. Jarang dalam partai nyata dan tetap layak diketahui, sebab polanyalah yang membuat Anda melihat ke sudut dan menghitung petak pelarian.',
      },
      {
        name: 'Buah menggantung',
        short: 'Sesuatu sekadar tak terjaga dan bisa diambil.',
        body: 'Tidak memesona, dan ia menentukan lebih banyak partai daripada semua isi daftar ini digabung. Sebagian besar kekalahan di bawah 1800 adalah satu pemain mengambil buah gratis yang luput dari pandangan pemain lain. Kebiasaan yang menyembuhkannya adalah memeriksa apa yang berdiri tanpa penjaga — pada kedua warna — sebelum setiap langkah.',
      },
      {
        name: 'Buah terperangkap',
        short: 'Sebuah buah tak punya petak aman dan bisa diburu dengan santai.',
        body: 'Biasanya gajah yang memakan pion yang seharusnya dibiarkan, atau kuda yang pergi menjarah. Taktiknya bukan satu pukulan melainkan pencekikan: ambil petak satu per satu, dan buah itu jatuh tanpa perlu pengorbanan.',
      },
      {
        name: 'Langkah senyap',
        short: 'Langkah yang menang bukan skak, bukan makan, dan bukan ancaman.',
        body: 'Alasan pemain kuat menemukan kombinasi yang luput dari yang lain. Setelah rangkaian yang memaksa, jawabannya adalah langkah bersahaja yang mencabut petak pelarian terakhir, dan itu tak terlihat oleh orang yang hanya menghitung skak dan makan. Ketika posisi tampak menang dan tak ada yang memaksa berhasil, carilah yang senyap.',
      },
      {
        name: 'Pengorbanan',
        short: 'Berikan material demi sesuatu yang lebih berharga daripada material.',
        body: 'Waktu, garis, petak, atau kedudukan raja lawan. Pengorbanan sejati bukan taruhan; ia perhitungan dengan ujung yang konkret. Yang memisahkan pengorbanan yang berhasil dari yang tidak hampir selalu adalah apakah buah-buah yang bertahan sempat kembali.',
      },
      {
        name: 'Pion maju',
        short: 'Pion yang dekat promosi mengubah nilai setiap buah lain.',
        body: 'Pion di baris ketujuh bukanlah pion; ia menteri yang harus dijaga sesuatu, dan sesuatu itu tak lagi bebas. Sebagian besar taktik akhir permainan sebenarnya tentang ketegangan antara menghentikan pion dan mengerjakan hal lain apa pun.',
      },
    ],
    after: {
      slug: 'Mengapa angkanya ada di sini',
      title: 'Glosarium mengatakan apa itu garpu. Angka mengatakan apakah Anda bisa melatihnya.',
      body: [
        'Mengetahui nama sebuah pola dan mampu menemukannya di bawah jam adalah keterampilan yang berbeda, dan hanya yang kedua yang memenangkan partai. Setiap angka di atas adalah jumlah nyata posisi dalam pustaka bawaan yang dilabeli motif tersebut — bukan perkiraan, dan tidak dibulatkan ke atas. Enam puluh soal sinar-X memang enam puluh; kalau justru itu yang terus Anda lewatkan, baik untuk tahu bahwa ia tak habis dalam satu malam.',
        'Pelatih mencatat motif mana yang Anda salahi, supaya setelah beberapa ratus soal ia dapat memberi tahu Anda bukan bahwa Anda 1620, melainkan bahwa Anda 1620 dan berulang kali terjebak pengalihan.',
      ],
      more: 'Bagaimana soal ditambang dan diperiksa →',
    },
  },
};
