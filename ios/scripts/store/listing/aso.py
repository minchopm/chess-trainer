# -*- coding: utf-8 -*-
"""Name, subtitle and keywords for every storefront.

Apple indexes the union of the app name, the subtitle and the keyword field,
and nothing else — the description is not searched. So a word that appears in
the name or the subtitle is wasted if it is repeated in the keywords, and the
keyword field is spent entirely on words those two do not already carry.

The subtitle leads with online play — playing people, friends — and the
puzzles after it (1.3, October 2026: the old one, "Puzzles, Tactics &
Endgames", said nothing of the multiplayer the app now has).

The name is "Brass Pawn: <chess trainer>" in each language: the brand first,
because it has to read as a name, and the two words somebody would actually
type after it. Where a language would ordinarily compound those two words
(German, Dutch, the Nordics), they are written apart so both tokens index.
"""

# locale: (name, subtitle, keywords)
ASO = {
"en-US": ("Brass Pawn: Chess Trainer", "Play Online, Friends & Puzzles",
 "multiplayer,blitz,rapid,ranked,tactics,endgame,coach,stockfish,elo,opening,analysis,board,offline"),

"en-CA": ("Brass Pawn: Chess Trainer", "Play Online, Friends & Puzzles",
 "multiplayer,blitz,rapid,ranked,tactics,endgame,coach,stockfish,elo,opening,analysis,board,offline"),

"de-DE": ("Brass Pawn: Schach Trainer", "Online mit Freunden & Rätsel",
 "mehrspieler,blitz,schnellschach,rangliste,taktik,endspiel,stockfish,elo,eröffnung,analyse,brett"),

"fr-FR": ("Brass Pawn: Coach d'Échecs", "Jouer en ligne, amis, puzzles",
 "multijoueur,blitz,rapide,classement,tactique,finale,stockfish,elo,ouverture,analyse,échiquier,partie"),

"fr-CA": ("Brass Pawn: Coach d'Échecs", "Jouer en ligne, amis, puzzles",
 "multijoueur,blitz,rapide,classement,tactique,finale,stockfish,elo,ouverture,analyse,échiquier,partie"),

"es-ES": ("Brass Pawn: Ajedrez Coach", "Juega online, amigos y puzles",
 "multijugador,blitz,rápidas,clasificación,táctica,finales,stockfish,elo,apertura,análisis,tablero"),

"it": ("Brass Pawn: Scacchi Coach", "Online con amici, rompicapi",
 "multigiocatore,blitz,rapid,classifica,tattica,finali,stockfish,elo,apertura,analisi,scacchiera,gioca"),

"pt-BR": ("Brass Pawn: Xadrez Coach", "Jogue online, amigos, puzzles",
 "multijogador,blitz,rápidas,ranking,táticas,finais,stockfish,elo,abertura,análise,tabuleiro,offline"),

"nl-NL": ("Brass Pawn: Schaak Trainer", "Online met vrienden & puzzels",
 "multiplayer,blitz,snelschaak,ranglijst,tactiek,eindspel,stockfish,elo,opening,analyse,bord,offline"),

"ru": ("Brass Pawn: Шахматы Тренер", "Онлайн с друзьями и задачи",
 "мультиплеер,блиц,рапид,рейтинг,тактика,эндшпиль,stockfish,эло,дебют,анализ,доска,офлайн,играть"),

"pl": ("Brass Pawn: Szachy Trener", "Gra online, znajomi, zadania",
 "multiplayer,blitz,szybkie,ranking,taktyka,końcówki,stockfish,elo,otwarcie,analiza,szachownica,mat"),

"cs": ("Brass Pawn: Šachy Trenér", "Hra online, přátelé, úlohy",
 "multiplayer,blitz,rapid,žebříček,taktika,koncovky,stockfish,elo,zahájení,analýza,šachovnice,offline"),

"hu": ("Brass Pawn: Sakk Edző", "Online barátokkal, feladványok",
 "többjátékos,villám,rapid,ranglista,taktika,végjáték,stockfish,elo,megnyitás,elemzés,tábla,offline"),

"ro": ("Brass Pawn: Șah Antrenor", "Online cu prieteni, probleme",
 "multiplayer,blitz,rapid,clasament,tactică,finaluri,stockfish,elo,deschidere,analiză,tablă,offline"),

"el": ("Brass Pawn: Σκάκι Προπονητής", "Online με φίλους και γρίφοι",
 "πολλοί παίκτες,μπλιτς,ράπιντ,κατάταξη,τακτική,φινάλε,stockfish,elo,άνοιγμα,ανάλυση,σκακιέρα"),

"tr": ("Brass Pawn: Satranç Koçu", "Online arkadaşlarla, bulmaca",
 "çok oyunculu,blitz,hızlı,sıralama,taktik,oyunsonu,stockfish,elo,açılış,analiz,tahta,çevrimdışı"),

"sv": ("Brass Pawn: Schack Tränare", "Spela online, vänner & pussel",
 "flerspelare,blixt,snabbschack,ranking,taktik,slutspel,stockfish,elo,öppning,analys,bräde,offline"),

"da": ("Brass Pawn: Skak Træner", "Spil online, venner og gåder",
 "multiplayer,lyn,hurtigskak,rangliste,taktik,slutspil,stockfish,elo,åbning,analyse,bræt,offline"),

"no": ("Brass Pawn: Sjakk Trener", "Spill online, venner og gåter",
 "flerspiller,lyn,hurtigsjakk,rangering,taktikk,sluttspill,stockfish,elo,åpning,analyse,brett"),

"fi": ("Brass Pawn: Shakki Valmentaja", "Pelaa netissä, kaverit, pulmat",
 "moninpeli,online,salama,pikashakki,ranking,taktiikka,loppupeli,stockfish,elo,avaus,analyysi,lauta"),

"ja": ("Brass Pawn: チェス トレーナー", "オンライン対戦・フレンド・詰めチェス",
 "マルチプレイ,対人戦,ブリッツ,ランキング,戦術,終盤,stockfish,レーティング,定跡,解析,盤,オフライン,コーチ,対局,学習,戦略,棋譜,初心者"),

"ko": ("Brass Pawn: 체스 트레이너", "온라인 대전 · 친구 · 퍼즐",
 "멀티플레이,블리츠,랭킹,전술,엔드게임,stockfish,레이팅,오프닝,분석,체스판,오프라인,코치,대국,학습,전략,초보"),

"zh-Hans": ("Brass Pawn: 国际象棋教练", "在线对战 · 好友 · 棋题",
 "多人,快棋,排行榜,战术,残局,stockfish,等级分,开局,分析,棋盘,离线,对局,学习,策略,将杀,棋谱,训练,入门"),

"zh-Hant": ("Brass Pawn: 西洋棋教練", "線上對戰 · 好友 · 棋題",
 "多人,快棋,排行榜,戰術,殘局,stockfish,等級分,開局,分析,棋盤,離線,對局,學習,策略,將殺,棋譜,訓練,入門"),

"th": ("Brass Pawn: หมากรุกฝรั่ง โค้ช", "เล่นออนไลน์ เพื่อน ปริศนา",
 "หลายผู้เล่น,บลิทซ์,อันดับ,แทกติก,จบเกม,stockfish,เรตติ้ง,เปิดเกม,วิเคราะห์,กระดาน,ออฟไลน์,กลยุทธ์"),

"vi": ("Brass Pawn: Cờ Vua Huấn Luyện", "Chơi online, bạn bè, câu đố",
 "trực tuyến,đối kháng,xếp hạng,chiến thuật,tàn cuộc,stockfish,elo,khai cuộc,phân tích,ngoại tuyến"),

"id": ("Brass Pawn: Catur Pelatih", "Main online, teman, teka-teki",
 "multiplayer,blitz,cepat,peringkat,taktik,akhir,stockfish,elo,pembukaan,analisis,papan,luring,skakmat"),

"ms": ("Brass Pawn: Catur Jurulatih", "Main online, rakan, teka-teki",
 "berbilang pemain,blitz,pantas,kedudukan,taktik,penamat,stockfish,elo,pembukaan,analisis,papan"),

"hi": ("Brass Pawn: शतरंज ट्रेनर", "ऑनलाइन खेलें, दोस्त, पहेली",
 "मल्टीप्लेयर,ब्लिट्ज़,रैंकिंग,रणनीति,अंत खेल,stockfish,elo,ओपनिंग,विश्लेषण,बोर्ड,ऑफ़लाइन,चेस"),

"he": ("Brass Pawn: שחמט מאמן", "משחק אונליין, חברים, חידות",
 "רב משתתפים,בליץ,דירוג,טקטיקה,סיומים,stockfish,פתיחה,ניתוח,לוח,לא מקוון,ללמוד,אסטרטגיה,מט"),

"ar-SA": ("Brass Pawn: شطرنج مدرب", "أونلاين مع الأصدقاء وألغاز",
 "متعدد اللاعبين,بليتز,سريع,تصنيف,تكتيك,نهايات,stockfish,افتتاح,تحليل,رقعة,دون إنترنت,تعلم,مباراة"),
}
