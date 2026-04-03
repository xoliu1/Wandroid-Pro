/// 文章数据模型
/// 对应玩Android开放API返回的文章信息
class Article {
  /// 文章唯一标识
  final int id;

  /// 文章标题
  final String title;

  /// 文章原始链接
  final String link;

  /// 文章作者（官方文章）
  final String? author;

  /// 分享人（用户分享的文章）
  final String? shareUser;

  /// 友好格式的时间（如"2小时前"、"2025-08-06"）
  final String niceDate;

  /// 文章所属二级分类名称（如"自助"）
  final String? chapterName;

  /// 文章所属一级分类名称（如"广场Tab"）
  final String? superChapterName;

  /// 文章所属二级分类ID
  final int? chapterId;

  /// 文章所属一级分类ID
  final int? superChapterId;

  /// 是否已收藏（可动态修改）
  bool collect;

  /// 是否为最新文章
  final bool fresh;

  /// 文章标签列表（如"项目"、"公众号"等）
  final List<dynamic> tags;

  /// 文章描述/摘要
  final String? desc;

  /// 文章封面图片链接
  final String? envelopePic;

  Article({
    required this.id,
    required this.title,
    required this.link,
    this.author,
    this.shareUser,
    required this.niceDate,
    this.chapterName,
    this.superChapterName,
    this.chapterId,
    this.superChapterId,
    required this.collect,
    required this.fresh,
    required this.tags,
    this.desc,
    this.envelopePic,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      author: json['author']?.toString(),
      shareUser: json['shareUser']?.toString(),
      niceDate: json['niceDate'] ?? '',
      chapterName: json['chapterName']?.toString(),
      superChapterName: json['superChapterName']?.toString(),
      chapterId: json['chapterId'],
      superChapterId: json['superChapterId'],
      collect: json['collect'] ?? false,
      fresh: json['fresh'] ?? false,
      tags: json['tags'] ?? [],
      desc: json['desc']?.toString(),
      envelopePic: json['envelopePic']?.toString(),
    );
  }

  //作者/分享人
  String get displayAuthor {
    if (author != null && author!.isNotEmpty) {
      return author!;
    } else if (shareUser != null && shareUser!.isNotEmpty) {
      return shareUser!;
    }
    return '匿名';
  }

  //分类
  String get displayCategory {
    if (superChapterName != null && superChapterName!.isNotEmpty && chapterName != null && chapterName!.isNotEmpty) {
      return '$superChapterName/$chapterName';
    } else if (superChapterName != null && superChapterName!.isNotEmpty) {
      return superChapterName!;
    } else if (chapterName != null && chapterName!.isNotEmpty) {
      return chapterName!;
    }
    return '未分类';
  }

  bool get hasImage => envelopePic != null && envelopePic!.isNotEmpty;


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'link': link,
      'author': author,
      'shareUser': shareUser,
      'niceDate': niceDate,
      'chapterName': chapterName,
      'superChapterName': superChapterName,
      'chapterId': chapterId,
      'superChapterId': superChapterId,
      'collect': collect,
      'fresh': fresh,
      'tags': tags,
      'desc': desc,
      'envelopePic': envelopePic,
    };
  }
}