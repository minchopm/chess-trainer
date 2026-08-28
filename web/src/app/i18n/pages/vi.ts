import type { Pages } from './types';

/** The four commercial pages in Vietnamese. */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Hỗ trợ',
      title: 'Hỏi một con người',
      lede: 'Không có hệ thống phiếu yêu cầu, không có chatbot, không có trung tâm trợ giúp với bốn trăm bài viết. Chỉ có một địa chỉ thư điện tử và một danh sách lỗi, và cả hai đều dẫn tới người đã viết ứng dụng này.',
    },
    meta: {
      title: 'Hỗ trợ',
      description:
        'Cách liên hệ một con người về Brass Pawn, cần gửi gì khi một thế cờ bị sai, và những câu hỏi hay gặp nhất.',
    },
    email: {
      slug: 'Thư điện tử',
      body: 'Về bất cứ điều gì: một lỗi, một thế cờ sai, một câu hỏi về việc mua, hoặc bất đồng với một đánh giá. Hãy viết bằng tiếng Anh hoặc tiếng Bulgaria.',
    },
    tracker: {
      slug: 'Danh sách lỗi',
      name: 'Issue trên GitHub',
      body: 'Cho mọi thứ bạn muốn để công khai — và cho mọi thứ người khác cần tìm lại về sau, vốn đúng với phần lớn báo cáo lỗi.',
    },
    report: {
      slug: 'Khi một thế cờ bị sai',
      title: 'Gửi bốn thứ, việc kiểm tra chỉ mất một phút.',
      checklist: [
        'Chuỗi FEN hiện trên màn hình thế cờ — nhấn giữ để sao chép.',
        'Nước bạn đã đi, và nước ứng dụng gọi là đúng.',
        'Bạn đang ở chế độ nào.',
        'Phiên bản ứng dụng, lấy từ màn hình thông tin.',
      ],
      caveat:
        'Thỉnh thoảng các thế cờ mâu thuẫn với một lượt tìm kiếm sâu hơn, và những mâu thuẫn ấy dồn lại ở các thế dài, tĩnh, được xếp hạng cao mà cái lý của chúng nằm sâu hơn tầm với của khâu kiểm tra. Đó là giới hạn của khâu kiểm tra chứ không phải lỗi của thế cờ — nhưng đáng để biết đó là những thế nào, và cách duy nhất để biết là bạn lên tiếng.',
    },
    faq: { slug: 'Câu hỏi', title: 'Được hỏi đủ nhiều để đáng ghi lại.' },
    more: {
      ratings: 'Một hệ số đo điều gì',
      tactics: 'Các mô-típ',
      privacy: 'Chính sách riêng tư',
      terms: 'Điều khoản sử dụng',
      licences: 'Giấy phép',
    },
  },

  pricing: {
    head: {
      slug: 'Giá bao nhiêu',
      title: 'Chơi thì miễn phí. Cái được bán là phần luyện tập.',
      lede: 'Cờ với máy và cờ với người, không giới hạn, không quảng cáo ở bất cứ đâu trong ứng dụng — điều đó miễn phí và sẽ tiếp tục như vậy. Cái được bán là thư viện, các bài tập, các thế cờ và cuộc đua với đồng hồ.',
    },
    meta: {
      title: 'Giá',
      description:
        'Chơi thì miễn phí và không giới hạn — máy cờ, một đối thủ người thật và cả 900 ván. Pro gỡ bỏ hạn mức năm lượt mỗi ngày: 3,99 đô mỗi tháng hoặc 49,99 trả một lần.',
    },
    free: {
      name: 'Miễn phí',
      note: 'Không cần tài khoản. Không có gì để đăng ký.',
      items: [
        'Chơi không giới hạn với máy, từ 1400 đến sức mạnh tối đa',
        'Ván trực tuyến không giới hạn qua Game Center',
        'Bình luận từng nước trong mọi ván bạn chơi',
        'Năm thế cờ chiến thuật mỗi ngày',
        'Năm lượt Rush mỗi ngày',
        'Năm lượt mỗi loại: thế trận, tàn cuộc, Đoán Elo',
        'Hệ số, chuỗi thành tích và ôn tập giãn cách, đầy đủ',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Hằng tháng',
      per: 'mỗi tháng',
      note: 'Hủy bất cứ lúc nào trong phần cài đặt tài khoản Apple của bạn.',
      items: [
        'Mọi hạn mức hằng ngày biến mất',
        'Toàn bộ {tactics} thế cờ chiến thuật',
        'Toàn bộ {positional} bài tập thế trận',
        'Toàn bộ {endgames} bài tập tàn cuộc',
        'Toàn bộ {games} ván để đánh giá',
        'Rush không giới hạn',
        'Mọi thứ trong bản miễn phí, không đổi',
      ],
    },
    lifetime: {
      name: 'Mở khóa một lần',
      once: 'một lần cho mãi mãi',
      note: 'Một khoản mua không tiêu hao. Nó không gia hạn.',
      items: [
        'Đúng y như Pro hằng tháng',
        'Không gia hạn, không hạn dùng, không thư nhắc',
        'Được khôi phục trên các thiết bị khác của bạn',
        'Dành cho người thích quyết định một lần',
      ],
    },
    table: {
      slug: 'Toàn bộ khẩu phần',
      title: 'Bản miễn phí thực sự cho những gì.',
      activity: 'Hoạt động',
      freeCol: 'Miễn phí',
      proCol: 'Pro',
      unlimited: 'Không giới hạn',
      fiveADay: '5 mỗi ngày',
      none: 'Không có',
      rows: [
        'Chơi với máy',
        'Ván trực tuyến qua Game Center',
        'Xem — thư viện 900 ván',
        'Thế cờ chiến thuật',
        'Lượt Rush',
        'Bài tập thế trận',
        'Bài tập tàn cuộc',
        'Đoán Elo',
        'Quảng cáo',
      ],
      reset:
        'Khẩu phần mỗi ngày đặt lại vào chín giờ sáng giờ địa phương — không phải nửa đêm, để một buổi tập buổi tối không bị cắt đôi bởi việc đổi ngày.',
    },
    why: {
      slug: 'Vì sao nó có hình dạng này',
      title: 'Ba quyết định, và lý do của từng cái.',
      reasons: [
        {
          title: 'Đếm, chứ không khóa',
          body: [
            'Không ai trả tiền cho một huấn luyện viên mình chưa dùng, và một chế độ từ chối mở ra thì chẳng nói được gì về thứ nằm phía sau nó. Vậy nên mọi chế độ đều mở, mỗi ngày, và bạn đi đủ xa để cảm được nhịp và thấy hệ số dịch chuyển.',
            'Màn hình mua hàng không bao giờ hiện lên lúc khởi động. Khi khẩu phần trong ngày đã hết, màn hình nói vậy, và chỉ một cú chạm có chủ ý mới mở phiếu mua.',
          ],
        },
        {
          title: 'Hai mức giá, không phải ba',
          body: [
            'Không có gói theo năm ở giữa, vì mức giá thứ ba là quyết định thứ ba đúng vào lúc ai đó muốn giải một thế cờ. Hằng tháng nếu bạn còn phân vân. Một lần nếu không.',
          ],
        },
        {
          title: 'Việc chơi thì không bao giờ đem bán',
          body: [
            'Cờ với máy và cờ với người không tốn gì để vận hành và là lý do ứng dụng này tồn tại. Đem bán chúng sẽ biến nó thành một ứng dụng cờ có trạm thu phí thay vì một huấn luyện viên.',
            'Và không có quảng cáo — một phần là gu, một phần là giấy phép. Ứng dụng liên kết hai máy cờ copyleft, Stockfish theo GPLv3 và Reckless theo AGPLv3, và một bộ SDK quảng cáo độc quyền trong cùng tệp nhị phân sẽ khiến toàn bộ không thể phân phối được. {link}',
          ],
        },
      ],
      licenceLink: 'Trang giấy phép giải thích chuyện này cặn kẽ.',
    },
    answers: {
      slug: 'Mua, hủy, hoàn tiền',
      title: 'Những câu hỏi khó chịu, trả lời ở đây thay vì qua thư.',
      items: [
        {
          q: 'Tôi hủy bằng cách nào?',
          a: 'Cài đặt → tên bạn → Đăng ký → Brass Pawn. Chúng tôi không thể hủy giúp bạn, vì gói đăng ký là giữa bạn và Apple và chưa bao giờ ở chỗ chúng tôi. Việc hủy dừng các lần gia hạn về sau và không rút ngắn kỳ hạn đã trả tiền.',
        },
        {
          q: 'Làm sao tôi lấy lại tiền?',
          a: 'Qua Apple, tại {link}. Chúng tôi không hoàn tiền cho các khoản mua trên App Store. Nếu có gì hỏng, hãy viết cho chúng tôi — chúng tôi thích sửa hơn.',
        },
        {
          q: 'Tôi đã mua bản mở khóa và giờ đổi điện thoại.',
          a: 'Đăng nhập cùng tài khoản Apple đó và chạm “Khôi phục các khoản mua” trên màn hình mua hàng. Ứng dụng hỏi StoreKit xem bạn sở hữu gì; không có gì nằm trên máy chủ của chúng tôi, vì chúng tôi không có máy chủ nào cả.',
        },
        {
          q: 'Pro có làm đổi hệ số của tôi hay mở ra những thế cờ “tốt hơn” không?',
          a: 'Không. Hệ thống xếp hạng y hệt, và mọi thế cờ trong thư viện đều tới được bằng tài khoản miễn phí — năm lượt mỗi ngày. Pro gỡ bộ đếm, chứ không gỡ một tấm màn.',
        },
        {
          q: 'Về sau khẩu phần miễn phí có bị thu hẹp không?',
          a: 'Nó có thể thay đổi theo cả hai hướng khi thư viện lớn lên. Việc chơi không giới hạn với máy và với người sẽ không trở thành tính năng trả tiền; điều đó được ghi trong {link}, chứ không chỉ hứa ở đây.',
        },
      ],
      termsLink: 'điều khoản',
      more: 'Thêm câu hỏi, và cách liên hệ một con người →',
    },
  },

  training: {
    head: {
      slug: 'Chương trình',
      title: 'Tám cách để nghe sự thật',
      lede: 'Ba trong số đó miễn phí và không giới hạn mãi mãi — chơi, chơi với ai đó, và chín trăm ván trong mục Xem. Năm cái còn lại là năm lượt mỗi ngày với tài khoản miễn phí và không giới hạn với Pro. Mỗi cái đánh giá bạn bằng lời về thế cờ chứ không bằng một con số mà bạn còn phải giải mã.',
    },
    meta: {
      title: 'Luyện tập',
      description:
        'Tám chế độ: chiến thuật, phán đoán thế trận, tàn cuộc, Rush, Đoán Elo, Xem, chơi kèm bình luận và trực tuyến. Từng chế độ hoạt động ra sao, các thế cờ được khai thác và kiểm chứng thế nào, và huấn luyện viên không làm gì.',
    },
    modes: [
      {
        title: 'Chiến thuật',
        lede: 'Những thế cờ có đúng một nước thắng, và một phán quyết ngay lúc bạn đi nước đó.',
        body: [
          'Mỗi thế cờ có một đáp án và không có nhánh rẽ. Đi nước đó trên bàn cờ và huấn luyện viên nói ngay bạn có tìm ra không; nếu trượt, thế cờ quay lại vào ngày mai, rồi bốn ngày sau, rồi mười ngày — chừng nào nó còn bắt được bạn.',
          'Mỗi thế cờ mang theo mô-típ mà nó xoay quanh — chĩa đôi, ghim, xiên, chiếu hết hàng cuối, đánh lạc hướng, nước đi thầm lặng — để sau vài trăm thế, huấn luyện viên có thể nói với bạn không phải rằng bạn ở mức 1620, mà rằng bạn ở mức 1620 và cứ mắc mãi vào các đòn đánh lạc hướng.',
        ],
        free: 'Năm lượt mỗi ngày với tài khoản miễn phí.',
        stat: 'thế cờ, xếp hạng từ 760 đến 2800',
      },
      {
        title: 'Phán đoán thế trận',
        lede: 'Không có đường thắng ép buộc. Hãy nói ai đứng tốt hơn, rồi tìm nước cờ nói lên vì sao.',
        body: [
          'Đây là chế độ được dựng cho đúng thứ phân tách người mạnh với người tính toán giỏi. Trước hết bạn đánh giá: hơn rõ rệt, hơn chút ít, cân bằng. Rồi bạn chọn một nước. Cả hai câu trả lời đều được chấm.',
          'Phản hồi gọi tên những đặc điểm cụ thể thay vì cảm giác — cột mở và có xe đứng trên đó hay không, ô cho mã mà không tốt nào tranh được, cấu trúc tốt, độ an toàn của vua, chênh lệch về mức hoạt động của quân. Một thế cờ không phải là “dễ chịu cho bên trắng”; nó tốt hơn vì bốn lý do bạn có thể kể ra.',
        ],
        free: 'Năm lượt mỗi ngày với tài khoản miễn phí.',
        stat: 'thế tĩnh, do máy chọn trước',
      },
      {
        title: 'Tàn cuộc',
        lede: 'Các thế điển hình, chơi tới cùng trước một máy cờ phòng thủ đàng hoàng.',
        body: [
          'Biết ý tưởng không giống với đưa được nó về đích, nên ở đây bạn phải thực sự đạt được kết quả. Stockfish cầm bên kia và dựng lên hàng phòng thủ tốt nhất đang có.',
          'Sau mỗi nước, huấn luyện viên kiểm tra lại xem kết quả còn đạt được nữa không — và nếu không, nó nêu đích danh nước cờ mà từ đó kết quả tuột mất. Đó mới là câu dạy được điều gì: không phải “bạn hòa”, mà “bạn hòa ở chỗ này”.',
        ],
        free: 'Năm lượt mỗi ngày với tài khoản miễn phí.',
        stat: 'bài tập, mỗi kết quả đều được máy kiểm chứng',
      },
      {
        title: 'Rush',
        lede: 'Một lượt tính giờ. Giải được bao nhiêu thì giải trước khi đồng hồ lấy nốt phần còn lại.',
        body: [
          'Vẫn những thế cờ ấy, dưới đồng hồ, với độ khó tăng dần chừng nào bạn còn tìm ra chúng. Điều đó rèn một cơ bắp khác với thế cờ mà bạn được phép ngồi ngắm: cái cơ bắp phải nhìn ra ngay bây giờ.',
          'Các lượt được tính điểm và lưu lại, nên con số tăng theo tháng chứ không theo một tối.',
        ],
        free: 'Năm lượt mỗi ngày với tài khoản miễn phí.',
      },
      {
        title: 'Đoán Elo',
        lede: 'Một ván có hệ số thật, chạy lại từng nước. Hai người này mạnh cỡ nào?',
        body: [
          'Đọc được trình độ của một ván cờ là cùng một kỹ năng với việc tự đánh giá nước đi của mình: cả hai đều quy về việc nhận ra sai lầm nào được phạm và sai lầm nào không. Vậy nên ván cờ chạy, bạn xem, và tới một lúc bạn chốt một con số.',
          'Các ván là thật, lấy từ kho lưu trữ của Lichess, hai kỳ thủ cách nhau dưới 150 điểm — một phỏng đoán về “các kỳ thủ” chỉ có nghĩa khi chỉ có một trình độ để đoán.',
        ],
        free: 'Năm lượt mỗi ngày với tài khoản miễn phí.',
        stat: 'ván có hệ số, từ 800 đến 2599',
      },
      {
        title: 'Xem',
        lede: 'Chín trăm ván đáng xem — và đúng lúc bạn định đi khác, bạn tiếp quản luôn.',
        body: [
          'Mỗi ván trong thư viện đều có kết quả phân định, giữa hai kỳ thủ có tên tuổi, và hoặc kết thúc trong hai mươi lăm nước, hoặc đủ nổi tiếng để có tên riêng. Chẳng ai học được gì từ một ván hòa chín mươi nước giữa những người mình chưa từng nghe tên, và một thư viện chứa thứ đó là thư viện không ai mở lần thứ hai.',
          'Hãy tra một kỳ thủ, một giải đấu, hay một năm. Rồi đi qua ván cờ theo nhịp của bạn. Chuyện không nằm ở những khoảnh khắc đỉnh cao: chuyện nằm ở chỗ tới một nước nào đó bạn sẽ nghĩ <em>chỗ ấy tôi đã ăn</em> — và đúng lúc đó bạn làm được. Hãy tiếp quản thế cờ và chơi tiếp với máy từ chính ô mà bạn không đồng ý. Tìm ra ý tưởng của bạn thực sự đáng giá bao nhiêu, đó chính là toàn bộ bài tập.',
        ],
        free: 'Miễn phí, không giới hạn, luôn luôn.',
        stat: 'ván, tất cả đều phân định thắng thua',
      },
      {
        title: 'Chơi cùng huấn luyện viên',
        lede: 'Một ván trọn vẹn ở mức sức mạnh bạn chọn, với mỗi nước đi của bạn được chấm ngay khi đang chơi.',
        body: [
          'Đặt máy ở đâu đó giữa 1400 và sức mạnh tối đa rồi chơi hết ván. Mỗi nước của bạn được chấm trong lúc ván còn đang diễn ra, và huấn luyện viên giải thích nước tốt hơn sẽ đạt được điều gì — bằng lời về thế cờ, không phải bằng một con số.',
          'Đến cuối, bạn nhận được độ chính xác, số nước sai nghiêm trọng, và một khoảnh khắc duy nhất khiến bạn trả giá đắt nhất.',
        ],
        free: 'Miễn phí, không giới hạn, luôn luôn.',
      },
      {
        title: 'Trực tuyến',
        lede: 'Hai con người, một đồng hồ, và không có máy cờ nào bên cạnh.',
        body: [
          'Game Center tìm một người đã chọn cùng thể thức — 3, 5, 10, 15 hoặc 30 phút. Đây là chế độ duy nhất không có máy bên trong: không gợi ý, không đánh giá nước đi, không huấn luyện, vì sự trợ giúp mà chỉ một bên nhận được thì không phải một ván cờ.',
          'Không có máy chủ. Hai thiết bị nói chuyện với nhau và cả hai đều thi hành luật, nên một nước chỉ được đi nếu nó hợp lệ trong thế cờ mà thiết bị nhận đã có. Một đối thủ nói dối chỉ tạo ra một gói tin bị bỏ, chứ không tạo ra một bàn cờ phạm luật.',
        ],
        free: 'Miễn phí, không giới hạn, luôn luôn.',
      },
    ],
    watchLink: 'Cái gì vào được thư viện và cái gì thì không →',
    pipeline: {
      slug: 'Một thế cờ được làm ra thế nào',
      title: 'Khai thác ra, chứ không chép lại.',
      lede: 'Chép thế cờ theo trí nhớ có nguy cơ tạo ra một bài mà “lời giải” sai hoặc không duy nhất, và điều đó rèn đúng cái phản xạ sai. Vậy nên không thế nào được chép theo trí nhớ. Chúng được tìm ra rồi bị tấn công cho đến khi sống sót hoặc bị loại.',
      steps: [
        {
          title: 'Chơi ở mức sức mạnh của con người',
          body: 'Stockfish tự chơi với chính nó ở mức sức mạnh cố ý mang tính con người — 1320 đến 2500 Elo — mở đầu bằng một lựa chọn ngẫu nhiên trong số các ứng viên nông tốt nhất của nó, để các ván khác nhau thay vì lặp mãi một biến.',
        },
        {
          title: 'Sàng theo tính chất, không theo nước hỏng',
          body: 'Mỗi thế được tìm kiếm ở độ sâu 12 với hai nhánh ứng viên. Tín hiệu không phải là “ai đó đi hỏng” mà là điều một bài tập thực sự cần: một nước tốt hơn hẳn mọi phương án khác.',
        },
        {
          title: 'Tìm sâu lại, có biên độ',
          body: 'Những thế sống sót được tìm lại ở độ sâu 20 với MultiPV. Một ứng viên chỉ ở lại nếu nước tốt nhất hơn nước nhì ít nhất 140 phần trăm của một tốt và đồng thời thực sự đạt được điều gì đó.',
        },
        {
          title: 'Kéo dài cho tới khi rẽ nhánh',
          body: 'Lời giải được kéo dài từng nước chừng nào mỗi nước của người giải vẫn là nước tốt nhất duy nhất. Ngay khi có hai câu trả lời tốt, bài tập kết thúc ở đó — nên nó không bao giờ có một nhánh rẽ khiến bạn bị tính là sai.',
        },
        {
          title: 'Kiểm chứng bằng một máy cờ mới',
          body: 'Toàn bộ tập hợp được rà lại ở độ sâu lớn hơn bằng một tập lệnh riêng với một máy mới. Trên tập khai thác đi kèm, việc đó loại 6 trong 172 bài mà lời giải thôi không còn duy nhất khi đi sâu thêm hai nửa nước. Chúng bị bỏ đi chứ không được đóng gói.',
        },
      ],
    },
    honest: {
      title: 'Và cũng chính sự nghi ngờ ấy áp lên các bài tàn cuộc',
      body: [
        'Kết quả được khai báo của mỗi bài tàn cuộc đều được đối chiếu với một lượt tìm sâu chứ không tin theo lời. Một bài gán nhãn sai sẽ trượt khâu kiểm chứng thay vì lặng lẽ dạy bạn một điều không đúng.',
        'Bộ kiểm chứng còn bắt được một thứ mà các thư viện cờ thông thường không nói cho bạn: bên không đến lượt đi có đang bị chiếu hay không. Một thế như vậy là phạm luật — không ván cờ nào tới được nó — nhưng thư viện lại vui vẻ chấp nhận, còn máy trả lời bestmove (none), nghe như máy hỏng chứ không như một thế cờ tồi. Ba bài viết tay đã hỏng đúng kiểu đó. Giờ khâu kiểm chứng bắt được.',
      ],
    },
    limits: {
      slug: 'Những giới hạn thành thật',
      title: 'Cái này không làm được gì.',
      items: [
        {
          title: 'Tập hợp trộn hai thang xếp hạng.',
          body: '{lichess} thế cờ Lichess mang hệ số được hiệu chỉnh trên hàng triệu lượt thử của con người. {mined} thế khai thác tại chỗ mang ước lượng suy từ độ sâu lời giải và mô-típ. Cả hai đều sắp xếp hợp lý, nhưng một mức 1600 khai thác và một mức 1600 Lichess không được đo theo cùng cách.',
        },
        {
          title: 'Hệ số thế cờ không phải hệ số bàn cờ.',
          body: 'Nó cao hơn vài trăm điểm, và sẽ vẫn thế. Nó đo tiến bộ so với chính bạn, chứ không đo sức mạnh trước một đám người ngồi trước đồng hồ — {link}, vì khoảng cách đó mang tính cấu trúc chứ không phải dấu hiệu bạn kết thúc ván kém.',
        },
        {
          title: 'Không có phần luyện khai cuộc.',
          body: 'Cố ý như vậy. Học khai cuộc là học thuộc theo một hệ thống bạn tự chọn, và đó là một công cụ khác với hình dạng khác. Chế độ thế trận bao quát đoạn chuyển ra khỏi khai cuộc, và chính phần ấy mới thực sự khái quát hóa được.',
        },
        {
          title: 'Cái này không biến bạn thành đại kiện tướng.',
          body: 'Chẳng thứ gì tự mình làm được điều đó. Danh hiệu đến từ hàng nghìn giờ cộng với các ván giải có hệ số trước những con người. Cái bạn nhận ở đây là nửa phần luyện tập của điều đó, có tổ chức, kèm một thước đo thành thật về chỗ bạn thực sự đang đứng.',
        },
      ],
      ratingsLink: 'đáng để hiểu cho đúng',
    },
    more: {
      motifs: 'Hai mươi mô-típ, được định nghĩa và đếm →',
      engine: 'Máy cờ được dùng thế nào →',
    },
  },

  tactics: {
    head: {
      slug: 'Bảng thuật ngữ',
      title: 'Hai mươi mô-típ',
      lede: 'Mọi đòn chiến thuật trong cờ vua đều là một trong số ít hình dạng, và ngay khi gọi được tên chúng, bạn nhìn ra chúng sớm hơn một nước. Đây là những mô-típ mà Brass Pawn dùng để gắn nhãn các thế cờ của mình — mỗi cái kèm theo con số thế cờ trong thư viện đi kèm thực sự xoay quanh nó.',
      meta: 'Đếm từ tập hợp đi kèm gồm 14.351 thế cờ · Kiểm tra lần cuối ngày 19 tháng 8 năm 2026',
    },
    meta: {
      title: 'Hai mươi mô-típ',
      description:
        'Mỗi mô-típ chiến thuật mà Brass Pawn dùng để gắn nhãn các thế cờ, được định nghĩa và đếm dựa trên thư viện đi kèm, để bạn biết mình thực sự luyện được những cái nào.',
    },
    indexLabel: 'Các mô-típ',
    puzzles: 'thế cờ',
    motifs: [
      {
        name: 'Chĩa đôi',
        short: 'Một quân tấn công hai thứ cùng lúc, và chỉ cứu được một.',
        body: 'Mã là quân chĩa đôi nổi tiếng vì nó đánh vào những ô mà không quân nào khác bao quát theo cách ấy, nhưng cái gì cũng chĩa đôi được: một tốt chạm tới hai quân nhẹ, một hậu chạm tới xe và một tượng bơ vơ, một vua trong tàn cuộc bước vào giữa hai tốt. Phép thử không phải “tôi có tấn công hai thứ không” mà là “cả hai có thoát được không”.',
      },
      {
        name: 'Ghim',
        short: 'Một quân không nhúc nhích được vì phía sau nó là thứ giá trị hơn.',
        body: 'Tuyệt đối khi phía sau là vua — đi là phạm luật, chứ không chỉ là dở. Tương đối khi phía sau là hậu hoặc xe, khi đó đi vẫn hợp lệ và đơn giản là mất quân. Phần tiếp theo mới thắng: quân bị ghim là quân không bảo vệ được, nên hãy chất thêm quân tấn công lên nó, hoặc đánh nó bằng một tốt.',
      },
      {
        name: 'Xiên',
        short: 'Ghim theo chiều ngược: quân giá trị đứng trước và buộc phải đi.',
        body: 'Chiếu vua dọc một đường bằng xe, tượng hoặc hậu, và thứ đứng phía sau là của bạn ngay khi vua né sang. Đòn xiên hiếm hơn đòn ghim vì nó cần hai quân đã sẵn nằm trên một đường với quân giá trị hơn ở phía trước — vì thế nó thường xuất hiện sau khi một nước chiếu đã đẩy vua vào đó.',
      },
      {
        name: 'Đòn mở',
        short: 'Dịch một quân đi làm lộ ra đòn tấn công của quân đứng sau nó.',
        body: 'Là đòn chiến thuật mạnh nhất trong cờ vua, cách biệt hẳn, vì quân rời đi được tự do làm việc của riêng nó trong khi đòn tấn công vừa lộ ra lo phần việc kia. Hai mối đe dọa sinh ra chỉ trong một nước, và không mối nào hóa giải được bằng cách ăn quân vừa rời đi.',
      },
      {
        name: 'Chiếu mở',
        short:
          'Đòn tấn công vừa lộ ra chính là một nước chiếu, nên đối thủ không còn thời gian cho việc gì khác.',
        body: 'Một đòn mở trong đó quân phía sau chiếu. Quân rời đi làm gì cũng được — ăn hậu, đứng vào ô chiếu hết, tự đưa mình vào chỗ bị ăn — câu trả lời vẫn phải lo nước chiếu trước đã, nên mọi thứ diễn ra miễn phí.',
      },
      {
        name: 'Chiếu đôi',
        short: 'Hai quân chiếu cùng lúc, nên vua buộc phải đi. Không chắn được, không ăn được.',
        body: 'Đòn duy nhất mà trước nó chỉ tồn tại đúng một loại đáp án hợp lệ. Ăn một quân chiếu thì còn quân kia; chắn một đường thì đường còn lại vẫn mở. Vì thế chiếu đôi tạo ra những nước chiếu hết trông như bất khả — bên phòng thủ có thể có năm cách chặn từng nước chiếu riêng lẻ và không cách nào chặn được cả hai.',
      },
      {
        name: 'Đánh lạc hướng',
        short: 'Buộc một quân phòng thủ rời khỏi công việc nó đang làm.',
        body: 'Một quân đang giữ ô chiếu hết, giữ hàng cuối, hoặc giữ một quân khác. Hãy tấn công thứ nó coi trọng hơn, hoặc đơn giản là ăn thứ mà nó buộc phải ăn lại, và sự bảo vệ nó từng đảm nhận cũng ra đi theo. Nước thí thường trông vô lý cho tới khi bạn nhận ra quân ăn lại đã thôi không còn bảo vệ cái gì.',
      },
      {
        name: 'Dụ quân',
        short: 'Dụ một quân — thường là vua — vào ô mà nó có thể bị đánh trúng.',
        body: 'Một nước thí mà đối thủ buộc phải nhận, đi không phải để ăn quân mà để đặt một quân vào chỗ chí tử: một vua bị lôi vào ô chĩa đôi, một hậu bị kéo lên cùng đường với xe. Quân thí trở về một nước sau đó kèm lãi.',
      },
      {
        name: 'Giải tỏa',
        short: 'Dời quân của chính bạn ra khỏi đường tấn công của chính bạn.',
        body: 'Đường hay ô ấy là đúng, chỉ có điều đang có người của bạn đứng đó. Đòn giải tỏa dời nó đi kèm tempo — thường là kèm chiếu hoặc ăn quân, để đối thủ không kịp bố trí lại trong lúc con đường mở ra.',
      },
      {
        name: 'Chắn đường',
        short: 'Cắt đường giữa một quân phòng thủ và thứ nó đang bảo vệ.',
        body: 'Đặt một quân — thường là quân thí — đúng vào giữa một xe và ô mà xe đó canh. Quân phòng thủ vẫn còn trên bàn, trên lý thuyết vẫn đang bảo vệ, và đã không thể. Hiếm, và là một trong những mẫu hình khó thấy nhất, vì quân chắn đường thường trông như một nước hỏng.',
      },
      {
        name: 'Đòn tia X',
        short: 'Một quân tác động xuyên qua một quân khác, dọc theo đường nó sẽ chiếm về sau.',
        body: 'Một xe bảo vệ quân của mình xuyên qua một quân đối phương, hoặc tấn công xuyên qua nó. Hiện chưa có gì xảy ra; điều quan trọng là chuyện gì xảy ra khi quân ở giữa dời đi hoặc bị ăn. Nhìn ra được một đòn tia X thường chính là thứ khiến một nước ăn tưởng “mất quân” hóa ra không mất quân.',
      },
      {
        name: 'Nước đi xen',
        short: 'Nước ở giữa: trước khi ăn lại, hãy làm một việc ép buộc hơn.',
        body: 'Từ tiếng Đức “Zwischenzug”, và là lý do đơn lẻ hay gặp nhất khiến một biến đã tính ra lại hóa sai. Bạn chờ một nước ăn lại; thay vào đó là một nước chiếu, hoặc một đe dọa lớn hơn, và tới khi nước ăn lại xảy ra thì thế cờ đã đổi. Hãy tìm nó mỗi lần một chuỗi nước trông có vẻ bị ép buộc.',
      },
      {
        name: 'Zugzwang',
        short: 'Chính nghĩa vụ phải đi là vấn đề.',
        body: 'Mọi nước hợp lệ đều làm thế cờ xấu đi, mà bỏ lượt thì không được phép. Chủ yếu là ý tưởng tàn cuộc — nó quyết định các tàn cuộc tốt — và là lý do “thế đối” lại quan trọng: ai phải né sang trước thì nhường ô. Gần như là tình huống duy nhất trong cờ vua mà quyền được đi lại là gánh nặng.',
      },
      {
        name: 'Chiếu hết hàng cuối',
        short: 'Một vua bị chính các tốt của mình vây kín bị chiếu hết ở hàng thứ nhất.',
        body: 'Là nước chiếu hết phổ biến nhất giữa những người đã nhập thành và để yên hàng tốt. Nó ít khi hiện ra như một nước chiếu hết trên bàn — nó hiện ra như một đe dọa giúp ăn quân, vì mỗi nước phòng thủ đều phải tiếp tục canh hàng đó. Cả họ nhà đòn đánh lạc hướng tồn tại là để gỡ bỏ sự canh giữ ấy.',
      },
      {
        name: 'Chiếu hết nghẹt thở',
        short: 'Một mã chiếu hết vị vua bị chính quân mình vây kín.',
        body: 'Đoạn kết của di sản Philidor: thí hậu ở g8, xe ăn lại, mã ở f7 chiếu hết trong khi vua bị chính người của mình vây quanh. Hiếm trong ván thật mà vẫn đáng biết, vì chính mẫu hình này khiến bạn nhìn vào góc bàn và đếm ô thoát.',
      },
      {
        name: 'Quân treo',
        short: 'Một thứ đơn giản là không được bảo vệ và có thể ăn được.',
        body: 'Không hào nhoáng, mà quyết định nhiều ván hơn tất cả những thứ khác trong danh sách này cộng lại. Phần lớn trận thua dưới mức 1800 là một bên ăn quân miễn phí mà bên kia bỏ sót. Thói quen chữa được điều đó là kiểm tra xem cái gì đang đứng trơ trọi — ở cả hai bên — trước mỗi nước đi.',
      },
      {
        name: 'Quân bị bẫy',
        short: 'Một quân không còn ô an toàn nào và có thể bị săn một cách thong thả.',
        body: 'Thường là một tượng đã ăn con tốt lẽ ra nên để yên, hoặc một mã đi kiếm mồi. Đòn này không phải một cú đánh mà là một sự bóp nghẹt: lấy đi từng ô một, rồi quân đó đổ mà chẳng cần thí gì.',
      },
      {
        name: 'Nước đi thầm lặng',
        short: 'Nước thắng không phải là chiếu, không phải ăn quân, cũng không phải một đe dọa.',
        body: 'Là lý do người mạnh tìm ra những phối hợp mà người khác bỏ sót. Sau một chuỗi ép buộc, đáp án lại là một nước khiêm nhường lấy đi ô thoát cuối cùng, và nó vô hình với ai chỉ tính chiếu và ăn. Khi một thế cờ trông như đã thắng mà chẳng nước ép buộc nào ăn thua, hãy tìm nước thầm lặng.',
      },
      {
        name: 'Thí quân',
        short: 'Cho đi quân để đổi lấy thứ đáng giá hơn quân.',
        body: 'Thời gian, các đường, các ô, hoặc vị trí vua đối phương. Một nước thí thật sự không phải một canh bạc; nó là một phép tính có điểm kết cụ thể. Thứ phân tách một nước thí chạy được với một nước thí không chạy hầu như luôn là: các quân phòng thủ có kịp quay về hay không.',
      },
      {
        name: 'Tốt tiến sâu',
        short: 'Một tốt sắp phong cấp làm thay đổi giá trị của mọi quân khác.',
        body: 'Một tốt ở hàng bảy không còn là tốt; nó là một hậu mà thứ gì đó buộc phải canh, và thứ đó thôi không còn tự do. Phần lớn đòn tàn cuộc thực chất nói về sự giằng co giữa việc chặn một tốt và việc làm bất cứ điều gì khác.',
      },
    ],
    after: {
      slug: 'Vì sao các con số ở đây',
      title: 'Bảng thuật ngữ cho biết chĩa đôi là gì. Con số cho biết bạn có luyện nó được không.',
      body: [
        'Biết tên một mẫu hình và tìm ra nó dưới đồng hồ là hai kỹ năng khác nhau, và chỉ cái thứ hai mới thắng ván cờ. Mỗi con số ở trên là số thế cờ thật sự trong thư viện đi kèm được gắn nhãn mô-típ đó — không phải ước lượng, và không làm tròn lên. Sáu mươi thế cờ tia X là sáu mươi; nếu đó đúng là thứ bạn cứ bỏ sót, thì biết rằng chúng không cạn trong một tối là điều tốt.',
        'Huấn luyện viên theo dõi bạn sai ở những mô-típ nào, để sau vài trăm thế cờ, nó có thể nói với bạn không phải rằng bạn ở mức 1620, mà rằng bạn ở mức 1620 và cứ mắc mãi vào các đòn đánh lạc hướng.',
      ],
      more: 'Các thế cờ được khai thác và kiểm chứng thế nào →',
    },
  },
};
