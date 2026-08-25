# -*- coding: utf-8 -*-
"""The block Apple wants at the foot of the description.

Guideline 3.1.2 asks for the subscription's length, what it unlocks, the
renewal terms, and working links to the Terms of Use and the privacy policy —
in the *metadata*, not only in the app. The app has had them on the purchase
screen all along; a listing without them is what gets returned.

No price is written here. It would have to be right in a hundred and seventy-five
storefronts and it is shown on the purchase screen in the reader's own currency
anyway. The other apps on this account are live and approved without it.

EULA is Apple's standard one, which is what the account uses throughout.
"""

EULA = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
PRIVACY = "https://brasspawn.com/privacy"

# locale: (heading, body, terms label, privacy label)
BLOCK = {
"en-US": ("SUBSCRIPTION",
 "Playing is free and stays free, with no limit and no advertising. Brass Pawn Pro "
 "lifts the five-a-day limit on training; there is a monthly subscription and a "
 "one-off unlock that never renews.\n\n"
 "Payment is charged to your Apple Account on confirmation of purchase. A "
 "subscription renews automatically unless it is cancelled at least 24 hours before "
 "the end of the current period, and your account is charged within the 24 hours "
 "before it renews. Manage or cancel it in your App Store account settings.",
 "Terms of Use (EULA)", "Privacy Policy"),

"de-DE": ("ABONNEMENT",
 "Spielen ist kostenlos und bleibt es — ohne Begrenzung und ohne Werbung. Brass Pawn Pro "
 "hebt das Limit von fünf Übungen pro Tag auf; es gibt ein Monatsabo und eine einmalige "
 "Freischaltung, die sich nie verlängert.\n\n"
 "Die Zahlung wird bei Kaufbestätigung über Ihren Apple-Account abgerechnet. Ein Abo "
 "verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ablauf des "
 "laufenden Zeitraums gekündigt wird; die Abbuchung erfolgt innerhalb der letzten "
 "24 Stunden davor. Verwalten oder kündigen können Sie es in den Einstellungen Ihres "
 "App-Store-Accounts.",
 "Nutzungsbedingungen (EULA)", "Datenschutzerklärung"),

"fr-FR": ("ABONNEMENT",
 "Jouer est gratuit et le restera, sans limite et sans publicité. Brass Pawn Pro lève la "
 "limite de cinq exercices par jour ; il existe un abonnement mensuel et un achat unique "
 "qui ne se renouvelle jamais.\n\n"
 "Le paiement est débité de votre compte Apple à la confirmation de l’achat. Un abonnement "
 "se renouvelle automatiquement sauf s’il est annulé au moins 24 heures avant la fin de la "
 "période en cours ; le débit intervient dans les 24 heures précédant le renouvellement. "
 "Vous pouvez le gérer ou l’annuler dans les réglages de votre compte App Store.",
 "Conditions d’utilisation (CLUF)", "Politique de confidentialité"),

"es-ES": ("SUSCRIPCIÓN",
 "Jugar es gratis y seguirá siéndolo, sin límite y sin publicidad. Brass Pawn Pro elimina el "
 "límite de cinco ejercicios al día; hay una suscripción mensual y una compra única que "
 "nunca se renueva.\n\n"
 "El pago se cargará a tu cuenta de Apple al confirmar la compra. La suscripción se renueva "
 "automáticamente salvo que se cancele al menos 24 horas antes del final del periodo en "
 "curso; el cargo se realiza en las 24 horas previas a la renovación. Puedes gestionarla o "
 "cancelarla en los ajustes de tu cuenta de App Store.",
 "Términos de uso (EULA)", "Política de privacidad"),

"it": ("ABBONAMENTO",
 "Giocare è gratis e lo resterà, senza limiti e senza pubblicità. Brass Pawn Pro toglie il "
 "limite di cinque esercizi al giorno; ci sono un abbonamento mensile e uno sblocco una "
 "tantum che non si rinnova mai.\n\n"
 "Il pagamento viene addebitato sull’account Apple alla conferma dell’acquisto. "
 "L’abbonamento si rinnova automaticamente se non viene disdetto almeno 24 ore prima della "
 "fine del periodo in corso; l’addebito avviene nelle 24 ore precedenti il rinnovo. Puoi "
 "gestirlo o disdirlo nelle impostazioni del tuo account App Store.",
 "Condizioni d’uso (EULA)", "Informativa sulla privacy"),

"pt-BR": ("ASSINATURA",
 "Jogar é grátis e continuará sendo, sem limite e sem publicidade. O Brass Pawn Pro remove o "
 "limite de cinco exercícios por dia; há uma assinatura mensal e uma compra única que nunca "
 "se renova.\n\n"
 "O pagamento será cobrado da sua conta Apple na confirmação da compra. A assinatura se "
 "renova automaticamente, a menos que seja cancelada pelo menos 24 horas antes do fim do "
 "período atual; a cobrança ocorre nas 24 horas anteriores à renovação. Você pode gerenciá-la "
 "ou cancelá-la nos ajustes da sua conta da App Store.",
 "Termos de uso (EULA)", "Política de Privacidade"),

"nl-NL": ("ABONNEMENT",
 "Spelen is gratis en blijft gratis, zonder limiet en zonder advertenties. Brass Pawn Pro "
 "heft de limiet van vijf oefeningen per dag op; er is een maandabonnement en een eenmalige "
 "ontgrendeling die nooit wordt verlengd.\n\n"
 "De betaling wordt bij aankoopbevestiging van je Apple-account afgeschreven. Een abonnement "
 "wordt automatisch verlengd tenzij het minstens 24 uur voor het einde van de lopende periode "
 "wordt opgezegd; de afschrijving vindt plaats in de 24 uur daarvoor. Je beheert of zegt het "
 "op in de instellingen van je App Store-account.",
 "Gebruiksvoorwaarden (EULA)", "Privacybeleid"),

"ru": ("ПОДПИСКА",
 "Играть бесплатно и останется бесплатно — без ограничений и без рекламы. Brass Pawn Pro "
 "снимает ограничение в пять упражнений в день; есть ежемесячная подписка и разовая покупка, "
 "которая никогда не продлевается.\n\n"
 "Оплата списывается с вашего аккаунта Apple при подтверждении покупки. Подписка продлевается "
 "автоматически, если её не отменить не менее чем за 24 часа до конца текущего периода; "
 "списание происходит в течение 24 часов до продления. Управлять подпиской и отменить её "
 "можно в настройках аккаунта App Store.",
 "Условия использования (EULA)", "Политика конфиденциальности"),

"pl": ("SUBSKRYPCJA",
 "Gra jest bezpłatna i taka pozostanie — bez limitu i bez reklam. Brass Pawn Pro znosi limit "
 "pięciu ćwiczeń dziennie; dostępna jest subskrypcja miesięczna oraz jednorazowy zakup, który "
 "nigdy się nie odnawia.\n\n"
 "Płatność zostanie pobrana z konta Apple po potwierdzeniu zakupu. Subskrypcja odnawia się "
 "automatycznie, o ile nie zostanie anulowana co najmniej 24 godziny przed końcem bieżącego "
 "okresu; obciążenie następuje w ciągu 24 godzin przed odnowieniem. Możesz nią zarządzać lub "
 "ją anulować w ustawieniach konta App Store.",
 "Warunki użytkowania (EULA)", "Polityka prywatności"),

"cs": ("PŘEDPLATNÉ",
 "Hraní je zdarma a zůstane zdarma — bez omezení a bez reklam. Brass Pawn Pro ruší limit pěti "
 "cvičení denně; k dispozici je měsíční předplatné a jednorázové odemčení, které se nikdy "
 "neobnovuje.\n\n"
 "Platba bude stržena z vašeho účtu Apple při potvrzení nákupu. Předplatné se automaticky "
 "obnovuje, pokud není zrušeno nejméně 24 hodin před koncem aktuálního období; částka se "
 "strhává během 24 hodin před obnovením. Spravovat nebo zrušit je můžete v nastavení účtu "
 "App Store.",
 "Podmínky použití (EULA)", "Zásady ochrany osobních údajů"),

"hu": ("ELŐFIZETÉS",
 "A játék ingyenes, és az is marad — korlát és hirdetés nélkül. A Brass Pawn Pro feloldja a "
 "napi öt gyakorlat korlátját; van havi előfizetés és egyszeri feloldás, amely soha nem "
 "újul meg.\n\n"
 "A díj a vásárlás megerősítésekor terheli az Apple-fiókját. Az előfizetés automatikusan "
 "megújul, hacsak legalább 24 órával az aktuális időszak vége előtt nem mondja le; a terhelés "
 "a megújulás előtti 24 órában történik. Az App Store-fiók beállításaiban kezelheti vagy "
 "mondhatja le.",
 "Felhasználási feltételek (EULA)", "Adatvédelmi irányelvek"),

"ro": ("ABONAMENT",
 "Jocul este gratuit și rămâne gratuit — fără limită și fără reclame. Brass Pawn Pro ridică "
 "limita de cinci exerciții pe zi; există un abonament lunar și o achiziție unică ce nu se "
 "reînnoiește niciodată.\n\n"
 "Plata este debitată din contul Apple la confirmarea achiziției. Abonamentul se reînnoiește "
 "automat dacă nu este anulat cu cel puțin 24 de ore înainte de sfârșitul perioadei curente; "
 "debitarea are loc în ultimele 24 de ore dinaintea reînnoirii. Îl poți gestiona sau anula "
 "din setările contului App Store.",
 "Termeni de utilizare (EULA)", "Politica de confidențialitate"),

"el": ("ΣΥΝΔΡΟΜΗ",
 "Το παιχνίδι είναι δωρεάν και θα παραμείνει — χωρίς όριο και χωρίς διαφημίσεις. Το Brass Pawn "
 "Pro αίρει το όριο των πέντε ασκήσεων την ημέρα· υπάρχει μηνιαία συνδρομή και εφάπαξ αγορά "
 "που δεν ανανεώνεται ποτέ.\n\n"
 "Η χρέωση γίνεται στον λογαριασμό Apple κατά την επιβεβαίωση της αγοράς. Η συνδρομή "
 "ανανεώνεται αυτόματα εκτός αν ακυρωθεί τουλάχιστον 24 ώρες πριν από τη λήξη της τρέχουσας "
 "περιόδου· η χρέωση γίνεται εντός 24 ωρών πριν την ανανέωση. Μπορείτε να τη διαχειριστείτε ή "
 "να την ακυρώσετε στις ρυθμίσεις του λογαριασμού App Store.",
 "Όροι χρήσης (EULA)", "Πολιτική απορρήτου"),

"tr": ("ABONELİK",
 "Oynamak ücretsizdir ve öyle kalacak — sınır yok, reklam yok. Brass Pawn Pro günde beş "
 "alıştırma sınırını kaldırır; aylık abonelik ve hiç yenilenmeyen tek seferlik bir satın alma "
 "vardır.\n\n"
 "Ödeme, satın alma onaylandığında Apple hesabınızdan tahsil edilir. Abonelik, mevcut dönemin "
 "bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir; ücret "
 "yenilemeden önceki 24 saat içinde alınır. App Store hesap ayarlarınızdan yönetebilir veya "
 "iptal edebilirsiniz.",
 "Kullanım Koşulları (EULA)", "Gizlilik Politikası"),

"sv": ("PRENUMERATION",
 "Att spela är gratis och förblir gratis — utan gräns och utan reklam. Brass Pawn Pro tar bort "
 "gränsen på fem övningar om dagen; det finns en månadsprenumeration och ett engångsköp som "
 "aldrig förnyas.\n\n"
 "Betalningen dras från ditt Apple-konto när köpet bekräftas. En prenumeration förnyas "
 "automatiskt om den inte sägs upp minst 24 timmar före den aktuella periodens slut; "
 "debiteringen sker inom 24 timmar före förnyelsen. Du hanterar eller säger upp den i "
 "inställningarna för ditt App Store-konto.",
 "Användarvillkor (EULA)", "Integritetspolicy"),

"da": ("ABONNEMENT",
 "Det er gratis at spille og bliver ved med at være det — uden grænse og uden reklamer. "
 "Brass Pawn Pro fjerner grænsen på fem øvelser om dagen; der er et månedsabonnement og et "
 "engangskøb, der aldrig fornys.\n\n"
 "Betalingen trækkes fra din Apple-konto, når købet bekræftes. Et abonnement fornys "
 "automatisk, medmindre det opsiges mindst 24 timer før den aktuelle periodes udløb; "
 "beløbet trækkes inden for de sidste 24 timer før fornyelsen. Du kan administrere eller "
 "opsige det i indstillingerne for din App Store-konto.",
 "Brugsvilkår (EULA)", "Privatlivspolitik"),

"no": ("ABONNEMENT",
 "Det er gratis å spille og forblir gratis — uten grense og uten reklame. Brass Pawn Pro "
 "fjerner grensen på fem øvelser om dagen; det finnes et månedsabonnement og et engangskjøp "
 "som aldri fornyes.\n\n"
 "Betalingen belastes Apple-kontoen din når kjøpet bekreftes. Et abonnement fornyes "
 "automatisk med mindre det sies opp minst 24 timer før inneværende periode utløper; beløpet "
 "trekkes innen 24 timer før fornyelsen. Du kan administrere eller si det opp i innstillingene "
 "for App Store-kontoen din.",
 "Bruksvilkår (EULA)", "Personvernerklæring"),

"fi": ("TILAUS",
 "Pelaaminen on ilmaista ja pysyy ilmaisena — ilman rajaa ja ilman mainoksia. Brass Pawn Pro "
 "poistaa viiden päivittäisen harjoituksen rajan; tarjolla on kuukausitilaus ja kertaosto, "
 "joka ei koskaan uusiudu.\n\n"
 "Maksu veloitetaan Apple-tililtäsi oston vahvistuksen yhteydessä. Tilaus uusiutuu "
 "automaattisesti, ellei sitä peruta vähintään 24 tuntia ennen kuluvan jakson päättymistä; "
 "veloitus tapahtuu 24 tunnin sisällä ennen uusiutumista. Voit hallita tai peruuttaa sen "
 "App Store -tilisi asetuksissa.",
 "Käyttöehdot (EULA)", "Tietosuojakäytäntö"),

"ja": ("サブスクリプション",
 "対局は無料で、これからも無料です。制限も広告もありません。Brass Pawn Pro は 1 日 5 問という"
 "トレーニングの上限を解除します。月額プランと、更新のない買い切りの 2 つがあります。\n\n"
 "購入確定時に Apple アカウントへ課金されます。サブスクリプションは、現在の期間の終了 24 時間前"
 "までに解約しないかぎり自動更新され、更新前の 24 時間以内に課金されます。管理と解約は "
 "App Store アカウントの設定から行えます。",
 "利用規約（EULA）", "プライバシーポリシー"),

"ko": ("구독",
 "대국은 무료이며 앞으로도 무료입니다. 제한도 광고도 없습니다. Brass Pawn Pro는 하루 다섯 개라는 "
 "훈련 제한을 해제합니다. 월 구독과, 갱신되지 않는 일회성 구매가 있습니다.\n\n"
 "구매를 확인하면 Apple 계정으로 결제됩니다. 구독은 현재 기간이 끝나기 최소 24시간 전에 취소하지 "
 "않으면 자동으로 갱신되며, 갱신 전 24시간 이내에 청구됩니다. App Store 계정 설정에서 관리하거나 "
 "취소할 수 있습니다.",
 "이용 약관(EULA)", "개인정보 처리방침"),

"zh-Hans": ("订阅",
 "对局免费，而且一直免费——没有限制，没有广告。Brass Pawn Pro 解除每天五道训练题的上限；"
 "有按月订阅，也有永不续订的一次性买断。\n\n"
 "确认购买时将从您的 Apple 账户扣款。订阅会自动续订，除非在当前周期结束前至少 24 小时取消；"
 "扣款发生在续订前 24 小时内。您可以在 App Store 账户设置中管理或取消。",
 "使用条款（EULA）", "隐私政策"),

"zh-Hant": ("訂閱",
 "對局免費，而且一直免費——沒有限制，沒有廣告。Brass Pawn Pro 解除每天五道訓練題的上限；"
 "有按月訂閱，也有永不續訂的一次性買斷。\n\n"
 "確認購買時將從您的 Apple 帳戶扣款。訂閱會自動續訂，除非在目前週期結束前至少 24 小時取消；"
 "扣款發生在續訂前 24 小時內。您可以在 App Store 帳戶設定中管理或取消。",
 "使用條款（EULA）", "隱私權政策"),

"th": ("การสมัครสมาชิก",
 "การเล่นฟรีและจะฟรีต่อไป ไม่มีขีดจำกัดและไม่มีโฆษณา Brass Pawn Pro ปลดขีดจำกัดวันละห้าข้อของการฝึก "
 "มีทั้งแบบรายเดือนและแบบจ่ายครั้งเดียวที่ไม่ต่ออายุ\n\n"
 "ระบบจะเรียกเก็บเงินจากบัญชี Apple ของคุณเมื่อยืนยันการซื้อ การสมัครสมาชิกจะต่ออายุอัตโนมัติ "
 "เว้นแต่จะยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดรอบปัจจุบัน และจะเรียกเก็บภายใน 24 ชั่วโมงก่อนต่ออายุ "
 "คุณจัดการหรือยกเลิกได้ในการตั้งค่าบัญชี App Store",
 "ข้อกำหนดการใช้งาน (EULA)", "นโยบายความเป็นส่วนตัว"),

"vi": ("ĐĂNG KÝ",
 "Chơi thì miễn phí và sẽ luôn miễn phí — không giới hạn, không quảng cáo. Brass Pawn Pro gỡ "
 "giới hạn năm bài luyện mỗi ngày; có gói hằng tháng và một lần mua vĩnh viễn không bao giờ "
 "gia hạn.\n\n"
 "Khoản thanh toán sẽ được tính vào tài khoản Apple của bạn khi xác nhận mua. Gói đăng ký tự "
 "động gia hạn trừ khi bị hủy ít nhất 24 giờ trước khi kỳ hiện tại kết thúc; tiền được trừ "
 "trong vòng 24 giờ trước khi gia hạn. Bạn có thể quản lý hoặc hủy trong phần cài đặt tài "
 "khoản App Store.",
 "Điều khoản sử dụng (EULA)", "Chính sách quyền riêng tư"),

"id": ("LANGGANAN",
 "Bermain itu gratis dan akan tetap gratis — tanpa batas dan tanpa iklan. Brass Pawn Pro "
 "menghapus batas lima latihan per hari; tersedia langganan bulanan dan pembelian sekali "
 "bayar yang tidak pernah diperpanjang.\n\n"
 "Pembayaran akan dibebankan ke akun Apple Anda saat pembelian dikonfirmasi. Langganan "
 "diperpanjang otomatis kecuali dibatalkan setidaknya 24 jam sebelum periode berjalan "
 "berakhir; tagihan ditarik dalam 24 jam sebelum perpanjangan. Anda dapat mengelola atau "
 "membatalkannya di pengaturan akun App Store.",
 "Ketentuan Penggunaan (EULA)", "Kebijakan Privasi"),

"ms": ("LANGGANAN",
 "Bermain adalah percuma dan akan kekal begitu — tanpa had dan tanpa iklan. Brass Pawn Pro "
 "menghapuskan had lima latihan sehari; ada langganan bulanan dan pembelian sekali bayar yang "
 "tidak pernah diperbaharui.\n\n"
 "Bayaran akan dicaj ke akaun Apple anda apabila pembelian disahkan. Langganan diperbaharui "
 "secara automatik melainkan dibatalkan sekurang-kurangnya 24 jam sebelum tempoh semasa "
 "berakhir; caj dikenakan dalam masa 24 jam sebelum pembaharuan. Anda boleh mengurus atau "
 "membatalkannya dalam tetapan akaun App Store.",
 "Terma Penggunaan (EULA)", "Dasar Privasi"),

"hi": ("सदस्यता",
 "खेलना मुफ़्त है और मुफ़्त ही रहेगा — कोई सीमा नहीं, कोई विज्ञापन नहीं। Brass Pawn Pro प्रशिक्षण की "
 "रोज़ाना पाँच की सीमा हटा देता है; मासिक सदस्यता है और एक बार का भुगतान भी, जो कभी नवीनीकृत नहीं होता।\n\n"
 "खरीद की पुष्टि पर आपके Apple खाते से भुगतान लिया जाएगा। सदस्यता स्वतः नवीनीकृत होती है, जब तक कि "
 "मौजूदा अवधि समाप्त होने से कम से कम 24 घंटे पहले रद्द न की जाए; शुल्क नवीनीकरण से पहले के 24 घंटों में "
 "लिया जाता है। आप इसे App Store खाता सेटिंग में प्रबंधित या रद्द कर सकते हैं।",
 "उपयोग की शर्तें (EULA)", "गोपनीयता नीति"),

"he": ("מנוי",
 "המשחק חינם ויישאר חינם — בלי הגבלה ובלי פרסומות. ‏Brass Pawn Pro מסיר את מגבלת חמשת "
 "התרגילים ביום; יש מנוי חודשי ורכישה חד-פעמית שאינה מתחדשת לעולם.\n\n"
 "התשלום ייגבה מחשבון ה-Apple שלך עם אישור הרכישה. המנוי מתחדש אוטומטית אלא אם בוטל לפחות "
 "24 שעות לפני תום התקופה הנוכחית; החיוב מתבצע בתוך 24 השעות שלפני החידוש. אפשר לנהל או "
 "לבטל אותו בהגדרות חשבון ה-App Store.",
 "תנאי שימוש (EULA)", "מדיניות פרטיות"),

"ar-SA": ("الاشتراك",
 "اللعب مجاني وسيبقى مجانيًا — بلا حدود وبلا إعلانات. يرفع Brass Pawn Pro حدّ التدريب البالغ "
 "خمسة يوميًا؛ هناك اشتراك شهري وشراء لمرة واحدة لا يُجدَّد أبدًا.\n\n"
 "يُخصم المبلغ من حساب Apple عند تأكيد الشراء. يتجدّد الاشتراك تلقائيًا ما لم يُلغَ قبل 24 ساعة "
 "على الأقل من نهاية الفترة الحالية، ويتم الخصم خلال 24 ساعة قبل التجديد. يمكنك إدارته أو "
 "إلغاؤه من إعدادات حساب App Store.",
 "شروط الاستخدام (EULA)", "سياسة الخصوصية"),
}

# The English text serves the other English storefronts and both French ones
# differ only by storefront, not by wording.
BLOCK["en-CA"] = BLOCK["en-US"]
BLOCK["fr-CA"] = BLOCK["fr-FR"]


def footer(locale):
    heading, body, terms_label, privacy_label = BLOCK[locale]
    return (f"{heading}\n{body}\n\n"
            f"{terms_label}: {EULA}\n"
            f"{privacy_label}: {PRIVACY}")
