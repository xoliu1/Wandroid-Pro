class Message {
  /// 消息分类：999=系统消息，2=问答消息 1=评论回复
  final int category;
  /// 消息时间戳（毫秒）
  final int date;
  /// 发送人昵称
  final String fromUser;
  /// 发送人用户ID
  final int fromUserId;
  /// 完整外链地址
  final String fullLink;
  /// 消息唯一ID
  final int id;
  /// 是否已读：1已读，0未读
  final int isRead;
  /// 短链地址
  final String link;
  /// 消息正文内容
  final String message;
  /// 格式化后的友好时间
  final String niceDate;
  /// 消息标签，如“系统消息”
  final String tag;
  /// 消息标题
  final String title;
  /// 接收人用户ID
  final int userId;

  Message({
    required this.category,
    required this.date,
    required this.fromUser,
    required this.fromUserId,
    required this.fullLink,
    required this.id,
    required this.isRead,
    required this.link,
    required this.message,
    required this.niceDate,
    required this.tag,
    required this.title,
    required this.userId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      category: json['category'] ?? 0,
      date: json['date'] ?? 0,
      fromUser: json['fromUser'] ?? '',
      fromUserId: json['fromUserId'] ?? 0,
      fullLink: json['fullLink'] ?? '',
      id: json['id'] ?? 0,
      isRead: json['isRead'] ?? 0,
      link: json['link'] ?? '',
      message: json['message'] ?? '',
      niceDate: json['niceDate'] ?? '',
      tag: json['tag'] ?? '',
      title: json['title'] ?? '',
      userId: json['userId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'date': date,
        'fromUser': fromUser,
        'fromUserId': fromUserId,
        'fullLink': fullLink,
        'id': id,
        'isRead': isRead,
        'link': link,
        'message': message,
        'niceDate': niceDate,
        'tag': tag,
        'title': title,
        'userId': userId,
      };
}

class MessageListResp {
  final int curPage;
  final List<Message> datas;
  final int offset;
  final bool over;
  final int pageCount;
  final int size;
  final int total;

  MessageListResp({
    required this.curPage,
    required this.datas,
    required this.offset,
    required this.over,
    required this.pageCount,
    required this.size,
    required this.total,
  });

  factory MessageListResp.fromJson(Map<String, dynamic> json) {
    return MessageListResp(
      curPage: json['curPage'] ?? 1,
      datas: (json['datas'] as List<dynamic>?)
          ?.map((e) => Message.fromJson(e))
          .toList() ?? [],
      offset: json['offset'] ?? 0,
      over: json['over'] ?? true,
      pageCount: json['pageCount'] ?? 0,
      size: json['size'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class UnreadCountResp {
  final int count;

  UnreadCountResp({required this.count});

  factory UnreadCountResp.fromJson(Map<String, dynamic> json) {
    return UnreadCountResp(
      count: json['data'] ?? 0,
    );
  }
}