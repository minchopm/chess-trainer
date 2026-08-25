# -*- coding: utf-8 -*-
"""Name, subtitle and keywords for every storefront.

Apple indexes the union of the app name, the subtitle and the keyword field,
and nothing else — the description is not searched. So a word that appears in
the name or the subtitle is wasted if it is repeated in the keywords, and the
keyword field is spent entirely on words those two do not already carry.

The name is "Brass Pawn: <chess trainer>" in each language: the brand first,
because it has to read as a name, and the two words somebody would actually
type after it. Where a language would ordinarily compound those two words
(German, Dutch, the Nordics), they are written apart so both tokens index.
"""

# locale: (name, subtitle, keywords)
ASO = {
"en-US": ("Brass Pawn: Chess Trainer", "Puzzles, Tactics & Endgames",
 "stockfish,elo,opening,analysis,board,offline,rating,coach,play,learn,strategy,game,study,checkmate"),

"en-CA": ("Brass Pawn: Chess Trainer", "Puzzles, Tactics & Endgames",
 "stockfish,elo,opening,analysis,board,offline,rating,coach,play,learn,strategy,game,study,checkmate"),

"de-DE": ("Brass Pawn: Schach Trainer", "Taktik, Endspiel & Rätsel",
 "stockfish,eröffnung,analyse,brett,offline,elo,lernen,strategie,partie,spiel,matt,studium,wertung"),

"fr-FR": ("Brass Pawn: Coach d'Échecs", "Tactiques, Finales, Problèmes",
 "stockfish,ouverture,analyse,échiquier,hors ligne,elo,apprendre,stratégie,partie,jeu,mat,niveau"),

"fr-CA": ("Brass Pawn: Coach d'Échecs", "Tactiques, Finales, Problèmes",
 "stockfish,ouverture,analyse,échiquier,hors ligne,elo,apprendre,stratégie,partie,jeu,mat,niveau"),

"es-ES": ("Brass Pawn: Ajedrez Coach", "Táctica, Finales y Puzles",
 "stockfish,apertura,análisis,tablero,sin conexión,elo,aprender,estrategia,partida,juego,mate,nivel"),

"it": ("Brass Pawn: Scacchi Coach", "Tattica, Finali e Rompicapi",
 "stockfish,apertura,analisi,scacchiera,offline,elo,imparare,strategia,partita,gioco,matto,livello"),

"pt-BR": ("Brass Pawn: Xadrez Coach", "Táticas, Finais e Puzzles",
 "stockfish,abertura,análise,tabuleiro,offline,elo,aprender,estratégia,partida,jogo,mate,nível"),

"nl-NL": ("Brass Pawn: Schaak Trainer", "Tactiek, Eindspel & Puzzels",
 "stockfish,opening,analyse,bord,offline,elo,leren,strategie,partij,spel,mat,studie,rating"),

"ru": ("Brass Pawn: Шахматы Тренер", "Тактика, эндшпиль, задачи",
 "stockfish,дебют,анализ,доска,офлайн,эло,учиться,стратегия,партия,игра,мат,рейтинг,разбор"),

"pl": ("Brass Pawn: Szachy Trener", "Taktyka, końcówki, zadania",
 "stockfish,otwarcie,analiza,szachownica,offline,elo,nauka,strategia,partia,gra,mat,ranking"),

"cs": ("Brass Pawn: Šachy Trenér", "Taktika, koncovky, úlohy",
 "stockfish,zahájení,analýza,šachovnice,offline,elo,učení,strategie,partie,hra,mat,rating"),

"hu": ("Brass Pawn: Sakk Edző", "Taktika, végjáték, feladvány",
 "stockfish,megnyitás,elemzés,tábla,offline,elo,tanulás,stratégia,parti,játék,matt,értékszám"),

"ro": ("Brass Pawn: Șah Antrenor", "Tactică, finaluri, probleme",
 "stockfish,deschidere,analiză,tablă,offline,elo,învăța,strategie,partidă,joc,mat,clasament"),

"el": ("Brass Pawn: Σκάκι Προπονητής", "Τακτική, φινάλε, γρίφοι",
 "stockfish,άνοιγμα,ανάλυση,σκακιέρα,offline,elo,μάθηση,στρατηγική,παρτίδα,παιχνίδι,ματ"),

"tr": ("Brass Pawn: Satranç Koçu", "Taktik, oyunsonu, bulmaca",
 "stockfish,açılış,analiz,tahta,çevrimdışı,elo,öğren,strateji,parti,oyun,mat,derecelendirme"),

"sv": ("Brass Pawn: Schack Tränare", "Taktik, slutspel & pussel",
 "stockfish,öppning,analys,bräde,offline,elo,lära,strategi,parti,spel,matt,rating,studie"),

"da": ("Brass Pawn: Skak Træner", "Taktik, slutspil og gåder",
 "stockfish,åbning,analyse,bræt,offline,elo,lære,strategi,parti,spil,mat,rating,studie"),

"no": ("Brass Pawn: Sjakk Trener", "Taktikk, sluttspill, gåter",
 "stockfish,åpning,analyse,brett,offline,elo,lære,strategi,parti,spill,matt,rating,studie"),

"fi": ("Brass Pawn: Shakki Valmentaja", "Taktiikka, loppupelit, pulmat",
 "stockfish,avaus,analyysi,lauta,offline,elo,oppia,strategia,peli,matti,luokitus,aloittelija"),

"ja": ("Brass Pawn: チェス トレーナー", "戦術・終盤・詰めチェス",
 "stockfish,定跡,解析,盤,オフライン,レーティング,コーチ,対局,学習,戦略,棋譜,詰将棋,初心者,上達,序盤,中盤"),

"ko": ("Brass Pawn: 체스 트레이너", "전술 · 엔드게임 · 퍼즐",
 "stockfish,오프닝,분석,체스판,오프라인,레이팅,코치,대국,학습,전략,메이트,기보,초보,입문,실력,묘수"),

"zh-Hans": ("Brass Pawn: 国际象棋教练", "战术 · 残局 · 棋题",
 "stockfish,开局,分析,棋盘,离线,等级分,对局,学习,策略,将杀,棋谱,复盘,训练,入门,新手,提高,中局,自学"),

"zh-Hant": ("Brass Pawn: 西洋棋教練", "戰術 · 殘局 · 棋題",
 "stockfish,開局,分析,棋盤,離線,等級分,對局,學習,策略,將殺,棋譜,複盤,訓練,入門,新手,提高,中局,自學"),

"th": ("Brass Pawn: หมากรุกฝรั่ง โค้ช", "แทกติก จบเกม ปริศนา",
 "stockfish,เปิดเกม,วิเคราะห์,กระดาน,ออฟไลน์,เรตติ้ง,ฝึก,กลยุทธ์,รุกจน,เรียน,มือใหม่,เกม,หมากรุก"),

"vi": ("Brass Pawn: Cờ Vua Huấn Luyện", "Chiến thuật, tàn cuộc, đố",
 "stockfish,khai cuộc,phân tích,bàn cờ,ngoại tuyến,elo,học,chiến lược,ván cờ,chiếu hết"),

"id": ("Brass Pawn: Catur Pelatih", "Taktik, akhir, teka-teki",
 "stockfish,pembukaan,analisis,papan,luring,elo,belajar,strategi,permainan,skakmat,peringkat"),

"ms": ("Brass Pawn: Catur Jurulatih", "Taktik, penamat, teka-teki",
 "stockfish,pembukaan,analisis,papan,luar talian,elo,belajar,strategi,permainan,mat,peringkat"),

"hi": ("Brass Pawn: शतरंज ट्रेनर", "रणनीति, अंत खेल, पहेली",
 "stockfish,ओपनिंग,विश्लेषण,बोर्ड,ऑफ़लाइन,रेटिंग,कोच,सीखें,खेल,शह और मात,अभ्यास,शुरुआती,चाल"),

"he": ("Brass Pawn: שחמט מאמן", "טקטיקה, סיומים, חידות",
 "stockfish,פתיחה,ניתוח,לוח,לא מקוון,דירוג,ללמוד,אסטרטגיה,משחק,מט,אימון,מתחילים,תרגול,קרב"),

"ar-SA": ("Brass Pawn: شطرنج مدرب", "تكتيك ونهايات وألغاز",
 "stockfish,افتتاح,تحليل,رقعة,دون إنترنت,تصنيف,تعلم,استراتيجية,مباراة,كش مات,تدريب,مبتدئين"),
}
